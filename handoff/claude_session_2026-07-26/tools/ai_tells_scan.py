"""
AI-writing tell scan for the MER manuscript.

Implements the checks in section 11.7 of WRITING_STYLE.md, which are derived
from three measurement studies rather than from impressions:

  - bioRxiv (Jan 2026), fine-grained detection in the biomedical literature:
    the corrective pivot as the dominant structural tell, and the finding that
    flagged passages concentrate in limitations and closing Discussion text.
  - Kobak et al., Science Advances 11(27), 2025: the excess-vocabulary list.
  - Organization Science AI Task Force, Org Sci 37(3), 2026: readability,
    nominalization load, editorial outcome by AI score.

Usage:  python3 ai_tells_scan.py mer_manuscript_v31.docx
"""

import re
import statistics
import sys

import docx
import textstat

EXCESS_VOCAB = r"""\b(
 delv\w+|underscor\w+|showcas\w+|crucial\w*|pivotal|vital\w*|notably|noteworthy
|importantly|interestingly|strikingly|remarkably|comprehensive\w*|holistic
|robust\w*|intricate\w*|nuanced|multifaceted|realm|landscape|paradigm\w*
|leverag\w+|harness\w*|utiliz\w+|garner\w*|foster\w*|bolster\w*
)\b"""

PIVOT = r"\brather than\b|\binstead of\b|\bbut rather\b|\bnot\b[^.]{1,60}?\bbut\b"
NOMIN = r"\b\w{5,}(?:ation|ization|isation|ment)s?\b"
CONNECTIVE = (r"\b(however|although|whereas|because|therefore|since|while"
              r"|but|which|so that|even though)\b")


# Full stops that do not end a sentence: author initials, "et al.", abbreviated
# genera ("C. pallasii"), and the usual Latin abbreviations. Splitting naively
# on ". " fragments the citations and triples the apparent short-sentence count.
_PROTECT = [
    (r"\bet al\.", "@ETAL@"),
    (r"\b(e\.g|i\.e|cf|vs|approx|ca|Fig|Figs|No|St|Dr|Prof)\.", r"\1@DOT@"),
    (r"\b([A-Z])\.(?= *[A-Z])", r"\1@DOT@"),   # B. L. Sullivan, C. pallasii
]

CAPTION = re.compile(r"^(Figure|Table)\s+\d+\.")


def _subsection_slices(paragraphs, lo, hi):
    heads = [i for i in range(lo, hi)
             if paragraphs[i].style.name.startswith("Heading")] + [hi]
    return list(zip(heads, heads[1:]))


def sentences(text):
    t = text.replace("\n", " ")
    for pat, rep in _PROTECT:
        t = re.sub(pat, rep, t)
    parts = re.split(r"(?<=[.!?]) +(?=[A-Z0-9(])", t)
    return [s.replace("@ETAL@", "et al.").replace("@DOT@", ".").strip()
            for s in parts if s.strip()]


def prose_sentences(paragraphs):
    """Sentences from body prose only.

    Headings and figure or table captions are labels, not prose. Counting them
    roughly doubles the apparent share of sentences under twelve words, which is
    the statistic the author reacted to, so they must be excluded.
    """
    out = []
    for p in paragraphs:
        t = p.text.strip()
        if not t or CAPTION.match(t) or p.style.name.startswith("Heading"):
            continue
        out.extend(sentences(t))
    return out


def section_bounds(paragraphs):
    """Body runs from the Introduction heading to the start of the back matter.

    Back matter (CRediT, declarations, funding, acknowledgements) is boilerplate
    and would otherwise dominate the short-sentence and nominalization counts.
    """
    lo = next(i for i, p in enumerate(paragraphs)
              if p.text.strip().lower().startswith(("1 introduction", "1. introduction")))
    hi = next(i for i, p in enumerate(paragraphs)
              if p.text.strip().lower().startswith(("data availability", "references")))
    return lo, hi


def main(path):
    doc = docx.Document(path)
    paras = doc.paragraphs
    lo, hi = section_bounds(paras)
    body = "\n".join(p.text for p in paras[lo:hi])
    words = len(body.split())
    sents = prose_sentences(paras[lo:hi])
    lengths = [len(s.split()) for s in sents]

    pivots = re.findall(PIVOT, body, re.I)
    vocab = re.findall(EXCESS_VOCAB, body, re.I | re.X)
    dashes = re.findall(r"—|--", body)
    short = sum(1 for n in lengths if n < 12)
    heavy = [s for s in sents if len(re.findall(NOMIN, s, re.I)) >= 3]
    conn = len(re.findall(CONNECTIVE, body, re.I))

    # Readability is the metric the Organization Science task force actually
    # measured, and it is driven far more by word choice than by sentence
    # length. Scientific prose sits low in absolute terms; watch the trend
    # between builds and the spread between sections, not the raw number.
    flesch = textstat.flesch_reading_ease(" ".join(sents))

    worst = ("", 999.0)
    profile = []
    for a, b in _subsection_slices(paras, lo, hi):
        ss = prose_sentences(paras[a:b])
        if len(" ".join(s for s in ss).split()) < 120:
            continue
        f = textstat.flesch_reading_ease(" ".join(ss))
        profile.append((paras[a].text.strip()[:42], len(" ".join(ss).split()), f,
                        statistics.mean([len(s.split()) for s in ss])))
        if f < worst[1]:
            worst = (paras[a].text.strip()[:34], f)

    print("body: %d words, %d sentences\n" % (words, len(sents)))
    rows = [
        ("Corrective pivots per 1,000 words", "< 2.0",
         "%.1f  (n=%d)" % (1000 * len(pivots) / words, len(pivots)),
         1000 * len(pivots) / words < 2.0),
        ("Excess-vocabulary hits", "0", str(len(vocab)), not vocab),
        ("Sentences with 3+ nominalizations", "0", str(len(heavy)), not heavy),
        ("Em dashes or double hyphens", "0", str(len(dashes)), not dashes),
        ("Flesch Reading Ease, body", "not falling",
         "%.1f" % flesch, flesch >= 50),
        ("Least readable subsection", "> 40",
         "%s at %.1f" % worst, worst[1] > 40),
    ]
    for label, target, got, ok in rows:
        print("  %-5s  %-36s target %-10s %s"
              % ("PASS" if ok else "CHECK", label, target, got))

    if vocab:
        print("\nexcess vocabulary:", sorted(set(w.lower() for w in vocab)))
    if heavy:
        print("\nnominalization-heavy sentences:")
        for s in heavy:
            print("  *", s.strip()[:200])
    print("\ncontext, not pass/fail: mean sentence length %.1f words, "
          "%.0f%% under twelve." % (statistics.mean(lengths),
                                    100 * short / len(sents)))
    print("Sentence length is an author preference, not a cited AI tell. Do not"
          "\nchase it. See section 11.8 of WRITING_STYLE.md.")

    print("\ncorrective pivots, judge each against section 11.1:")
    for s in sents:
        if re.search(PIVOT, s, re.I):
            print("  *", s.strip()[:210])

    # Per-section profile. The bioRxiv result says detectors find machine text
    # in the closing Discussion and the Conclusion, so those rows matter most.
    print("\nper-section profile, least readable last:")
    for name, n, f, mean in sorted(profile, key=lambda r: -r[2]):
        print("  %-44s %5dw  Flesch %5.1f  (mean %4.1f)" % (name, n, f, mean))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "mer_manuscript_v31.docx")
