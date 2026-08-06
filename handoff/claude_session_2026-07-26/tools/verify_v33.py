"""Final verification for v33."""
import csv, json, re, sys, zipfile
sys.path.insert(0, "/sessions/keen-confident-allen/mnt/outputs/v32")
from lxml import etree
import tracklib as T
from tracklib import w

W15 = "{http://schemas.microsoft.com/office/word/2012/wordml}"
DML = "{http://schemas.openxmlformats.org/drawingml/2006/main}"
DOC = "/sessions/keen-confident-allen/mnt/outputs/mer_manuscript_v33.docx"
R = "/sessions/keen-confident-allen/mnt/herring-x-ebird-version-2/"
V30 = ("/sessions/keen-confident-allen/mnt/uploads/"
       "37a27e84-b9b8-4f60-8722-c8fb9e53a776-1785110454677_mer_manuscript_v30.docx")

z = zipfile.ZipFile(DOC)
raw = z.read("word/document.xml")
target = json.load(open("v33_target.json"))
r0 = etree.fromstring(raw)
raw_p = r0.find(w("body")).findall(w("p"))

acc = T.accept_all(etree.fromstring(raw))
P = acc.find(w("body")).findall(w("p"))
got = [T.para_text(p) for p in P]

r30 = T.accept_all(etree.fromstring(zipfile.ZipFile(V30).read("word/document.xml")))
A = [T.para_text(p) for p in r30.find(w("body")).findall(w("p")) if T.para_text(p).strip()]
rej = etree.fromstring(raw)
for ins in rej.findall(".//" + w("ins")):
    ins.getparent().remove(ins)
for de in rej.findall(".//" + w("del")):
    par = de.getparent(); i = list(par).index(de)
    for ch in reversed(list(de)):
        par.insert(i, ch)
    par.remove(de)
for dt in rej.findall(".//" + w("delText")):
    dt.tag = w("t")
gr = [T.para_text(p) for p in rej.find(w("body")).findall(w("p")) if T.para_text(p).strip()]

stop = next((k for k, p in enumerate(P)
             if T.para_text(p).strip().lower().startswith("references")), len(P))
body = "\n".join(got[:stop])

vals = set()
for path in ["figures_out/tableS_primary_contrast_49x2.csv",
             "outputs/referee_reads_v1/item2_specificity_comparators.csv"]:
    for row in csv.DictReader(open(R + path)):
        for k, v in row.items():
            try:
                vals.add(round(float(v), 4))
            except (TypeError, ValueError):
                pass
trip = re.findall(r"(\d+\.\d+)\s*\((\d+\.\d+)[–-](\d+\.\d+)\)", body)
bad = [t for t in trip
       if not all(any(abs(float(x) - v) <= 0.0051 for v in vals) for x in t)]

names = set()
for row in csv.DictReader(open(R + "metadata/canonical_species_registry.csv")):
    s = (row.get("scientific_name") or "").strip()
    if " " in s:
        names.add(s)
        g, sp = s.split()[0], s.split()[1]
        if "%s. %s" % (g[0], sp) != "M. americana":
            names.add("%s. %s" % (g[0], sp))
names |= {"Clupea pallasii", "Turdus migratorius"}
PAT = re.compile("(" + "|".join(re.escape(x) for x in
                 sorted(names, key=len, reverse=True)) + ")")
rstop = next((k for k, p in enumerate(raw_p)
              if T.para_text(p).strip().lower().startswith("references")), len(raw_p))
miss = []
for k, p in enumerate(raw_p[:rstop]):
    chars = []
    for r in p.iter(w("r")):
        rPr = r.find(w("rPr"))
        it = rPr is not None and rPr.find(w("i")) is not None
        for tag in (w("t"), w("delText")):
            for x in r.findall(tag):
                for ch in (x.text or ""):
                    chars.append((ch, it))
    txt = "".join(c for c, _ in chars)
    for m in PAT.finditer(txt):
        if not all(i for _, i in chars[m.start():m.end()]):
            miss.append((k, m.group(0)))

c = etree.fromstring(z.read("word/comments.xml"))
e = etree.fromstring(z.read("word/commentsExtended.xml"))
ex = e.findall(W15 + "commentEx")
heads = [g.strip() for g in got]
i_case = next(k for k, g in enumerate(heads) if g.startswith("Fine-Scale Timing"))
i_35 = next(k for k, g in enumerate(heads) if g.startswith("3.5 "))
i_37 = next(k for k, g in enumerate(heads) if g.startswith("3.7 "))

checks = [
 ("zip integrity", z.testzip() is None, "ok"),
 ("accept all == v33 target",
  len(got) == len(target) and all(got[k].strip() == target[k].strip()
                                  for k in range(len(target))),
  "%d paragraphs" % len(got)),
 ("reject all == v30 with your edits in",
  len(gr) == len(A) and all(gr[k].strip() == A[k].strip() for k in range(len(A))),
  "%d paragraphs" % len(A)),
 ("interval triples match released tables", not bad,
  "%d/%d" % (len(trip) - len(bad), len(trip))),
 ("figures present", len(r0.findall(".//" + DML + "blip")) == 5,
  "5, incl. Figure 5 placeholder"),
 ("equations preserved",
  len(r0.findall(".//{http://schemas.openxmlformats.org/officeDocument/2006/math}oMath")) == 11, "11"),
 ("Latin names italic, incl. tracked runs", not miss, "%d misses" % len(miss)),
 ("comments anchored, replied, resolved",
  len(c.findall(w("comment"))) == 30
  and len(r0.findall(".//" + w("commentReference"))) == 30
  and len(r0.findall(".//" + w("commentRangeStart"))) == 30
  and sum(1 for x in ex if x.get(W15 + "done") == "1") == 30,
  "15 originals + 15 replies, all anchored"),
 ("ordination removed",
  "ordination" not in body and "non-metric" not in body and "0.974" not in body, "0 mentions"),
 ("case study sits inside 3.4", i_case < i_35 < i_37, "before 3.5"),
 ("no em dashes", "—" not in body, "0"),
 ("banned vocabulary",
  not any(x in body for x in ["StartDate", "EndDate", "study rules",
                              "analysis frame", "estimand"]), "0"),
]
width = max(len(a) for a, _, _ in checks)
fails = 0
for name, good, detail in checks:
    fails += not good
    print("  %-8s %-*s %s" % ("PASS" if good else "**FAIL**", width, name, detail))
for k, nm in miss[:6]:
    print("      miss:", k, nm)
print("\n  %d insertions, %d deletions across %d paragraphs" % (
    len(r0.findall(".//" + w("ins"))), len(r0.findall(".//" + w("del"))),
    sum(1 for p in raw_p if p.findall(w("ins")) or p.findall(w("del")))))
sys.exit(1 if fails else 0)
