# -*- coding: utf-8 -*-
"""v32 edits, expressed as substring replacements on the v31 text.

Substring replacement rather than retyping whole paragraphs, so that no
reported figure, interval or species name can be altered by a typo.

Two classes of change:
  FIX  - repairs a v31 build error, including the author's own tracked
         insertions that landed at the end of the wrong paragraph.
  HEDGE- removes a pre-emptive denial whose point already has a home in
         Section 4.4, Section 4.3 or Section 3.5. Comment 26.
"""

EDITS = [
 # ---- FIX: author insertions stranded at paragraph end by the v31 build ----
 (36, "and although an omission is informative it does not prove that the species was absent.",
      "and although an omission is informative about reporting it does not prove that the species was absent."),
 (36, "cannot or will not count it, most often when the flock is large.reporting but",
      "cannot or do not want to count it, most often when the number of individuals is large."),
 (37, "which is a selection problem and not only a difference of question.the number of individuals is",
      "which is a selection problem and not only a difference of question."),

 # ---- HEDGE: Methods ----
 (24, ", and the index value itself was not used as a measure of how much spawn was deposited.",
      "."),
 (37, " Exponentiated estimates therefore compare geometric mean counts among those records, and they do not measure abundance across all checklists, since a total from a travelling checklist need not represent a single flock.",
      " Exponentiated estimates therefore compare geometric mean counts among those records."),
 (45, " What the design cannot remove, however, is a change that differs between zones and happens to coincide with spawning.",
      ""),

 # ---- HEDGE: Results ----
 (66, " Ratios refer to one additional recorded spawning event nearby and are not changes in occupancy or in regional abundance.",
      " Ratios refer to one additional recorded spawning event nearby."),
 (81, " In both ordinations the pre-assigned feeding groups overlap substantially. The group differences reported above are differences in average timing, not a partition of the family, which is what the large unexplained residual heterogeneity already indicated.",
      " In both ordinations the pre-assigned feeding groups overlap substantially, and the large unexplained residual heterogeneity says the same thing: the group differences reported above are differences in average timing."),
 (89, " Whether these birds are responding to herring or to something that puts them on the same beaches in the same weeks cannot be determined here.",
      ""),
 (91, " That check does not extend to the two comparators, which form a separate set; Section 4.2 explains why one of them is harder to reconcile with a clean pre-onset record.",
      " The two comparators form a separate set, and Section 4.2 takes them up."),
 (92, ", though with that many singular fits the check has little power, and it does not show that the counted subset is unbiased.",
      ", though with that many singular fits the check has little power."),

 # ---- HEDGE: Discussion, outside 4.4 ----
 (122, " That is enough to say the pair does not establish specificity, and enough to show that a directional seasonal difference between near and far shorelines can arise in a bird with no herring link. It is not enough to say how common such structure is, because it rests on one species.",
       " The pair therefore does not establish specificity, and it shows that a directional seasonal difference between near and far shorelines can arise in a bird with no herring link, though one species cannot say how common such structure is."),
# ---- HEDGE: Methods, second pass ----
 (26, " Blocks are a statistical grouping and carry no claim about the biology, since two events in the same block need not belong to one spawning population.",
      " Two events in the same block need not belong to one spawning population."),
 (26, "carried the random effect for its block..",
      "carried the random effect for its block."),
 (29, " The reference zone is not assumed to be spawn-free, and Section 4.4 describes what the comparison can support.",
      " The reference zone is not assumed to be spawn-free."),
 (31, "Event blocks were not matched treatment and control strata, and the models did not require every event or block to contain checklists in both zones.",
      "The models did not require every event or block to contain checklists in both zones."),
 (44, " It is not the raw difference between near and reference checklists, and it is not a percentage change in the number of birds present.",
      " It is not a percentage change in the number of birds present."),
 (74, "The active-period result does not describe one common pattern through time (Figure 3), and the difference between groups can be tested.",
      "The active-period result averages over patterns that differ through time (Figure 3), and the difference between groups can be tested."),

 # ---- HEDGE: second pass, remaining pre-emptive denials outside 4.3 / 4.4 ----
 (34, " The result is an event-linked association, not a measure of consumption, movement or abundance.",
      ""),
 (32, ", although its direction is not guaranteed",
      ""),
 (47, "Day of year and time of day were not available in the linked dataset, so seasonal balance between the zones could not be demonstrated and time of day could not be adjusted for; the absence of a diel term is a real gap rather than a considered omission.",
      "Day of year and time of day were not available in the linked dataset, so neither could be adjusted for."),
 (64, "The tightest estimates are not the largest ones, because Bald Eagle shows a count increase of 1.063 (1.045\u20131.080) that is modest in size and among the most precise in the family, resting on 83,359 counted records, whereas Bonaparte's Gull's count increase of 1.16 spans 0.87 to 1.56 on 4,025.",
      "Precision tracks how often a species is counted rather than how large its estimate is. Bald Eagle's count increase of 1.063 (1.045\u20131.080) is modest in size and among the most precise in the family, resting on 83,359 counted records, whereas Bonaparte's Gull's count increase of 1.16 spans 0.87 to 1.56 on 4,025."),
 (89, " What can be said is that the group responded through reporting and not counts, the opposite of the sea ducks, and that its timing was flat, so it does not share the late peak the divers show.",
      " The group responded through reporting and not counts, the opposite of the sea ducks, and its timing was flat, without the late peak the divers show."),
 (104, " It accounts for seasonal change shared by near and far shorelines and for their average difference before the event date, but it cannot remove a change that differs between zones and happens to coincide with spawning, and it never observes a bird eating herring, moving toward a spawn, or being present at all.",
       " It accounts for seasonal change shared by near and far shorelines and for their average difference before the event date, and it never observes a bird eating herring or moving toward a spawn."),
]
