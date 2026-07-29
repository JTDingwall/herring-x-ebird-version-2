# -*- coding: utf-8 -*-
"""v43 = v42 with the author's edits accepted, then this pass tracked on top.

Rejecting everything in v43 returns his v42 exactly, so he can see only what
was done in response to his comments.

Changes:
  INTRO   Complete rewrite. Comments 13, 14, 15 (awkward opening paragraph and
          sentences) and 36 (merge the two evidence paragraphs).
  C117    All Gadwall and Northern Shoveler comparator material removed, from
          Methods, Results and Discussion.
  FIX     Typos introduced while editing.
  C58     Author-judgement phrasing removed.
  C112    "so" reduced as a clause connective.
  C124    Section 3.1 retitled.
"""
import copy, json, re, shutil, sys, zipfile
from lxml import etree

sys.path.insert(0, "/sessions/keen-confident-allen/mnt/outputs/v32")
import tracklib as T
from tracklib import w
sys.path.insert(0, "/sessions/keen-confident-allen/mnt/outputs/v43")
from intro import PARAS as INTRO

SRC = ("/sessions/keen-confident-allen/mnt/herring-x-ebird-version-2/handoff/"
       "claude_session_2026-07-26/manuscript/mer_manuscript_v42.docx")
OUT = "/sessions/keen-confident-allen/mnt/outputs/mer_manuscript_v43.docx"

# substring edits outside the Introduction
EDITS = [
 # --- typos his editing left behind ---
 (47, "exploratory set.T", "exploratory set."),

 # --- C117: remove the comparators from Methods ---
 (48, "Gadwall (Mareca strepera) and Northern Shoveler (Spatula clypeata) were "
      "carried as comparators in a separate two-species exploratory analysis, so "
      "their correction threshold differs from that of the 49 and clearing it is "
      "not by itself evidence of specificity. Their adjusted p-values also refer "
      "to the comparison against baseline and not to the main before-and-after "
      "comparison used for the 49. Released counts",
      "Released counts"),

 # --- C108 and C112: unclear paragraph, and "so" as a connective ---
 (47, "correction was applied across all 49 species, so every adjusted p-value "
      "below belongs to that set. The main test compares the duration-weighted "
      "days 0 to 14 estimate directly against the mean estimate for days −14 to "
      "−1, using the full fixed-effect covariance matrix, so it is not a naive "
      "difference of two independent ratios.",
      "correction was applied across all 49 species. Every adjusted p-value "
      "reported below belongs to that set. The main test compares the "
      "duration-weighted days 0 to 14 estimate directly against the mean "
      "estimate for days −14 to −1, using the full fixed-effect covariance "
      "matrix; it is therefore not a naive difference of two independent "
      "ratios."),

 # --- C117: model tally no longer counts comparators ---
 (55, "Of 100 models across 49 species, two outcomes and two comparators, 96 fitted.",
      "Of 98 models across 49 species and two outcomes, 94 fitted."),

 # --- C117: Results ---
 (89, " The two comparators do not behave alike once uncertainty is attached. "
      "Gadwall's near-to-reference reporting ratio was 0.88 (95% CI 0.80–0.97) "
      "at baseline and 0.92 (0.84–1.01) during late egg availability, a climb "
      "indistinguishable from flat, and neither its active-period value of 1.03 "
      "(0.90–1.17) nor its late-egg value of 1.05 (0.92–1.19) differed from one. "
      "Northern Shoveler climbed from 1.00 (0.90–1.11) at baseline to 1.26 "
      "(1.15–1.39) during late egg availability, and both its active value of "
      "1.24 (1.08–1.43) and its late-egg value of 1.27 (1.10–1.46) exceeded one, "
      "the later of the two being larger. Only Northern Shoveler cleared "
      "correction. The full period series for both is in the supplementary "
      "material.", ""),
 (90, " The cleaner comparison is Gadwall and Northern Shoveler, neither of "
      "which has an established herring association: one responded and one did "
      "not, which is the level of specificity these data support.", ""),
 (92, " The two comparators form a separate set, and Section 4.2 takes them up.", ""),

 # --- C117: Discussion ---
 (118, "Positive results for American Wigeon, Northern Pintail, Mallard, Brant "
       "and, in the exploratory comparison, Northern Shoveler cannot be "
       "attributed with any confidence.",
       "Positive results for American Wigeon, Northern Pintail, Mallard and "
       "Brant cannot be attributed with any confidence."),

 # --- C58: no author-judgement phrasing ---
 (28, " These bounds were set by judgement before fitting.", ""),

 # --- C124: retitle ---
 (53, "3.1 Coverage and Model Convergence", "3.1 Model Support and Fit Status"),
]

DELETE_WHOLE = [119]   # C117: the comparator paragraph in 4.2

zin = zipfile.ZipFile(SRC)
parts = {i.filename: zin.read(i.filename) for i in zin.infolist()}
infos = list(zin.infolist())
root = etree.fromstring(parts["word/document.xml"])
T.accept_all(root)                      # his edits become the baseline
body = root.find(w("body"))
P = body.findall(w("p"))
base = [T.para_text(p) for p in P]
target = list(base)

lo = next(k for k, t in enumerate(base) if t.strip().startswith("1 Introduction"))
hi = next(k for k, t in enumerate(base) if t.strip().startswith("2 Methods"))
old_intro = [k for k in range(lo + 1, hi) if base[k].strip()]
assert len(old_intro) == 8, old_intro
for k, txt in zip(old_intro[:6], INTRO):
    target[k] = txt
drop = old_intro[6:] + DELETE_WHOLE

n_edit = 0
for idx, old, new in EDITS:
    assert old in target[idx], "edit %d no longer matches" % idx
    target[idx] = target[idx].replace(old, new, 1)
    n_edit += 1
target = [re.sub(r"\s{2,}", " ", t).strip() if i in
          set(old_intro[:6]) | {i for i, _, _ in EDITS} else t
          for i, t in enumerate(target)]

rev = T.Rev(60000)
n_mark = n_drop = 0
for j, p in enumerate(P):
    if j in drop:
        if T.delete_paragraph_tracked(p, rev):
            n_drop += 1
        continue
    if base[j].strip() == target[j].strip():
        continue
    if T.set_tracked(p, base[j], target[j], rev):
        n_mark += 1

# italics
import csv as _csv
REG = ("/sessions/keen-confident-allen/mnt/herring-x-ebird-version-2/"
       "metadata/canonical_species_registry.csv")
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
json.dump({"base": base, "target": target, "drop": drop},
          open("v43_state.json", "w"))
print("Introduction paragraphs replaced : 6 (from 8)")
print("substring edits applied          : %d" % n_edit)
print("paragraphs marked up             : %d" % n_mark)
print("paragraphs deleted whole         : %d" % n_drop)
print("paragraphs re-italicised         : %d" % n_ital)
