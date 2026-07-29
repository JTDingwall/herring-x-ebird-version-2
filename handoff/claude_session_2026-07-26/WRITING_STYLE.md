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

**Revised by the author, 26 July 2026. This supersedes the earlier description
of a reader who "last thought about mixed models in graduate school".**

An ecologist with at least a master's degree, comfortable with statistics. They
fit mixed models themselves. They know what a random intercept absorbs, what a
false discovery rate correction does, and what a difference-in-differences
design assumes. They do not need any of it explained.

What they do not necessarily have is the herring literature, the eBird literature
or the coastal ecology of this particular sea. That is where explanation is
worth spending words.

They are still skimming. Abstract, figures, first and last paragraph of the
Discussion, then the Results if the first two earned it.

**What follows from this.**

- Name a method and move on. "A binomial mixed model with a logit link" is a
  complete statement to this reader. Do not follow it with what a logit link is.
- Standard procedures need a citation, not a tutorial. Benjamini-Hochberg,
  parallel trends, Wald intervals, singular fits, `nAGQ = 0`: name them, cite
  them, say what was chosen and why, and stop.
- Assume they can read a confidence interval. Do not tell them which column to
  read first, which estimate is most precise, or that a wide interval means
  uncertainty.
- Diagnostics belong in the text only where they change what a result means. A
  singular fit that affects a headline species matters. A list of every
  convergence setting does not; that is supplement material.
- Effect sizes on a natural scale are still worth giving, not because the reader
  cannot exponentiate but because "3.34 more birds on a checklist" is the
  ecologically meaningful quantity and the ratio is not.
- Ecological reasoning is where the effort goes. This reader will not be
  impressed by the statistics and will not be forgiving about the biology.

The methods referee is a secondary audience and is served by the supplement.

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

**Revised after v30. See section 10.1, which supersedes what follows.**

The original diagnosis was that short sentences were being used as percussion
after long ones, which is a model habit. That was true. Acting on it too
aggressively produced the opposite fault: by v30 the prose was clipped and
fragmented, with 113 of 506 sentences under twelve words. Cut the drumbeat
without cutting the length.

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

Items 1 to 5 are mechanical and should be scripted. Run them on every build and
report the numbers.

1. **Binomial at first mention.** For every common name in
   `metadata/canonical_species_registry.csv`, find its first occurrence in the
   body and confirm the scientific name is present at that occurrence. Genus
   spelled out on first appearance, abbreviated after, except where the
   abbreviation is ambiguous. This has been missed twice; script it.
2. **Readability, not sentence length.** Report Flesch Reading Ease for the body
   and per subsection. It should not fall between builds and no subsection
   should sit below 40. Sentence length is an author preference, not evidence of
   machine writing, and section 11.8 records what went wrong when it was treated
   as evidence. Report the mean for interest; do not act on it.
3. **First person.** Search `\bI\b`, `\bme\b`, `\bmy\b`. The only permitted hit
   is "I thank" in the Acknowledgements.
4. **Banned vocabulary.** Search for: frozen, release, gate, hash-lock, study
   rules, analysis frame, estimand, component, execution record, and any
   CamelCase or snake_case field name. All should return zero.
5. **Counts.** Zero em dashes. Colons and semicolons halved from whatever the
   previous draft had. Corrective pivots ("rather than", "instead of", "not X
   but Y") under two per thousand words, and every survivor load-bearing by the
   test in section 11.1. Run the full scan in section 11.7, which supersedes the
   flat cap this item used to carry.

Then read:

6. Read the last sentence of every paragraph. Delete any that is an aphorism.
7. Delete every sentence that tells the reader how to read something.
8. Delete every clause that restates a condition the sentence already implied.
9. Delete every "Section X sets out Y" that is not doing real work.
10. Count paragraphs under four sentences in the Introduction and Discussion.
    Merge them.
11. Check that connectives are present. However, although, whereas, because,
    therefore, in contrast. Their absence is what makes prose staccato.
12. Any passage with four or more numbers doing the same job becomes a table.
13. Read the abstract aloud. Any sentence a colleague would not say out loud
    goes, and it must not end on a limitation.
14. Check the section word shares against section 1.
15. Concrete-noun test on three random Discussion paragraphs.
16. Find every hedge on the same point and keep one.
17. Read the Methods and mark anything only a methods referee would want. Move
    it to the supplement.
18. Confirm no `[[AUTHOR INPUT REQUIRED]]` marker is asking the author for
    writing he already asked for. Those are for facts only he holds.

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

## 10. Second round of author edits, on v30

Fifteen comments, 26 July 2026. Three of these correct guidance given earlier in
this document, so where they conflict, section 10 wins.

### 10.1 The prose is now too short, not too long

> "Also overall the paragraphs appear to be too short. They sound clippy and
> fragmented."

Measured on v30: 506 sentences, mean 20.5 words, and **113 of them under twelve
words**. That is 22% of the paper in sentences shorter than a normal academic
clause. Section 3 of this guide caused it. Cutting aphoristic closers and
negative parallelism was right; the collateral damage was that everything got
short.

Targets going forward:

- Mean sentence length around 24 to 26 words.
- Under 12 words: no more than about 5% of sentences, and only where the thought
  is genuinely simple.
- Paragraphs of five or more sentences in the Introduction and Discussion. A
  three-sentence paragraph in those sections is usually two paragraphs that
  should be one.

The related comment: "These paragraphs feel like they overlap a lot and should
maybe be combined." Short paragraphs and repeated content are the same fault
seen from two directions.

### 10.2 Use ordinary academic connectives

The author inserted ", however," into a sentence and commented:

> "I think you need to add more transitions words like this."

Section 3.7 blacklists a set of promise-a-reveal phrases, and that stands. It
does not extend to the ordinary connective vocabulary of academic prose.
**Use** however, although, whereas, because, therefore, in contrast, by
comparison, moreover, since, while, given that. Their absence is what makes
prose staccato, and staccato reads more artificial than a well-placed "however"
ever will.

### 10.3 Never use variable or field names

Two separate comments, one emphatic:

> "Describe more about the dataset and don't use variable names. How do they
> collect it, etc."
> "Don't use variable names! Use english!"

Both anchored to `StartDate` and `EndDate`. Write "the start and end dates
recorded for each spawning record". The reader does not have the schema and
should not need it.

This extends to anything from the pipeline. On the phrase "frozen analysis
frame":

> "In no scientific paper would you ever see someone describing their coding
> process like this. This sort of stuff is bad."

Banned vocabulary: frozen, release, gate, gate-enforced, hash-locked, study
rules, analysis frame, component, model component, versioned mapping, execution
record. Also "under the study rules", which drew "Nobody cares about study
rules. Remove."

Section 4 of this guide has a translation table. Add these to it.

### 10.4 Do not restate a condition you have already stated

On "conditional on the species being reported and assigned a finite count":

> "This type of unnecessary detail is evident throughout the paper and is a good
> hallmark of AI writing."

The sentence had already said the outcome was the log of the number reported.
Adding the formal condition afterwards is precision theatre. It reads as though
the writer is proving they understand rather than telling the reader something.

This is the most transferable of the fifteen comments and it is worth a pass of
its own: find every clause that re-specifies something the sentence already
implied, and delete it.

### 10.5 Cross-reference sentences are usually filler

On "Section 4.4 sets out where it matters most", the comment was simply:

> "bad"

The pattern "Section X sets out / returns to / discusses Y" defers instead of
saying anything. Either say the thing now, in a clause, or leave it for that
section and say nothing here. One or two genuine forward references in a paper
are fine; this draft had many, and I wrote most of them.

### 10.6 Latin names: at first mention, but do not enumerate genera

The author's rule, stated as an instruction to this document:

> "Remember all first time common names need a species name! Add this to the
> writing style md"

That is in section 9.7 and in the checklist, and it was still missed: American
Robin appeared without *Turdus migratorius*. **Treat it as a mechanical check,
not a stylistic aspiration.** See the checklist.

But the earlier request to name taxa has a limit. On a passage giving genus
names for every group, "Loons in Gavia, mergansers in Mergus and Lophodytes,
grebes in Podiceps and Aechmophorus, and cormorants in Urile and Nannopterum":

> "Change my mind on adding these latin names here"

Naming the birds means naming the birds. It does not mean a taxonomic inventory.
Species get a binomial at first mention; groups referred to collectively do not
need every genus listed.

### 10.7 Design detail does not belong in the Introduction

On the sentence introducing the two comparator species and the terrestrial
control:

> "Probably unnecessarily rigorous for an intro."

Comparators, controls and multiplicity families are Methods material. The
Introduction states the question and what would count as an answer.

### 10.8 Dense numbers belong in a table or a figure

On the date-precision audit paragraph, which ran several sentences of counts and
percentiles:

> "This whole section needs to be more readable. Is there information you can add
> to a table? Or to the flow diagram figure? This is really hard to read."

If a passage is four or more numbers doing the same job, it is a table. Prose
should give the one number that matters and point at the table for the rest.

### 10.9 When the author leaves a placeholder asking for prose, write the prose

The author had written "*put something here about bird and herring conservation
and management*". The draft returned it as
`[[AUTHOR INPUT REQUIRED: add the intended sentence connecting this study to
bird and herring conservation or management.]]`. His response:

> "I asked you to do this?"

`[[AUTHOR INPUT REQUIRED]]` is for facts only he holds: a DOI, a grant number, a
funding statement, an unpublished reference. It is not for writing he has asked
for. Draft it, mark it as a draft if you are unsure of his angle, and let him
correct it.

### 10.10 Describe how data are collected, not what fields exist

Comment 12 asks for more about the dataset: how it is collected, by whom, at what
frequency. The draft listed the fields instead. A reader wants to know that DFO
runs surface and dive surveys along the coast each spring and how a record comes
to exist, not which columns the file has.

Note that the author also deleted "run by the Cornell Lab of Ornithology" as
unnecessary. More about the collection process, less institutional furniture.

## 11. What the 2025 and 2026 literature on AI writing in science says

Sections 3 and 4 were built from general-audience commentary on how to recognise
machine prose. This section is built from measurement, and specifically from
measurement inside the scientific literature. Three studies matter. Kobak and
colleagues tracked vocabulary across 15 million PubMed abstracts. The
*Organization Science* AI Task Force scored every submission to the journal and
linked those scores to readability and to editorial outcome. A 2026 bioRxiv
study ran a window-level detector across the biomedical corpus and reported
where in a paper the machine text sits.

Their findings do not all point the same way as sections 3 and 4, and where they
conflict, these win, because they are counts rather than impressions.

### 11.1 The corrective pivot is the single strongest tell

The bioRxiv study describes one construction as the native register of language
models, present regardless of how the model is prompted: the pivot that sets up
a wrong reading and corrects it. Its surface forms are "not X but Y", "X rather
than Y", "instead of", "less about X than about Y", and "it is not that X, it is
that Y".

This is worth taking seriously because the construction is not obviously bad. It
is a normal English move, and scientific writing needs it whenever a real
alternative has to be ruled out. The failure is one of density and of honesty
about whether the alternative was ever live.

**The test: was the negated reading something a reader would actually have
reached for?**

Load-bearing, keep:

> The resulting index is relative rather than absolute.

A reader would default to absolute. The pivot corrects a real expectation.

> Distances ran from checklist points to recorded event points, not from
> travelling routes to a real spawning footprint.

The negated version is what a reader assumes the analysis did. Correcting it is
the whole point of the sentence.

Decorative, cut:

> This is a description of what observers recorded rather than a claim about
> what birds did.

If the surrounding text already says the design cannot observe behaviour, the
pivot is restating a condition, which section 10.4 already bans. Write the
positive half and stop.

A count of these in the manuscript body is a useful diagnostic. Version 31 has
15 in 10,009 words, and on inspection nearly all are load-bearing, several of
them on the literal contrast between a number and an X in the data. That is an
acceptable density. Two or three per paragraph is not.

### 11.2 Machine text concentrates in the Limitations and the Conclusion

This is the most directly useful finding for this manuscript. In *Nature*,
*Science* and *Cell*, the bioRxiv study found that flagged passages were almost
always confined to the final sections, typically the limitations subsection or
the closing remarks of the Discussion. Detection runs on sliding windows of a
few hundred words, so a single machine-drafted paragraph inside an otherwise
human paper is enough to register.

The reason is obvious once stated. Limitations sections are where an author has
least invested, where the content is generic across papers, and where it is
most tempting to ask for a list. That is exactly where a model will produce
fluent, ordered, faintly hollow prose.

Section 4.4 and Section 5 of this manuscript are precisely those sections, and
both were drafted by machine and rewritten several times. They get read last and
hardest. Two rules follow.

**A limitation must be specific to this study and to nobody else's.** Anything
that could appear verbatim in any observational ecology paper does not belong.
"Correlation does not imply causation" is furniture. "Distances ran from
checklist points to recorded event points, not from travelling routes to a real
spawning footprint" could only be written about this analysis.

**Do not let the limitations become a list.** The tell is a sequence of
same-shaped sentences, each naming a concern and closing it off. Version 31
handles this by grouping: one paragraph on the block structure and what the
design cannot say, one on model fitting, one on measurement and coverage. Each
paragraph argues rather than enumerates, and each ends on something concrete.
The last one ends on the 2 km result, which turns a limitation into evidence.

The Conclusion has the same exposure. It should say what happened, in numbers,
and what it is not evidence of. It should not summarise the paper section by
section and it should not end on a call for further work in general terms.

### 11.3 Machine prose is harder to read, not easier

This inverts an assumption worth naming. The *Organization Science* Task Force
found that abstract readability at the journal was stable for a decade, then
fell from the launch of ChatGPT, reaching 1.28 standard deviations below the
January 2021 level by January 2026. The correlation between AI score and Flesch
Reading Ease was negative and strong. Manuscripts with high AI scores were
desk-rejected at roughly 70%, against 44% for manuscripts with little or no
detectable AI, and reached a first-round revise-and-resubmit at 3.2% against
about 12%.

What makes the prose harder is named precisely: longer words, more complex
sentence structures, more jargon, and more nominalizations.

**This does not contradict the author's instruction in section 10.1 to write
longer sentences, and the distinction matters.** Both a good long sentence and a
machine long sentence run past 25 words. They get there differently.

A long sentence earns its length through connectives and concrete subjects:

> Only complete checklists were retained, because marking a checklist complete
> means the observer reported every species they detected and identified, so a
> species that does not appear on one can be treated as a genuine non-detection.

Subjects are things in the world. The joins are *because* and *so*. A reader
follows it in one pass.

A machine long sentence gets there by stacking abstractions:

> Contrary to prevailing expectations, loss framing weakly reduces overall
> performance, with substantial heterogeneity across task dimensions.

That is from the Task Force's own experiment, in which a language model was
asked to rewrite a published abstract for a top journal. Its version scored in
the 24th percentile for readability against the 87th for the original, and 98.9%
on the detector. Read the two side by side before starting any rewrite; it is
the best single worked example available of the failure this manuscript is
trying to avoid.

Practical consequence: **prefer length from subordination, not from
nominalization.** If a sentence has three or more words ending in *-ation*,
*-ization* or *-ment*, rewrite it around verbs. Version 31 has 49 such words in
10,009, none of them three to a sentence.

### 11.4 Being concrete and numerical is not a defence

The same study found that machine writing tends to hedge less, use less passive
voice, and include more numbers than human writing. This is worth flagging
because it removes a comfortable defence. Prose full of species names,
percentages and confidence intervals can still read as machine-written. The
tells in sections 11.1 to 11.3 are structural, and they survive the presence of
data.

### 11.5 The excess-vocabulary list

Kobak and colleagues identified 379 style words whose frequency jumped abruptly
in 2024 abstracts, and estimated that at least 13.5% of 2024 biomedical
abstracts had been processed by a language model, reaching 40% in some
subcorpora. The words are the familiar ones: *delve*, *underscore*, *showcase*,
*crucial*, *pivotal*, *intricate*, *comprehensive*, *robust*, *notably*,
*align with*, *shed light on*, *highlight*, *leverage*, *harness*, *foster*,
*bolster*, *realm*, *landscape*, *paradigm*, *valuable insights*, *plays a
critical role*, *serves as*, *multifaceted*, *nuanced*.

Section 4 already bans most of these. The scan of version 31 returns zero for
every item on the list, so this is maintenance rather than repair. Keep it that
way, and keep the scan in the build.

Note the direction of travel. Once a word is known as a tell, careful authors
stop using it, and the signal shifts to the structures in 11.1 to 11.3, which
are much harder to strip out. Vocabulary is the easy half.

### 11.6 Light editing does not remove the signal

The detection studies report a rising band of intermediate scores, read as text
drafted by a model and then edited by a person. Editing a machine draft
sentence by sentence leaves the paragraph architecture intact, and the
architecture is what registers. Where a passage reads as machine-written, the
repair is to rewrite the paragraph from its argument, not to substitute words
inside it.

### 11.7 Scan to run on every build

Implemented in `ai_tells_scan.py`. Add it to the checks in section 8. Figures
below are for the body of version 31, Introduction through Conclusion, 10,224
words and 383 sentences.

**Measure it correctly or the numbers will mislead.** Three counting decisions
change the answer by a factor of two, and all three were got wrong on the first
attempt:

- Split sentences with author initials, "et al." and abbreviated genera
  protected. Splitting naively on a full stop plus a space turns "(B. L.
  Sullivan et al. 2009)." into four sentences and inflates the short-sentence
  share from 15% to 22%.
- Exclude headings. They are two or three words each and there are about thirty.
- Exclude figure and table captions. They are labels, and their fragments push
  the Results subsections down by ten words per sentence.
- Stop at the back matter. CRediT statements and declarations are boilerplate.

| Check | Target | v31 |
|---|---|---|
| Corrective pivots per 1,000 words | under 2, each load-bearing | 1.5 (n=15) |
| Excess-vocabulary list, section 11.5 | 0 | 0 |
| Sentences with 3 or more nominalizations | 0 | 0 |
| Em dashes or double hyphens | 0 | 0 |
| Flesch Reading Ease, whole body | not falling between builds | 53.8 |
| Flesch, least readable subsection | above 40 | 34.6 in Section 5 |

Sentence length is deliberately absent. Section 11.8 explains why.

**On reading the Flesch numbers.** Scientific prose scores low in absolute
terms, and species names and statistical vocabulary drag it down regardless of
how the sentences are built. The number is worth nothing on its own. Two things
about it are worth something: whether it falls between builds, which is the
signal the *Organization Science* task force detected, and the spread between
sections, which shows where the prose has thickened.

**Where this manuscript thickens.** Ranking the subsections by readability puts
the same block at the bottom every time: Section 4.1 at 45.8, Section 4.5 at
44.3, Section 4.3 at 47.2, Section 4.4 at 47.5, and Section 5 at 34.6, the
lowest in the paper. Methods sit low too, which is expected and not a concern.
The Discussion tail sitting low is a concern, because it is the same block the
bioRxiv study identifies as where detectors find machine text. Those five
subsections should be read hardest and, where possible, written in shorter
words. Not shorter sentences. Shorter words.

### 11.8 Sentence length is not a tell, and chasing it caused a real error

The author's instruction on this is direct: he is not concerned about sentence
length unless it is a cited marker of machine writing. It is not, and the data
from this manuscript shows why the earlier guidance here was wrong.

**Short sentences appear nowhere in the literature as a sign of AI.** The
opposite is true. Machine prose is longer and more complex, not clipped. The
"too clippy and fragmented" note on v30 is a preference about how the author
wants his paper to read, which is reason enough to honour it, but it carries no
weight as evidence of anything. It belongs in section 10, not here, and the
5% threshold invented for it in 10.1 should be treated as loose guidance.

**Long sentences are cited, but only through readability, and readability in
this manuscript is not driven by sentence length.** Ranking the 24 subsections
by both statistics puts them almost in opposition:

| Subsection | Mean sentence | Flesch |
|---|---|---|
| 3.2 Overall Pattern | 39.6, the longest | 63.5, third most readable |
| 3.3 Responses by Feeding Group | 32.5 | 63.2 |
| 5 Conclusion | 23.9, near the median | 34.6, least readable |
| 2.4 Statistical Comparison | 26.1 | 40.3 |

Section 3.2 has by far the longest sentences in the paper and is among its most
readable, because the words are short and the subjects are birds. The Conclusion
has ordinary sentences and is the hardest passage in the paper, because it is
carrying "nearest-event assignment", "present-or-absent indicator" and
"species-specific" in a small space.

**The practical rule.** Length is not the lever. Word choice is. A long sentence
about scoters and eggs is fine. A short sentence made of compound technical nouns
is not. When a passage reads badly, replace the abstractions; do not chop the
sentence in half.

**Recorded so the same mistake is not repeated.** The v31 build included a
paper-wide sentence-length pass, and this file then flagged four subsections as
having overshot at 31 to 40 words. That flag was wrong. Three of those four are
in the top half of the readability ranking, and Section 3.2, the one flagged
hardest, is the third most readable subsection in the manuscript. No rewriting
was done on that basis, and none should be.

## 12. Opener monotony is the strongest structural tell

Found in v35 and fixed in v36. It is not in any of the published lists, but it
is the thing that made the page read as generated after the vocabulary and the
hedging were already clean.

**Twenty-two of 91 body paragraphs opened with "The".** Sixty-five of 378
sentences did. Every paragraph arrived in the same shape: definite article,
abstract noun, verb, claim. "The design assumes", "The analysis covered", "The
study's main strength is", "The nearest-event sensitivity changed", "The
scoter results fit", "The gulls also show", "The timing adds detail".

A human writing 91 paragraphs does not do this, because a human varies where
the weight falls. A model does it because the definite-article topic sentence
is the safest possible opening and it has no reason to stop choosing it.

**The fix is not synonym substitution.** Rewriting "The" to "This" or "These"
changes nothing. What works is asking what the paragraph is actually about and
putting that first:

| Was | Now |
|---|---|
| The scoter results fit local aggregation most closely. | Scoters fit local aggregation most closely. |
| The gulls also show the limits of community-science data. | Gulls show the limits of community-science data. |
| The same shape appears in the family as a whole. | Widening from eight species to the whole family gives the same shape. |
| The direction of that separation follows the order in which food appears. | Food appears in a sequence, and the separation follows it. |
| The study's main strength is how it frames the comparison. | This design earns its keep by how it frames the comparison. |
| The Strait of Georgia was selected for this study because it has the most data. | Two records overlap in the Strait of Georgia more than anywhere else on this coast, which is why the study is set there. |

Most of these are better sentences independently of the tell, which is the test
of whether the change is worth making. Where varying the opener would have made
the sentence worse, it was left alone: six paragraphs still begin with "The",
and that is a normal rate.

**Add to the scan.** Paragraph openers beginning "The" should sit under 10%.
v35 was 24%, v36 is 7%. Sentence openers under 15%; v35 was 17%, v36 is 13%.

**Watch for the same monotony in other positions.** Runs of paragraphs that all
end on a short summary clause, or all place their citation in the same slot,
produce the same effect. The general rule is that structural variety is
evidence of a person having made choices, and its absence is evidence of a
default having been applied.

## 13. The gnomic framing sentence

Named by the author on this sentence, which I had written one revision earlier
while fixing something else:

> Food appears in a sequence, and the separation follows it.

His verdict: "this type of sentence sounds very AI-esque." He is right, and the
diagnosis matters more than the example.

**The shape.** The subject is an abstraction. The predicate makes a claim about
the argument rather than about the world. A pronoun points at something the
reader cannot see. The sentence sounds like a finding and contains none.

Every one of these was in the draft:

| Gnomic | What replaced it |
|---|---|
| Food appears in a sequence, and the separation follows it. | Adult fish and spent carcasses come first, attached eggs later, and the groups separate in that order. |
| This design earns its keep by how it frames the comparison in space and time. | Framing the comparison in both space and time is what keeps two confounds out of it. |
| What this analysis provides is a map of where to look. | (cut; the next sentence already said it concretely) |
| The logic is easiest to see in terms of event links. | (cut; the equation follows immediately) |
| Standardized predictions put several of these ratios on a scale a reader can picture. | Standardized predictions convert several of these ratios into birds on a checklist and percentage points. |
| These results are harder to read than they first appear. | (cut) |
| The internal structure of these results fits that concern. | (cut) |
| That matters beyond the birds themselves. | (cut) |

**The test.** Ask what the subject of the sentence is. If the answer is "food",
"the logic", "the internal structure", "this analysis", "these results" or "the
design", rewrite it so the subject is a bird, a fish, an observer, a number or a
date. If the sentence then has nothing left to say, it was scaffolding and
should go: four of the eight above were simply deleted, and nothing was lost,
because the sentence after them already carried the content.

**Why it appears.** It is the transition a model reaches for when it wants to
signal that an explanation is coming. A person writing about scoters writes
about scoters. Section 10.4 already banned restating a condition and section 3
already banned aphorisms at the end of a paragraph; this is the same instinct
arriving at the start.

**It survives the other checks.** None of these eight would be caught by
vocabulary, hedging, readability or sentence length. Three of them were
introduced by the opener pass in section 12, which is worth recording plainly:
fixing one tell mechanically will introduce another unless each replacement is
read as a sentence in its own right.

## 14. Measured against the author's own published prose

On 27 July the author supplied Dingwall et al. 2026, his co-authored paper in
the same journal. It is in `reviews/dingwall_et_al_2026_style_reference.docx`
and it **outranks every inferred rule in this file**, because everything before
section 14 was reasoning from published advice about machine writing, and this
is evidence about how he actually writes.

Both texts measured identically, body prose only:

| | Dingwall 2026 | v39 | v40 |
|---|---|---|---|
| 2+ comma-joined subordinate clauses | **1%** | 12% | 8% |
| Paragraphs ending on a subordinate clause | **17%** | 48% | 45% |
| Connectives per 1,000 words | **7.8** | 16.1 | 14.0 |
| Semicolons per 1,000 words | **10.2** | 2.5 | 2.5 |
| Sentences per paragraph | **5.6** | 4.1 | 4.5 |
| Nominalizations per 1,000 words | **33.4** | 5.6 | 5.6 |
| Flesch Reading Ease | **23.3** | 54.1 | 55.1 |
| Mean sentence length | 24.9 | 24.9 | 22.7 |
| Em dashes | 0 | 0 | 0 |

### 14.1 What this confirms

**Clause chains are the real tell.** He stacks two or more comma-joined
subordinate clauses in 1% of sentences. v39 did it in 12%. This is the largest
single discrepancy in the table and the v40 pass exists because of it.

**Paragraph endings matter as much.** He lands on a subordinate clause 17% of
the time; v39 did it 48% of the time. Nearly half the paragraphs trailing off in
"…, because X" is a rhythm signature no human produces by accident.

### 14.2 Three rules in this file that were wrong

**The connective target was double his rate.** Section 10.2 told the draft to
add ordinary connectives, correctly, because v30 was staccato. The pass took the
manuscript from 45 to 93 connectives, which is 16 per thousand words against his
7.8. The instruction was right and the magnitude was not.

**Halving semicolons was wrong.** Section 8, item 5 said to halve colons and
semicolons every draft. He uses 51 semicolons in 5,000 words, four times v39's
rate. That is a signature and the rule was deleting it.

**Plain vocabulary is not his register.** He runs 33 nominalizations per
thousand words and a Flesch score of 23. v39 runs 5.6 and 55. "This portfolio
effect reduces the likelihood of simultaneous collapse by buffering against
localized disturbances" is an ordinary sentence in his paper and nothing in v39
sounds like it.

### 14.2b Appending a clause with ", and" — a preference, not a rule

The author, 27 July, on this sentence:

> **Mine:** Community science records offer a different kind of leverage, and it
> is worth being specific about what kind.
>
> **His:** Community science records offer a different kind of leverage. Though,
> it is worth being specific about what kind.

The habit he is correcting is appending a second independent clause with ", and"
followed by a pronoun. Dingwall et al. 2026 contains zero instances of it in 614
sentences; the v44 Introduction draft had five per thousand words.

**It is a preference and not an absolute.** He said so explicitly when this file
first recorded it as a rule. Split where the two halves are separate thoughts;
keep the join where the second half depends on the first. One of the five splits
made the text worse, because "Both depend on effort" lost its referents across
the full stop.

Note also that his published turn-word is **However** (4 uses), with Although
(5) and While (8). Sentence-initial "Though," does not appear in print.

**The meta-lesson, which has now happened four times.** Sentence length,
connective density, paragraph openers and this. Each time a measured difference
was converted into a threshold and over-applied, and each time the
over-application was itself the thing that read as machine-written. Measure to
find where to look. Do not measure to decide what to write.

### 14.3 What not to copy

Do not chase the Flesch score down. Deliberately making prose harder to read in
order to match a style signature is the wrong trade, and it would undo section
11.3, which is grounded in measurement of what reviewers actually reject. Two
caveats also apply to the comparison itself: Dingwall et al. 2026 has five
authors including a senior author, so its voice is not purely his, and its
subject matter carries more inherently technical vocabulary than a bird-counting
paper does.

Copy the structural signatures, which are unambiguously his: few clause chains,
paragraphs that end on a main clause, connectives near 8 per thousand words,
semicolons used freely, and paragraphs of five to six sentences.

### 14.4 Outstanding gap after v40

| Target | His | v40 | Action |
|---|---|---|---|
| 2+ joins | 1% | 8% | Keep cutting |
| Paragraph ends on subordinate clause | 17% | 45% | Barely addressed; needs its own pass |
| Connectives per 1,000 words | 7.8 | 14.0 | Remove roughly a third |
| Semicolons per 1,000 words | 10.2 | 2.5 | Restore where clauses are genuinely balanced |
| Sentences per paragraph | 5.6 | 4.5 | Merge short paragraphs |

## 15. Section headings

Retitled at the author's request in v33. The old ones were conversational where
this reader expects a label. Compare:

| Was | Now |
|---|---|
| 2.3 Checklist Selection and Response Construction | 2.3 Response Variables |
| 2.4 Statistical Comparison and Models | 2.4 Model Structure and the Difference-in-Differences Contrast |
| 2.5 Multiplicity, Sensitivity Analyses and Interpretation | 2.5 Multiple Testing and Sensitivity Analyses |
| 3.1 Study Coverage and Model Completion | 3.1 Coverage and Model Convergence |
| 3.4 When Each Group Responded | 3.4 Timing of Response |
| 3.5 What the Changes Mean on a Natural Scale | 3.5 Effect Sizes on the Observed Scale |
| 3.6 Results That Complicate a Herring-Specific Reading | 3.6 Results Inconsistent with a Herring-Specific Response |
| 3.7 Sensitivity to Design and Observation Choices | 3.7 Sensitivity Analyses |
| 4.1 What the Study Shows | 4.1 Principal Findings |
| 4.3 Why Reported Number Was More Stable Than Checklist Reporting | 4.3 Divergence Between the Count and Reporting Outcomes |
| 4.4 Design Strengths and Limitations | 4.4 Strengths and Limitations |
| 4.5 Implications and Next Steps | 4.5 Implications and Future Work |
| Birds That Should Have Responded and Did Not | Expected Responders That Did Not Respond |

The rule behind it: a heading names its contents, it does not narrate them. "What
the Study Shows" is a sentence fragment addressed to the reader. "Principal
Findings" is a label. Headings that begin with "What", "Why", "When" or "How"
are almost always the former.

Keep the naming consistent with the body text. The manuscript says "feeding
group" throughout, so the headings say feeding group and not guild.

## Sources

- [Fine-Grained Detection of AI-Generated Writing in the Biomedical Literature](https://www.biorxiv.org/content/10.64898/2026.01.01.697311), bioRxiv, January 2026. Window-level detection across the biomedical corpus. Source of the corrective-pivot finding and of the result that flagged passages in *Nature*, *Science* and *Cell* sit almost entirely in limitations and closing Discussion text.
- Kobak, D., González-Márquez, R., Horvát, E.-Á. and Lause, J. (2025) [Delving into LLM-assisted writing in biomedical publications through excess vocabulary](https://doi.org/10.1126/sciadv.adt3813). *Science Advances* 11(27). 15 million PubMed abstracts, 379 excess style words, at least 13.5% of 2024 abstracts machine-processed.
- Organization Science AI Task Force (2026) [More versus Better: Artificial Intelligence, Incentives, and the Emerging Crisis in Peer Review](https://doi.org/10.1287/orsc.2026.ed.v37.n3). *Organization Science* 37(3). Readability, desk-rejection and revise-and-resubmit rates by AI score. Companion essay: [More Versus Better, Part I](https://orgsci.substack.com/p/more-versus-better-part-i), 27 April 2026, which contains the side-by-side abstract experiment referenced in 11.3.
- [AI Slop Is Flooding Academic Journals. A Top Journal Measured It](https://www.forbes.com/sites/johndrake/2026/04/30/ai-slop-is-flooding-academic-journals-a-top-journal-measured-it/), Forbes, 30 April 2026, reporting the above.
- [Resisting AI slop](https://doi.org/10.1126/science.aee8267), *Science* editorial, January 2026.
- [Model Style Is So Cringe](https://ruth.substack.com/p/model-style-is-so-cringe), Ruth Starkman, March 2026, on negative parallelism, prefab triads, and alignment-induced style. Contains the Narayanan quote on hollowness.
- [How to spot when writing is AI: the 6 elements of robot style](https://huntingthemuse.net/library/how-to-tell-if-writing-is-ai), Thomas Cox, updated June 2026, on em dashes, buzzwords and formulaic structures.
- [The Helsinki study of student writing before and after ChatGPT](https://arxiv.org/pdf/2504.13038), source of the surged-vocabulary list.
- [How to Spot AI Writing Tells](https://www.oliviacal.com/post/ai-writing-tells) and [Signs of AI Writing](https://vrid.ai/blog/signs-of-ai-writing), for the wider blacklist.
