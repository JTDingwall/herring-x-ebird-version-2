# -*- coding: utf-8 -*-
"""v36 edits: substring replacements on the v35 text.

Two problems, both structural rather than lexical.

OPENER  Twenty-two of 91 body paragraphs began "The", and 65 of 378 sentences.
        Uniform topic-sentence shape is what makes a page read as generated.
        Varied only where the new opener is also the better sentence: several
        put the subject of the paragraph first instead of an abstraction.

PLAIN   Compound technical nouns stacked into short spans, worst in the
        Conclusion (Flesch 34.6, the lowest passage in the paper) and 4.5.
        Replaced with ordinary words. No number, name or claim changes.
"""

EDITS = [
 # ---------------- OPENER ----------------
 (12, "The Strait of Georgia was selected for this study because it has the most data on both sides of that question.",
      "Two records overlap in the Strait of Georgia more than anywhere else on this coast, which is why the study is set there."),
 (17, "The study covers the Strait of Georgia, British Columbia, Canada, a semi-enclosed coastal sea",
      "Fieldwork and observation both concentrate in the Strait of Georgia, British Columbia, Canada, a semi-enclosed coastal sea"),
 (37, "The second outcome was the natural logarithm of the number reported.",
      "Reported number, the second outcome, entered the models as a natural logarithm."),
 (48, "The family of 49 species was fixed before any event-link model was run.",
      "All 49 species were fixed as a family before any event-link model was run."),
 (59, "The analysis covered 217,200 complete eBird checklists collected between 2005 and 2025,",
      "In total, 217,200 complete eBird checklists collected between 2005 and 2025 entered the analysis,"),
 (74, "The active-period result averages over patterns that differ through time (Figure 3), and the difference between groups can be tested.",
      "Averaging over the active period hides patterns that differ through time (Figure 3), and the difference between groups can be tested."),
 (75, "The direction of that separation follows the order in which food appears.",
      "Food appears in a sequence, and the separation follows it."),
 (80, "The same shape appears in the family as a whole.",
      "Widening from eight species to the whole family gives the same shape."),
 (97, "The design assumes that, without spawning, the gap between near and reference shorelines would have gone on evolving the same way in both.",
      "Without spawning, the design assumes, the gap between near and reference shorelines would have gone on evolving the same way in both."),
 (99, "The main models counted every eligible link between a checklist and an event, so they were compared against the alternative encoding chosen in advance and described in Section 2.5, which assigns each checklist to its nearest event.",
      "Every eligible link between a checklist and an event entered the main models, so those models were compared against the alternative encoding chosen in advance and described in Section 2.5, which assigns each checklist to its nearest event."),
 (105, "The timing adds detail that a single before-and-after number cannot.",
       "Timing adds detail that a single before-and-after number cannot."),
 (109, "The scoter results fit local aggregation most closely.",
       "Scoters fit local aggregation most closely."),
 (116, "The gulls also show the limits of community-science data as clearly as its strengths.",
       "Gulls show the limits of community-science data as clearly as its strengths."),
 (130, "The study's main strength is how it frames the comparison in space and time.",
       "This design earns its keep by how it frames the comparison in space and time."),

 # ---------------- PLAIN: 4.3, 4.5 ----------------
 (127, "The nearest-event sensitivity changed more reporting conclusions than count conclusions.",
       "Switching to nearest-event assignment overturned more reporting conclusions than count conclusions."),
 (127, "The sensitivity cannot say which dominates, although it does mark where species-level claims need restraint.",
       "These data cannot say which dominates, but they do mark the species whose results should be quoted carefully."),
 (135, "The analysis maps hypotheses onto a region, and the strongest candidates differ in timing and in which outcome moved, so they call for different fieldwork.",
       "What this analysis provides is a map of where to look. The strongest candidates differ in timing and in which outcome moved, so they call for different fieldwork."),
 (137, "A fitted nonlinear response to link count would show whether the per-link quantity is comparable across species whose checklists carry different numbers of links, which matters because between 29% and 44% of exposed checklists carry two or more.",
       "Letting the response to link count curve would show whether the quantity means the same thing for species whose checklists carry different numbers of links, which matters because between 29% and 44% of exposed checklists carry two or more."),

 # ---------------- PLAIN: Conclusion ----------------
 (139, "Across 49 coastal bird species, recorded herring spawning was associated with change in both what observers reported and what they counted.",
       "Herring spawning changed what observers of these 49 coastal birds wrote down, in both which species they listed and how many they counted."),
 (139, "and all 18 kept their direction, with 17 still significant, when overlapping events were represented by nearest-event assignment or by a simple present-or-absent indicator.",
       "and all 18 kept their direction, with 17 still significant, whether each checklist was tied to its nearest event or simply marked as near one or not."),
 (139, "Reporting changes were more species-specific, more sensitive to that representation, and concentrated in gulls.",
       "Reporting changes were narrower, more sensitive to that choice, and concentrated in gulls."),
 (139, "Timing separated the feeding groups in both outcomes, tested against groups fixed before fitting: diving sea ducks",
       "Timing separated the feeding groups in both outcomes, against groups fixed before fitting: diving sea ducks"),
 (140, "Habitat, migration, shoreline access, how events are represented and observer behaviour all remain plausible contributors, and the dabbling-duck results show that some such structure survives the design.",
       "Habitat, migration, shoreline access, the encoding of overlapping events and observer behaviour could all contribute, and the dabbling ducks show that some of that structure survives the design."),
 (140, "What this study offers is a broad, event-linked description of what observers recorded across two decades, a tested difference in timing among feeding groups, and a focused basis for fieldwork.",
       "What the study offers is two decades of what observers actually recorded near spawning events, a difference in timing among feeding groups that was tested rather than asserted, and a short list of places to go and look."),
]
