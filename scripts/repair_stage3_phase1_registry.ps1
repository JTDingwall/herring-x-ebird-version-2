param(
  [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

function Write-Sha256Sidecar {
  param(
    [string]$RelativePath,
    [string]$SidecarRelativePath = "$RelativePath.sha256"
  )
  $full = Join-Path $RepoRoot $RelativePath
  $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $full).Hash.ToLowerInvariant()
  $sidecar = Join-Path $RepoRoot $SidecarRelativePath
  [IO.File]::WriteAllText($sidecar, "$hash  $RelativePath`n", [Text.UTF8Encoding]::new($false))
}

function Write-CsvLf {
  param(
    [object[]]$Rows,
    [string]$Path
  )
  $lines = @($Rows | ConvertTo-Csv -NoTypeInformation)
  [IO.File]::WriteAllText(
    $Path,
    ([string]::Join("`n", $lines) + "`n"),
    [Text.UTF8Encoding]::new($false)
  )
}

$registryPath = Join-Path $RepoRoot 'metadata/canonical_species_registry.csv'
$crosswalkPath = Join-Path $RepoRoot 'metadata/source_taxonomy_crosswalk.csv'
$ambiguityPath = Join-Path $RepoRoot 'metadata/ambiguous_taxon_rules.csv'
$supportPath = Join-Path $RepoRoot 'outputs/stage2_design_lock/species_support_summary.csv'
$taxonomyPath = Join-Path $RepoRoot 'outputs/stage2_design_lock/species_taxonomy_reconciliation.csv'
$auditDirectory = Join-Path $RepoRoot 'outputs/stage3_phase1_repair'
$auditPath = Join-Path $auditDirectory 'registry_reconciliation_audit.csv'

$registry = @(Import-Csv -LiteralPath $registryPath)
$crosswalk = [Collections.Generic.List[object]]@(Import-Csv -LiteralPath $crosswalkPath)
$ambiguity = @(Import-Csv -LiteralPath $ambiguityPath)
$support = @(Import-Csv -LiteralPath $supportPath)
$taxonomy = @(Import-Csv -LiteralPath $taxonomyPath)

if ($registry.Count -ne 58 -or $support.Count -ne 58 -or $taxonomy.Count -ne 58) {
  throw 'Frozen taxon cardinality is not 58 in all controlling Stage 2 sources'
}
if (@($registry.analysis_taxon_id | Group-Object | Where-Object Count -ne 1).Count -ne 0 -or
    @($support.analysis_taxon_id | Group-Object | Where-Object Count -ne 1).Count -ne 0 -or
    @($taxonomy.analysis_taxon_id | Group-Object | Where-Object Count -ne 1).Count -ne 0) {
  throw 'Taxon keys are not unique in a controlling registry'
}

$supportByTaxon = @{}
$taxonomyByTaxon = @{}
foreach ($row in $support) { $supportByTaxon[$row.analysis_taxon_id] = $row }
foreach ($row in $taxonomy) { $taxonomyByTaxon[$row.analysis_taxon_id] = $row }

$snapshotVersions = @($taxonomy.taxonomy_version | Sort-Object -Unique)
$snapshotHashes = @($crosswalk.taxonomy_snapshot_sha256 | Where-Object { $_ } | Sort-Object -Unique)
if ($snapshotVersions.Count -ne 1 -or $snapshotHashes.Count -ne 1) {
  throw 'Frozen taxonomy version or snapshot hash is not singular'
}
$snapshotVersion = $snapshotVersions[0]
$snapshotHash = $snapshotHashes[0]

foreach ($taxon in $registry) {
  if (-not $supportByTaxon.ContainsKey($taxon.analysis_taxon_id) -or
      -not $taxonomyByTaxon.ContainsKey($taxon.analysis_taxon_id)) {
    throw "Frozen Stage 2 disposition is missing for $($taxon.analysis_taxon_id)"
  }
  $frozenTaxonomy = $taxonomyByTaxon[$taxon.analysis_taxon_id]
  if ($frozenTaxonomy.exact_species_concept_reconciled -ne 'TRUE' -or
      $frozenTaxonomy.recommended_taxonomy_disposition -ne 'approve_exact_v2025_species_concept' -or
      $frozenTaxonomy.observed_categories -ne 'species' -or
      $frozenTaxonomy.observed_common_names -ne $taxon.common_name -or
      $frozenTaxonomy.observed_scientific_names -ne $taxon.scientific_name -or
      [string]::IsNullOrWhiteSpace($frozenTaxonomy.observed_taxon_concept_ids)) {
    throw "Exact frozen taxonomy mapping failed for $($taxon.analysis_taxon_id)"
  }

  $wasStale = $taxon.approval_status -ne 'provisional_design'
  $taxon.source_taxon_concept_ids = $frozenTaxonomy.observed_taxon_concept_ids
  if ($wasStale) {
    $taxon.support_status = 'frozen_stage2_disposition_available'
    $taxon.approval_status = 'frozen_stage2_retained'
  }
  $taxon | Add-Member -NotePropertyName phase1_denominator_included -NotePropertyValue 'TRUE' -Force
  $taxon | Add-Member -NotePropertyName phase1_denominator_inclusion_basis -NotePropertyValue 'frozen_stage2_retained_taxon' -Force
  $taxon | Add-Member -NotePropertyName phase1_denominator_registry_version -NotePropertyValue 'stage3_phase1_repair_v2' -Force

  $concept = $frozenTaxonomy.observed_taxon_concept_ids
  $matches = @($crosswalk | Where-Object source_taxon_id -eq $concept)
  if ($matches.Count -gt 1) {
    throw "Source concept is duplicated in the taxonomy crosswalk: $concept"
  }
  if ($matches.Count -eq 0) {
    $template = [ordered]@{}
    foreach ($name in $crosswalk[0].PSObject.Properties.Name) { $template[$name] = '' }
    $mapping = [pscustomobject]$template
    $crosswalk.Add($mapping)
  } else {
    $mapping = $matches[0]
  }
  if ($wasStale -or $matches.Count -eq 0) {
    $mapping.parent_candidate_name = $taxon.common_name
    $mapping.analysis_taxon_id = $taxon.analysis_taxon_id
    $mapping.analysis_taxon_key = $taxon.common_name.ToLowerInvariant().Replace(' ', '_').Replace("'", '')
    $mapping.proposed_role = 'frozen_stage2_retained_taxon'
    $mapping.source_taxon_id = $concept
    $mapping.source_category = 'species'
    $mapping.source_common_name = $taxon.common_name
    $mapping.source_scientific_name = $taxon.scientific_name
    $mapping.ebird_taxon_code = $taxon.ebird_taxon_code
    $mapping.official_category = 'species'
    $mapping.official_common_name = $taxon.common_name
    $mapping.official_scientific_name = $taxon.scientific_name
    $mapping.effective_source_common_name = $taxon.common_name
    $mapping.effective_source_scientific_name = $taxon.scientific_name
    $mapping.official_match = 'TRUE'
    $mapping.name_match = 'TRUE'
    $mapping.category_match = 'TRUE'
    $mapping.mapping_treatment = 'candidate_identity'
    $mapping.historical_taxonomy_review = 'TRUE'
    $mapping.zero_fill_eligible_candidate = 'TRUE'
    $mapping.review_stratum = 'frozen_stage2_exact_species_concept'
    $mapping.taxonomy_snapshot_version = $snapshotVersion
    $mapping.taxonomy_snapshot_sha256 = $snapshotHash
    $mapping.approval_status = 'approved'
    $mapping.ambiguity_flag = 'FALSE'
    $mapping.zero_fill_mapping_eligible = 'TRUE'
    $mapping.final_mapping_decision = 'approve_exact_v2025_species_concept'
    $mapping.approved_taxonomy_version = $snapshotVersion
  } elseif ($mapping.analysis_taxon_id -ne $taxon.analysis_taxon_id -or
            $mapping.mapping_treatment -ne 'candidate_identity' -or
            $mapping.approval_status -ne 'approved' -or
            $mapping.source_category -ne 'species' -or
            $mapping.source_common_name -ne $taxon.common_name -or
            $mapping.source_scientific_name -ne $taxon.scientific_name) {
    throw "Existing approved identity mapping is inconsistent for $($taxon.analysis_taxon_id)"
  }
}

$included = @($registry | Where-Object phase1_denominator_included -eq 'TRUE')
$includedIds = @($included.analysis_taxon_id)
if ($included.Count -ne 58) { throw 'Repaired denominator registry does not retain 58 taxa' }
if (@($ambiguity | Where-Object { $_.affected_analysis_taxon_id -notin $includedIds }).Count -ne 0) {
  throw 'An ambiguity rule points outside the repaired denominator registry'
}

$approvedIdentity = @($crosswalk | Where-Object {
  $_.approval_status -eq 'approved' -and $_.mapping_treatment -eq 'candidate_identity'
})
foreach ($taxon in $included) {
  $identity = @($approvedIdentity | Where-Object analysis_taxon_id -eq $taxon.analysis_taxon_id)
  if ($identity.Count -ne 1 -or $identity[0].source_taxon_id -ne $taxon.source_taxon_concept_ids) {
    throw "Repaired identity mapping is not one-to-one for $($taxon.analysis_taxon_id)"
  }
}

Write-CsvLf $registry $registryPath
Write-CsvLf $crosswalk $crosswalkPath

New-Item -ItemType Directory -Path $auditDirectory -Force | Out-Null
$audit = foreach ($taxon in ($registry | Sort-Object analysis_taxon_id)) {
  $frozenSupport = $supportByTaxon[$taxon.analysis_taxon_id]
  $frozenTaxonomy = $taxonomyByTaxon[$taxon.analysis_taxon_id]
  $identity = @($crosswalk | Where-Object {
    $_.approval_status -eq 'approved' -and $_.mapping_treatment -eq 'candidate_identity' -and
    $_.analysis_taxon_id -eq $taxon.analysis_taxon_id
  })
  $masks = @($ambiguity | Where-Object {
    $_.affected_analysis_taxon_id -eq $taxon.analysis_taxon_id -and
    $_.approval_status -eq 'approved' -and $_.production_zero_mask_eligible -eq 'TRUE'
  })
  [pscustomobject][ordered]@{
    analysis_taxon_id = $taxon.analysis_taxon_id
    common_name = $taxon.common_name
    scientific_name = $taxon.scientific_name
    ebird_taxon_code = $taxon.ebird_taxon_code
    taxonomy_version = $taxon.taxonomy_version
    exact_species_concept_reconciled = $frozenTaxonomy.exact_species_concept_reconciled
    frozen_taxonomy_disposition = $frozenTaxonomy.recommended_taxonomy_disposition
    frozen_named_disposition = $frozenSupport.named_species_recommendation
    frozen_guild_disposition = $frozenSupport.guild_recommendation
    frozen_community_disposition = $frozenSupport.community_recommendation
    frozen_count_disposition = $frozenSupport.count_recommendation
    denominator_included = $taxon.phase1_denominator_included
    denominator_inclusion_basis = $taxon.phase1_denominator_inclusion_basis
    registry_approval_status = $taxon.approval_status
    source_taxon_concept_id = $identity[0].source_taxon_id
    source_category = $identity[0].source_category
    source_common_name = $identity[0].source_common_name
    source_scientific_name = $identity[0].source_scientific_name
    source_mapping_treatment = $identity[0].mapping_treatment
    source_mapping_decision = $identity[0].final_mapping_decision
    production_ambiguity_mask_rules = $masks.Count
  }
}
Write-CsvLf $audit $auditPath

Write-Sha256Sidecar 'metadata/canonical_species_registry.csv'
Write-Sha256Sidecar 'metadata/source_taxonomy_crosswalk.csv'
Write-Sha256Sidecar 'metadata/ambiguous_taxon_rules.csv'
Write-Sha256Sidecar 'outputs/stage2_design_lock/species_support_summary.csv'
Write-Sha256Sidecar 'outputs/stage2_design_lock/species_taxonomy_reconciliation.csv'
Write-Sha256Sidecar 'outputs/stage3_phase1_repair/registry_reconciliation_audit.csv'
Write-Sha256Sidecar 'metadata/stage3_phase1_denominator_repair_v2.yml' 'metadata/stage3_phase1_denominator_repair_v2.sha256'
if (Test-Path (Join-Path $RepoRoot 'metadata/stage3_phase1_execution_v2.yml')) {
  Write-Sha256Sidecar 'metadata/stage3_phase1_execution_v2.yml' 'metadata/stage3_phase1_execution_v2.sha256'
}
Write-Sha256Sidecar 'metadata/stage3_phase1_artifact_history.csv'

Write-Output 'Stage 3 Phase 1 registry repair: 58 exact frozen taxa reconciled.'
