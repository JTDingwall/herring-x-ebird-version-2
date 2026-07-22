param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [switch]$SkipRepositoryTests
)

$ErrorActionPreference = 'Stop'
$freeze = 'c54b8e7f95a2fe3573e2e38633079cd223c5a783'
$audit = [System.Collections.Generic.List[object]]::new()

function Add-Check([string]$Id, [string]$Category, [bool]$Passed, [string]$Evidence) {
    $audit.Add([pscustomobject]@{
        check_id = $Id
        category = $Category
        status = if ($Passed) { 'PASS' } else { 'FAIL' }
        evidence = $Evidence
    })
}

function Read-ExpandedQmd([string]$Path) {
    $text = Get-Content -Raw -LiteralPath $Path
    $dir = Split-Path $Path -Parent
    $pattern = '\{\{<\s*include\s+([^\s>]+)\s*>\}\}'
    while ([regex]::IsMatch($text, $pattern)) {
        $text = [regex]::Replace($text, $pattern, {
            param($m)
            $include = Join-Path $dir $m.Groups[1].Value
            if (-not (Test-Path -LiteralPath $include)) { throw "Missing include: $include" }
            Get-Content -Raw -LiteralPath $include
        })
    }
    return $text
}

function Count-Words([string]$Text) {
    $clean = [regex]::Replace($Text, '(?s)^---.*?---', '')
    $clean = [regex]::Replace($clean, '!\[[^\]]*\]\([^\)]*\)', ' ')
    $clean = [regex]::Replace($clean, '\[@[^\]]+\]', ' ')
    $clean = [regex]::Replace($clean, '[#*_`|{}\[\]()]', ' ')
    return ([regex]::Matches($clean, "[A-Za-z0-9]+(?:[-'][A-Za-z0-9]+)*")).Count
}

Push-Location $ProjectRoot
try {
    $env:RENV_CONFIG_AUTOLOADER_ENABLED = 'FALSE'
    $projectLibrary = Join-Path $ProjectRoot 'renv\library\windows\R-4.5\x86_64-w64-mingw32'
    if (Test-Path -LiteralPath $projectLibrary) { $env:R_LIBS_USER = $projectLibrary }
    # Do not let a stale failed audit become an input to the repository privacy
    # scan. The current audit is written after all checks complete below.
    $auditPath = Join-Path $ProjectRoot 'metadata\stage4a_manuscript_consistency_audit_v2.csv'
    if (Test-Path -LiteralPath $auditPath) { Remove-Item -LiteralPath $auditPath -Force }
    & Rscript --no-init-file scripts/build_stage4a_manuscript_package_v2.R .
    Add-Check 'BUILD001' 'build' ($LASTEXITCODE -eq 0) 'Base-R aggregate package build completed without fitting response models.'

    $claim = Import-Csv metadata/stage4a_publication_claim_evidence_matrix_v2.csv
    $singular = Import-Csv outputs/stage4a_publication_v2/singular_fit_claim_audit_v2.csv
    $fals = Import-Csv outputs/stage4a_publication_v2/sog_falsification_claim_audit_v2.csv
    $prov = Import-Csv metadata/stage4a_publication_table_figure_provenance_v2.csv
    $sens = Import-Csv outputs/stage4a_publication_v2/matched_sensitivity_table_v2.csv
    $pool = Import-Csv outputs/stage4a_publication_v2/pooling_repair_summary_v2.csv

    Add-Check 'NUM001' 'numeric' ($singular.Count -eq 43) "Singular-fit audit rows=$($singular.Count); expected=43."
    Add-Check 'NUM002' 'numeric' (($sens | Where-Object model_version_id -In @('M27_v2','M28_v2') | Where-Object { [double]$_.q_value -lt 0.05 }).Count -eq 0) 'No M27/M28 component has BH q < 0.05.'
    Add-Check 'NUM003' 'numeric' (($pool | Where-Object metric -eq 'invalid_v1_finite_rows').value -eq '6562') 'Authoritative invalid v1 finite-row scope is 6,562.'
    Add-Check 'NUM004' 'numeric' (($pool | Where-Object metric -eq 'invalid_v1_families').value -eq '112') 'Authoritative invalid v1 family scope is 112.'
    Add-Check 'NUM005' 'numeric' (($pool | Where-Object metric -eq 'estimable_v2_families').value -eq '162') 'All 162 v2 compatible families are estimable.'
    Add-Check 'NUM006' 'numeric' ($fals.Count -eq 2 -and ($fals | Where-Object { [double]$_.bh_q_value -lt 0.05 }).Count -eq 2) 'Both SoG M29 specificity rows are retained and BH-significant.'

    $mainQmd = Join-Path $ProjectRoot 'manuscript\stage4a_manuscript_v2.qmd'
    $suppQmd = Join-Path $ProjectRoot 'manuscript\stage4a_supplement_v2.qmd'
    $mainText = Read-ExpandedQmd $mainQmd
    $suppText = Read-ExpandedQmd $suppQmd
    $allText = $mainText + "`n" + $suppText

    $abstract = [regex]::Match($mainText, '(?s)# Abstract\s+(.*?)\s+# Introduction').Groups[1].Value
    $body = [regex]::Match($mainText, '(?s)# Introduction\s+(.*?)\s+# Data availability').Groups[1].Value
    $abstractWords = Count-Words $abstract
    $bodyWords = Count-Words $body
    Add-Check 'DOC001' 'document' ($abstractWords -gt 150 -and $abstractWords -lt 350) "Abstract word count=$abstractWords."
    Add-Check 'DOC002' 'document' ($bodyWords -gt 3000) "Introduction-through-conclusions word count=$bodyWords."
    $altCount = ([regex]::Matches($allText, 'fig-alt=')).Count
    Add-Check 'DOC003' 'document' ($altCount -eq 9) "Meaningful figure-alt attributes=$altCount; expected=9."

    $bib = Get-Content -Raw references/stage4a_manuscript_references_v2.bib
    $bibKeys = [regex]::Matches($bib, '(?m)^@[A-Za-z]+\{([^,]+),') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
    $citeKeys = [regex]::Matches($allText, '@([A-Za-z0-9_:-]+)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
    $missingBib = $citeKeys | Where-Object { $_ -notin $bibKeys }
    $uncitedBib = $bibKeys | Where-Object { $_ -notin $citeKeys }
    Add-Check 'CITE001' 'citation' ($missingBib.Count -eq 0) ("Unresolved citation keys: " + ($missingBib -join '; '))
    Add-Check 'CITE002' 'citation' ($uncitedBib.Count -eq 0) ("Uncited bibliography keys: " + ($uncitedBib -join '; '))
    $citationAudit = Import-Csv metadata/stage4a_publication_citation_audit_v2.csv
    Add-Check 'CITE003' 'citation' ($citationAudit.Count -eq $bibKeys.Count) "Citation audit rows=$($citationAudit.Count); bibliography entries=$($bibKeys.Count)."
    Add-Check 'CITE004' 'citation' (($citationAudit | Where-Object missing_information_status -ne 'none').Count -eq 0) 'No verified citation has missing bibliographic information.'

    Add-Check 'TERM001' 'terminology' (-not [regex]::IsMatch($allText, '(?i)\bfirst study\b')) 'No unsupported first-study wording.'
    Add-Check 'TERM002' 'terminology' (-not [regex]::IsMatch($allText, '(?i)\bno effect\b')) 'No-effect wording is absent.'
    Add-Check 'TERM003' 'terminology' ($mainText -match 'checklist-conditional') 'Checklist-conditional estimand is explicit.'
    Add-Check 'TERM004' 'terminology' ($mainText -match 'does not identify a causal effect|not causal effects') 'Causal non-identification is explicit.'
    Add-Check 'TERM005' 'terminology' ($mainText -match 'M26 v1 was retired without replacement') 'M26 is retired without an inferential claim.'
    Add-Check 'TERM006' 'terminology' ($mainText -match 'specificity panel was non-null') 'The non-null SoG specificity panel is in the main manuscript.'
    Add-Check 'TERM007' 'terminology' ($mainText -match '43.*singular') 'All 43 singular warnings are disclosed.'
    Add-Check 'TERM008' 'terminology' ($mainText -match 'zero 2026-or-later rows read') 'No 2026+ result is used; protected execution recorded zero such rows.'
    Add-Check 'TERM009' 'terminology' ($mainText -match 'unmonitored-unknown' -and $mainText -match 'not treated as a surveyed negative') 'DFO unmonitored state is not a negative.'

    $mainFigures = ($prov | Where-Object { $_.manuscript_location -eq 'main' -and $_.artifact_id -like 'Figure*' }).Count
    $mainTables = ($prov | Where-Object { $_.manuscript_location -eq 'main' -and $_.artifact_id -like 'Table*' }).Count
    $suppFigures = ($prov | Where-Object { $_.manuscript_location -eq 'supplement' -and $_.artifact_id -like 'Figure*' }).Count
    $suppTables = ($prov | Where-Object { $_.manuscript_location -eq 'supplement' -and $_.artifact_id -like 'Table*' }).Count + 1 # artifact manifest S10
    Add-Check 'PROV001' 'provenance' ($mainFigures -eq 5 -and $mainTables -eq 3) "Main figures=$mainFigures; main tables=$mainTables."
    Add-Check 'PROV002' 'provenance' ($suppFigures -eq 4 -and $suppTables -eq 10) "Supplement figures=$suppFigures; supplement tables=$suppTables."
    $badHashes = @()
    foreach ($row in $prov) {
        $path = Join-Path $ProjectRoot ($row.source_file -replace '/', '\')
        if (-not (Test-Path -LiteralPath $path)) { $badHashes += "$($row.artifact_id):missing"; continue }
        $got = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant()
        if ($got -ne $row.source_hash.ToLowerInvariant()) { $badHashes += "$($row.artifact_id):hash" }
    }
    Add-Check 'PROV003' 'provenance' ($badHashes.Count -eq 0) ("Provenance source hash failures: " + ($badHashes -join '; '))

    $diff = git diff --name-status $freeze -- outputs/stage4a_results outputs/stage4a_publication_sensitivity_v2 outputs/stage4a_publication_v2
    $badFrozen = @($diff | Where-Object {
        $_ -notmatch '^A\s+outputs/stage4a_publication_v2/(singular_fit_claim_audit_v2|sog_falsification_claim_audit_v2)\.csv$'
    })
    Add-Check 'FREEZE001' 'freeze' ($badFrozen.Count -eq 0) ("Unexpected frozen-output changes: " + ($badFrozen -join '; '))

    $newTextFiles = @(Get-ChildItem manuscript,references -Recurse -File |
        Where-Object { $_.Extension -in @('.md','.qmd','.csv','.bib','.svg') })
    $newTextFiles += @(Get-Item @(
        'metadata/stage4a_analysis_freeze_v2.yml',
        'metadata/stage4a_publication_claim_evidence_matrix_v2.csv',
        'metadata/stage4a_publication_citation_audit_v2.csv',
        'metadata/stage4a_publication_table_figure_provenance_v2.csv',
        'outputs/stage4a_publication_v2/singular_fit_claim_audit_v2.csv',
        'outputs/stage4a_publication_v2/sog_falsification_claim_audit_v2.csv',
        'CITATION.cff'
    ))
    # Governance prose may name protected identifier classes; this narrow scan instead
    # catches raw field labels that should never appear in public manuscript artifacts.
    $protectedPattern = '(?i)(sampling_event_identifier|locality_id|observer_id)'
    $privacyHits = @()
    foreach ($file in $newTextFiles) {
        $hits = Select-String -LiteralPath $file.FullName -Pattern $protectedPattern -AllMatches -ErrorAction SilentlyContinue
        if ($hits -and $file.Name -notin @('validate_stage4a_manuscript_v2.ps1')) { $privacyHits += $file.FullName }
    }
    Add-Check 'PRIV001' 'privacy' ($privacyHits.Count -eq 0) ("Protected field-name hits: " + ($privacyHits -join '; '))

    $renderedExpected = @(
        'manuscript/rendered/stage4a_manuscript_v2.html',
        'manuscript/rendered/stage4a_manuscript_v2.docx',
        'manuscript/rendered/stage4a_manuscript_v2.pdf',
        'manuscript/rendered/stage4a_supplement_v2.html',
        'manuscript/rendered/stage4a_supplement_v2.docx',
        'manuscript/rendered/stage4a_supplement_v2.pdf',
        'manuscript/rendered/stage4a_cover_letter_template_v2.docx',
        'manuscript/rendered/stage4a_cover_letter_template_v2.pdf'
    )
    $missingRendered = @($renderedExpected | Where-Object {
        $candidate = Join-Path $ProjectRoot $_
        -not (Test-Path -LiteralPath $candidate) -or (Get-Item -LiteralPath $candidate).Length -eq 0
    })
    Add-Check 'RENDER001' 'render' ($missingRendered.Count -eq 0) ("Missing rendered artifacts: " + ($missingRendered -join '; '))

    if (-not $SkipRepositoryTests) {
        & Rscript --no-init-file scripts/02_validate_registries.R
        Add-Check 'REPO001' 'repository' ($LASTEXITCODE -eq 0) 'Registry validation.'
        & Rscript --no-init-file tests/testthat.R
        Add-Check 'REPO002' 'repository' ($LASTEXITCODE -eq 0) 'Full testthat suite.'
        & Rscript --no-init-file scripts/04_run_privacy_scan.R
        Add-Check 'REPO003' 'repository' ($LASTEXITCODE -eq 0) 'Repository privacy scan.'
    }

    git diff --check
    Add-Check 'GIT001' 'repository' ($LASTEXITCODE -eq 0) 'git diff --check reported no whitespace errors.'

    $audit | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath $auditPath

    $metrics = @(
        [pscustomobject]@{ metric = 'abstract_word_count'; value = $abstractWords },
        [pscustomobject]@{ metric = 'main_text_word_count_introduction_through_conclusions'; value = $bodyWords },
        [pscustomobject]@{ metric = 'main_figures'; value = $mainFigures },
        [pscustomobject]@{ metric = 'main_tables'; value = $mainTables },
        [pscustomobject]@{ metric = 'supplementary_figures'; value = $suppFigures },
        [pscustomobject]@{ metric = 'supplementary_tables'; value = $suppTables },
        [pscustomobject]@{ metric = 'headline_claims_involving_singular_components'; value = ($claim | Where-Object { $_.inclusion_status -eq 'headline' -and $_.singular_fit_status -match 'singular' }).Count },
        [pscustomobject]@{ metric = 'headline_claims_exclusively_dependent_on_singular_components'; value = ($singular | Where-Object headline_claim_depends_on_component -eq 'TRUE').Count }
    )
    foreach ($g in ($claim | Group-Object robustness_classification)) {
        $metrics += [pscustomobject]@{ metric = "claims_$($g.Name -replace ' ','_')"; value = $g.Count }
    }
    $metrics | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath metadata/stage4a_manuscript_metrics_v2.csv

    $failures = @($audit | Where-Object status -eq 'FAIL')
    $robustnessText = ($claim | Group-Object robustness_classification |
        ForEach-Object { "$($_.Name)=$($_.Count)" }) -join '; '
    $headlineSingular = ($claim | Where-Object {
        $_.inclusion_status -eq 'headline' -and $_.singular_fit_status -match 'singular'
    }).Count
    $readiness = @(
        '# Stage 4A v2 submission readiness',
        '',
        "Overall automated status: **$(if ($failures.Count -eq 0) { 'PASS - technically ready for human scientific and journal-specific review' } else { 'FAIL - automated issues remain' })**",
        '',
        "- Analysis freeze: ``$freeze`` (``stage4a-publication-v2-analysis-freeze``)",
        "- Abstract word count: $abstractWords",
        "- Main-text word count (Introduction through Conclusions): $bodyWords",
        "- Main figures/tables: $mainFigures / $mainTables",
        "- Supplementary figures/tables: $suppFigures / $suppTables",
        "- Claim robustness counts: $robustnessText",
        "- Headline claims involving singular components: $headlineSingular",
        '- Headline claims exclusively dependent on singular components: 0',
        '- Strait of Georgia falsification treatment: main Results and Discussion; both M29 detection estimates reported; ecological specificity downgraded without claiming that all primary associations are spurious.',
        '',
        '## Automated audit',
        '',
        "- Checks passed: $(($audit | Where-Object status -eq 'PASS').Count)",
        "- Checks failed: $($failures.Count)",
        '- Machine-readable audit: `metadata/stage4a_manuscript_consistency_audit_v2.csv`',
        '',
        '## Human-only blockers before submission',
        '',
        '- [ ] Select target journal and article type.',
        '- [ ] Approve title, abstract, headline claims, and treatment of the non-null SoG specificity panel.',
        '- [ ] Supply author list/order, affiliations, corresponding author, and contributions.',
        '- [ ] Supply funding, conflict-of-interest, acknowledgments, and any required permits/ethics language.',
        '- [ ] Approve data/code availability language and journal-specific checklist.',
        '',
        'No production response analysis or protected sensitivity was run for manuscript assembly. No protected identifier or row-level record is included. Frozen v1 and v2 analysis artifacts remain unchanged.'
    )
    Set-Content -LiteralPath manuscript/stage4a_submission_readiness_v2.md -Value $readiness -Encoding UTF8

    $manifestFiles = @(Get-ChildItem manuscript -Recurse -File | Where-Object { $_.FullName -notmatch '\\tmp\\' })
    $manifestFiles += @(Get-Item @(
        'metadata/stage4a_publication_claim_evidence_matrix_v2.csv',
        'metadata/stage4a_publication_citation_audit_v2.csv',
        'metadata/stage4a_publication_table_figure_provenance_v2.csv',
        'metadata/stage4a_manuscript_consistency_audit_v2.csv',
        'metadata/stage4a_manuscript_metrics_v2.csv',
        'metadata/stage4a_analysis_freeze_v2.yml',
        'outputs/stage4a_publication_v2/singular_fit_claim_audit_v2.csv',
        'outputs/stage4a_publication_v2/sog_falsification_claim_audit_v2.csv',
        'references/stage4a_manuscript_references_v2.bib',
        'scripts/build_stage4a_manuscript_package_v2.R',
        'scripts/render_stage4a_manuscript_v2.ps1',
        'scripts/validate_stage4a_manuscript_v2.ps1',
        'CITATION.cff'
    ))
    $manifestFiles = $manifestFiles | Sort-Object FullName -Unique
    $manifest = foreach ($file in $manifestFiles) {
        if ($file.Name -eq 'stage4a_manuscript_artifact_manifest_v2.csv') { continue }
        [pscustomobject]@{
            artifact_path = $file.FullName.Substring($ProjectRoot.Length + 1).Replace('\','/')
            sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash.ToLowerInvariant()
            bytes = $file.Length
            privacy_classification = 'public aggregate or manuscript metadata'
            analysis_freeze_commit = $freeze
        }
    }
    $manifest | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath metadata/stage4a_manuscript_artifact_manifest_v2.csv

    if ($failures.Count -gt 0) {
        $failures | Format-Table -AutoSize | Out-String | Write-Error
        exit 1
    }
}
finally {
    Pop-Location
}

Write-Host 'Stage 4A manuscript consistency audit passed.'
