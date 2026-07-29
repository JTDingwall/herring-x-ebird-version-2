# -*- coding: utf-8 -*-
"""Build v32: v30 with the author's revisions accepted, then every subsequent
editorial change marked as a tracked change he can accept or reject.

Structure comes from v31 (which carries Table 1 and the merged paragraphs);
the tracked baseline is v30 with his own edits accepted.
"""
import copy
import json
import shutil
import sys
import zipfile

from lxml import etree

sys.path.insert(0, "/sessions/keen-confident-allen/mnt/outputs/v32")
import tracklib as T
from tracklib import w, W
from edits import EDITS

V30 = "/sessions/keen-confident-allen/mnt/uploads/37a27e84-b9b8-4f60-8722-c8fb9e53a776-1785110454677_mer_manuscript_v30.docx"
V31 = "/sessions/keen-confident-allen/mnt/outputs/mer_manuscript_v31.docx"
OUT = "/sessions/keen-confident-allen/mnt/outputs/mer_manuscript_v32.docx"

al = json.load(open("align.json"))
A = al["A"]                                   # v30, author revisions accepted
target = list(al["B"])                        # v31 text, about to become v32

# ---- apply the editorial pass to the target text -------------------------
applied = 0
for idx, old, new in EDITS:
    assert old in target[idx], "edit no longer matches at %d" % idx
    target[idx] = target[idx].replace(old, new, 1)
    applied += 1

pairs = {j: i for i, j in al["pairs"]}        # v31 index -> v30 index

# ---- rebuild the document ------------------------------------------------
shutil.copy(V31, OUT)
zin = zipfile.ZipFile(V31)
root = etree.fromstring(zin.read("word/document.xml"))
# v31 still carries the author's own five insertions and seven deletions.
# Accept them first so the only revisions in v32 are the editorial ones.
T.accept_all(root)
body = root.find(w("body"))
paras = body.findall(w("p"))
assert len(paras) == len(target), (len(paras), len(target))

rev = T.Rev(9000)
n_ins = n_del = n_same = 0

for j, p in enumerate(paras):
    old_text = A[pairs[j]] if j in pairs else ""      # "" => wholly new
    new_text = target[j]
    if old_text.strip() == new_text.strip():
        n_same += 1
        continue
    if T.set_tracked(p, old_text, new_text, rev):
        n_ins += 1

# Paragraphs the author had in v30 that no longer exist: reinsert them as
# tracked deletions so he sees what went, positioned where they used to be.
inv = {i: j for i, j in al["pairs"]}
for i in al["del30"]:
    if not A[i].strip():
        continue
    after = None
    for k in range(i - 1, -1, -1):
        if k in inv:
            after = inv[k]
            break
    anchor = paras[after] if after is not None else paras[0]
    ghost = copy.deepcopy(anchor)
    for c in list(ghost):
        if c.tag != w("pPr"):
            ghost.remove(c)
    for tag in (w("commentRangeStart"), w("commentRangeEnd")):
        for c in ghost.findall(tag):
            ghost.remove(c)
    anchor.addnext(ghost)
    T.delete_paragraph_tracked_text(ghost, A[i], rev)
    n_del += 1

# ---- restore italics on the paragraphs that were rebuilt -----------------
import csv as _csv
import re as _re
REG = "/sessions/keen-confident-allen/mnt/herring-x-ebird-version-2/metadata/canonical_species_registry.csv"
names = set()
for row in _csv.DictReader(open(REG)):
    sci = (row.get("scientific_name") or "").strip()
    if " " not in sci:
        continue
    names.add(sci)
    g, sp = sci.split()[0], sci.split()[1]
    if "%s. %s" % (g[0], sp) != "M. americana":
        names.add("%s. %s" % (g[0], sp))
names |= {"Clupea pallasii", "Turdus migratorius"}
PAT = _re.compile("(" + "|".join(_re.escape(x) for x in
                  sorted(names, key=len, reverse=True)) + ")")
# Apply across the whole body, not only the paragraphs rebuilt here: v31
# carried the same italic bleed from its own build and it should go too.
# Stop at References, where journal and book titles are legitimately italic.
all_p = body.findall(w("p"))
stop = len(all_p)
for k, p in enumerate(all_p):
    if T.para_text(p).strip().lower().startswith("references"):
        stop = k
        break
n_ital = 0
for p in all_p[:stop]:
    T.fix_italics(p, PAT)
    n_ital += 1

xml = etree.tostring(root, xml_declaration=True, encoding="UTF-8", standalone=True)

zout_name = OUT + ".tmp"
with zipfile.ZipFile(V31) as src, zipfile.ZipFile(zout_name, "w", zipfile.ZIP_DEFLATED) as dst:
    for item in src.infolist():
        data = src.read(item.filename)
        if item.filename == "word/document.xml":
            data = xml
        dst.writestr(item, data)
shutil.move(zout_name, OUT)

print("edits applied to text : %d" % applied)
print("paragraphs marked up  : %d" % n_ins)
print("paragraphs re-deleted : %d" % n_del)
print("paragraphs untouched  : %d" % n_same)
print("paragraphs re-italicised: %d" % n_ital)
