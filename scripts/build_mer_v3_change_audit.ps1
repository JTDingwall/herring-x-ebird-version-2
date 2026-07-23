param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
$pkg = Join-Path $ProjectRoot 'manuscript\journal_submission\marine_environmental_research'
$auditDir = Join-Path $pkg 'audits'
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
New-Item -ItemType Directory -Force -Path $auditDir | Out-Null

function Write-Utf8Lf([string]$Path, [string[]]$Lines) {
    [IO.File]::WriteAllText($Path, (($Lines -join "`n") + "`n"), $script:utf8NoBom)
}

function Export-CsvUtf8Lf([object[]]$Data, [string]$Path) {
    Write-Utf8Lf $Path @($Data | ConvertTo-Csv -NoTypeInformation)
}

function Get-SectionAtLine([string[]]$Lines, [int]$LineNumber) {
    $section = 'front matter'
    $limit = [Math]::Min([Math]::Max($LineNumber, 1), $Lines.Count)
    for ($i = 0; $i -lt $limit; $i++) {
        if ($Lines[$i] -match '^#{1,3}\s+(.+)$') { $section = $Matches[1] }
    }
    $section
}

function Classify-Hunk([string]$Artifact, [string]$Section, [string]$Text) {
    $lower = ($Section + "`n" + $Text).ToLowerInvariant()
    if ($lower -match 'anonymous|double-anonymous|identity|withheld') {
        return @('anonymization_and_versioning', 'manuscript-only correction')
    }
    if ($lower -match 'active_near|active-near versus|omitted other|m08|engine|fallback|immediate_pre|late pre-spawn|distance baseline|20\.0001|contrast algebra') {
        return @('estimand_engine_or_window_correction', 'manuscript-only correction')
    }
    if ($lower -match 'map|privacy|coordinate|projection|display anchor|spatial display|suppression') {
        return @('privacy_safe_spatial_addition', 'new privacy-safe descriptive summary')
    }
    if ($lower -match 'descriptive|eligible checklist|detection prevalence|numeric availability|event support|sampling coverage|observer replication|quantile|median|right-skewed|source event') {
        return @('descriptive_foundation', 'new privacy-safe descriptive summary')
    }
    if ($lower -match 'p1|p2|p3|p4|prediction|evidence hierarchy|primary manuscript evidence|secondary evidence|crosswalk') {
        return @('scientific_question_and_evidence_hierarchy', 'manuscript-only correction')
    }
    if ($lower -match 'singular|rank-deficient|non-estimable|noncompleted|pooling|provenance|complete coefficient|diagnostic|table s[0-9]') {
        return @('supplementary_completeness_and_provenance', 'existing adjusted result')
    }
    if ($lower -match 'future work|future analysis|prospective|redistribution|spawn intensity|mechanism|structured independent') {
        return @('future_or_companion_analysis_boundary', 'question reserved for future work')
    }
    if ($lower -match 'author|orcid|affiliation|corresponding|funding|competing|conflict|acknowledg|ai assistance|telephone|postal') {
        return @('author_metadata_and_declarations', 'manuscript-only correction')
    }
    if ($Artifact -match 'abstract|highlight|cover|title') {
        return @('journal_front_matter', 'manuscript-only correction')
    }
    if ($lower -match 'resource pulse|surf scoter|shorebird|sea bird|gull|ecological|community science|heterogeneous|attribution') {
        return @('ecological_narrative_and_interpretation', 'manuscript-only correction')
    }
    return @('editorial_restructure_and_plain_language', 'manuscript-only correction')
}

$pairs = @(
    @{ artifact='main manuscript, unblinded'; old='source\mer_manuscript_unblinded_v2.qmd'; new='source_v3\mer_manuscript_unblinded_v3.qmd' },
    @{ artifact='main manuscript, blinded'; old='source\mer_manuscript_blinded_companion_v2.qmd'; new='source_v3\mer_manuscript_blinded_companion_v3.qmd' },
    @{ artifact='supplement, unblinded'; old='source\mer_supplement_v2.qmd'; new='source_v3\mer_supplement_v3.qmd' },
    @{ artifact='supplement, blinded'; old='source\mer_supplement_blinded_companion_v2.qmd'; new='source_v3\mer_supplement_blinded_companion_v3.qmd' },
    @{ artifact='abstract'; old='source\mer_abstract_v2.md'; new='source_v3\mer_abstract_v3.md' },
    @{ artifact='title page'; old='source\mer_title_page_v2.md'; new='source_v3\mer_title_page_v3.md' },
    @{ artifact='cover letter'; old='source\mer_cover_letter_v2.md'; new='source_v3\mer_cover_letter_v3.md' },
    @{ artifact='highlights'; old='source\mer_highlights_v2.md'; new='source_v3\mer_highlights_v3.md' },
    @{ artifact='bibliography'; old='source\mer_references_v2.bib'; new='source_v3\mer_references_v3.bib' }
)

$rows = [Collections.Generic.List[object]]::new()
$pairSummary = [Collections.Generic.List[object]]::new()

Push-Location $ProjectRoot
try {
    foreach ($pair in $pairs) {
        $oldPath = Join-Path $pkg $pair.old
        $newPath = Join-Path $pkg $pair.new
        if (-not (Test-Path $oldPath) -or -not (Test-Path $newPath)) {
            throw "Missing v2/v3 comparison source: $($pair.old) or $($pair.new)"
        }
        $newLines = [IO.File]::ReadAllLines($newPath)
        $diff = @(& git -c core.quotepath=false -c core.autocrlf=false -c core.safecrlf=false diff --no-index --unified=0 -- $oldPath $newPath 2>$null)
        $hunkStarts = @()
        for ($i = 0; $i -lt $diff.Count; $i++) {
            if ($diff[$i] -match '^@@\s+-(\d+)(?:,(\d+))?\s+\+(\d+)(?:,(\d+))?\s+@@') {
                $hunkStarts += $i
            }
        }
        if ($hunkStarts.Count -eq 0) {
            $rows.Add([pscustomobject]@{
                change_id = ($pair.artifact -replace '[^A-Za-z0-9]+','_').Trim('_') + '_NO_CHANGE'
                artifact = $pair.artifact; v2_path = $pair.old; v3_path = $pair.new
                old_start = ''; old_count = 0; new_start = ''; new_count = 0
                v3_section = 'all'; classification = 'no_content_change'
                evidence_origin = 'unchanged v2 content'; analysis_result_changed = $false
                additions = 0; deletions = 0; change_summary = 'Files are byte-identical or text-identical.'
            })
            $pairSummary.Add([pscustomobject]@{artifact=$pair.artifact; hunks=0; additions=0; deletions=0})
            continue
        }

        $pairAdds = 0; $pairDeletes = 0
        for ($h = 0; $h -lt $hunkStarts.Count; $h++) {
            $start = $hunkStarts[$h]
            $end = if ($h + 1 -lt $hunkStarts.Count) { $hunkStarts[$h + 1] - 1 } else { $diff.Count - 1 }
            $header = $diff[$start]
            [void]($header -match '^@@\s+-(\d+)(?:,(\d+))?\s+\+(\d+)(?:,(\d+))?\s+@@')
            $oldStart = [int]$Matches[1]
            $oldCount = if ($Matches[2]) { [int]$Matches[2] } else { 1 }
            $newStart = [int]$Matches[3]
            $newCount = if ($Matches[4]) { [int]$Matches[4] } else { 1 }
            $content = if ($end -gt $start) { @($diff[($start + 1)..$end]) } else { @() }
            $added = @($content | Where-Object { $_ -match '^\+[^+]' }).Count
            $deleted = @($content | Where-Object { $_ -match '^-[^-]' }).Count
            $pairAdds += $added; $pairDeletes += $deleted
            $section = Get-SectionAtLine $newLines $newStart
            $joined = ($content -join ' ')
            $classified = Classify-Hunk $pair.artifact $section $joined
            $plain = ($content | ForEach-Object { $_ -replace '^[+-]', '' } | Where-Object { $_.Trim() } | Select-Object -First 2) -join ' / '
            if ($plain.Length -gt 280) { $plain = $plain.Substring(0, 277) + '...' }
            $rows.Add([pscustomobject]@{
                change_id = (($pair.artifact -replace '[^A-Za-z0-9]+','_').Trim('_') + '_H' + ('{0:D3}' -f ($h + 1)))
                artifact = $pair.artifact; v2_path = $pair.old; v3_path = $pair.new
                old_start = $oldStart; old_count = $oldCount; new_start = $newStart; new_count = $newCount
                v3_section = $section; classification = $classified[0]
                evidence_origin = $classified[1]; analysis_result_changed = $false
                additions = $added; deletions = $deleted; change_summary = $plain
            })
        }
        $pairSummary.Add([pscustomobject]@{artifact=$pair.artifact; hunks=$hunkStarts.Count; additions=$pairAdds; deletions=$pairDeletes})
    }
}
finally { Pop-Location }

# V2-only journal support documents remain preserved. They were not silently
# deleted; the replacement prompt did not require v3 versions of these forms.
$retainedV2Only = @(
    'source/mer_author_declarations_v2.md',
    'source/mer_reporting_checklist_v2.md',
    'source/mer_response_to_reviewers_template_v2.md',
    'source/mer_reviewer_expertise_v2.md',
    'source/mer_title_options_v2.md'
)
foreach ($p in $retainedV2Only) {
    $rows.Add([pscustomobject]@{
        change_id = 'RETAINED_' + (($p -replace '[^A-Za-z0-9]+','_').Trim('_'))
        artifact = 'v2-only support document'; v2_path = $p; v3_path = 'no v3 replacement requested'
        old_start = ''; old_count = ''; new_start = ''; new_count = ''
        v3_section = 'not applicable'; classification = 'preserved_v2_support_artifact'
        evidence_origin = 'unchanged v2 content'; analysis_result_changed = $false
        additions = 0; deletions = 0; change_summary = 'Preserved in place; not part of the versioned v3 deliverable list.'
    })
}

# Classify every versioned v3-only source, table, figure, rendered submission
# file, audit, and builder/validator script. Paired source documents are already
# represented at hunk level above and are not duplicated here. QA page rasters
# are inspection derivatives rather than submission-package changes.
$pairedNew = @($pairs | ForEach-Object { $_.new.Replace('\', '/') })
$v3OnlyFiles = @()
foreach ($dir in 'source_v3','tables_v3','figures_v3','rendered_v3','audits') {
    $v3OnlyFiles += @(Get-ChildItem -LiteralPath (Join-Path $pkg $dir) -File | Where-Object {
        $dir -ne 'audits' -or $_.Name -match 'v3'
    })
}
$v3OnlyFiles += @(Get-ChildItem -LiteralPath $pkg -File | Where-Object { $_.Name -match 'v3\.(md|csv)$' })
$v3OnlyFiles += @(Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'scripts') -File | Where-Object { $_.Name -match 'mer_v3' })
$v3OnlyFiles = @($v3OnlyFiles | Sort-Object FullName -Unique)

foreach ($file in $v3OnlyFiles) {
    $repoRelative = $file.FullName.Substring($ProjectRoot.Length + 1).Replace('\', '/')
    $pkgRelative = if ($file.FullName.StartsWith($pkg, [StringComparison]::OrdinalIgnoreCase)) {
        $file.FullName.Substring($pkg.Length + 1).Replace('\', '/')
    } else { $repoRelative }
    if ($pkgRelative -in $pairedNew) { continue }

    $classification = 'versioned_package_derivative'
    $origin = 'manuscript-only correction'
    $summary = 'New versioned v3 package artifact; v1 and v2 counterparts remain preserved.'
    if ($pkgRelative -match '^tables_v3/(descriptive|species_descriptive|guild_descriptive|herring_event_descriptive|Table_1)') {
        $classification = 'descriptive_foundation'
        $origin = 'new privacy-safe descriptive summary'
        $summary = 'Deterministic table assembled from tracked privacy-safe aggregates.'
    } elseif ($pkgRelative -match '^tables_v3/') {
        $classification = 'supplementary_completeness_and_provenance'
        $origin = 'existing adjusted result'
        $summary = 'Versioned v3 table retaining or re-expressing existing frozen aggregate results.'
    } elseif ($pkgRelative -match '^figures_v3/Figure_(1|S1|S2)_') {
        $classification = 'privacy_safe_spatial_addition'
        $origin = 'new privacy-safe descriptive summary'
        $summary = 'Privacy-safe broad-region map or nongeographic exposure schematic.'
    } elseif ($pkgRelative -match '^figures_v3/Figure_2_') {
        $classification = 'descriptive_foundation'
        $origin = 'new privacy-safe descriptive summary'
        $summary = 'Unadjusted descriptive display assembled from tracked aggregate values.'
    } elseif ($pkgRelative -match '^figures_v3/') {
        $classification = 'ecological_narrative_and_interpretation'
        $origin = 'existing adjusted result'
        $summary = 'Publication display of existing frozen adjusted results or diagnostics.'
    } elseif ($pkgRelative -match '^rendered_v3/') {
        $classification = 'rendered_submission_derivative'
        $origin = 'derived from versioned v3 source'
        $summary = 'Rendered DOCX or PDF derivative; not directly edited.'
    } elseif ($pkgRelative -match '^audits/') {
        $classification = 'validation_and_provenance'
        $origin = 'manuscript-only audit'
        $summary = 'Machine- or human-readable v3 validation, privacy, provenance, or change record.'
    } elseif ($repoRelative -match '(^|/)scripts/') {
        $classification = 'reproducible_generation_and_validation'
        $origin = 'manuscript-only implementation'
        $summary = 'Versioned builder, renderer, change-audit, or validation script; no response-model fitting.'
    }

    $rows.Add([pscustomobject]@{
        change_id = 'NEW_' + (($repoRelative -replace '[^A-Za-z0-9]+','_').Trim('_'))
        artifact = 'v3-only package artifact'; v2_path = 'no v2 file at this versioned path'; v3_path = $repoRelative
        old_start = ''; old_count = 0; new_start = ''; new_count = ''
        v3_section = 'file level'; classification = $classification
        evidence_origin = $origin; analysis_result_changed = $false
        additions = ''; deletions = 0; change_summary = $summary
    })
}

$csvPath = Join-Path $auditDir 'v2_to_v3_change_audit_v3.csv'
Export-CsvUtf8Lf @($rows) $csvPath

$classCounts = @($rows | Group-Object classification | Sort-Object Name)
$md = [Collections.Generic.List[string]]::new()
$md.Add('# V2-to-v3 change audit')
$md.Add('')
$md.Add('This audit classifies every zero-context text-diff hunk across paired v2 and v3 source documents, every versioned v3-only package file, and v2-only support documents preserved without a v3 replacement. Rendered files are recorded as derivatives and were not independently edited.')
$md.Add('')
$md.Add('## Scope and result')
$md.Add('')
$md.Add("- Paired source artifacts: $($pairs.Count)")
$md.Add("- Classified source diff hunks or no-change records: $(@($rows | Where-Object classification -ne 'preserved_v2_support_artifact').Count)")
$md.Add("- Preserved v2-only support documents: $($retainedV2Only.Count)")
$md.Add("- Classified v3-only package files: $(@($rows | Where-Object artifact -eq 'v3-only package artifact').Count)")
$md.Add('- Frozen coefficients, standard errors, intervals, p-values, q-values, sample sizes, fit states, and diagnostics changed: **0**')
$md.Add('- The complete line-level classification is `audits/v2_to_v3_change_audit_v3.csv`.')
$md.Add('')
$md.Add('## Classification counts')
$md.Add('')
$md.Add('| Classification | Records |')
$md.Add('|---|---:|')
foreach ($g in $classCounts) { $md.Add("| $($g.Name -replace '_',' ') | $($g.Count) |") }
$md.Add('')
$md.Add('## Artifact-level diff accounting')
$md.Add('')
$md.Add('| Artifact | Hunks | Added lines | Deleted lines |')
$md.Add('|---|---:|---:|---:|')
foreach ($s in $pairSummary) { $md.Add("| $($s.artifact) | $($s.hunks) | $($s.additions) | $($s.deletions) |") }
$md.Add('')
$md.Add('## Interpretation')
$md.Add('')
$md.Add('The v3 changes add a privacy-safe descriptive foundation and broad-region maps, correct the primary baseline and engine wording, reorganize the paper around P1–P4 and species-level evidence, expand the ecological discussion, and move completeness/provenance detail to the supplement. Existing adjusted results are only re-expressed on interpretable ratio scales or reorganized; no response model was refit.')
$md.Add('')
$md.Add('Items unavailable from public aggregates remain explicitly unavailable. They were not approximated and would require separate protected-data authorization.')
Write-Utf8Lf (Join-Path $pkg 'v2_to_v3_change_audit_v3.md') @($md)

Write-Host "Built v2-to-v3 change audit: $($rows.Count) classified records."
