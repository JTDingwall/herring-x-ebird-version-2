# Metadata audit before Version 2 analysis

Source repository audited: `JTDingwall/ebird_herring_analysis`  
Pinned source commit: `f3387d58f6d55a070b86f41ef41e11512dcf7688`

This audit was completed before creating the Version 2 model registry. It uses only
repository metadata, aggregate QA, source dictionaries, and approved results. It does not
copy restricted eBird rows.

## 1. Source inventory

| Source | Version | Size | Key implication |
|---|---:|---:|---|
| eBird EBD | May 2026 | 14.59 GB | Must be streamed/partitioned; raw observations include counts and taxon concepts. |
| eBird SED | matching May 2026 | 757.6 MB | Supplies checklist effort, observer, location, completeness, and protocol. |
| DFO spawn CSV | 2025 | 3.55 MB | 31,167 source rows from 1951–2025; 13,332 rows from 1988–2025. |
| BC coastline | supplied bundle | 20.55 MB | Metric shoreline linkage in EPSG:3005. |
| DFO sections | supplied bundle | 0.32 MB | Spatial hierarchy and region/section fallback. |

Expected checksums and licences are in `metadata/source_inventory.csv`.

### eBird source profile already established

The Version 1 SED profile found:

- 2,961,400 checklist rows;
- 2,733,598 rows in 1988–2025;
- 2,288,405 complete checklists and 672,995 incomplete checklists;
- 609,875 checklists carrying a shared `GROUP IDENTIFIER`;
- 11 protocol labels and 29 county labels.

After the Version 1 Strait of Georgia filters and shared-checklist resolution, 412,775
eligible complete checklists were zero-filled for 45 approved taxa, producing 18,574,875
checklist-species rows. These counts demonstrate that the dataset can support substantially
more than five focal species, although support must still be evaluated by event, phase,
distance, region, and outcome.

### Relevant eBird metadata

The raw EBD provides `TAXON CONCEPT ID`, taxonomic category, names, observation count,
date, checklist key, review fields, behavior fields, and species comments. The SED provides
coordinates, date and start time, observer ID, checklist key, protocol, duration, distance,
area, number of observers, completeness, group ID, locality metadata, and checklist
comments.

Version 2 implications:

1. keep `TAXON CONCEPT ID` as the raw taxonomic key;
2. resolve shared checklists before any response table is constructed;
3. preserve numeric, `X`, lower-bound, ambiguous, and zero-filled count states;
4. use complete checklists for encounter/non-detection inference;
5. model effort, observer, location, calendar, and protocol rather than treating raw counts
   as standardized surveys;
6. model checklist/observer allocation separately because spawn can attract birders.

## 2. Herring source metadata

The post-1988 source table contains 13,332 records and the following 17 authoritative
fields:

`Region`, `Year`, `StatisticalArea`, `Section`, `LocationCode`, `LocationName`,
`SpawnNumber`, `StartDate`, `EndDate`, `Longitude`, `Latitude`, `Length`, `Width`,
`Method`, `Surface`, `Macrocystis`, and `Understory`.

### Missingness and range findings

| Field | Missing | Nonmissing | V2 implication |
|---|---:|---:|---|
| Region | 3,212 | 10,120 | Region can often be derived from section/geometry; missing Region alone should not exclude an event. |
| StartDate | 425 | 12,907 | Use interval-aware and uncertainty-aware timing. |
| EndDate | 602 | 12,730 | Same; do not reduce every event to one start date. |
| Longitude/Latitude | 124 each | 13,208 | Point analyses can use nearly all rows; same-location recovery can be a labelled sensitivity. |
| Length | 306 | 13,026 | A highly complete event-extent covariate that Version 1 did not use analytically. |
| Width | 576 | 12,756 | Another useful footprint/extent variable. |
| Method | 25 | 13,307 | Missing Method should be an uncertainty category, not automatic exclusion. |
| Surface | 7,192 | 6,140 | Component-specific modeling only; missing is not zero. |
| Macrocystis | 11,851 | 1,481 | Very sparse and method-dependent. |
| Understory | 7,183 | 6,149 | Component-specific modeling only. |

Observed event extent is large: `Length` ranges from 1 m to 24.24 km and `Width` from
1 m to about 2.29 km. A checklist can therefore be ecologically close to a long spawn but
more than 5 km from the single source point. Point-to-point distance is an exposure proxy,
not exact distance to eggs.

### Version 1 event exclusions were consequential

Version 1 retained 9,373 of 13,332 post-1988 records after excluding 3,959 records if any
of seven flags was present: both dates missing, reversed interval, year/date discordance,
missing coordinates, missing Region, missing Method, or `Method = Incomplete`.

That rule is reproducible but too blunt for the broader Version 2 questions:

- missing Region is often recoverable from Section or spatial overlay;
- missing or incomplete Method affects measurement quality, not necessarily event existence;
- a record with one valid date is temporally informative;
- records with missing point coordinates may still support section/location analyses;
- 11 reversed intervals and 12 year-discordant records are small enough for explicit
  review or uncertainty treatment rather than automatic global deletion.

Version 2 replaces the binary exclusion with quality tiers. Core point-level models use
high-quality rows; section-level, uncertainty-aware, and sensitivity models can retain
additional records without pretending they are equally precise.

### Source rows are not necessarily biological events

Version 1 defined one event per `(Year, LocationCode, Section, SpawnNumber)` and did not
merge records. Yet its QA found 14,550 same-location temporal-overlap pairs and 16,284
adjacency flags under the registered distance/time rules. This is evidence that source
records can represent parts of a larger spawning complex.

Version 2 will retain both layers:

1. the immutable source-record layer;
2. derived event complexes under 1 km/3 days, 2 km/7 days, and 5 km/14 days.

Results must be compared across these definitions.

### Herring intensity is not one clean variable

The old `total_biomass_tonnes` field sums whichever Surface, Macrocystis, and Understory
components are observed. It is a relative spawn index, not absolute biomass. Because
component completeness differs sharply, two equal sums can have different measurement
bases.

Version 2 uses several dose variables rather than one assumed truth:

- component-specific indices when observed;
- component count and survey Method;
- standardized within-method/component-pattern index;
- Length and Width;
- an extent proxy such as `Length × Width`;
- a latent or measurement-error intensity model as an advanced sensitivity.

## 3. The strongest lesson from Version 1 outcomes

The primary encounter models did not show the expected broad positive pattern. That does
not imply that bird numbers did not increase. The primary outcome was the probability that
a species appeared at all on a checklist.

In the registered positive-count sensitivity, the active-phase coefficient was positive
for all five focal species:

| Species | Positive-count coefficient | Top-1%-excluded coefficient |
|---|---:|---:|
| Surf Scoter | 0.706 | 0.690 |
| White-winged Scoter | 0.430 | 0.434 |
| Harlequin Duck | 0.317 | 0.297 |
| Glaucous-winged Gull | 0.719 | 0.663 |
| Short-billed Gull | 1.174 | 1.160 |

These were conditional positive reported-count models, not abundance models and not a new
confirmatory result. They nevertheless show that the previous analysis placed the most
biologically responsive quantity—flock size—behind a secondary gate. Version 2 makes
positive reported count and marginal total count co-primary.

The count metadata also support this decision. Numeric counts were available for about
94.9%–98.9% of focal detections. Positive medians ranged from 5 to 10 birds, but p99 values
ranged from 60 to 2,000 and maxima from 493 to 45,000. Hurdle, Tweedie, negative-binomial,
ordinal, robust, and interval-bound analyses are therefore all registered.

## 4. Evidence relevant to redistribution

The Version 1 regional diagnostic estimated declines at simultaneous comparison areas for
Surf Scoter, Harlequin Duck, Glaucous-winged Gull, and Short-billed Gull. Difference-in-
changes estimates were positive for four of five species and clearly positive for the two
gull species, but observer turnover and calendar seasonality were unresolved.

This is not a reason to abandon redistribution. It is a reason to use better estimands:

- condition on regional bird totals and model allocation among distance zones;
- compare near, far, and total trajectories simultaneously;
- use repeated-location and same-observer contrasts;
- keep checklist/observer visitation as a separate response;
- use event-cluster uncertainty and explicit multi-event dependence.

## 5. Main Version 2 redesign decisions

1. **Geography:** all BC herring sections with outcome-blind support; Strait of Georgia is
   a high-support subset.
2. **Time:** event-relative windows drawn from the full-year raw source, not a fixed
   January–June subset.
3. **Taxa:** all 45 curated legacy taxa plus new candidates and mechanistic ambiguous
   guild taxa.
4. **Outcomes:** reported count, encounter, total guild count, richness, composition, and
   allocation.
5. **Distance:** 1-km rings through 5 km, then 5–10 and 10–20 km, plus continuous kernels.
6. **Timing:** early pre, pre, immediate pre, active interval, early egg, late egg/post,
   and a restricted continuous trajectory.
7. **Events:** source-record and event-complex definitions.
8. **Geometry:** source point, shoreline anchor, and length/width footprint sensitivities.
9. **Intensity:** component-aware and extent-aware dose models.
10. **Observation process:** separate checklist and unique-observer visitation models.
11. **Synthesis:** species-specific first-stage models plus guild/trait synthesis; no
    rank-one shared contextual structure.
12. **Inference:** cross-model triangulation, hierarchical shrinkage, effect sizes, and
    placebos—not selecting whichever model produces a favorable p-value.

## 6. Hard interpretation limits

- Reported eBird count is not absolute abundance.
- A non-spawn comparison means no recorded active spawn under the available data.
- Event date and geometry are measured with error.
- Herring index components are incompletely observed and method-dependent.
- eBird visitation is preferential and spatially concentrated.
- Version 2 is post-result exploratory. Prospective confirmation remains necessary.
