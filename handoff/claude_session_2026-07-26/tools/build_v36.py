# -*- coding: utf-8 -*-
"""v36: the non-AI prose pass, tracked against v35.

v35 was accepted clean, so v35 is the new baseline: rejecting everything in v36
returns v35 exactly. Paragraph structure is unchanged, so the alignment is the
identity map and no DP search is needed.
"""
import csv, json, re, shutil, sys, zipfile
from lxml import etree

sys.path.insert(0, "/sessions/keen-confident-allen/mnt/outputs/v32")
import tracklib as T
from tracklib import w
from edits_v36 import EDITS

SRC = "/sessions/keen-confident-allen/mnt/outputs/mer_manuscript_v35.docx"
OUT = "/sessions/keen-confident-allen/mnt/outputs/mer_manuscript_v36.docx"

zin = zipfile.ZipFile(SRC)
parts = {i.filename: zin.read(i.filename) for i in zin.infolist()}
infos = list(zin.infolist())
root = etree.fromstring(parts["word/document.xml"])
body = root.find(w("body"))
P = body.findall(w("p"))

old_text = [T.para_text(p) for p in P]
target = list(old_text)
for idx, old, new in EDITS:
    assert old in target[idx], "edit no longer matches at %d" % idx
    target[idx] = target[idx].replace(old, new, 1)

rev = T.Rev(20000)
n_mark = 0
for j, p in enumerate(P):
    if old_text[j].strip() == target[j].strip():
        continue
    if T.set_tracked(p, old_text[j], target[j], rev):
        n_mark += 1

REG = ("/sessions/keen-confident-allen/mnt/herring-x-ebird-version-2/"
       "metadata/canonical_species_registry.csv")
names = set()
for row in csv.DictReader(open(REG)):
    sci = (row.get("scientific_name") or "").strip()
    if " " not in sci:
        continue
    names.add(sci)
    g, sp = sci.split()[0], sci.split()[1]
    if "%s. %s" % (g[0], sp) != "M. americana":
        names.add("%s. %s" % (g[0], sp))
names |= {"Clupea pallasii", "Turdus migratorius"}
PAT = re.compile("(" + "|".join(re.escape(x) for x in
                 sorted(names, key=len, reverse=True)) + ")")
stop = next((k for k, p in enumerate(P)
             if T.para_text(p).strip().lower().startswith("references")), len(P))
n_ital = sum(1 for p in P[:stop] if T.fix_italics_paragraph(p, PAT))

parts["word/document.xml"] = etree.tostring(
    root, xml_declaration=True, encoding="UTF-8", standalone=True)
tmp = OUT + ".tmp"
with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as dst:
    for info in infos:
        dst.writestr(info, parts[info.filename])
shutil.move(tmp, OUT)
json.dump(target, open("v36_target.json", "w"))
print("edits applied         : %d" % len(EDITS))
print("paragraphs marked up  : %d" % n_mark)
print("paragraphs italic-fix : %d" % n_ital)
