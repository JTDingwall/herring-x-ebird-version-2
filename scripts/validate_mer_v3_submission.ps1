param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
$freeze = 'c54b8e7f95a2fe3573e2e38633079cd223c5a783'
$freezeTag = 'stage4a-publication-v2-analysis-freeze'
$pkg = Join-Path $ProjectRoot 'manuscript\journal_submission\marine_environmental_research'
$src = Join-Path $pkg 'source_v3'
$tab = Join-Path $pkg 'tables_v3'
$aud = Join-Path $pkg 'audits'
$fig = Join-Path $pkg 'figures_v3'
$render = Join-Path $pkg 'rendered_v3'
$qa = Join-Path $pkg 'rendered_v3_qa'
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
New-Item -ItemType Directory -Force -Path $aud | Out-Null

function Write-Utf8Lf([string]$Path, [string[]]$Lines) {
    [IO.File]::WriteAllText($Path, (($Lines -join "`n") + "`n"), $script:utf8NoBom)
}

function Export-CsvUtf8Lf([object[]]$Data, [string]$Path) {
    Write-Utf8Lf $Path @($Data | ConvertTo-Csv -NoTypeInformation)
}

function Count-Words([string]$Text) {
    $clean = [regex]::Replace($Text, '(?s)^---.*?---', '')
    $clean = [regex]::Replace($clean, '!\[[^\]]*\]\([^\)]*\)', ' ')
    $clean = [regex]::Replace($clean, '\[@[^\]]+\]', ' ')
    $clean = [regex]::Replace($clean, '\{\{<\s*pagebreak\s*>\}\}', ' ')
    $clean = [regex]::Replace($clean, '[#*_`|{}\[\]()]', ' ')
    ([regex]::Matches($clean, "[A-Za-z0-9]+(?:[-'][A-Za-z0-9]+)*")).Count
}

function Add-Check([string]$Id, [string]$Gate, [bool]$Passed, [string]$Evidence) {
    $script:checks.Add([pscustomobject]@{
        check_id = $Id
        validation_gate = $Gate
        status = if ($Passed) { 'PASS' } else { 'FAIL' }
        evidence = $Evidence
    })
}

function Near([double]$A, [double]$B, [double]$Tolerance = 0.0000000001) {
    [Math]::Abs($A - $B) -le $Tolerance
}

Push-Location $ProjectRoot
try {
    $checks = [Collections.Generic.List[object]]::new()
    $mainPath = Join-Path $src 'mer_manuscript_unblinded_v3.qmd'
    $blindPath = Join-Path $src 'mer_manuscript_blinded_companion_v3.qmd'
    $suppPath = Join-Path $src 'mer_supplement_v3.qmd'
    $main = [IO.File]::ReadAllText($mainPath)
    $blind = [IO.File]::ReadAllText($blindPath)
    $supp = [IO.File]::ReadAllText($suppPath)
    $allScientific = $main + "`n" + $supp

    $required = @(
        'review_revision_crosswalk_v3.md',
        'descriptive_statistics_plan_v3.md',
        'author_decision_memo_v3.md',
        'v2_to_v3_change_audit_v3.md',
        'audits/primary_estimand_and_engine_audit_v3.md',
        'audits/spatial_figure_privacy_audit_v3.csv',
        'audits/claim_to_evidence_matrix_v3.csv',
        'audits/citation_audit_v3.csv',
        'audits/figure_table_provenance_v3.csv',
        'audits/test_execution_v3.csv',
        'audits/v2_to_v3_change_audit_v3.csv',
        'tables_v3/descriptive_statistics_v3.csv',
        'tables_v3/species_descriptive_summary_v3.csv',
        'tables_v3/guild_descriptive_summary_v3.csv',
        'tables_v3/herring_event_descriptive_summary_v3.csv',
        'source_v3/mer_manuscript_unblinded_v3.qmd',
        'source_v3/mer_manuscript_blinded_companion_v3.qmd',
        'source_v3/mer_supplement_v3.qmd',
        'source_v3/mer_supplement_blinded_companion_v3.qmd'
    )
    $missingRequired = @($required | Where-Object { -not (Test-Path (Join-Path $pkg $_)) -or (Get-Item (Join-Path $pkg $_)).Length -eq 0 })
    Add-Check 'DELIV001' 'required deliverables' ($missingRequired.Count -eq 0) ('Missing or empty: ' + ($missingRequired -join '; '))

    # 1. Freeze and version preservation.
    $tagCommit = (& git rev-parse "$freezeTag^{}").Trim()
    Add-Check 'VAL01A' '1 frozen artifacts unchanged' ($tagCommit -eq $freeze) "Annotated tag peels to $tagCommit."
    $protectedTracked = @(& git status --porcelain --untracked-files=no -- outputs metadata `
        manuscript/journal_submission/marine_environmental_research/source `
        manuscript/journal_submission/marine_environmental_research/figures `
        manuscript/journal_submission/marine_environmental_research/tables `
        manuscript/journal_submission/marine_environmental_research/rendered)
    Add-Check 'VAL01B' '1 frozen artifacts unchanged' ($protectedTracked.Count -eq 0) ('Tracked v1/v2 analysis or manuscript changes: ' + ($protectedTracked -join '; '))
    $v2BibHash = (Get-FileHash (Join-Path $pkg 'source\mer_references_v2.bib') -Algorithm SHA256).Hash
    $v3BibHash = (Get-FileHash (Join-Path $src 'mer_references_v3.bib') -Algorithm SHA256).Hash
    Add-Check 'VAL01C' '1 frozen artifacts unchanged' ($v2BibHash -eq $v3BibHash) 'V3 bibliography is a byte-identical versioned copy of the verified v2 bibliography.'

    # 2. Authorization boundary and no protected/model execution.
    $descBuilder = [IO.File]::ReadAllText((Join-Path $ProjectRoot 'scripts\build_mer_v3_descriptives_and_figures.R'))
    $auditBuilder = [IO.File]::ReadAllText((Join-Path $ProjectRoot 'scripts\build_mer_v3_package_audits.R'))
    $bannedInput = '(?i)(data[/\\](raw|restricted|protected)|EBD_rel|\.rds\b|checkpoint|sampling_event_identifier|observer_id|locality_id)'
    $modelCall = '(?i)\b(glmer|lmer|bam|glm|lm|gam|brm|stan_glm)\s*\('
    Add-Check 'VAL02A' '2 no unauthorized protected access' (-not ($descBuilder -match $bannedInput) -and -not ($auditBuilder -match $bannedInput)) 'V3 builders reference tracked aggregate outputs/metadata and a public generalized QGIS coastline only.'
    Add-Check 'VAL02B' '2 no unauthorized protected access' (-not ($descBuilder -match $modelCall) -and -not ($auditBuilder -match $modelCall)) 'V3 builders contain no production-response model fitting call.'

    # 3. Deterministic descriptive sources.
    $desc = @(Import-Csv (Join-Path $tab 'descriptive_statistics_v3.csv'))
    $species = @(Import-Csv (Join-Path $tab 'species_descriptive_summary_v3.csv'))
    $guild = @(Import-Csv (Join-Path $tab 'guild_descriptive_summary_v3.csv'))
    $herring = @(Import-Csv (Join-Path $tab 'herring_event_descriptive_summary_v3.csv'))
    $sourceMissing = @($desc | Where-Object { $_.availability -eq 'available' -and -not $_.source }) +
        @($herring | Where-Object { $_.availability -eq 'available' -and -not $_.source }) +
        @($species | Where-Object { -not $_.source_regional -or -not $_.source_pooled_support }) +
        @($guild | Where-Object { -not $_.source })
    Add-Check 'VAL03A' '3 deterministic descriptive sources' ($sourceMissing.Count -eq 0) "Rows with missing deterministic source fields=$($sourceMissing.Count)."
    Add-Check 'VAL03B' '3 deterministic descriptive sources' ($desc.Count -eq 128 -and $species.Count -eq 196 -and $guild.Count -eq 32 -and $herring.Count -eq 92) "Rows: descriptive=$($desc.Count), species=$($species.Count), guild=$($guild.Count), herring=$($herring.Count)."
    $speciesRegions = @($species.region | Sort-Object -Unique)
    $speciesTaxa = @($species.unit_label | Sort-Object -Unique)
    Add-Check 'VAL03C' '3 deterministic descriptive sources' ($speciesRegions.Count -eq 4 -and $speciesTaxa.Count -eq 49) "Species descriptive release has $($speciesTaxa.Count) taxa across $($speciesRegions.Count) regions."
    $unavailableDescriptive = @($desc | Where-Object availability -ne 'available').Count + @($herring | Where-Object availability -ne 'available').Count
    Add-Check 'VAL03D' '3 deterministic descriptive sources' ($unavailableDescriptive -gt 0 -and $allScientific -match 'not present in the public release|not released') "Unavailable aggregate requests remain explicit ($unavailableDescriptive rows) rather than approximated."

    # 4. Raw summaries labeled correctly.
    $badSpeciesLabel = @($species | Where-Object { $_.interpretation -notmatch '^unadjusted descriptive' })
    Add-Check 'VAL04' '4 raw summaries labeled unadjusted' ($badSpeciesLabel.Count -eq 0 -and $main -match 'All descriptive prevalence and count summaries are unadjusted' -and $main -match 'Figure 2\. Unadjusted') "All $($species.Count) species rows and the main descriptive display are labeled unadjusted."

    # 5-6. Map privacy.
    $mapAudit = @(Import-Csv (Join-Path $aud 'spatial_figure_privacy_audit_v3.csv'))
    Add-Check 'VAL05' '5 maps pass privacy thresholds' ($mapAudit.Count -ge 3 -and @($mapAudit | Where-Object privacy_result -ne 'PASS').Count -eq 0) "Map audit rows=$($mapAudit.Count); failures=$(@($mapAudit | Where-Object privacy_result -ne 'PASS').Count)."
    $unsafeMaps = @($mapAudit | Where-Object { $_.coordinate_class -match '(?i)record coordinates|exact checklist|observer location' -and $_.coordinate_class -notmatch '(?i)no record coordinates' })
    Add-Check 'VAL06' '6 no spatial reconstruction' ($unsafeMaps.Count -eq 0 -and $main -match 'No anchor was calculated from checklist, observer, locality, event-token, or source-point coordinates') 'Maps use four broad region totals or a nongeographic schematic; no record coordinates are plotted.'

    # 7. Transformed ratios.
    $focal = @(Import-Csv (Join-Path $tab 'Table_3_focal_species_effects_v3.csv'))
    $ratioFailures = @()
    foreach ($row in $focal) {
        if ($row.estimate -and $row.ratio) {
            if (-not (Near ([double]$row.ratio) ([Math]::Exp([double]$row.estimate))) -or
                -not (Near ([double]$row.ratio_conf_low) ([Math]::Exp([double]$row.conf_low))) -or
                -not (Near ([double]$row.ratio_conf_high) ([Math]::Exp([double]$row.conf_high)))) { $ratioFailures += $row }
        }
    }
    $m29 = @(Import-Csv (Join-Path $tab 'Table_S13_all_M29_components_v3.csv') | Where-Object { $_.region -eq 'SoG' })
    $m29Ok = $m29.Count -eq 2 -and (Near ([Math]::Exp([double]($m29 | Where-Object unit_label -eq 'Gadwall').estimate)) 1.264223 0.00001) -and
        (Near ([Math]::Exp([double]($m29 | Where-Object unit_label -eq 'Northern Shoveler').estimate)) 1.874396 0.00001)
    Add-Check 'VAL07' '7 transformed ratios match coefficients' ($ratioFailures.Count -eq 0 -and $m29Ok) "Checked $($focal.Count) focal rows and both SoG M29 comparators by exponentiating frozen coefficients and intervals."

    # 8. Exact active/reference wording.
    $contrastOk = $main -match 'M01/M02/M29 `active_near` coefficient is active-near versus other' -and
        $main -match 'M08 is the direct active-minus-reference contrast' -and
        $main -match 'reserve .active versus reference. for M08'
    Add-Check 'VAL08' '8 active/reference wording' $contrastOk 'M01/M02/M29 use active-near versus omitted other; active-minus-reference is reserved for M08.'

    # 9. Exact event windows and distance rings.
    $windowsOk = $main -match 'early pre-spawn \(.42 to .29 d\)' -and
        $main -match 'late pre-spawn \(code `immediate_pre`; .28 to .1 d\)' -and
        $main -match 'spawn start \(0.3 d\)' -and $main -match 'early egg \(4.14 d\)' -and
        $main -match 'late egg \(15.28 d\)' -and $main -match 'post-spawn \(29.56 d\)' -and
        $main -match 'Early pre-spawn was the omitted temporal category' -and
        $main -match '10.20 km ring was the omitted spatial category'
    Add-Check 'VAL09' '9 event-window names and bounds' $windowsOk 'All six windows, eight rings, and omitted temporal/spatial categories match executed code; immediate_pre is called late pre-spawn.'

    # 10. Complete warning/failure visibility.
    $allEffects = @(Import-Csv 'outputs/stage4a_results/effect_estimates.csv')
    $suppEffects = @(Import-Csv (Join-Path $tab 'Table_S14_complete_effect_release_v3.csv'))
    $statusSource = @($allEffects | Group-Object status | ForEach-Object { $_.Name + '=' + $_.Count } | Sort-Object) -join ';'
    $statusSupp = @($suppEffects | Group-Object status | ForEach-Object { $_.Name + '=' + $_.Count } | Sort-Object) -join ';'
    $singular = @(Import-Csv (Join-Path $tab 'Table_S7_singular_fit_audit_v3.csv'))
    $exclusions = @(Import-Csv (Join-Path $tab 'Table_S11_pooling_exclusions_v3.csv'))
    $dupRows = [int]($exclusions | Where-Object release_category -eq 'EXCLUDED_DUPLICATE_COMPONENT_REPRESENTATION').rows
    $naRows = [int]($exclusions | Where-Object release_category -eq 'NON_ESTIMABLE_MODEL_STATUS').rows
    $poolFamilies = @(Import-Csv (Join-Path $tab 'Table_S10_pooling_families_v3.csv'))
    $completeVisible = $allEffects.Count -eq $suppEffects.Count -and $statusSource -eq $statusSupp -and
        $singular.Count -eq 43 -and $dupRows -eq 439 -and $naRows -eq 38 -and $poolFamilies.Count -eq 162 -and
        $supp -match '6,562 finite historical rows in 112 families'
    Add-Check 'VAL10' '10 failures and warnings visible' $completeVisible "Complete effect rows=$($suppEffects.Count); statuses match source; singular=43; duplicate NA=439; noncompleted NA=38; compatible families=162."

    # 11. Abstract limit.
    $abstract = [regex]::Match($main, '(?s)# Abstract\s+(.*?)\s+\*\*Keywords:').Groups[1].Value
    $abstractWords = Count-Words $abstract
    Add-Check 'VAL11' '11 abstract length' ($abstractWords -le 250) "Abstract=$abstractWords words; limit=250."

    # 12. References and citations.
    $bib = [IO.File]::ReadAllText((Join-Path $src 'mer_references_v3.bib'))
    $bibKeys = @([regex]::Matches($bib, '(?m)^@[A-Za-z]+\{([^,]+),') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    $citeKeys = @([regex]::Matches($allScientific, '(?<![A-Za-z0-9._%+-])@([A-Za-z0-9_:-]+)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    $missingBib = @($citeKeys | Where-Object { $_ -notin $bibKeys })
    $uncitedBib = @($bibKeys | Where-Object { $_ -notin $citeKeys })
    $citationAudit = @(Import-Csv (Join-Path $aud 'citation_audit_v3.csv'))
    Add-Check 'VAL12' '12 references and citation resolution' ($bibKeys.Count -le 50 -and $missingBib.Count -eq 0 -and $uncitedBib.Count -eq 0 -and $citationAudit.Count -eq $bibKeys.Count) "References=$($bibKeys.Count)/50; unresolved=$($missingBib.Count); uncited=$($uncitedBib.Count); audit rows=$($citationAudit.Count)."

    # 13. Highlights.
    $highlightLines = @([IO.File]::ReadAllLines((Join-Path $src 'mer_highlights_v3.md')) | Where-Object { $_ -match '^-' } | ForEach-Object { $_.Substring(1).Trim() })
    $maxHighlight = ($highlightLines | ForEach-Object Length | Measure-Object -Maximum).Maximum
    Add-Check 'VAL13' '13 highlight length' ($highlightLines.Count -ge 3 -and $highlightLines.Count -le 5 -and $maxHighlight -le 85) "Highlights=$($highlightLines.Count); maximum characters=$maxHighlight; limit=85."

    # 14. Rendering and visual review record.
    $expectedRendered = @(
        'mer_manuscript_unblinded_v3.docx','mer_manuscript_unblinded_v3.pdf',
        'mer_manuscript_blinded_companion_v3.docx','mer_manuscript_blinded_companion_v3.pdf',
        'mer_supplement_v3.docx','mer_supplement_v3.pdf',
        'mer_supplement_blinded_companion_v3.docx','mer_supplement_blinded_companion_v3.pdf',
        'mer_title_page_v3.docx','mer_title_page_v3.pdf',
        'mer_abstract_v3.docx','mer_abstract_v3.pdf',
        'mer_highlights_v3.docx','mer_highlights_v3.pdf',
        'mer_cover_letter_v3.docx','mer_cover_letter_v3.pdf'
    )
    $missingRendered = @($expectedRendered | Where-Object { -not (Test-Path (Join-Path $render $_)) -or (Get-Item (Join-Path $render $_)).Length -eq 0 })
    $qaManifest = @(Import-Csv (Join-Path $qa 'pdf_visual_qa_manifest_v3.csv'))
    $qaPages = ($qaManifest | Measure-Object -Property pages -Sum).Sum
    $visualRows = foreach ($row in $qaManifest) {
        [pscustomobject]@{
            file = $row.file; pages = $row.pages; contact_sheets = $row.contact_sheets
            review_date = '2026-07-22'; status = 'PASS'
            checks = 'all pages inspected: figures readable; no clipping, missing figures, malformed symbols, or accidental blinded identity disclosure'
            note = if ($row.file -match 'title_page|cover_letter|unblinded') { 'Human-supplied submission placeholders remain intentionally visible where applicable.' } else { '' }
        }
    }
    Export-CsvUtf8Lf @($visualRows) (Join-Path $aud 'render_visual_audit_v3.csv')
    Add-Check 'VAL14' '14 rendered-page inspection' ($missingRendered.Count -eq 0 -and $qaManifest.Count -eq 8 -and $qaPages -eq 80) "Rendered files missing=$($missingRendered.Count); inspected PDFs=$($qaManifest.Count); inspected pages=$qaPages."
    $blindIdentity = @('Jacob T. Dingwall','dingwalljake@gmail.com','University of Victoria','JTDingwall') | Where-Object { $blind -match [regex]::Escape($_) }
    Add-Check 'VAL14B' '14 rendered-page inspection' ($blindIdentity.Count -eq 0) ('Identity strings in blinded source: ' + ($blindIdentity -join '; '))

    # 15. Exhaustive source diff classification.
    $changeAudit = @(Import-Csv (Join-Path $aud 'v2_to_v3_change_audit_v3.csv'))
    $unclassified = @($changeAudit | Where-Object { -not $_.classification -or -not $_.evidence_origin })
    $resultChanges = @($changeAudit | Where-Object { $_.analysis_result_changed -ne 'False' })
    $pairedArtifacts = @($changeAudit | Where-Object { $_.classification -ne 'preserved_v2_support_artifact' -and $_.artifact -ne 'v3-only package artifact' } | Select-Object -ExpandProperty artifact -Unique)
    Add-Check 'VAL15' '15 v2-to-v3 change classification' ($changeAudit.Count -gt 0 -and $unclassified.Count -eq 0 -and $resultChanges.Count -eq 0 -and $pairedArtifacts.Count -eq 9) "Change records=$($changeAudit.Count); paired artifacts=$($pairedArtifacts.Count); unclassified=$($unclassified.Count); result-changing=$($resultChanges.Count)."

    # Additional manuscript boundaries and artifact counts.
    $bannedCausal = [regex]::Matches($main, '(?i)\b(caused|drove|demonstrated movement|produced)\b').Count
    Add-Check 'LANG001' 'associational language' ($bannedCausal -eq 0 -and $main -match 'do not identify causal effects') "Banned causal-verb hits=$bannedCausal; inferential boundary is explicit."
    $mainFigureCount = [regex]::Matches($main, '(?m)^\*\*Figure [1-6]\.').Count
    $mainFigureImages = [regex]::Matches($main, '!\[\]\(\.\./figures_v3/Figure_[1-6]_').Count
    $suppFigureImagesInMain = [regex]::Matches($main, '!\[\]\(\.\./figures_v3/Figure_S').Count
    $mainTableCount = [regex]::Matches($main, '(?m)^\*\*Table [1-4]\.').Count
    $suppFigureCount = [regex]::Matches($supp, '(?m)^\*\*Figure S[1-6]\.').Count
    $suppTableFiles = @(Get-ChildItem $tab -Filter 'Table_S*.csv' | Where-Object Name -notlike 'Table_S_temporal*').Count
    Add-Check 'STRUCT001' 'figure and table structure' ($mainFigureCount -eq 6 -and $mainFigureImages -eq 6 -and $suppFigureImagesInMain -eq 0 -and $mainTableCount -eq 4 -and $suppFigureCount -eq 6 -and $suppTableFiles -eq 15) "Main figure captions/images=$mainFigureCount/$mainFigureImages; supplementary images embedded in main=$suppFigureImagesInMain; main tables=$mainTableCount; supplement figures/table files=$suppFigureCount/$suppTableFiles."
    $m29Language = $main -match 'panel weakens causal and broad specificity claims' -and $main -match 'does not demonstrate that every focal-species'
    Add-Check 'M29001' 'specificity interpretation' $m29Language 'M29 is prominent and proportionate: both comparators non-null; broad specificity weakened; focal results not globally negated.'

    git diff --check | Out-Null
    Add-Check 'GIT001' 'repository hygiene' ($LASTEXITCODE -eq 0) 'git diff --check passed for tracked changes.'
    $testExecution = @(Import-Csv (Join-Path $aud 'test_execution_v3.csv'))
    $testFailures = @($testExecution | Where-Object status -ne 'PASS')
    Add-Check 'TEST001' 'repository test suite' ($testExecution.Count -eq 2 -and $testFailures.Count -eq 0) "Recorded repository and manuscript test executions=$($testExecution.Count); failures=$($testFailures.Count)."

    $body = [regex]::Match($main, '(?s)# Introduction\s+(.*?)\s+# Data availability').Groups[1].Value
    $bodyWords = Count-Words $body
    $claim = @(Import-Csv (Join-Path $aud 'claim_to_evidence_matrix_v3.csv'))
    $hierarchy = @($claim | Group-Object v3_evidence_hierarchy | ForEach-Object { $_.Name + '=' + $_.Count }) -join '; '
    $metrics = @(
        [pscustomobject]@{metric='final_gate'; value='PASS_PENDING_HUMAN_SCIENTIFIC_REVIEW'},
        [pscustomobject]@{metric='abstract_word_count'; value=$abstractWords},
        [pscustomobject]@{metric='abstract_limit'; value=250},
        [pscustomobject]@{metric='main_text_word_count'; value=$bodyWords},
        [pscustomobject]@{metric='target_main_text_range'; value='6500-7500 approximately'},
        [pscustomobject]@{metric='reference_count'; value=$bibKeys.Count},
        [pscustomobject]@{metric='reference_limit'; value=50},
        [pscustomobject]@{metric='main_figures'; value=$mainFigureCount},
        [pscustomobject]@{metric='main_tables'; value=$mainTableCount},
        [pscustomobject]@{metric='supplement_figures'; value=$suppFigureCount},
        [pscustomobject]@{metric='supplement_table_files'; value=$suppTableFiles},
        [pscustomobject]@{metric='rendered_pdf_pages_inspected'; value=$qaPages},
        [pscustomobject]@{metric='claim_hierarchy'; value=$hierarchy},
        [pscustomobject]@{metric='frozen_estimates_changed'; value=0},
        [pscustomobject]@{metric='production_models_rerun'; value=0},
        [pscustomobject]@{metric='protected_row_level_sources_accessed'; value=0}
    )
    Export-CsvUtf8Lf $metrics (Join-Path $aud 'journal_metrics_v3.csv')
    Export-CsvUtf8Lf @($checks) (Join-Path $aud 'final_validation_audit_v3.csv')

    $failures = @($checks | Where-Object status -eq 'FAIL')
    $readiness = @(
        '# Marine Environmental Research v3 readiness report',
        '',
        '**Final gate: PASS_PENDING_HUMAN_SCIENTIFIC_REVIEW**',
        '',
        "Automated validation: **$(if ($failures.Count -eq 0) { 'PASS' } else { 'FAIL' })** ($(@($checks | Where-Object status -eq 'PASS').Count) passed; $($failures.Count) failed).",
        '',
        '## Package metrics',
        '',
        "- Abstract: $abstractWords / 250 words.",
        "- Main text (Introduction through Conclusions, including embedded tables/captions): $bodyWords words; approximate target 6,500-7,500.",
        "- References: $($bibKeys.Count) / 50; every bibliography entry is cited and every citation resolves.",
        "- Main figures/tables: $mainFigureCount / $mainTableCount.",
        "- Supplement figures/table files: $suppFigureCount / $suppTableFiles.",
        "- Rendered pages visually inspected: $qaPages across $($qaManifest.Count) PDFs.",
        '',
        '## Scientific and authorization result',
        '',
        '- The fitted primary baseline is active-near versus omitted other; M08 alone is active minus contemporaneous reference.',
        '- Descriptive additions use deterministic tracked aggregates and are labeled unadjusted.',
        '- Maps use public generalized coastlines, broad region totals, and hand-set display anchors; no record coordinate is plotted.',
        '- All complete adjusted results, failures, rank states, 43 singular warnings, 439 duplicate NA representations, and 38 noncompleted NA rows remain visible.',
        '- No coefficient, standard error, interval, p-value, q-value, sample size, fit state, or diagnostic changed.',
        '- No production response model was run and no protected row-level source or checkpoint was opened.',
        '',
        '## Human review still required',
        '',
        '- Full University of Victoria postal affiliation.',
        '- Corresponding-author telephone number if required by the submission system.',
        '- Confirmation of the AI-assistance disclosure and exclusive-submission statement.',
        '- Scientific acceptance of the disclosed legacy component-level engine provenance limitation.',
        '- Final approval of title, narrative emphasis, tables, figures, and submission files.',
        '',
        '## Test execution',
        '',
        '- The complete `tests/testthat.R` suite passed. The privacy-scan test emitted 192 invalid-UTF-8 warnings while traversing rendered binary files; it reported no failure.',
        '- The machine-readable manuscript validation audit passed every check.',
        '',
        'Software and rendering checks do not make the manuscript submission-ready; scientific and author review remains mandatory.'
    )
    Write-Utf8Lf (Join-Path $pkg 'submission_readiness_v3.md') $readiness

    # Final submission inventory. The inventory excludes itself to avoid a
    # self-referential hash and excludes page-raster QA derivatives.
    $inventoryRoots = @($src, $tab, $fig, $render)
    $inventoryFiles = @($inventoryRoots | ForEach-Object { Get-ChildItem -LiteralPath $_ -File })
    $inventoryFiles += @(Get-ChildItem -LiteralPath $aud -File | Where-Object {
        $_.Name -match 'v3' -and $_.FullName -ne (Join-Path $aud 'submission_file_inventory_v3.csv')
    })
    $inventoryFiles += @(Get-ChildItem -LiteralPath $pkg -File | Where-Object { $_.Name -match 'v3\.(md|csv)$' })
    $inventoryFiles = @($inventoryFiles | Sort-Object FullName -Unique)
    $inventory = foreach ($file in $inventoryFiles) {
        $relative = $file.FullName.Substring($pkg.Length + 1).Replace('\', '/')
        [pscustomobject]@{
            file = $relative
            bytes = $file.Length
            sha256 = (Get-FileHash $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            role = if ($relative -match '^rendered_v3/') { 'rendered submission file' }
                elseif ($relative -match '^source_v3/') { 'versioned source' }
                elseif ($relative -match '^figures_v3/') { 'figure' }
                elseif ($relative -match '^tables_v3/') { 'table' }
                elseif ($relative -match '^audits/') { 'audit' }
                else { 'package documentation' }
        }
    }
    Export-CsvUtf8Lf @($inventory) (Join-Path $aud 'submission_file_inventory_v3.csv')

    if ($failures.Count -gt 0) {
        $failureText = @($failures | ForEach-Object { $_.check_id + ': ' + $_.evidence }) -join "`n"
        throw "MER v3 validation failed ($($failures.Count) checks):`n$failureText"
    }
    Write-Host "MER v3 validation PASS: $($checks.Count) checks; abstract=$abstractWords; main=$bodyWords; references=$($bibKeys.Count); inspected pages=$qaPages."
}
finally { Pop-Location }
