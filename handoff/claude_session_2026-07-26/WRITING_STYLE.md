# Writing style: Jacob T. Dingwall

A working reference for manuscripts, not an essay about writing. Read section 1
before drafting and section 8 before submitting.

The worked examples are drawn from `mer_manuscript_v23.docx`. The bad ones are
all mine.

---

## 0. The one idea

Arvind Narayanan, quoted in Ruth Starkman's *Model Style Is So Cringe*:

> The real sign of AI writing is not superficial stuff like "It's not X, it's Y."
> It's the hollowness. Polished writing but relatively mundane ideas. Reading
> text that has the syntactic smell of AI is mildly annoying, but when I read
> hollow writing I feel the writer is wasting my time.

Starkman's own diagnosis is sharper still: a model "can produce the rhetoric of
argument before it has fully specified an actor, a relation, a limit, or a
claim."

That is the disease. The tics in section 3 are symptoms. A sentence that sounds
balanced and careful while saying very little is worse than a clumsy sentence
that says something. Before writing any sentence in the Results or Discussion,
be able to answer: which birds, doing what, when, and how sure am I. If the
sentence survives without those, delete it.

---

## 1. Where the words go

The current draft spends its effort in the wrong place.

| Section | Words | Share | Should be |
|---|---:|---:|---:|
| Introduction | 1,351 | 11% | 12 to 15% |
| Methods | 2,999 | 25% | 15 to 18% |
| Results | 3,510 | 30% | 32 to 35% |
| Discussion and Conclusion | 4,004 | 34% | 35 to 40% |

**Methods is a reference, not an argument.** A reader who wants to reproduce the
analysis will open the repository. A reader of *Marine Environmental Research*
wants to know what the birds did. Write Methods so a competent reader can follow
the logic and judge whether it is sound, then stop. Everything else goes to the
supplement or the repository.

Things that do not belong in Methods at all:

- How taxonomic splits and lumps were handled. One sentence maximum, or a
  pointer to the supplement. Nobody has ever chosen to read a paper for this.
- Convergence checking, optimizer status, gradient checks, singular fits. These
  belong in a supplementary table with one sentence in the main text saying where
  to find them.
- The internal names of anything: `did_active_0_14_day`, release identifiers,
  suppression thresholds, hash gates. Never in the main text.
- Justifications of choices nobody would question.

Things that are worth the space:

- The comparison being made, in plain language, once, clearly.
- The two outcomes and why they are kept apart.
- The one or two assumptions a sceptical reader would actually attack.

**The Discussion is where the paper earns its place.** If a section has to grow,
grow this one. Ecological interpretation, what the pattern means, what it does
not mean, what should be measured next. That is what gets cited.

---

## 2. Who is reading

A marine ecologist or ornithologist who knows about forage fish and coastal
birds, does not do causal inference, and last thought about mixed models in
graduate school. They are skimming. They will read the abstract, look at the
figures, read the first and last paragraph of the Discussion, and read the
Results properly only if the first two convinced them it was worth it.

Write for that person. The methods referee is a secondary audience and is served
by the supplement.

---

## 3. Sentence-level habits to break

Counts are from the current draft, 506 sentences.

### 3.1 "Rather than" — 66 occurrences

The dominant tic. It is negative parallelism wearing a subordinate clause. Each
one asks the reader to hold a thing that is not true in mind while learning the
thing that is.

Budget: **five per manuscript.** Use it when the wrong alternative is one a
reader would genuinely have assumed. Otherwise state the positive.

> **Bad:** "The result is a genuine absence rather than a failure to fit."
> **Good:** "The models fitted. They found nothing."

> **Bad:** "these are conditional predictions for a typical event block, observer
> and location rather than population-averaged probabilities"
> **Good:** "these predictions describe a typical site, observer and event."

> **Bad:** "its shape matches feeding method more closely than it matches which
> species had the largest contrasts"
> **Good:** "the pattern follows how a bird feeds, not how big its response was."

### 3.2 Colon and semicolon as drum roll — 43 and 55 occurrences

When em dashes were removed, the rhetorical gesture stayed and changed costume.
A colon should introduce a list or a definition. A semicolon should join two
independent clauses of equal weight. Neither should be used to create a pause
before a payoff.

> **Bad:** "This matters most where it is least comfortable: the strongest
> reporting contrasts are in gull taxa that appear on a small fraction of
> checklists."
> **Good:** "The approximation is least reliable for scarce species, and the
> strongest reporting results are in scarce gulls."

Halve both counts.

### 3.3 The aphoristic closer

A short, quotable sentence at the end of a paragraph, doing rhythm instead of
work. I do this constantly.

> "That is the limit the conclusions are framed around."
> "A design that returned positive results for every group would be more worrying
> than one that does not."
> "It is uninformative in either direction."
> "They did not."

Delete them. If the paragraph needs a conclusion, make it a finding.

### 3.4 "Which is what X would look like"

Seven occurrences between "would look like" and "which is what". It performs
inference without committing to any.

> **Bad:** "which is what continued access to eggs, adults, carcasses or
> associated prey would look like"
> **Good:** "consistent with birds still finding eggs and carcasses two weeks
> after spawning."

### 3.5 Rule of three

Four-item and three-item lists are everywhere: "diet, individual trajectories,
energetic benefit or demographic consequence". If the third and fourth items are
not load-bearing, cut to two. If they are, keep them and do not apologise. The
test is whether a reader could name what each item adds.

### 3.6 Sentence rhythm

Mean 24 words, standard deviation 13.6. Fifty-two sentences under eight words.
The short ones are used as percussion after long ones, which is a model habit.
Real variation comes from some thoughts being simple and others complicated, not
from a rhythm scheme. Let a few paragraphs run long without a punchy closer.

### 3.7 Don't explain the reader to themselves

The worst habit in the draft, and the one that reads as condescending rather than
merely wordy. A sentence that tells the reader how to read a table, why a number
was given, or what to notice next assumes they cannot work it out.

> **Cut:** "That range of nearly three orders of magnitude is why interval width,
> and not the size of the estimate, is the column to read first in the complete
> results table."
> **Keep only:** the two prevalence figures. An ecologist reading 53.5% against
> 0.09% already knows what that does to precision.

> **Cut:** "Both sides are given because two percentage points from a base of 22%
> is a different statement from two points from a base of 3%."
> **Keep only:** both sides. The reason is obvious once they are there.

> **Cut:** "Keeping the two outcomes apart makes that ambiguity visible without
> resolving it."

Also cut: announcements of what a section is about to demonstrate, restatements
of a finding immediately after giving it, and any sentence whose job is to
reassure the reader that a choice was sensible.

The test: delete the sentence. If nothing is lost except the feeling of being
guided, it was doing no work.

### 3.8 First person

Do not use I, me or my in the body. This is a sole-authored paper and the
temptation is to write "I asked whether", but ecology journals expect the
impersonal register and it reads as more professional.

- "I asked whether X" → "This study asks whether X" or "The analysis asks"
- "I set those bounds by judgement" → "These bounds were set by judgement"
- "I cannot tell whether" → "Whether X cannot be determined here"
- "I have watched dabbling ducks take eggs" → "Dabbling ducks have been seen
  taking eggs (J. T. Dingwall, personal observation)"

Two exceptions. The Acknowledgements keep "I thank", which is conventional. A
personal observation keeps its attribution in the standard parenthetical form,
which carries the first person without a first-person verb.

Avoid the passive-voice trap that comes with this. "It asks whether" and "these
bounds were set" are fine. "It was decided that the bounds would be set" is not.

### 3.9 Words to avoid

From the Helsinki study of pre- and post-ChatGPT student writing, plus the
detection literature and my own drafts.

Never: delve, leverage, foster, underscore, tapestry, testament, realm, elevate,
resonate, navigate (metaphorically), landscape (metaphorically), unlock, crucial,
pivotal, myriad, nuanced, showcase, robust (as a filler adjective).

Sparingly and only when literal: highlight, key, significant (statistical sense
only), comprehensive, framework, insight.

My own, which are worse because they sound like caution: plainly, honestly,
genuinely, precisely, exactly, "worth noting", "worth stating", "it is important
to note", "in either direction", "the honest position is".

Phrases that promise a reveal: "here's the thing", "the result?", "what this
means is", "and that matters because".

---

## 4. Vocabulary: say it in bird

The draft uses **contrast** 84 times as a noun and **family** 39 times in the
multiple-comparisons sense. Both are statistician's words. An ecologist reading
"the active-minus-pre-onset contrast was 1.30" has to translate before they can
picture anything.

Define the technical term once, in Methods, then use plain language everywhere
else. The reader who needs the precise term will know it from the definition.

| Avoid | Use |
|---|---|
| estimand | what I measured / the quantity compared |
| contrast (noun) | change, increase, difference |
| the active-minus-pre-onset contrast | the change after spawning began |
| checklist reporting | how often a species was reported |
| reported number when quantified | how many birds were counted |
| adjusted-significant | significant after correcting for multiple tests (once), then just significant |
| the fixed 49-species family | the 49 species |
| per additional recorded event link | per nearby spawning event |
| near/reference | near and farther-away shorelines |
| link scale | (delete; internal detail) |
| model component | model |
| observation process | what observers did |
| the design cannot determine | I cannot tell from these data |

**Concrete-noun test.** In any Results or Discussion paragraph, count the
sentences whose subject is a bird, an egg, a shoreline or an observer, against
those whose subject is a contrast, a family, a component or an association. The
first group should win. Right now it does not.

> **Bad:** "Positive reported-number contrasts were far more widespread than the
> significant subset alone conveys."
> **Good:** "Counts rose for almost every species, not only the ones that cleared
> the significance threshold."

---

## 5. Hedging

Hedging is necessary. Stacked hedging is cowardice with extra words, and it reads
as though the author does not believe the result.

**One hedge per claim.** Say the finding, qualify it once, move on.

> **Bad:** "Their response is therefore not evidence that the design has recovered
> something other than herring, and it is equally not evidence that it has
> recovered herring use. It is uninformative in either direction."
> **Good:** "I cannot tell whether dabbling ducks are responding to herring or to
> something that happens on the same shorelines at the same time."

Do not hedge the same thing in three sections. Say it where it belongs and
cross-reference.

---

## 6. The abstract

250 words. It is an advertisement, not a confession and not a methods summary.
The reader decides here whether to continue.

Shape: what the system is and why it is interesting; what I did, in one sentence;
what I found, in three or four; what it does and does not mean.

**Do not put in the abstract:**

- Caveats about the analysis being exploratory. This line was in the draft:
  *"Eligibility rules came from earlier work on these data whose results I had
  seen; the analysis is exploratory."* No ecologist writes that in an abstract.
  It belongs in Methods, stated once, properly.
- **A limitations sentence.** Almost no published ecology abstract ends on what
  the study could not do. This was in the draft and is now gone: *"These results
  describe what observers recorded near spawning events. They do not measure
  herring consumption, movement, or how many birds were present."* Two sentences
  of disclaimer in the position of greatest emphasis.
- Model machinery, adjustment procedures, sample-size gymnastics.
- Compressed jargon. *"that leaves specificity open"* means nothing to a reader
  encountering it for the first time. If a phrase needs the paper to decode it,
  it is not abstract material.

**Do put in the abstract:** the system, what was done, the numbers, and an
ending that says what the pattern means.

The honesty problem solves itself if the results are phrased as what was
measured. "18 species were counted in larger numbers" claims nothing about
abundance and needs no disclaimer attached. "18 species increased" would, which
is why the first version is better writing as well as safer. Reserve the caveats
for the Discussion, where a reader who has reached them has earned the detail.

**Length.** The journal cap is 250 words. Treat it as a guide rather than a
target to hit exactly; an abstract that lands near 250 and reads well is right,
and one padded to 250 is not.

---

## 7. What not to overcorrect into

Starkman's warning: "A student who removes every marked stylistic choice in order
to avoid sounding like a model has let the model set the terms anyway."

Em dashes, contrasts and three-item lists are not banned. They are overused. A
contrast that marks a real distinction earns its place. Three items that each
carry weight are a list, not a tic. The question is always whether the thought
needs the device or whether the device is standing in for a thought.

Do not flatten the writing into a hedge-free monotone either. The paper's
willingness to say what it cannot show is one of its strengths, and a referee
already said so. The problem is not that it hedges. The problem is that it hedges
in the same shape every time.

---

## 8. Revision checklist

Run before every submission.

1. Search for `\bI\b`, `\bme\b`, `\bmy\b`. The only permitted hit is "I thank"
   in the Acknowledgements.
2. Count "rather than". Over five, start cutting.
3. Count colons and semicolons. Halve them.
4. Read the last sentence of every paragraph. Delete any that is an aphorism.
5. Delete every sentence that tells the reader how to read something.
6. Search the vocabulary table and replace.
7. Read the abstract aloud. Any sentence a colleague would not say out loud
   goes, and it must not end on a limitation.
8. Check the section word shares against section 1.
9. Concrete-noun test on three random Discussion paragraphs.
10. Find every hedge on the same point and keep one.
11. Read the Methods and mark anything only a methods referee would want. Move
    it to the supplement.
12. Read the whole Results aloud. Where you stumble, the reader stops.

---

## 9. What the author's own edits show

Drawn from 43 insertions, 35 deletions and 25 comments on v27. This section
outranks everything above it, because it is the voice rather than a description
of it.

### 9.1 Write what a person saw

The single most instructive insertion:

> "On the day of spawn these fish are available and vulnerable and very close to
> shore and many are often left stranded if the tide recedes."

Compare what it replaced in spirit: "Adult fish arrive first, in dense schools
that a pursuit diver can chase." Mine names a category. His describes a scene,
and it carries information mine does not: vulnerable, very close to shore,
stranded on a falling tide. Slightly run-on, entirely concrete, no hedging
apparatus. Also added: pinnipeds accompanying the spawn.

When describing what happens at a spawn, describe what happens at a spawn.

### 9.2 Plain word over literary word

- "a fortnight" → "two weeks"
- "seaweed and eelgrass" → "marine vegetation"
- "glut" flagged as disliked
- "community science" → "citizen science"
- "macroalgae, eelgrass and rock in the bottom few metres of the intertidal" →
  "marine vegetation in the inter- and shallow subtidal"

That last one is also a three-item list collapsing to one phrase. Simplify
before elaborating.

### 9.3 The abstract carries results, not method qualifiers

Deleted from the abstract: "all chosen before fitting", "After correction for
multiple testing,", "held under every alternative encoding of overlapping
events", ", which is harder to attribute to herring."

Everything that qualifies *how* the result was obtained comes out. What remains
is the system, the numbers and what they mean.

### 9.4 State uncertainty as uncertainty

On "Loons, mergansers, grebes and cormorants chase fish, so they should meet
adults and not eggs":

> "This isnt confirmed. Id assume they focus on adults but can probably make use
> of eggs too?"

On gulls:

> "Probably not entirely true because gulls will eat floating vegetation with
> eggs and make use of herring that get pushed to the surface or are very
> shallow."

Two lessons. Do not write a plausible mechanism in the grammar of an
established one. And do not let a tidy guild scheme flatten what the birds
actually do; the categories are an organising device, not a description of
diet.

Related: "Can you give genus or group names?" Name the taxa rather than
gesturing at a group.

### 9.5 The concluding sentence is usually the problem

Four comments land on closers and summary sentences: "Don't like this concluding
sentence", "Don't like this sentence", "Bad sentence", "This feels super
AI-worded." The flagged examples were all sentences doing rhythm rather than
work. Section 3.3 above already says to delete them; his edits confirm it is the
most reliable single test.

### 9.6 Give the honest reason, not the presentable one

On the Strait of Georgia paragraph:

> "the SOG is chosen because it has the most data on both ends"

I had written an ecological justification. The real reason is data density on
both the herring side and the bird side. Say that.

### 9.7 Structure

- Section headings in title case.
- Split study area from data sources. Study area gets a map showing coastal bird
  migration and the timing of major groups. Then a data-sources section with one
  subsection per source, eBird and then herring, then a third on how they were
  combined.
- "Estimand" out of any heading. Nobody uses the word.
- Define terms of art at first use, in plain language. "Explain what an event
  block is." His own model for this is the definition he wrote for X: "Users
  would input an 'X' when they determine that a bird is present but are not able
  to or are not willing to quantify it – often due to large numbers." Written
  from the user's point of view, not the model's.
- Say a thing once. "We say this before too so decide when to say it and just
  say it once."

### 9.8 What he deleted outright

Both of these were open questions I had been carrying, and the edits settle
them:

- The exploratory disclosure in Section 2.1, deleted in full.
- The taxonomy sentence, deleted in full, even in the one-clause form.

Neither survives contact with an author who knows what readers care about.

## Sources

- [Model Style Is So Cringe](https://ruth.substack.com/p/model-style-is-so-cringe), Ruth Starkman, March 2026, on negative parallelism, prefab triads, and alignment-induced style. Contains the Narayanan quote on hollowness.
- [How to spot when writing is AI: the 6 elements of robot style](https://huntingthemuse.net/library/how-to-tell-if-writing-is-ai), Thomas Cox, updated June 2026, on em dashes, buzzwords and formulaic structures.
- [The Helsinki study of student writing before and after ChatGPT](https://arxiv.org/pdf/2504.13038), source of the surged-vocabulary list.
- [How to Spot AI Writing Tells](https://www.oliviacal.com/post/ai-writing-tells) and [Signs of AI Writing](https://vrid.ai/blog/signs-of-ai-writing), for the wider blacklist.
