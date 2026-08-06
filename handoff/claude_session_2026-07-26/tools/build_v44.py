# -*- coding: utf-8 -*-
"""v44 = v43 accepted, with the rebuilt Introduction tracked on top.

Seven paragraphs replacing six. Structure follows Dingwall et al. 2026: three
escalating gap statements, a paragraph on what two decades of community
observation makes possible, and closing if/then predictions.
"""
import csv, json, re, shutil, sys, zipfile
from lxml import etree

sys.path.insert(0, "/sessions/keen-confident-allen/mnt/outputs/v32")
import tracklib as T
from tracklib import w

SRC = ("/sessions/keen-confident-allen/mnt/herring-x-ebird-version-2/handoff/"
       "claude_session_2026-07-26/manuscript/mer_manuscript_v43.docx")
OUT = "/sessions/keen-confident-allen/mnt/outputs/mer_manuscript_v44.docx"

NEW = [l.strip() for l in open("intro_final.txt", encoding="utf8") if l.strip()]
NEW = [p.replace("[[CITATION]]",
                 "[[AUTHOR INPUT REQUIRED: citation for the shortening of the "
                 "Strait of Georgia spawning season at both ends]]") for p in NEW]
assert len(NEW) == 7, len(NEW)

zin = zipfile.ZipFile(SRC)
parts = {i.filename: zin.read(i.filename) for i in zin.infolist()}
infos = list(zin.infolist())
root = etree.fromstring(parts["word/document.xml"])
T.accept_all(root)
body = root.find(w("body"))
P = body.findall(w("p"))
base = [T.para_text(p) for p in P]

lo = next(k for k, t in enumerate(base) if t.strip().startswith("1 Introduction"))
hi = next(k for k, t in enumerate(base) if t.strip().startswith("2 Methods"))
old = [k for k in range(lo + 1, hi) if base[k].strip()]
assert len(old) == 6, old

rev = T.Rev(70000)
n_mark = 0
for k, txt in zip(old, NEW[:6]):
    if T.set_tracked(P[k], base[k], txt, rev):
        n_mark += 1
T.insert_paragraph_tracked(P[old[-1]], NEW[6], rev)

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
allp = body.findall(w("p"))
stop = next((k for k, p in enumerate(allp)
             if T.para_text(p).strip().lower().startswith("references")), len(allp))
n_ital = sum(1 for p in allp[:stop] if T.fix_italics_paragraph(p, PAT))

parts["word/document.xml"] = etree.tostring(
    root, xml_declaration=True, encoding="UTF-8", standalone=True)
tmp = OUT + ".tmp"
with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as dst:
    for info in infos:
        dst.writestr(info, parts[info.filename])
shutil.move(tmp, OUT)
json.dump({"base": base, "new": NEW, "old_idx": old}, open("v44_state.json", "w"))
print("Introduction: 6 paragraphs -> 7")
print("paragraphs rewritten : %d" % n_mark)
print("paragraphs inserted  : 1")
print("paragraphs italic-fix: %d" % n_ital)
