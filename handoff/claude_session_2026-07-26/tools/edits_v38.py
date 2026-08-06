# -*- coding: utf-8 -*-
"""v38: remove gnomic framing sentences.

The pattern, named by the author on the sentence "Food appears in a sequence,
and the separation follows it": the subject is an abstraction, the predicate is
a claim about the argument rather than about the world, and a pronoun points at
something the reader cannot see. It reads as a pronouncement.

Three of these were introduced by the v36 opener pass, which traded one tell for
another. The rest predate it.

The fix in every case is to make the subject a bird, a fish, an observer, a
number or a date.
"""

EDITS = [
 # introduced in v36 while breaking the "The" monotony
 (75, "Food appears in a sequence, and the separation follows it.",
      "Adult fish and spent carcasses come first, attached eggs later, and the "
      "groups separate in that order."),
 (130, "This design earns its keep by how it frames the comparison in space and time.",
       "Framing the comparison in both space and time is what keeps two "
       "confounds out of it."),
 (135, "What this analysis provides is a map of where to look. The strongest "
       "candidates differ in timing and in which outcome moved, so they call "
       "for different fieldwork.",
       "Each of the strongest candidates differs in timing and in which outcome "
       "moved, so each calls for different fieldwork."),

 # pre-existing
 (14, " That matters beyond the birds themselves. Herring on this coast are managed",
      " Herring on this coast are managed"),
 (39, "The logic is easiest to see in terms of event links. For checklist (i), the model for each species was",
      "For checklist (i), the model for each species was"),
 (91, "Standardized predictions put several of these ratios on a scale a reader can picture.",
      "Standardized predictions convert several of these ratios into birds on a "
      "checklist and percentage points."),
 (95, "These results are harder to read than they first appear. Mallard, American Wigeon and Northern Pintail were assigned",
      "Mallard, American Wigeon and Northern Pintail were assigned"),
 (116, "The internal structure of these results fits that concern. Bonaparte's Gull,",
       "Bonaparte's Gull,"),
]
