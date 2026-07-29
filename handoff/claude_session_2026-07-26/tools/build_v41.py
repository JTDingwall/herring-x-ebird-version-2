# -*- coding: utf-8 -*-
"""v41: insert the Dingwall et al. 2026 reference, supplied by the author.

Replaces the last blocking [[AUTHOR INPUT REQUIRED]] marker in the bibliography.
Formatted to match the list's Chicago author-date style: full given names, title
case in quotation marks, journal name, then the Elsevier article number. No DOI
was supplied and none is invented. The binomial is italicised, matching the
Bishop and Green entry.

Tracked against v40.
"""
import copy, json, shutil, sys, zipfile
from lxml import etree

sys.path.insert(0, "/sessions/keen-confident-allen/mnt/outputs/v32")
import tracklib as T
from tracklib import w

SRC = "/sessions/keen-confident-allen/mnt/outputs/mer_manuscript_v40.docx"
OUT = "/sessions/keen-confident-allen/mnt/outputs/mer_manuscript_v41.docx"

PLACEHOLDER = ("[[AUTHOR INPUT REQUIRED: provide the full reference for Dingwall "
               "et al. 2026; no bibliographic details were available in the "
               "repository.]]")
PRE = ("Dingwall, Jacob T., Jessica Qualley, Matthew Thompson, Sydni Long, and "
       "Amanda E. Bates. 2026. “Vegetation Preference and the Puzzle of "
       "Abandonment: High-Quality Spawning Habitat Remains Unused by Pacific "
       "Herring (")
ITAL = "Clupea pallasii"
POST = ").” Marine Environmental Research, 108067."

zin = zipfile.ZipFile(SRC)
parts = {i.filename: zin.read(i.filename) for i in zin.infolist()}
infos = list(zin.infolist())
root = etree.fromstring(parts["word/document.xml"])
body = root.find(w("body"))
P = body.findall(w("p"))

idx = next(k for k, p in enumerate(P) if PLACEHOLDER in T.para_text(p))
para = P[idx]
rev = T.Rev(50000)

# Build the replacement as three runs so the binomial can carry italics, then
# mark the whole exchange as one tracked change.
template = next((copy.deepcopy(r) for r in para.findall(w("r")) if r.findall(w("t"))), None)
assert template is not None

for c in [c for c in para if c.tag != w("pPr")]:
    para.remove(c)

d = etree.SubElement(para, w("del"))
d.set(w("id"), rev()); d.set(w("author"), T.AUTHOR); d.set(w("date"), T.DATE)
d.append(T._make_run(template, PLACEHOLDER, deleted=True))

ins = etree.SubElement(para, w("ins"))
ins.set(w("id"), rev()); ins.set(w("author"), T.AUTHOR); ins.set(w("date"), T.DATE)
for text, italic in ((PRE, False), (ITAL, True), (POST, False)):
    r = T._make_run(template, text)
    T._set_italic(r, italic)
    ins.append(r)

parts["word/document.xml"] = etree.tostring(
    root, xml_declaration=True, encoding="UTF-8", standalone=True)
tmp = OUT + ".tmp"
with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as dst:
    for info in infos:
        dst.writestr(info, parts[info.filename])
shutil.move(tmp, OUT)
print("reference inserted at paragraph %d" % idx)
