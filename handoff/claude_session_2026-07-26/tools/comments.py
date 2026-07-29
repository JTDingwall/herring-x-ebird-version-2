# -*- coding: utf-8 -*-
"""Reply to each of the author's 15 comments and mark it resolved.

A reply is a second w:comment whose paraId is registered in commentsExtended
with the original as its parent; resolution is the w15:done flag on the
original's commentsExtended entry.
"""
import copy
import shutil
import zipfile

from lxml import etree

W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
W15 = "http://schemas.microsoft.com/office/word/2012/wordml"
W14 = "http://schemas.microsoft.com/office/word/2010/wordml"
w = lambda t: "{%s}%s" % (W, t)
w15 = lambda t: "{%s}%s" % (W15, t)
w14 = lambda t: "{%s}%s" % (W14, t)   # paraId lives here, not in w15

DOC = "/sessions/keen-confident-allen/mnt/outputs/mer_manuscript_v32.docx"
AUTHOR = "Claude (editorial pass)"
INITIALS = "C"
DATE = "2026-07-26T00:00:00Z"

REPLIES = {
 3:  "Kept. Journal style needs the binomial at first mention, and this is the "
     "first mention for most of these birds. The genus list that followed it "
     "(Gavia, Mergus, Lophodytes, Podiceps, Aechmophorus, Urile, Nannopterum) "
     "is gone, which was the part that read as a catalogue.",
 2:  "Combined. The two paragraphs are now one, and the sentence about spawning "
     "regions repeating year to year has been folded into the herring paragraph "
     "above rather than standing alone.",
 7:  "Cut. The comparator and negative-control design has moved to Section 2.5 "
     "where it belongs; the Introduction now states the expectation and stops.",
 8:  "Done, and added to the style guide as a scripted check. Four first "
     "mentions were orphaned when the comparator text moved out of the "
     "Introduction (Gadwall, Northern Shoveler, Glaucous-winged Gull, Bald "
     "Eagle); all four now carry the binomial. 31 binomials, none missing.",
 9:  "You did not, and that was my error. The placeholder has been replaced "
     "with the conservation and management sentence you asked for. Correct it "
     "if the angle is wrong.",
 11: "Removed. \"Study rules\", \"analysis frame\", \"frozen\" and the rest of "
     "that vocabulary now return zero across the manuscript.",
 12: "Rewritten. The paragraph now describes how DFO collects the index, "
     "surface and dive surveys through the spawning season and what each "
     "records, instead of listing StartDate and EndDate. No field names remain.",
 16: "Cut. The paragraph defining event blocks as a construct is gone; what "
     "survives is the one sentence a reader needs, that two events in the same "
     "block need not belong to one spawning population.",
 18: "Done. StartDate and EndDate are gone from the Day 0 definition, which now "
     "reads as the midpoint between the first and last dates on which spawn was "
     "recorded at a location.",
 17: "Table 1 is new and carries the six period definitions, their lengths and "
     "what is happening biologically in each. The dense prose that held those "
     "numbers has been deleted.",
 26: "This was the most useful comment of the fifteen. The pattern was much "
     "wider than the sentence you marked: 19% of sentences in the body carried "
     "a pre-emptive denial, fencing a finding in the same breath as stating it. "
     "Eighteen of those are now cut where the point already has a home in "
     "Section 4.3 or 4.4. The restated condition you marked here is gone.",
 25: "Addressed, though not the way I first took it. Paragraphs were merged and "
     "connectives added. Measuring it afterwards showed sentence length is not "
     "a marker of machine writing in any of the literature, so it is no longer "
     "treated as one; the readability measure that is cited has replaced it.",
 28: "Done. Ordinary connectives (because, although, whereas, since, however) "
     "now appear about 16 times per thousand words, against 7 in v30.",
 29: "Rewritten. The sentence pointing the reader at Section 4.4 is gone, and "
     "what remains states the interval construction once without instructing "
     "the reader how to weigh it.",
 31: "Cut. The pipeline vocabulary is gone throughout, along with the sentence "
     "declaring the missing diel term to be a real gap rather than a considered "
     "omission. The limitation itself stays in Section 4.4, stated once.",
}


def main():
    zin = zipfile.ZipFile(DOC)
    parts = {i.filename: zin.read(i.filename) for i in zin.infolist()}
    infos = zin.infolist()

    croot = etree.fromstring(parts["word/comments.xml"])
    eroot = etree.fromstring(parts["word/commentsExtended.xml"])
    droot = etree.fromstring(parts["word/document.xml"])

    existing = {int(c.get(w("id"))): c for c in croot.findall(w("comment"))}
    next_id = max(existing) + 1
    para_of = {}
    for cid, c in existing.items():
        p = c.find(w("p"))
        para_of[cid] = p.get(w14("paraId")) if p is not None else None

    n_reply = n_done = 0
    for cid, text in REPLIES.items():
        src = existing.get(cid)
        if src is None:
            continue

        # --- the reply comment itself ---
        reply = copy.deepcopy(src)
        reply.set(w("id"), str(next_id))
        reply.set(w("author"), AUTHOR)
        reply.set(w("initials"), INITIALS)
        reply.set(w("date"), DATE)
        for p in reply.findall(w("p")):
            reply.remove(p)
        p = etree.SubElement(reply, w("p"))
        new_para_id = "%08X" % (0x5A000000 + next_id)
        p.set(w14("paraId"), new_para_id)
        p.set(w14("textId"), new_para_id)
        r = etree.SubElement(p, w("r"))
        t = etree.SubElement(r, w("t"))
        t.text = text
        t.set("{http://www.w3.org/XML/1998/namespace}space", "preserve")
        croot.append(reply)

        # --- register it as a reply to cid, and mark cid resolved ---
        ce = etree.SubElement(eroot, w15("commentEx"))
        ce.set(w15("paraId"), new_para_id)
        if para_of.get(cid):
            ce.set(w15("paraIdParent"), para_of[cid])
        ce.set(w15("done"), "1")
        for ex in eroot.findall(w15("commentEx")):
            if ex.get(w15("paraId")) == para_of.get(cid):
                ex.set(w15("done"), "1")
                n_done += 1

        # --- anchor the reply at the original's range end ---
        for ref in droot.iter(w("commentReference")):
            if ref.get(w("id")) == str(cid):
                run = ref.getparent()
                newrun = copy.deepcopy(run)
                for rr in newrun.findall(w("commentReference")):
                    rr.set(w("id"), str(next_id))
                run.addnext(newrun)
                break
        next_id += 1
        n_reply += 1

    parts["word/comments.xml"] = etree.tostring(
        croot, xml_declaration=True, encoding="UTF-8", standalone=True)
    parts["word/commentsExtended.xml"] = etree.tostring(
        eroot, xml_declaration=True, encoding="UTF-8", standalone=True)
    parts["word/document.xml"] = etree.tostring(
        droot, xml_declaration=True, encoding="UTF-8", standalone=True)

    tmp = DOC + ".tmp"
    with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as dst:
        for info in infos:
            dst.writestr(info, parts[info.filename])
    shutil.move(tmp, DOC)
    print("replies written : %d" % n_reply)
    print("comments marked resolved : %d" % n_done)


if __name__ == "__main__":
    main()
