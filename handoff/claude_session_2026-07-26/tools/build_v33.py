# -*- coding: utf-8 -*-
"""Build v33 on the same tracked baseline as v32: v30 with the author's own
revisions accepted. Adds the structural changes he asked for.

  * ordination material removed from the timing section
  * eagle / robin / gull case study moved out of the sensitivity section and
    into the timing section, with a placeholder figure
  * section headings retitled for a reader who already knows the statistics
  * italics repaired at paragraph level rather than run by run
"""
import copy, csv, difflib, json, re, shutil, sys, zipfile
from lxml import etree

sys.path.insert(0, "/sessions/keen-confident-allen/mnt/outputs/v32")
import tracklib as T
from tracklib import w, W

V30 = "/sessions/keen-confident-allen/mnt/uploads/37a27e84-b9b8-4f60-8722-c8fb9e53a776-1785110454677_mer_manuscript_v30.docx"
V32 = "/sessions/keen-confident-allen/mnt/outputs/v32/v32_nocomments.docx"  # replies are added last, after all text edits
OUT = "/sessions/keen-confident-allen/mnt/outputs/mer_manuscript_v33.docx"
PNG = "/sessions/keen-confident-allen/mnt/outputs/v32/fig5_placeholder.png"
REL = "{http://schemas.openxmlformats.org/officeDocument/2006/relationships}"
DML = "{http://schemas.openxmlformats.org/drawingml/2006/main}"

HEADINGS = {
 "2.3 Checklist Selection and Response Construction": "2.3 Response Variables",
 "2.4 Statistical Comparison and Models":
     "2.4 Model Structure and the Difference-in-Differences Contrast",
 "2.5 Multiplicity, Sensitivity Analyses and Interpretation":
     "2.5 Multiple Testing and Sensitivity Analyses",
 "3.1 Study Coverage and Model Completion": "3.1 Coverage and Model Convergence",
 "3.2 Overall Pattern During the Active Spawning Period":
     "3.2 Responses During the Active Spawning Period",
 "3.4 When Each Group Responded": "3.4 Timing of Response",
 "3.5 What the Changes Mean on a Natural Scale":
     "3.5 Effect Sizes on the Observed Scale",
 "3.6 Results That Complicate a Herring-Specific Reading":
     "3.6 Results Inconsistent with a Herring-Specific Response",
 "3.7 Sensitivity to Design and Observation Choices": "3.7 Sensitivity Analyses",
 "4.1 What the Study Shows": "4.1 Principal Findings",
 "4.2 Ecological Interpretation Across Bird Groups":
     "4.2 Ecological Interpretation by Feeding Group",
 "4.3 Why Reported Number Was More Stable Than Checklist Reporting":
     "4.3 Divergence Between the Count and Reporting Outcomes",
 "4.4 Design Strengths and Limitations": "4.4 Strengths and Limitations",
 "4.5 Implications and Next Steps": "4.5 Implications and Future Work",
 "Birds That Should Have Responded and Did Not":
     "Expected Responders That Did Not Respond",
 "Taxa Without a Strong Herring Expectation":
     "Taxa Without an Established Herring Association",
 "Bald Eagle, American Robin and Glaucous-winged Gull Case Study":
     "Fine-Scale Timing in Two Waterbirds and a Terrestrial Control",
}

ORDINATION_OLD = (
 "Species do not, however, fall into discrete response types. An ordination of "
 "the five period estimates, standardized across species, places 62.8% of the "
 "variation on a first axis with similar loadings for every period, which "
 "describes overall response size and not timing, and 14.7% on a second axis "
 "separating early pre-spawn from late egg availability. A two-dimensional "
 "non-metric scaling of the same distances has stress 0.094 and reproduces the "
 "original distances closely, with a Spearman correlation of 0.974. In both "
 "ordinations the pre-assigned feeding groups overlap substantially, and the "
 "large unexplained residual heterogeneity says the same thing: the group "
 "differences reported above are differences in average timing.")
ORDINATION_NEW = (
 "Species do not, however, fall into discrete response types. Residual "
 "heterogeneity after fitting the feeding groups remains large in both "
 "outcomes, so the group differences reported above describe average timing "
 "and not a partition of the family.")

FIG5_CAPTION = (
 "Figure 5. Placeholder. Event-time profiles at 2 km resolution for Bald Eagle, "
 "Glaucous-winged Gull and American Robin across the 13 distance bands from 0 "
 "to 2 km out to 24 to 26 km. Reporting and count ratios are shown against the "
 "same-band baseline, so each band carries its own reference and the comparison "
 "is within band rather than between bands. The final figure will be produced "
 "from the distance-band output.")


def para_style(p):
    pPr = p.find(w("pPr"))
    if pPr is None:
        return ""
    st = pPr.find(w("pStyle"))
    return st.get(w("val")) if st is not None else ""


def set_text(p, text):
    """Replace a paragraph's text, keeping its first run's formatting."""
    tmpl = None
    for r in p.findall(w("r")):
        if r.findall(w("t")):
            tmpl = copy.deepcopy(r)
            break
    for c in [c for c in p if c.tag != w("pPr")]:
        p.remove(c)
    if tmpl is None:
        tmpl = etree.SubElement(etree.Element(w("p")), w("r"))
    for c in list(tmpl):
        if c.tag == w("t"):
            tmpl.remove(c)
    t = etree.SubElement(tmpl, w("t"))
    t.text = text
    t.set("{http://www.w3.org/XML/1998/namespace}space", "preserve")
    p.append(tmpl)


# ---------------------------------------------------------------- load v32
zin = zipfile.ZipFile(V32)
parts = {i.filename: zin.read(i.filename) for i in zin.infolist()}
infos = list(zin.infolist())
root = T.accept_all(etree.fromstring(parts["word/document.xml"]))
body = root.find(w("body"))
P = body.findall(w("p"))

# ---------------------------------------------------------------- 1. headings
n_head = 0
for p in P:
    t = T.para_text(p).strip()
    if t in HEADINGS:
        set_text(p, HEADINGS[t])
        n_head += 1

# ---------------------------------------------------------------- 2. ordination
n_ord = 0
for p in P:
    if T.para_text(p).strip() == ORDINATION_OLD:
        set_text(p, ORDINATION_NEW)
        n_ord += 1
assert n_ord == 1, "ordination paragraph not matched"

# ------------------------------------------- 3. move the case study into 3.4
case_head = next(p for p in P if T.para_text(p).strip().startswith(
    "Fine-Scale Timing in Two Waterbirds"))
idx = list(body).index(case_head)
block = [case_head]
sib = case_head.getnext()
while sib is not None and not (sib.tag == w("p") and para_style(sib).startswith("Heading1")):
    if sib.tag == w("p") and para_style(sib).startswith("Heading2"):
        break
    block.append(sib)
    sib = sib.getnext()
for el in block:
    body.remove(el)

fig4 = next(p for p in body.findall(w("p"))
            if T.para_text(p).strip().startswith("Figure 4."))
anchor = fig4
for el in block:
    anchor.addnext(el)
    anchor = el

# ------------------------------------------- 4. placeholder figure after it
img_para = next(p for p in body.findall(w("p")) if p.findall(".//" + DML + "blip"))
new_img = copy.deepcopy(img_para)
rels = etree.fromstring(parts["word/_rels/document.xml.rels"])
used = {r.get("Id") for r in rels}
rid = next("rId%d" % n for n in range(900, 999) if "rId%d" % n not in used)
etree.SubElement(rels, "{http://schemas.openxmlformats.org/package/2006/relationships}Relationship",
                 Id=rid,
                 Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image",
                 Target="media/image_fig5_placeholder.png")
for b in new_img.findall(".//" + DML + "blip"):
    b.set(REL + "embed", rid)
for e in new_img.iter():
    if e.tag.endswith("}extent") or e.tag.endswith("}ext"):
        if e.get("cx"):
            e.set("cx", "5486400")
            e.set("cy", "3048000")
cap = copy.deepcopy(fig4)
set_text(cap, FIG5_CAPTION)
anchor.addnext(cap)
cap.addprevious(new_img)

parts["word/_rels/document.xml.rels"] = etree.tostring(
    rels, xml_declaration=True, encoding="UTF-8", standalone=True)
parts["word/media/image_fig5_placeholder.png"] = open(PNG, "rb").read()

# ---------------------------------------------------------------- final text
P = body.findall(w("p"))
target = [T.para_text(p) for p in P]
json.dump(target, open("v33_target.json", "w"))
print("headings retitled : %d" % n_head)
print("ordination cut    : %d paragraph" % n_ord)
print("case-study block  : %d elements moved" % len(block))
print("v33 paragraphs    : %d" % len(P))

# ================= tracked changes against v30 with his edits in ============
z30 = zipfile.ZipFile(V30)
r30 = T.accept_all(etree.fromstring(z30.read("word/document.xml")))
A = [T.para_text(p) for p in r30.find(w("body")).findall(w("p"))]


_rcache = {}


def ratio(x, y):
    """Similarity, memoised. The DP below evaluates this ~36,000 times."""
    key = (x, y)
    if key in _rcache:
        return _rcache[key]
    xs, ys = x.strip(), y.strip()
    if xs[:60] and xs[:60] == ys[:60]:
        r = 0.95
    else:
        sm = difflib.SequenceMatcher(None, xs[:300], ys[:300], autojunk=False)
        r = 0.0 if sm.real_quick_ratio() < 0.45 else (
            0.0 if sm.quick_ratio() < 0.45 else sm.ratio())
    _rcache[key] = r
    return r


n, m = len(A), len(target)
NEG = -1e9
# Band the DP. Paragraph order barely changes between drafts, so the alignment
# stays within a few rows of the diagonal; scoring the full grid costs ~32 s.
BAND = 25
dp = [[NEG] * (m + 1) for _ in range(n + 1)]
bt = [[None] * (m + 1) for _ in range(n + 1)]
dp[0][0] = 0
GAP = -0.55
for i in range(n + 1):
    lo = max(0, i - BAND)
    hi = min(m, i + BAND)
    for j in range(lo, hi + 1):
        if dp[i][j] == NEG:
            continue
        if i < n and j < m:
            r = ratio(A[i], target[j])
            s_ = dp[i][j] + (r if r > 0.45 else -0.4)
            if s_ > dp[i + 1][j + 1]:
                dp[i + 1][j + 1] = s_
                bt[i + 1][j + 1] = ("M", i, j)
        if i < n and dp[i][j] + GAP > dp[i + 1][j]:
            dp[i + 1][j] = dp[i][j] + GAP
            bt[i + 1][j] = ("D", i, j)
        if j < m and dp[i][j] + GAP > dp[i][j + 1]:
            dp[i][j + 1] = dp[i][j] + GAP
            bt[i][j + 1] = ("I", i, j)
i, j = n, m
ops = []
while (i, j) != (0, 0):
    t_, pi, pj = bt[i][j]
    ops.append((t_, pi, pj))
    i, j = pi, pj
ops.reverse()
pairs = {pj: pi for t_, pi, pj in ops if t_ == "M"}
del30 = [pi for t_, pi, pj in ops if t_ == "D"]

rev = T.Rev(9000)
P = body.findall(w("p"))
n_mark = 0
for j, p in enumerate(P):
    old = A[pairs[j]] if j in pairs else ""
    if old.strip() == target[j].strip():
        continue
    if T.set_tracked(p, old, target[j], rev):
        n_mark += 1

inv = {pi: pj for pj, pi in pairs.items()}
n_ghost = 0
# Consecutive deletions share an anchor, so each one becomes the anchor for the
# next; inserting them all after the same element reverses their order.
chain = {}
for i in sorted(del30):
    if not A[i].strip():
        continue
    after = None
    for k in range(i - 1, -1, -1):
        if k in inv:
            after = inv[k]
            break
    anchor_p = chain.get(after, P[after] if after is not None else P[0])
    ghost = copy.deepcopy(anchor_p)
    for c in list(ghost):
        if c.tag != w("pPr"):
            ghost.remove(c)
    anchor_p.addnext(ghost)
    chain[after] = ghost
    T.delete_paragraph_tracked_text(ghost, A[i], rev)
    n_ghost += 1

# ---------------------------------------------------------------- italics
REG = "/sessions/keen-confident-allen/mnt/herring-x-ebird-version-2/metadata/canonical_species_registry.csv"
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
all_p = body.findall(w("p"))
stop = next((k for k, p in enumerate(all_p)
             if T.para_text(p).strip().lower().startswith("references")), len(all_p))
n_ital = sum(1 for p in all_p[:stop] if T.fix_italics_paragraph(p, PAT))

parts["word/document.xml"] = etree.tostring(
    root, xml_declaration=True, encoding="UTF-8", standalone=True)

names_in = {i.filename for i in infos}
tmp = OUT + ".tmp"
with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as dst:
    for info in infos:
        dst.writestr(info, parts[info.filename])
    for fn, data in parts.items():
        if fn not in names_in:
            dst.writestr(fn, data)
shutil.move(tmp, OUT)

print("paragraphs marked up  : %d" % n_mark)
print("paragraphs re-deleted : %d" % n_ghost)
print("paragraphs italic-fixed: %d" % n_ital)
