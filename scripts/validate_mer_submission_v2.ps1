param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [string]$GenerationCommit = ''
)

$ErrorActionPreference = 'Stop'
$freeze = 'c54b8e7f95a2fe3573e2e38633079cd223c5a783'
$freezeTag = 'stage4a-publication-v2-analysis-freeze'
$packageCommit = '05a07dc2bd754706508a5293d1a496b2db86cc61'
$journalRoot = Join-Path $ProjectRoot 'manuscript\journal_submission\marine_environmental_research'
$sourceDir = Join-Path $journalRoot 'source'
$auditDir = Join-Path $journalRoot 'audits'
$tableDir = Join-Path $journalRoot 'tables'
$renderedDir = Join-Path $journalRoot 'rendered'
$figureDir = Join-Path $journalRoot 'figures'
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
New-Item -ItemType Directory -Force -Path $auditDir | Out-Null
if (-not $GenerationCommit) { $GenerationCommit = (git rev-parse HEAD).Trim() }

function Write-Utf8Lf([string]$Path, [string[]]$Lines) {
    [IO.File]::WriteAllText($Path, (($Lines -join "`n") + "`n"), $script:utf8NoBom)
}
function Export-CsvUtf8Lf([object[]]$Data, [string]$Path) {
    Write-Utf8Lf $Path @($Data | ConvertTo-Csv -NoTypeInformation)
}
function Add-Check([string]$Id, [string]$Category, [bool]$Passed, [string]$Evidence) {
    $script:audit.Add([pscustomobject]@{check_id=$Id; category=$Category; status=$(if($Passed){'PASS'}else{'FAIL'}); evidence=$Evidence})
}
function Expand-Qmd([string]$Path) {
    $text = [IO.File]::ReadAllText($Path)
    $dir = Split-Path $Path -Parent
    $pattern = '\{\{<\s*include\s+([^\s>]+)\s*>\}\}'
    while ([regex]::IsMatch($text,$pattern)) {
        $text = [regex]::Replace($text,$pattern,{param($m) [IO.File]::ReadAllText((Join-Path $dir $m.Groups[1].Value))})
    }
    $text
}
function Count-Words([string]$Text) {
    $clean = [regex]::Replace($Text,'(?s)^---.*?---','')
    $clean = [regex]::Replace($clean,'!\[[^\]]*\]\([^\)]*\)',' ')
    $clean = [regex]::Replace($clean,'\[@[^\]]+\]',' ')
    $clean = [regex]::Replace($clean,'[#*_`|{}\[\]()]',' ')
    ([regex]::Matches($clean,"[A-Za-z0-9]+(?:[-'][A-Za-z0-9]+)*")).Count
}

Push-Location $ProjectRoot
try {
    $audit = [Collections.Generic.List[object]]::new()
    $mainPath = Join-Path $sourceDir 'mer_manuscript_unblinded_v2.qmd'
    $blindPath = Join-Path $sourceDir 'mer_manuscript_blinded_companion_v2.qmd'
    $suppPath = Join-Path $sourceDir 'mer_supplement_v2.qmd'
    $main = Expand-Qmd $mainPath
    $blind = Expand-Qmd $blindPath
    $supp = Expand-Qmd $suppPath
    $all = $main + "`n" + $supp
    $abstract = [regex]::Match($main,'(?s)# Abstract\s+(.*?)\s+# Introduction').Groups[1].Value
    $body = [regex]::Match($main,'(?s)# Introduction\s+(.*?)\s+# Data availability').Groups[1].Value
    $abstractWords = Count-Words $abstract
    $bodyWords = Count-Words $body

    $tagCommit = (git rev-list -n 1 $freezeTag).Trim()
    Add-Check 'FREEZE001' 'freeze' ($tagCommit -eq $freeze) "Tag resolves to $tagCommit; expected $freeze."
    Add-Check 'FREEZE002' 'freeze' ((git cat-file -t $freeze).Trim() -eq 'commit') "Analysis-freeze commit exists: $freeze."
    $frozenDiff = @(git diff --name-status $freeze -- outputs/stage4a_results outputs/stage4a_publication_sensitivity_v2 outputs/stage4a_publication_v2 | Where-Object { $_ -notmatch '^A\s+outputs/stage4a_publication_v2/(singular_fit_claim_audit_v2|sog_falsification_claim_audit_v2)\.csv$' })
    Add-Check 'FREEZE003' 'freeze' ($frozenDiff.Count -eq 0) ('Unexpected frozen artifact changes: ' + ($frozenDiff -join '; '))

    Add-Check 'JOURNAL001' 'journal_limit' ($abstractWords -le 250) "Abstract words=$abstractWords; limit=250."
    Add-Check 'JOURNAL002' 'journal_limit' ($bodyWords -ge 5000 -and $bodyWords -le 10000) "Main-text words=$bodyWords; typical range=5,000-10,000."
    $keywords = [regex]::Match($main,'(?m)^\*\*Keywords:\*\*\s*(.+)$').Groups[1].Value -split ';\s*'
    Add-Check 'JOURNAL003' 'journal_limit' ($keywords.Count -ge 1 -and $keywords.Count -le 7) "Keywords=$($keywords.Count); permitted=1-7."
    $highlightLines = @(Get-Content (Join-Path $sourceDir 'mer_highlights_v2.md') | Where-Object {$_ -match '^- '})
    $maxHighlight = ($highlightLines | ForEach-Object {$_.Substring(2).Length} | Measure-Object -Maximum).Maximum
    Add-Check 'JOURNAL004' 'journal_limit' ($highlightLines.Count -ge 3 -and $highlightLines.Count -le 5 -and $maxHighlight -le 85) "Highlights=$($highlightLines.Count); maximum characters=$maxHighlight."
    Add-Check 'JOURNAL005' 'journal_limit' (([regex]::Matches($main,'(?m)^\*\*Figure [1-5]\.')).Count -eq 5) 'Five main figure captions resolve.'
    Add-Check 'JOURNAL006' 'journal_limit' (([regex]::Matches($main,'(?m)^\*\*Table [1-3]\.')).Count -eq 3) 'Three main table captions resolve.'

    $pool = Import-Csv outputs/stage4a_publication_v2/pooling_repair_summary_v2.csv
    $singular = Import-Csv outputs/stage4a_publication_v2/singular_fit_claim_audit_v2.csv
    $fals = Import-Csv outputs/stage4a_publication_v2/sog_falsification_claim_audit_v2.csv
    $sens = Import-Csv outputs/stage4a_publication_v2/matched_sensitivity_table_v2.csv
    $claim = Import-Csv metadata/stage4a_publication_claim_evidence_matrix_v2.csv
    Add-Check 'NUM001' 'numeric' (($pool|Where-Object metric -eq 'invalid_v1_finite_rows').value -eq '6562') 'Corrected historical scope is 6,562 rows.'
    Add-Check 'NUM002' 'numeric' (($pool|Where-Object metric -eq 'invalid_v1_families').value -eq '112') 'Corrected historical scope is 112 families.'
    Add-Check 'NUM003' 'numeric' (($pool|Where-Object metric -eq 'estimable_v2_families').value -eq '162') 'There are 162 estimable compatible v2 families.'
    Add-Check 'NUM004' 'numeric' (($pool|Where-Object metric -eq 'duplicate_representations_explicit_na').value -eq '439') 'All 439 duplicate M11/M12 representations remain explicit NA.'
    Add-Check 'NUM005' 'numeric' (($pool|Where-Object metric -eq 'noncompleted_rows_explicit_na').value -eq '38') 'All 38 noncompleted rows remain explicit NA.'
    Add-Check 'NUM006' 'numeric' ($singular.Count -eq 43) "Singular warnings=$($singular.Count); expected=43."
    Add-Check 'NUM007' 'numeric' (($sens|Where-Object model_version_id -in @('M27_v2','M28_v2')|Where-Object {[double]$_.q_value -lt .05}).Count -eq 0) 'No M27/M28 component has BH q < 0.05.'
    $gad = $fals | Where-Object species -eq 'Gadwall'
    $sho = $fals | Where-Object species -eq 'Northern Shoveler'
    Add-Check 'NUM008' 'numeric' ([math]::Abs([double]$gad.estimate_log_odds-.234452221260533)-lt 1e-14 -and [math]::Abs([double]$gad.conf_low-.132000178970503)-lt 1e-14 -and [math]::Abs([double]$gad.conf_high-.336904263550563)-lt 1e-14 -and [math]::Abs([double]$gad.bh_q_value-7.28173879611925e-06)-lt 1e-18) 'Gadwall M29 estimate, interval, and BH q match the frozen output.'
    Add-Check 'NUM009' 'numeric' ([math]::Abs([double]$sho.estimate_log_odds-.628286308891756)-lt 1e-14 -and [math]::Abs([double]$sho.conf_low-.527312017924018)-lt 1e-14 -and [math]::Abs([double]$sho.conf_high-.729260599859494)-lt 1e-14 -and [math]::Abs([double]$sho.bh_q_value-6.56228692262959e-34)-lt 1e-45) 'Northern Shoveler M29 estimate, interval, and BH q match the frozen output.'

    $approvedM29 = 'The prespecified Strait of Georgia specificity panel was non-null for Gadwall and Northern Shoveler. This indicates that recorded active-near exposure captured shared seasonal, spatial-access, checklist-submission, site-selection, or exposure-classification structure in addition to any taxon-specific ecological response. The panel therefore limits causal and simple species-specific interpretations, but does not negate the checklist-conditional associations or directly test conditional positive-count responses.'
    $replication = 'Independent replication and structured local monitoring would help distinguish ecological response from residual observation-process and exposure-classification mechanisms.'
    Add-Check 'CLAIM001' 'claim_language' ($main.Contains($approvedM29)) 'Approved M29 interpretation appears verbatim.'
    Add-Check 'CLAIM002' 'claim_language' ($main.Contains($replication)) 'Approved replication sentence appears verbatim.'
    Add-Check 'CLAIM003' 'claim_language' ($main -match 'confirmatory observational evidence') 'Registered core is presented as confirmatory observational evidence.'
    Add-Check 'CLAIM004' 'claim_language' (-not ($main -match 'remain exploratory or estimand-refining pending prospective confirmation')) 'Over-conservative global exploratory wording is absent.'
    Add-Check 'CLAIM005' 'claim_language' ($main -match 'M26 v1 was retired without replacement') 'M26 is not interpreted.'
    Add-Check 'CLAIM006' 'claim_language' ($main -match 'does not identify a causal effect|not a causal effect' -and $main -match 'population abundance, biomass, occupancy, migration') 'Causal and population-level overclaims are excluded.'
    Add-Check 'CLAIM007' 'claim_language' ($main -match 'not treated as a surveyed negative' -and $main -match 'unmonitored-unknown') 'Missing DFO monitoring is not a zero or surveyed negative.'
    Add-Check 'CLAIM008' 'claim_language' ($main -match 'zero 2026-or-later rows read') 'No 2026+ response result appears.'
    Add-Check 'CLAIM009' 'claim_language' ($main -match 'Three headline claims include some singular-warning support' -and $main -match 'no headline claim depends exclusively') 'Singularity is localized to three headline claims and none depends exclusively on it.'

    $bib = [IO.File]::ReadAllText((Join-Path $sourceDir 'mer_references_v2.bib'))
    $bibKeys = @([regex]::Matches($bib,'(?m)^@[A-Za-z]+\{([^,]+),')|ForEach-Object{$_.Groups[1].Value}|Sort-Object -Unique)
    $citeKeys = @([regex]::Matches($all,'(?<![A-Za-z0-9._%+-])@([A-Za-z0-9_:-]+)')|ForEach-Object{$_.Groups[1].Value}|Sort-Object -Unique)
    $missingBib = @($citeKeys|Where-Object{$_ -notin $bibKeys}); $uncitedBib=@($bibKeys|Where-Object{$_ -notin $citeKeys})
    Add-Check 'CITE001' 'citation' ($missingBib.Count -eq 0) ('Unresolved citation keys: '+($missingBib -join '; '))
    Add-Check 'CITE002' 'citation' ($uncitedBib.Count -eq 0) ('Uncited bibliography keys: '+($uncitedBib -join '; '))
    $citationAudit = Import-Csv metadata/stage4a_publication_citation_audit_v2.csv
    Add-Check 'CITE003' 'citation' ($citationAudit.Count -eq $bibKeys.Count -and ($citationAudit|Where-Object missing_information_status -ne 'none').Count -eq 0) "Citation audit rows=$($citationAudit.Count); bibliography entries=$($bibKeys.Count); missing information=0."
    Add-Check 'CITE004' 'citation' ($bib -match 'Mar\. Ecol\. Prog\. Ser\.' -and $bib -match 'Can\. J\. Fish\. Aquat\. Sci\.') 'Journal names use abbreviated forms in the journal-specific bibliography.'

    $expectedRendered = @('mer_manuscript_unblinded_v2.docx','mer_manuscript_unblinded_v2.pdf','mer_manuscript_unblinded_v2.html','mer_manuscript_blinded_companion_v2.docx','mer_manuscript_blinded_companion_v2.pdf','mer_supplement_v2.docx','mer_supplement_v2.pdf','mer_supplement_blinded_companion_v2.docx','mer_supplement_blinded_companion_v2.pdf','mer_title_page_v2.docx','mer_cover_letter_v2.docx','mer_highlights_v2.docx','mer_highlights_v2.txt','mer_author_declarations_v2.docx','mer_abstract_v2.docx','mer_reporting_checklist_v2.docx','mer_response_to_reviewers_template_v2.docx','mer_reviewer_expertise_v2.docx')
    $missingRendered = @($expectedRendered|Where-Object{-not(Test-Path (Join-Path $renderedDir $_)) -or (Get-Item (Join-Path $renderedDir $_)).Length -eq 0})
    Add-Check 'RENDER001' 'render' ($missingRendered.Count -eq 0) ('Missing or empty rendered files: '+($missingRendered -join '; '))
    $visualPath = Join-Path $auditDir 'render_visual_audit_v2.csv'
    $visual = if(Test-Path $visualPath){Import-Csv $visualPath}else{@()}
    Add-Check 'RENDER002' 'render' ($visual.Count -gt 0 -and ($visual|Where-Object status -ne 'PASS').Count -eq 0) "Visual audit rows=$($visual.Count); failures=$(($visual|Where-Object status -ne 'PASS').Count)."

    Add-Type -AssemblyName System.Drawing
    $figRows = foreach($file in Get-ChildItem $figureDir -Filter '*.png'|Sort-Object Name){$img=[Drawing.Image]::FromFile($file.FullName);try{[pscustomobject]@{file=$file.Name;width_px=$img.Width;height_px=$img.Height;minimum_class=$(if($img.Width-ge 3543){'line/full-width capable'}elseif($img.Width-ge 1772){'combination/single-column capable'}else{'below target'});status=$(if($img.Width-ge 1772){'PASS'}else{'FAIL'})}}finally{$img.Dispose()}}
    Add-Check 'FIG001' 'figure' (($figRows|Where-Object status -eq 'FAIL').Count -eq 0) "All nine PNG figures meet at least the 500-dpi single-column pixel target."
    Export-CsvUtf8Lf $figRows (Join-Path $auditDir 'figure_dimensions_v2.csv')

    $protectedPattern = '(?i)(sampling_event_identifier|locality_id|observer_id|event_token)'
    $privacyHits = @()
    foreach($file in Get-ChildItem $journalRoot -Recurse -File|Where-Object{$_.Extension -in @('.md','.qmd','.csv','.bib','.svg','.txt')}){if(Select-String -LiteralPath $file.FullName -Pattern $protectedPattern -Quiet){$privacyHits += $file.FullName.Substring($ProjectRoot.Length+1)}}
    Add-Check 'PRIV001' 'privacy' ($privacyHits.Count -eq 0) ('Protected field-name hits: '+($privacyHits -join '; '))
    $blindIdentity = @('Jacob T. Dingwall','dingwalljake@gmail.com','University of Victoria','JTDingwall')|Where-Object{$blind -match [regex]::Escape($_)}
    Add-Check 'BLIND001' 'anonymization' ($blindIdentity.Count -eq 0) ('Identity strings in blinded manuscript: '+($blindIdentity -join '; '))

    git diff --check | Out-Null
    Add-Check 'GIT001' 'repository' ($LASTEXITCODE -eq 0) 'git diff --check passed.'

    $classCounts = @{}; foreach($g in $claim|Group-Object classification){$classCounts[$g.Name]=$g.Count}
    $metrics = @(
        [pscustomobject]@{metric='abstract_word_count';value=$abstractWords},[pscustomobject]@{metric='abstract_limit';value=250},
        [pscustomobject]@{metric='main_text_word_count';value=$bodyWords},[pscustomobject]@{metric='main_text_typical_minimum';value=5000},[pscustomobject]@{metric='main_text_typical_maximum';value=10000},
        [pscustomobject]@{metric='main_figures';value=5},[pscustomobject]@{metric='main_tables';value=3},[pscustomobject]@{metric='supplement_figures';value=4},[pscustomobject]@{metric='supplement_tables';value=10},
        [pscustomobject]@{metric='confirmatory_claims';value=$classCounts['confirmatory']},[pscustomobject]@{metric='secondary_claims';value=$classCounts['secondary']},[pscustomobject]@{metric='exploratory_claims';value=0},
        [pscustomobject]@{metric='methodological_claims';value=$classCounts['methodological']},[pscustomobject]@{metric='limitation_claims';value=$classCounts['limitation']},
        [pscustomobject]@{metric='wording_changes';value=(Import-Csv (Join-Path $journalRoot 'claim_language_change_log_v2.csv')).Count},
        [pscustomobject]@{metric='headline_claims_with_singular_support';value=3},[pscustomobject]@{metric='headline_claims_exclusively_singular';value=0}
    )
    Export-CsvUtf8Lf $metrics (Join-Path $auditDir 'journal_metrics_v2.csv')

    $journalCitation = foreach($row in $citationAudit){$journalName='';if($bib -match ('(?s)@[^{]+\{'+[regex]::Escape($row.citation_key)+',.*?journal\s*=\s*\{([^}]+)\}')){$journalName=$Matches[1]};[pscustomobject]@{citation_key=$row.citation_key;doi_or_stable_identifier=$row.doi_or_stable_identifier;source_type=$row.source_type;identity_verification=$row.verification_status;journal_abbreviation=$journalName;in_text_resolved=($row.citation_key -in $citeKeys);cited_and_listed=($row.citation_key -in $citeKeys -and $row.citation_key -in $bibKeys);audit_date='2026-07-22'}}
    Export-CsvUtf8Lf $journalCitation (Join-Path $auditDir 'citation_audit_v2.csv')
    Copy-Item outputs/stage4a_publication_v2/sog_falsification_claim_audit_v2.csv (Join-Path $auditDir 'sog_m29_audit_v2.csv') -Force

    $baseProv = Import-Csv metadata/stage4a_publication_table_figure_provenance_v2.csv
    $prov = foreach($row in $baseProv){$out = if($row.artifact_id -like 'Figure*'){Join-Path $figureDir (($row.artifact_id -replace ' ','_')+'.png')}elseif($row.manuscript_location -eq 'main'){Join-Path $tableDir (($row.artifact_id -replace ' ','_')+'.csv')}else{Join-Path $tableDir (($row.artifact_id -replace ' ','_')+'.csv')};[pscustomobject]@{artifact_id=$row.artifact_id;manuscript_location=$row.manuscript_location;journal_output_path=$(if(Test-Path $out){$out.Substring($ProjectRoot.Length+1).Replace('\','/')}else{'embedded_or_not_applicable'});journal_output_hash=$(if(Test-Path $out){(Get-FileHash $out -Algorithm SHA256).Hash.ToLowerInvariant()}else{''});source_file=$row.source_file;source_hash=$row.source_hash;generation_script=$row.generation_script;journal_render_script='scripts/render_mer_submission_v2.ps1';generation_commit=$GenerationCommit;filters=$row.filters;model_or_family_ids=$row.model_or_family_ids;caption=$row.caption;privacy_classification=$row.privacy_classification}}
    Export-CsvUtf8Lf $prov (Join-Path $auditDir 'figure_table_provenance_v2.csv')

    Export-CsvUtf8Lf @($audit) (Join-Path $auditDir 'journal_consistency_audit_v2.csv')
    $files = @(Get-ChildItem $journalRoot -Recurse -File|Where-Object{$_.FullName -notmatch '\\audits\\journal_artifact_manifest_v2\.csv$' -and $_.FullName -notmatch '\\tables\\Table_S10\.csv$'}|Sort-Object FullName)
    $manifest = foreach($file in $files){[pscustomobject]@{artifact_path=$file.FullName.Substring($ProjectRoot.Length+1).Replace('\','/');sha256=(Get-FileHash $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant();bytes=$file.Length;generation_commit=$GenerationCommit}}
    Export-CsvUtf8Lf $manifest (Join-Path $auditDir 'journal_artifact_manifest_v2.csv')
    Copy-Item (Join-Path $auditDir 'journal_artifact_manifest_v2.csv') (Join-Path $tableDir 'Table_S10.csv') -Force
    $inventory = foreach($file in Get-ChildItem $renderedDir -File|Sort-Object Name){[pscustomobject]@{file=$file.Name;format=$file.Extension.TrimStart('.').ToUpperInvariant();purpose=$(if($file.Name -match 'blinded'){if($file.Name -match 'supplement'){'optional blinded supplement companion'}else{'optional blinded manuscript companion'}}elseif($file.Name -match '^mer_manuscript_unblinded'){'official unblinded manuscript'}elseif($file.Name -match '^mer_supplement_v2'){'official supplement'}elseif($file.Name -match 'title_page'){'separate title page'}elseif($file.Name -match 'cover_letter'){'cover letter'}elseif($file.Name -match 'highlights'){'required highlights'}else{'submission support document'});required_or_optional=$(if($file.Name -match 'blinded|reviewer_expertise|response_to_reviewers|reporting_checklist|\.pdf$|\.html$'){'support/optional'}else{'submission file'});sha256=(Get-FileHash $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant();bytes=$file.Length}}
    Export-CsvUtf8Lf $inventory (Join-Path $auditDir 'submission_file_inventory_v2.csv')

    $failures=@($audit|Where-Object status -eq 'FAIL')
    $readiness=@('# Marine Environmental Research submission-readiness report','',"Automated status: **$(if($failures.Count-eq 0){'PASS'}else{'FAIL'})**","","- Official requirements accessed: 2026-07-22","- Article type: Full-length Article","- Abstract: $abstractWords / 250 words","- Main text: $bodyWords / typical 5,000-10,000 words","- Main figures/tables: 5 / 3","- Supplement figures/tables: 4 / 10","- Claim classifications: confirmatory=$($classCounts['confirmatory']); secondary=$($classCounts['secondary']); exploratory=0; methodological=$($classCounts['methodological']); limitation=$($classCounts['limitation'])","- Checks passed: $(($audit|Where-Object status -eq 'PASS').Count)","- Checks failed: $($failures.Count)",'','## Human fields still required','','- Full postal address for the University of Victoria affiliation and corresponding author.','- Corresponding-author telephone number requested by the submission checklist.','- Human confirmation of the drafted generative-AI disclosure after final review.','- Human confirmation of originality/exclusive submission and current preprint status in the cover letter.','','No production response model or protected sensitivity was rerun. No analysis estimate changed. No protected record-level identifier was exposed. Frozen v1 and v2 analysis artifacts remain unchanged.')
    Write-Utf8Lf (Join-Path $journalRoot 'submission_readiness_v2.md') $readiness
    if($failures.Count -gt 0){throw "Journal validation failed: $($failures.Count) check(s)."}
    Write-Host "MER validation PASS: $($audit.Count) checks; abstract=$abstractWords; main=$bodyWords."
}
finally { Pop-Location }
