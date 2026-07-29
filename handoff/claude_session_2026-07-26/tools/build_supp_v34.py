# -*- coding: utf-8 -*-
"""Supplement v34: remove Figure S3, the NMDS ordination.

Nothing in the main text refers to it now that the ordination is gone from
Section 3.4. The heading was also mislabelled "Count response profiles", a
copy of the Figure S2 heading.
"""
import shutil, sys, zipfile
from lxml import etree

sys.path.insert(0, "/sessions/keen-confident-allen/mnt/outputs/v32")
import tracklib as T
from tracklib import w

DML = "{http://schemas.openxmlformats.org/drawingml/2006/main}"
SRC = ("/sessions/keen-confident-allen/mnt/herring-x-ebird-version-2/handoff/"
       "claude_session_2026-07-26/manuscript/mer_supplementary_material_v27.docx")
OUT = "/sessions/keen-confident-allen/mnt/outputs/mer_supplementary_material_v34.docx"

zin = zipfile.ZipFile(SRC)
parts = {i.filename: zin.read(i.filename) for i in zin.infolist()}
infos = list(zin.infolist())
root = etree.fromstring(parts["word/document.xml"])
body = root.find(w("body"))
P = body.findall(w("p"))

# The block is: heading "Figure S3. ...", the image, then the caption, which
# also begins "Figure S3." -- so run to the LAST paragraph bearing that label.
hits = [k for k, p in enumerate(P) if T.para_text(p).strip().startswith("Figure S3.")]
start, end = hits[0], hits[-1]

# take the blank spacer paragraph immediately above the heading too
if start > 0 and not T.para_text(P[start - 1]).strip():
    start -= 1

removed = []
for p in P[start:end + 1]:
    removed.append((T.para_text(p).strip()[:70],
                    len(p.findall(".//" + DML + "blip"))))
    body.remove(p)

parts["word/document.xml"] = etree.tostring(
    root, xml_declaration=True, encoding="UTF-8", standalone=True)
tmp = OUT + ".tmp"
with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as dst:
    for info in infos:
        dst.writestr(info, parts[info.filename])
shutil.move(tmp, OUT)

print("removed %d paragraphs:" % len(removed))
for t, img in removed:
    print("   img=%d  %s" % (img, t or "(blank)"))
