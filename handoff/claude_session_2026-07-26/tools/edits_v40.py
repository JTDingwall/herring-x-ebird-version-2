# -*- coding: utf-8 -*-
"""v40: break the clause chains.

The v31 pass added connectives to fix the author's "clippy and fragmented"
complaint and overshot. 46 of 374 sentences ended up carrying two or more
comma-joined subordinate clauses, and 44 of 91 paragraphs ended on one. The
result is a uniform long-compound rhythm, which reads as generated for the same
reason uniform short sentences did.

Every number, name, citation and claim is unchanged. Only the joins move.

One edit is not a style change and is marked FACT: v30 said day of year and time
of day "were not carried into the frozen analysis frame", which is accurate. My
v31 rewrite changed it to "were not available in the linked dataset", which is
not: both fields exist in the source and in the project's own model helper.
"""

EDITS = [
 # ---------------- Introduction ----------------
 (8, "Although the same general regions are used again from year to year, the exact shoreline, extent and date shift among years",
     "The same general regions are used again from year to year, but the exact shoreline, extent and date shift among years"),
 (8, "2024), so the pulse is predictable at the scale of a coastal region but much less so at any particular beach. What is available also changes as an event proceeds, because adult fish create a short feeding opportunity when they enter the shallows, whereas attached eggs persist after the adults have left, and eggs on floating vegetation or exposed by a falling tide remain reachable by other routes.",
     "2024). The pulse is therefore predictable at the scale of a coastal region and much less so at any particular beach. What is available also changes as an event proceeds. Adult fish create a short feeding opportunity when they enter the shallows. Attached eggs persist after the adults have left, and eggs on floating vegetation or exposed by a falling tide remain reachable by other routes."),
 (10, "2018), and many other vertebrates use the same pulse (Willson and Womble 2006).",
      "2018). Many other vertebrates use the same pulse (Willson and Womble 2006)."),
 (14, "Gulls and shoreline scavengers should respond near the event date, whereas diving ducks that feed on attached roe should respond once eggs are available, and alcids that feed away from the shoreline deposit were expected to show little response at all.",
      "Gulls and shoreline scavengers should respond near the event date. Diving ducks that feed on attached roe should respond once eggs are available. Alcids feed away from the shoreline deposit and were expected to show little response at all."),
 (14, "supports, so a regional account of which species track spawning, and when, would give",
      "supports. A regional account of which species track spawning, and when, would give"),

 # ---------------- Methods ----------------
 # FACT: restores the accurate wording from v30.
 (47, "Day of year and time of day were not available in the linked dataset, so neither could be adjusted for.",
      "Day of year and time of day were not included in these models, so seasonal balance between the zones could not be demonstrated and time of day could not be adjusted for."),
 (47, "The three effort terms carry their own caution, because duration, distance and observer count are measured on the same checklist as the outcome, and a conspicuous flock may itself lengthen a visit,",
      "The three effort terms carry their own caution. Duration, distance and observer count are measured on the same checklist as the outcome. A conspicuous flock may itself lengthen a visit,"),

 # ---------------- 3.2 ----------------
 (62, "Reporting rose for 28 of 48 species and fell for 20, of which 13 increases survived correction for multiple testing, whereas counts rose for 42 of 46 species and fell for four, with 18 increases surviving, and no decrease survived in either outcome.",
      "Reporting rose for 28 of 48 species and fell for 20, with 13 of those increases surviving correction for multiple testing. Counts rose for 42 of 46 and fell for four, with 18 increases surviving. No decrease survived in either outcome."),
 (62, "The gap between the two outcomes is wider than those tallies suggest, because among the 46 species with both models 27 rose in both, 15 rose only in counts, four rose in neither, and none rose only in reporting, so every species that disagreed with itself disagreed in the same direction.",
      "The gap between the two outcomes is wider than those tallies suggest. Among the 46 species with both models, 27 rose in both and 15 rose only in counts. Four rose in neither. None rose only in reporting, so every species that disagreed with itself disagreed in the same direction."),

 # ---------------- 3.3 ----------------
 (71, "No alcid cleared correction in either outcome, since Pigeon Guillemot",
      "No alcid cleared correction in either outcome. Pigeon Guillemot"),
 (71, "Shorebirds are the harder case, because they are documented consumers of herring eggs on exposed substrate (Bishop and Green 2001), yet Black Oystercatcher",
      "Shorebirds are the harder case. They are documented consumers of herring eggs on exposed substrate (Bishop and Green 2001), yet Black Oystercatcher"),
 (71, "between 0.94 and 0.96, none significantly, and none was counted in larger numbers either.",
      "between 0.94 and 0.96 and none significantly. None was counted in larger numbers either."),
 (71, "Egg availability to a wader depends on the tide, and these models carry no tidal or diel term, so a response confined to the hours around low water would wash out across every other checklist, while shorebird use of spawn here may also be too local to register across a whole strait.",
      "Egg availability to a wader depends on the tide, and these models carry no tidal or diel term. A response confined to the hours around low water would wash out across every other checklist. Shorebird use of spawn here may also be too local to register across a whole strait."),

 # ---------------- 3.4 ----------------
 (74, "For each species, the estimate at the event date minus the estimate during early egg gives a timing score, whose variance comes from the fitted covariance matrix, and regressing that score on the feeding groups fixed before any model was run, weighted by precision, tests whether the groups differ.",
      "For each species, the estimate at the event date minus the estimate during early egg gives a timing score, with its variance taken from the fitted covariance matrix. Regressing that score on the feeding groups, weighted by precision, tests whether the groups differ. Those groups were fixed before any model was run."),
 (74, "For counts the result comes from roe-feeding divers, which peak once eggs are available, and from shoreline scavengers, which peak at the event date, whereas for reporting the two groups whose intervals exclude zero are gulls and shoreline scavengers, both peaking early, while the divers that dominate the count result are flat.",
      "The two outcomes separate different groups. In counts the result comes from roe-feeding divers, which peak once eggs are available, and from shoreline scavengers, which peak at the event date. In reporting the two groups whose intervals exclude zero are gulls and shoreline scavengers, both peaking early. The divers that dominate the count result are flat."),
 (74, "Both outcomes say they do, counts far more decisively than reporting (Q = 117.3 and Q = 15.0, each on 6 degrees of freedom, p < 0.001 and p = 0.02), although the two outcomes separate different groups.",
      "Both outcomes say they do, counts far more decisively than reporting (Q = 117.3 and Q = 15.0, each on 6 degrees of freedom, p < 0.001 and p = 0.02)."),

 # ---------------- 4.1 ----------------
 (104, "That distinction is the main result, and it holds up in three ways: it survived every change in how overlapping events were represented, it is the outcome for which the timing test is most decisive, and it is the harder of the two to produce through observer behaviour alone, because writing a larger number means seeing more birds in a way that writing a species name does not.",
       "That distinction is the main result. It survived every change in how overlapping events were represented, and it is the outcome for which the timing test is most decisive. It is also the harder of the two to produce through observer behaviour alone, since writing a larger number means seeing more birds. Writing a species name does not."),

 # ---------------- 4.3 ----------------
 (126, "Reporting and counting sit at different stages of the same process, since reporting needs a bird to be present, available, detected, identified and written down, whereas the count model starts after all of that and only when the observer supplied a number.",
       "Reporting and counting sit at different stages of the same process. Reporting needs a bird to be present, available, detected, identified and written down. The count model starts after all of that, and only when the observer supplied a number."),
 (126, "That ordering matters for the outcome carrying the main conclusion, because counts are measured among records that were made and quantified, and reporting itself rose for 13 species, so for those species the checklists contributing counts after the event date are not the set that would have contributed before.",
       "That ordering matters for the outcome carrying the main conclusion. Counts are measured among records that were made and quantified, and reporting itself rose for 13 species. For those species the checklists contributing counts after the event date are not the set that would have contributed before."),
 (126, "The concern is weakest where reporting did not move, and Surf Scoter, flat in reporting and up 1.30 in counts, is the clearest such case, while for species in which both outcomes moved the direction of the bias is unknown.",
       "The concern is weakest where reporting did not move. Surf Scoter, flat in reporting and up 1.30 in counts, is the clearest such case. Where both outcomes moved, the direction of the bias is unknown."),
 (128, "It would be wrong to conclude that excluding X records makes the count estimates conservative, since if observers write X more often when a flock is large then the counted subset systematically misses the biggest groups, and misses them most often when the birds are most concentrated, which would pull the count estimates down.",
       "Excluding X records does not make the count estimates conservative. If observers write X more often when a flock is large, the counted subset systematically misses the biggest groups, and misses them most often when the birds are most concentrated. That would pull the count estimates down."),
]
