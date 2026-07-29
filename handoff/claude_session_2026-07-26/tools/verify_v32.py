"""Final verification for v32. Every check here has failed at least once."""
import csv, json, re, sys, zipfile
sys.path.insert(0, "/sessions/keen-confident-allen/mnt/outputs/v32")
from lxml import etree
import tracklib as T
from tracklib import w
from edits import EDITS

W15 = "http://schemas.microsoft.com/office/word/2012/wordml"
DOC = "/sessions/keen-confident-allen/mnt/outputs/mer_manuscript_v32.docx"
R = "/sessions/keen-confident-allen/mnt/herring-x-ebird-version-2/"

z = zipfile.ZipFile(DOC)
raw = z.read("word/document.xml")
al = json.load(open("align.json"))
A = al["A"]
target = list(al["B"])
for i, o, n in EDITS:
    target[i] = target[i].replace(o, n, 1)

r0 = etree.fromstring(raw)
acc = T.accept_all(etree.fromstring(raw))
paras = acc.find(w("body")).findall(w("p"))
got = [T.para_text(p) for p in paras]

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
a30 = [x for x in A if x.strip()]

# References are excluded: journal titles are legitimately italic there, and
# cited article titles carry their own (sometimes different) binomial spelling.
stop = next((k for k, p in enumerate(paras)
             if T.para_text(p).strip().lower().startswith("references")), len(paras))
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

ital = set()
for p in paras[:stop]:
    for r in p.iter(w("r")):
        rPr = r.find(w("rPr"))
        if rPr is not None and rPr.find(w("i")) is not None:
            t = "".join(x.text or "" for x in r.iter(w("t"))).strip()
            if t:
                ital.add(t)
BINO = re.compile(r"^([A-Z][a-z]+|[A-Z]\.) [a-z-]{3,}$")
bp = set(re.findall(r"\(([A-Z][a-z]+ [a-z]{3,})\)", body))

c = etree.fromstring(z.read("word/comments.xml"))
e = etree.fromstring(z.read("word/commentsExtended.xml"))
done = sum(1 for x in e.findall("{%s}commentEx" % W15)
           if x.get("{%s}done" % W15) == "1")

checks = [
    ("zip integrity", z.testzip() is None, "ok"),
    ("accept all == v32 target",
     all(got[k].strip() == target[k].strip() for k in range(len(target))),
     "%d paragraphs" % len(got)),
    ("reject all == v30 with your edits in",
     all(gr[k].strip() == a30[k].strip() for k in range(len(a30))),
     "%d paragraphs" % len(a30)),
    ("interval triples match released tables", not bad,
     "%d/%d" % (len(trip) - len(bad), len(trip))),
    ("images preserved",
     len(r0.findall(".//{http://schemas.openxmlformats.org/drawingml/2006/main}blip")) == 4, "4"),
    ("equations preserved",
     len(r0.findall(".//{http://schemas.openxmlformats.org/officeDocument/2006/math}oMath")) == 11, "11"),
    ("binomials italic", all(b in ital for b in bp), "%d/%d" % (len(bp), len(bp))),
    ("no stray italics", all(BINO.match(t) for t in ital), "%d runs" % len(ital)),
    ("comments replied to and resolved",
     len(c.findall(w("comment"))) == 30 and done == 30, "15 originals + 15 replies"),
    ("v31 build artifacts repaired",
     "large.reporting" not in body and "question.the number" not in body, "both"),
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
print("\n  %d insertions, %d deletions across %d paragraphs" % (
    len(r0.findall(".//" + w("ins"))), len(r0.findall(".//" + w("del"))),
    sum(1 for p in r0.find(w("body")).findall(w("p"))
        if p.findall(w("ins")) or p.findall(w("del")))))
sys.exit(1 if fails else 0)
