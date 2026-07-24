param(
  [string]$ProjectRoot = (Get-Location).Path
)

$ErrorActionPreference = "Stop"

$outputDir = Join-Path $ProjectRoot "outputs\conventional_exposure_sensitivity_v1"
$summary = Import-Csv -LiteralPath (Join-Path $outputDir "comparison_summary.csv")
$changes = Import-Csv -LiteralPath (Join-Path $outputDir "interpretation_changes.csv")
$enDash = [char]0x2013
$minus = [char]0x2212
$approximately = [char]0x2248
$emDash = [char]0x2014

function Get-OutcomeSummary {
  param([string]$Outcome)
  $row = @($summary | Where-Object { $_.outcome -eq $Outcome })
  if ($row.Count -ne 1) {
    throw "Expected one summary row for $Outcome"
  }
  return $row[0]
}

$reporting = Get-OutcomeSummary "checklist_reporting"
$count = Get-OutcomeSummary "conditional_positive_numeric_count"
$material = @(
  $changes | Where-Object {
    $_.interpretation_changes_materially -eq "TRUE"
  }
)

if ($material.Count -eq 0) {
  $materialAbstract = "No component met the prespecified material-change rule."
  $materialResults = (
    "No component met the prespecified material-change rule of a sign " +
    "reversal with at least one 95% interval excluding zero. BH-threshold " +
    "crossing and same-direction interval nonoverlap were flagged but were " +
    "not treated as material scientific reversals because exposure units " +
    "differ between encodings."
  )
  $materialLimit = (
    "The nearest-event results therefore support the main taxon- and " +
    "response-specific interpretation, but do not remove the observational " +
    "or noncausal limitations."
  )
} else {
  $materialNames = @(
    $material | ForEach-Object {
      $label = if ($_.outcome -eq "checklist_reporting") {
        "checklist reporting"
      } else {
        "conditional positive numeric reported count"
      }
      "$($_.species) ($label)"
    }
  ) -join "; "
  $materialAbstract = (
    "$($material.Count) component(s) met the prespecified material-change " +
    "rule."
  )
  $materialResults = (
    "$($material.Count) component(s) met the prespecified material-change " +
    "rule: $materialNames. BH-threshold crossing alone was not treated as " +
    "a material scientific reversal; same-direction interval nonoverlap was " +
    "also not treated as material because exposure units differ."
  )
  $materialLimit = (
    "The main interpretation therefore requires the species- and " +
    "outcome-specific qualifications reported in the Supplement."
  )
}

$abstract = (
  "Pacific herring (Clupea pallasii) spawning creates a brief coastal " +
  "resource pulse, but spring migration, habitat, access, and observer " +
  "behaviour can produce similar patterns in bird observations. In a " +
  "post-result exploratory refinement of an earlier registered analysis, " +
  "we linked 1,120 Fisheries and Oceans Canada spawning events to 217,200 " +
  "complete eBird checklists from the Strait of Georgia, British Columbia " +
  "(2005${enDash}2025). Checklists <5 km from recorded events were compared " +
  "with contemporaneous checklists linked to events 5${enDash}20 km away. " +
  "Separate mixed " +
  "models described checklist reporting and conditional positive numeric " +
  "reported counts. Primary predictors counted concurrent checklist-to-event " +
  "links. The A14 contrast directly compared days 0${enDash}14 with days " +
  "${minus}14 to ${minus}1 " +
  "after adjusting both periods for the near/reference difference during " +
  "days ${minus}28 to ${minus}15. Among 49 support-qualified species, 13 of " +
  "48 estimable " +
  "reporting contrasts and 18 of 46 count contrasts were BH-significant; all " +
  "were positive. A deterministic nearest-event sensitivity produced " +
  "$($reporting.sensitivity_estimable) reporting and " +
  "$($count.sensitivity_estimable) count estimates; signs agreed with the " +
  "primary analysis for $($reporting.sign_concordant) of " +
  "$($reporting.paired_estimable) and $($count.sign_concordant) of " +
  "$($count.paired_estimable) paired estimates, respectively. " +
  "$materialAbstract These event-linked associations are compatible with " +
  "local aggregation but do not establish herring consumption, " +
  "herring-induced movement, or regional abundance change."
)

$methodSensitivity = (
  "Observed reporting proportions, finite positive-count medians and " +
  "interquartile ranges, and proportions recorded as X were summarised " +
  "without adjustment. Fixed-effect predictions were standardised over the " +
  "observed checklist covariate distribution with all random intercepts and " +
  "nonselected event-link predictors set to zero. Previously completed " +
  "sensitivities evaluated binary any-link exposure and link-count linearity. " +
  "For the present revision, a single conventional exposure sensitivity was " +
  "chosen before fitting from support and geometry alone: complete " +
  "single-event restriction retained 72,443 checklists and supported count " +
  "models for 19 of 49 species, whereas deterministic nearest-event " +
  "assignment retained all 217,200 checklists, full fixed-effect rank, and " +
  "count-model support for 41 species. The nearest-event encoding retained " +
  "one minimum-distance modeled-window event per checklist with a " +
  "deterministic tie break. No response estimate or fitted result informed " +
  "this choice, and no other new sensitivity was fitted."
)

$completion = (
  "Checklist reporting was estimable for 48 core species and conditional " +
  "positive numeric reported count for 46 in the primary analysis. Four " +
  "primary components were non-estimable; one completed count fit was " +
  "singular and one retained a convergence warning. The nearest-event " +
  "sensitivity was estimable for $($reporting.sensitivity_estimable) " +
  "reporting and $($count.sensitivity_estimable) count components. Figures " +
  "and effect tables show only estimable fits; the synchronized Supplement " +
  "retains every primary, finite-number-versus-X, and sensitivity component " +
  "as an explicit status, so a failed component is not represented as a " +
  "biological null result. BH adjustment retained the declared 49-species " +
  "families."
)

$finiteX = (
  "Among reports with either a finite number or X, the finite-number-versus-X " +
  "model was estimable for 41 species. Eighteen A14 point estimates were " +
  "positive and 23 negative, but none survived BH adjustment (minimum q " +
  "$approximately " +
  "0.545). Thirty fits were singular. Failed components remain explicit in " +
  "the Supplement's component-status table rather than being displayed as " +
  "estimates. The analysis therefore found no multiplicity-adjusted timing " +
  "signal in numeric-versus-X assignment, but it does not establish that " +
  "selection into the numeric-count model is ignorable or has a known " +
  "direction of bias."
)

$sensitivityResults = (
  "Replacing additive event-link counts with binary any-link indicators " +
  "preserved the primary A14 sign for 35 of 48 reporting estimates and 40 of " +
  "46 count estimates. Under deterministic nearest-event assignment, signs " +
  "agreed for $($reporting.sign_concordant) of " +
  "$($reporting.paired_estimable) paired reporting estimates and " +
  "$($count.sign_concordant) of $($count.paired_estimable) paired count " +
  "estimates. Signs of primary BH-significant results were preserved for " +
  "$($reporting.primary_bh_sign_preserved) of " +
  "$($reporting.primary_bh_paired) paired reporting and " +
  "$($count.primary_bh_sign_preserved) of " +
  "$($count.primary_bh_paired) paired count components; " +
  "$($reporting.primary_bh_remains_bh_significant) and " +
  "$($count.primary_bh_remains_bh_significant), respectively, remained " +
  "BH-significant. The nearest-event analysis produced " +
  "$($reporting.sensitivity_bh_significant) BH-significant reporting and " +
  "$($count.sensitivity_bh_significant) BH-significant count contrasts " +
  "($($reporting.sensitivity_bh_positive) positive and " +
  "$($reporting.sensitivity_bh_negative) negative for reporting; " +
  "$($count.sensitivity_bh_positive) positive and " +
  "$($count.sensitivity_bh_negative) negative for reported count). " +
  "$materialResults Alternative-engine checks remained limited to the two " +
  "previously completed representatives; no new engine or model family was " +
  "run."
)

$spatialLimit = (
  "Spatial exposure remains approximate. Distances run from a checklist " +
  "point to a recorded source point, not from the complete travelled route " +
  "to the realized prey footprint. Additive event-link counts measure " +
  "recorded linkage, not prey quantity. Binary-any-link and deterministic " +
  "nearest-event results were directionally concordant for many, but not " +
  "all, estimable components. This shows that exposure encoding is a " +
  "substantive assumption. $materialLimit"
)

$incomplete = (
  "The reporting models used nAGQ = 0, and the higher-accuracy nAGQ = 1 probe " +
  "was computationally infeasible. One glmmTMB reporting refit and one mixed " +
  "zero-truncated count refit were directionally concordant with their " +
  "primary models, but four other frozen representative checks were not " +
  "completed. Event-block resampling, leave-one-block-out influence analysis, " +
  "alternative radii, stationary or travel restrictions, observer " +
  "restrictions, placebo analyses, and hierarchical models were not run in " +
  "this revision. Complete single-event restriction was not fitted because " +
  "the prefit support comparison left only 19 of 49 count species supported."
)

$future = (
  "The remaining statistical work named in earlier versions${emDash}including " +
  "representative alternative-engine checks, event-block uncertainty, " +
  "stationary or short-travel restrictions, alternative radii, observer " +
  "overlap, and placebo analyses${emDash}was not part of this " +
  "single-sensitivity " +
  "revision. These analyses must not be implied to have been completed. Any " +
  "future addition requires separate authorization and versioned reporting."
)

$conclusion = (
  "After accounting for seasonal changes shared by near and reference areas " +
  "and for the spatial difference present during baseline, 13 species showed " +
  "a positive active-minus-pre change in checklist reporting and 18 showed a " +
  "positive change in conditional positive numeric reported count after BH " +
  "adjustment. The deterministic nearest-event sensitivity retained all " +
  "checklists and showed sign agreement for $($reporting.sign_concordant) of " +
  "$($reporting.paired_estimable) paired reporting and " +
  "$($count.sign_concordant) of $($count.paired_estimable) paired count " +
  "estimates. $materialLimit These are species-level event-linked contrasts; " +
  "shared checklists and clusters prevented a dependence-aware test of one " +
  "family-wide mean shift. Habitat, migration, access, event classification, " +
  "exposure encoding, and observer behaviour prevent attribution specifically " +
  "to herring consumption or herring-induced movement. The results identify " +
  "taxon- and response-specific patterns for prospective confirmation and " +
  "structured field study."
)

$sourceDoc = Join-Path $ProjectRoot (
  "manuscript\journal_submission\marine_environmental_research\" +
  "rendered_v9\mer_manuscript_unblinded_v9_revised_clean.docx"
)
$qaDir = Join-Path $ProjectRoot (
  "manuscript\journal_submission\marine_environmental_research\" +
  "rendered_v9_qa"
)
$pdfPath = Join-Path $qaDir "mer_manuscript_unblinded_v9_revised_clean.pdf"
New-Item -ItemType Directory -Path $qaDir -Force | Out-Null

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0

function Set-ParagraphByNeedle {
  param(
    [object]$Document,
    [string]$Needle,
    [string]$Replacement
  )
  $matches = New-Object System.Collections.Generic.List[object]
  foreach ($paragraph in $Document.Paragraphs) {
    $text = $paragraph.Range.Text.Trim([char]13, [char]7)
    if ($text.Contains($Needle)) {
      $matches.Add($paragraph.Range.Duplicate)
    }
  }
  if ($matches.Count -ne 1) {
    throw "Expected one paragraph containing '$Needle'; found $($matches.Count)"
  }
  $target = $matches[0]
  if ($target.Characters.Count -gt 0) {
    $target.MoveEnd(1, -1) | Out-Null
  }
  $target.Text = $Replacement
}

try {
  $document = $word.Documents.Open($sourceDoc, $false, $false)

  Set-ParagraphByNeedle $document "Pacific herring (Clupea pallasii) spawning creates" $abstract
  Set-ParagraphByNeedle $document "Observed reporting proportions, finite positive-count medians" $methodSensitivity
  Set-ParagraphByNeedle $document "Checklist reporting was estimable for 48 core species" $completion
  Set-ParagraphByNeedle $document "Among reports with either a finite number or X" $finiteX
  Set-ParagraphByNeedle $document "Replacing additive event-link counts with binary any-link indicators" $sensitivityResults
  Set-ParagraphByNeedle $document "Spatial exposure remains approximate" $spatialLimit
  Set-ParagraphByNeedle $document "The reporting models used nAGQ = 0" $incomplete
  Set-ParagraphByNeedle $document "The most useful remaining statistical work" $future
  Set-ParagraphByNeedle $document "After accounting for seasonal changes shared by near and reference areas" $conclusion

  foreach ($section in $document.Sections) {
    $lineNumbers = $section.PageSetup.LineNumbering
    $lineNumbers.Active = $true
    $lineNumbers.CountBy = 1
    $lineNumbers.StartingNumber = 1
    $lineNumbers.RestartMode = 0
    $lineNumbers.DistanceFromText = 12

    $section.PageSetup.DifferentFirstPageHeaderFooter = $false
    $footer = $section.Footers.Item(1)
    $footer.Range.Text = ""
    $footer.Range.ParagraphFormat.Alignment = 1
    $footer.Range.Fields.Add($footer.Range, 33) | Out-Null
  }

  $abstractParagraph = @(
    $document.Paragraphs | Where-Object {
      $_.Range.Text.Contains(
        "Pacific herring (Clupea pallasii) spawning creates"
      )
    }
  )
  $abstractWords = $abstractParagraph[0].Range.ComputeStatistics(0)
  if ($abstractWords -gt 250) {
    throw "Abstract exceeds 250 words: $abstractWords"
  }

  $document.Save()
  $document.ExportAsFixedFormat($pdfPath, 17)
  Write-Output "MANUSCRIPT_UPDATE=PASS"
  Write-Output "ABSTRACT_WORDS=$abstractWords"
  Write-Output ("PAGES=" + $document.ComputeStatistics(2))
  Write-Output "PDF=$pdfPath"
  $document.Close(0)
} finally {
  $word.Quit()
  [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
}
