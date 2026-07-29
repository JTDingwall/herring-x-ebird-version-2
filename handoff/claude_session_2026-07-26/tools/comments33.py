# -*- coding: utf-8 -*-
"""Re-anchor the author's 15 comments in v33, reply to each, and mark resolved.

The v31 build destroyed most comment anchors (12 of 15 commentReference runs
and 3 of 15 ranges), so they are rebuilt here from scratch rather than patched:
each comment is re-attached to whichever v33 paragraph best matches the v30
paragraph it was originally written against.
"""
import copy, difflib, json, shutil, zipfile
from lxml import etree

W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
W15 = "http://schemas.microsoft.com/office/word/2012/wordml"
W14 = "http://schemas.microsoft.com/office/word/2010/wordml"
w = lambda t: "{%s}%s" % (W, t)
w15 = lambda t: "{%s}%s" % (W15, t)
w14 = lambda t: "{%s}%s" % (W14, t)

DOC = "/sessions/keen-confident-allen/mnt/outputs/mer_manuscript_v33.docx"
V30 = ("/sessions/keen-confident-allen/mnt/uploads/"
       "37a27e84-b9b8-4f60-8722-c8fb9e53a776-1785110454677_mer_manuscript_v30.docx")
AUTHOR = "Claude (editorial pass)"
DATE = "2026-07-26T00:00:00Z"

from comments import REPLIES          # the 15 replies, unchanged


def ptext(p):
    return "".join(t.text or "" for t in p.iter(w("t")))


def main():
    zin = zipfile.ZipFile(DOC)
    parts = {i.filename: zin.read(i.filename) for i in zin.infolist()}
    infos = list(zin.infolist())

    droot = etree.fromstring(parts["word/document.xml"])
    croot = etree.fromstring(parts["word/comments.xml"])
    eroot = etree.fromstring(parts["word/commentsExtended.xml"])
    body = droot.find(w("body"))

    # --- where each comment was originally anchored, in v30 ---
    z30 = zipfile.ZipFile(V30)
    d30 = etree.fromstring(z30.read("word/document.xml"))
    anchor_text = {}
    for p in d30.find(w("body")).findall(w("p")):
        ids = [s.get(w("id")) for s in p.iter(w("commentRangeStart"))]
        for cid in ids:
            anchor_text[int(cid)] = ptext(p)

    # --- strip every existing comment anchor; they are unreliable ---
    for tag in ("commentRangeStart", "commentRangeEnd"):
        for el in droot.findall(".//" + w(tag)):
            el.getparent().remove(el)
    for ref in droot.findall(".//" + w("commentReference")):
        run = ref.getparent()
        run.getparent().remove(run)

    # --- keep only the author's originals in comments.xml ---
    originals = {}
    for c in list(croot.findall(w("comment"))):
        cid = int(c.get(w("id")))
        if cid in REPLIES:
            originals[cid] = c
        else:
            croot.remove(c)
    for ex in list(eroot.findall(w15("commentEx"))):
        eroot.remove(ex)

    paras = body.findall(w("p"))
    texts = [ptext(p) for p in paras]
    used = set()

    def best_para(target_text):
        best, score = None, 0.0
        for k, t in enumerate(texts):
            if not t.strip() or k in used:
                continue
            r = difflib.SequenceMatcher(
                None, target_text.strip()[:300], t.strip()[:300],
                autojunk=False).ratio()
            if r > score:
                best, score = k, r
        return best, score

    def run_with(el_tag, cid, template):
        r = copy.deepcopy(template)
        for c in list(r):
            if c.tag != w("rPr"):
                r.remove(c)
        etree.SubElement(r, w(el_tag)).set(w("id"), str(cid))
        return r

    next_id = max(REPLIES) + 100
    n_anchor = n_reply = 0
    for cid in sorted(REPLIES):
        src = originals.get(cid)
        if src is None:
            continue
        k, score = best_para(anchor_text.get(cid, ""))
        if k is None or score < 0.30:
            continue
        used.add(k)
        p = paras[k]
        tmpl = next((r for r in p.findall(w("r"))), etree.Element(w("r")))

        start = etree.Element(w("commentRangeStart"))
        start.set(w("id"), str(cid))
        p.insert(0, start)
        end = etree.SubElement(p, w("commentRangeEnd"))
        end.set(w("id"), str(cid))
        p.append(run_with("commentReference", cid, tmpl))
        n_anchor += 1

        # --- the reply ---
        rid = next_id
        next_id += 1
        reply = copy.deepcopy(src)
        reply.set(w("id"), str(rid))
        reply.set(w("author"), AUTHOR)
        reply.set(w("initials"), "C")
        reply.set(w("date"), DATE)
        for q in reply.findall(w("p")):
            reply.remove(q)
        rp = etree.SubElement(reply, w("p"))
        para_id = "%08X" % (0x5A000000 + rid)
        rp.set(w14("paraId"), para_id)
        rp.set(w14("textId"), para_id)
        rr = etree.SubElement(rp, w("r"))
        rt = etree.SubElement(rr, w("t"))
        rt.text = REPLIES[cid]
        rt.set("{http://www.w3.org/XML/1998/namespace}space", "preserve")
        croot.append(reply)

        rstart = etree.Element(w("commentRangeStart"))
        rstart.set(w("id"), str(rid))
        p.insert(0, rstart)
        rend = etree.SubElement(p, w("commentRangeEnd"))
        rend.set(w("id"), str(rid))
        p.append(run_with("commentReference", rid, tmpl))

        src_pid = src.find(w("p")).get(w14("paraId")) if src.find(w("p")) is not None else None
        ex = etree.SubElement(eroot, w15("commentEx"))
        if src_pid:
            ex.set(w15("paraId"), src_pid)
        ex.set(w15("done"), "1")
        ex2 = etree.SubElement(eroot, w15("commentEx"))
        ex2.set(w15("paraId"), para_id)
        if src_pid:
            ex2.set(w15("paraIdParent"), src_pid)
        ex2.set(w15("done"), "1")
        n_reply += 1

    for name, root_ in (("word/document.xml", droot),
                        ("word/comments.xml", croot),
                        ("word/commentsExtended.xml", eroot)):
        parts[name] = etree.tostring(root_, xml_declaration=True,
                                     encoding="UTF-8", standalone=True)
    tmp = DOC + ".tmp"
    with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as dst:
        for info in infos:
            dst.writestr(info, parts[info.filename])
    shutil.move(tmp, DOC)
    print("comments re-anchored : %d" % n_anchor)
    print("replies written      : %d" % n_reply)


if __name__ == "__main__":
    main()
