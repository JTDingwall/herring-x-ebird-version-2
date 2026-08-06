"""Tracked-change helpers for Word documents.

python-docx has no API for w:ins / w:del, so these operate on the XML directly.
Workflow: accept the author's own revisions first, then rewrite paragraphs so
that every difference from that accepted baseline appears as a tracked change
attributed to the editor.
"""
import copy
import difflib
import re

from lxml import etree

W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
w = lambda t: "{%s}%s" % (W, t)

AUTHOR = "Claude (editorial pass)"
DATE = "2026-07-26T00:00:00Z"


class Rev:
    """Monotonic revision ids. Word requires them unique across the document."""

    def __init__(self, start=9000):
        self.n = start

    def __call__(self):
        self.n += 1
        return str(self.n)


def accept_all(root):
    """Accept every existing revision: unwrap w:ins, drop w:del outright."""
    # Note which paragraph marks are deleted BEFORE the w:del sweep below
    # removes those markers along with the content deletions.
    body = root.find(w("body")) if root.tag == w("document") else root
    mark_deleted = []
    if body is not None:
        for p in body.findall(w("p")):
            pPr = p.find(w("pPr"))
            if pPr is not None:
                rPr = pPr.find(w("rPr"))
                if rPr is not None and rPr.find(w("del")) is not None:
                    mark_deleted.append(p)
    for ins in root.findall(".//" + w("ins")):
        parent = ins.getparent()
        idx = list(parent).index(ins)
        for child in reversed(list(ins)):
            parent.insert(idx, child)
        parent.remove(ins)
    for de in root.findall(".//" + w("del")):
        de.getparent().remove(de)
    # A w:delText left anywhere else becomes ordinary text.
    for dt in root.findall(".//" + w("delText")):
        dt.tag = w("t")
    # A paragraph whose mark was deleted merges into the next one; if it is now
    # empty, drop it. Word does this on accept; do it here so verification of an
    # accept-all pass matches what the author will actually see.
    for p in mark_deleted:
        if not "".join(t.text or "" for t in p.iter(w("t"))).strip():
            p.getparent().remove(p)
    return root


def para_text(p):
    return "".join(t.text or "" for t in p.iter(w("t")))


def _template_run(p):
    """Reuse the paragraph's first run so character formatting survives."""
    for r in p.iter(w("r")):
        return copy.deepcopy(r)
    r = etree.SubElement(etree.Element(w("p")), w("r"))
    return r


def _make_run(template, text, deleted=False):
    r = copy.deepcopy(template)
    # Keep run properties only. Anything else carried over from the template
    # gets duplicated into every rebuilt run; a commentReference cloned this way
    # made the whole paragraph vanish when comment anchors were later stripped.
    for child in list(r):
        if child.tag != w("rPr"):
            r.remove(child)
    el = etree.SubElement(r, w("delText") if deleted else w("t"))
    el.text = text
    el.set("{http://www.w3.org/XML/1998/namespace}space", "preserve")
    return r


def _content_children(p):
    """Runs and similar, excluding pPr and bookmark/comment plumbing."""
    return [c for c in p if c.tag not in (w("pPr"),)]


def rewrite_tracked(p, new_text, rev, author=AUTHOR):
    """Replace a paragraph's text, marking the delta as tracked changes.

    Word-level diff, so an edit touching one clause does not mark the whole
    paragraph as rewritten. Runs that carry no text (images, comment anchors,
    bookmarks) are preserved in place.
    """
    old_text = para_text(p)
    if old_text == new_text:
        return False

    template = _template_run(p)
    keep = [c for c in _content_children(p)
            if c.tag in (w("commentRangeStart"), w("commentRangeEnd"),
                         w("bookmarkStart"), w("bookmarkEnd"))
            or (c.tag == w("r") and not c.findall(w("t")))]

    for c in _content_children(p):
        p.remove(c)
    for c in keep:
        p.append(c)

    old_w = re.findall(r"\S+\s*", old_text)
    new_w = re.findall(r"\S+\s*", new_text)
    sm = difflib.SequenceMatcher(None, old_w, new_w, autojunk=False)

    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag in ("equal",):
            p.append(_make_run(template, "".join(old_w[i1:i2])))
        else:
            if tag in ("replace", "delete"):
                d = etree.SubElement(p, w("del"))
                d.set(w("id"), rev())
                d.set(w("author"), author)
                d.set(w("date"), DATE)
                d.append(_make_run(template, "".join(old_w[i1:i2]), deleted=True))
            if tag in ("replace", "insert"):
                a = etree.SubElement(p, w("ins"))
                a.set(w("id"), rev())
                a.set(w("author"), author)
                a.set(w("date"), DATE)
                a.append(_make_run(template, "".join(new_w[j1:j2])))
    return True


def delete_paragraph_tracked(p, rev, author=AUTHOR):
    """Mark a whole paragraph deleted, including its paragraph mark."""
    text = para_text(p)
    if not text.strip():
        return False
    template = _template_run(p)
    for c in _content_children(p):
        p.remove(c)
    d = etree.SubElement(p, w("del"))
    d.set(w("id"), rev())
    d.set(w("author"), author)
    d.set(w("date"), DATE)
    d.append(_make_run(template, text, deleted=True))
    # Mark the paragraph mark itself deleted so the paragraph merges away.
    pPr = p.find(w("pPr"))
    if pPr is None:
        pPr = etree.Element(w("pPr"))
        p.insert(0, pPr)
    rPr = pPr.find(w("rPr"))
    if rPr is None:
        rPr = etree.SubElement(pPr, w("rPr"))
    dm = etree.SubElement(rPr, w("del"))
    dm.set(w("id"), rev())
    dm.set(w("author"), author)
    dm.set(w("date"), DATE)
    return True


MATH = "{http://schemas.openxmlformats.org/officeDocument/2006/math}oMath"
DRAW = "{http://schemas.openxmlformats.org/drawingml/2006/main}blip"


def has_embedded_objects(p):
    """Equations and images are not text and cannot survive a word-level diff."""
    return bool(p.findall(".//" + MATH) or p.findall(".//" + DRAW))


def set_tracked(p, old_text, new_text, rev, author=AUTHOR):
    """Render the delta between two explicit strings as tracked changes.

    The paragraph currently holds new_text (it came from the later draft); this
    rewrites its content so Word shows old_text struck through and new_text
    inserted, at word granularity.
    """
    if old_text.strip() == new_text.strip() or has_embedded_objects(p):
        return False
    template = _template_run(p)
    keep = [c for c in _content_children(p)
            if c.tag in (w("commentRangeStart"), w("commentRangeEnd"),
                         w("bookmarkStart"), w("bookmarkEnd"))
            or (c.tag == w("r") and not c.findall(w("t")))]
    for c in _content_children(p):
        p.remove(c)
    for c in keep:
        p.append(c)

    old_w = re.findall(r"\S+\s*", old_text)
    new_w = re.findall(r"\S+\s*", new_text)
    sm = difflib.SequenceMatcher(None, old_w, new_w, autojunk=False)
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal":
            p.append(_make_run(template, "".join(old_w[i1:i2])))
            continue
        if tag in ("replace", "delete"):
            d = etree.SubElement(p, w("del"))
            d.set(w("id"), rev()); d.set(w("author"), author); d.set(w("date"), DATE)
            d.append(_make_run(template, "".join(old_w[i1:i2]), deleted=True))
        if tag in ("replace", "insert"):
            a = etree.SubElement(p, w("ins"))
            a.set(w("id"), rev()); a.set(w("author"), author); a.set(w("date"), DATE)
            a.append(_make_run(template, "".join(new_w[j1:j2])))
    return True


def delete_paragraph_tracked_text(p, text, rev, author=AUTHOR):
    """Fill an empty paragraph with text marked wholly deleted."""
    template = _template_run(p)
    for c in _content_children(p):
        p.remove(c)
    d = etree.SubElement(p, w("del"))
    d.set(w("id"), rev()); d.set(w("author"), author); d.set(w("date"), DATE)
    d.append(_make_run(template, text, deleted=True))
    pPr = p.find(w("pPr"))
    if pPr is None:
        pPr = etree.Element(w("pPr")); p.insert(0, pPr)
    rPr = pPr.find(w("rPr"))
    if rPr is None:
        rPr = etree.SubElement(pPr, w("rPr"))
    dm = etree.SubElement(rPr, w("del"))
    dm.set(w("id"), rev()); dm.set(w("author"), author); dm.set(w("date"), DATE)
    return True


def _split_run_italics(run, spans_fn):
    """Rebuild a run so only the spans returned by spans_fn are italic."""
    tel = run.find(w("t"))
    deleted = False
    if tel is None:
        tel = run.find(w("delText"))
        deleted = True
    if tel is None or not tel.text:
        return [run]
    text = tel.text
    spans = spans_fn(text)
    if not spans:
        _set_italic(run, False)
        return [run]

    out, pos = [], 0
    for a, b in spans:
        if a > pos:
            out.append(_clone_text_run(run, text[pos:a], False, deleted))
        out.append(_clone_text_run(run, text[a:b], True, deleted))
        pos = b
    if pos < len(text):
        out.append(_clone_text_run(run, text[pos:], False, deleted))
    parent = run.getparent()
    idx = list(parent).index(run)
    for k, r in enumerate(out):
        parent.insert(idx + k, r)
    parent.remove(run)
    return out


def _set_italic(run, on):
    rPr = run.find(w("rPr"))
    if rPr is None:
        rPr = etree.Element(w("rPr"))
        run.insert(0, rPr)
    i = rPr.find(w("i"))
    if on and i is None:
        etree.SubElement(rPr, w("i"))
    elif not on and i is not None:
        rPr.remove(i)
    iCs = rPr.find(w("iCs"))
    if not on and iCs is not None:
        rPr.remove(iCs)


def _clone_text_run(run, text, italic, deleted):
    r = copy.deepcopy(run)
    for child in list(r):
        if child.tag != w("rPr"):
            r.remove(child)
    el = etree.SubElement(r, w("delText") if deleted else w("t"))
    el.text = text
    el.set("{http://www.w3.org/XML/1998/namespace}space", "preserve")
    _set_italic(r, italic)
    return r


def fix_italics(paragraph, pattern):
    """Re-apply italics by content on a paragraph that was rebuilt.

    Rebuilding a paragraph from one template run makes every new run inherit
    that run's formatting, so a paragraph beginning with an italic binomial
    comes back entirely italic. This restores italics to the binomials alone.
    """
    def spans(text):
        return [(m.start(), m.end()) for m in pattern.finditer(text)]
    for run in list(paragraph.iter(w("r"))):
        _split_run_italics(run, spans)


def fix_italics_paragraph(p, pattern):
    """Italicise every match of `pattern` across a whole paragraph.

    fix_italics() works one run at a time, so a binomial split across a w:ins
    or w:del boundary is invisible to it and renders half-italic in Word. This
    builds a character map over the paragraph, finds matches in the full text,
    and splits whichever runs the match crosses.
    """
    runs = []
    for r in p.iter(w("r")):
        for tag in (w("t"), w("delText")):
            for el in r.findall(tag):
                if el.text:
                    runs.append([r, el, len(el.text)])
    if not runs:
        return 0
    text = "".join(el.text for _, el, _ in runs)
    matches = [(m.start(), m.end()) for m in pattern.finditer(text)]

    # Every run starts non-italic; matched spans are then turned back on.
    for r, _, _ in runs:
        _set_italic(r, False)
    if not matches:
        return 0

    changed = 0
    pos = 0
    for r, el, n in runs:
        start, end = pos, pos + n
        pos = end
        cuts = sorted({0, n} | {max(0, min(n, a - start)) for a, b in matches}
                      | {max(0, min(n, b - start)) for a, b in matches})
        pieces = []
        for a, b in zip(cuts, cuts[1:]):
            if a == b:
                continue
            abs_a = start + a
            ital = any(ms <= abs_a < me for ms, me in matches)
            pieces.append((el.text[a:b], ital))
        if len(pieces) <= 1:
            if pieces and pieces[0][1]:
                _set_italic(r, True)
                changed += 1
            continue
        deleted = el.tag == w("delText")
        parent = r.getparent()
        at = list(parent).index(r)
        for k, (txt, ital) in enumerate(pieces):
            parent.insert(at + k, _clone_text_run(r, txt, ital, deleted))
        parent.remove(r)
        changed += 1
    return changed


def insert_paragraph_tracked(after, text, rev, author=AUTHOR):
    """Add a wholly new paragraph after `after`, marked as an insertion.

    The paragraph mark itself carries w:ins, so rejecting the change removes the
    paragraph rather than leaving an empty one behind.
    """
    p = copy.deepcopy(after)
    for c in [c for c in p if c.tag != w("pPr")]:
        p.remove(c)
    for tag in (w("commentRangeStart"), w("commentRangeEnd")):
        for c in p.findall(tag):
            p.remove(c)
    template = _template_run(after)
    ins = etree.SubElement(p, w("ins"))
    ins.set(w("id"), rev()); ins.set(w("author"), author); ins.set(w("date"), DATE)
    ins.append(_make_run(template, text))
    pPr = p.find(w("pPr"))
    if pPr is None:
        pPr = etree.Element(w("pPr")); p.insert(0, pPr)
    rPr = pPr.find(w("rPr"))
    if rPr is None:
        rPr = etree.SubElement(pPr, w("rPr"))
    mark = etree.SubElement(rPr, w("ins"))
    mark.set(w("id"), rev()); mark.set(w("author"), author); mark.set(w("date"), DATE)
    after.addnext(p)
    return p
