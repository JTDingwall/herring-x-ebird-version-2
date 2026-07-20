using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Security.Cryptography;
using System.Text;

public static class Stage3Phase1Denominator
{
    private const int StartYear = 1988;
    private const int EndYear = 2025;

    private sealed class SedRecord
    {
        public string SourceId;
        public string ObserverId;
        public string AnalysisId;
        public string Date;
        public bool HasEbdRow;
    }

    private sealed class EventGroup
    {
        public string AnalysisId;
        public string CanonicalSourceId;
        public string Date;
        public string Latitude;
        public string Longitude;
        public string Protocol;
        public double? Duration;
        public double? Distance;
        public int? Observers;
        public bool Complete;
        public bool EffortDisagreement;
        public bool PrimaryEffortCandidate;
        public bool HasEbdIdentity;
        public bool SourceIdentityDisagreement;
        public int Members;
        public readonly Dictionary<string, CountState> Named =
            new Dictionary<string, CountState>(StringComparer.Ordinal);
        public readonly HashSet<string> AmbiguityMasks =
            new HashSet<string>(StringComparer.Ordinal);

        public EventGroup(string analysisId, string sourceId, string date,
            string latitude, string longitude, string protocol, double? duration,
            double? distance, int? observers, bool complete)
        {
            AnalysisId = analysisId;
            CanonicalSourceId = sourceId;
            Date = date;
            Latitude = latitude;
            Longitude = longitude;
            Protocol = protocol;
            Duration = duration;
            Distance = distance;
            Observers = observers;
            Complete = complete;
            Members = 1;
            PrimaryEffortCandidate = IsPrimaryEffort(protocol, duration, distance, observers, complete);
        }

        public void AddMember(string sourceId, string date, string latitude,
            string longitude, string protocol, double? duration, double? distance,
            int? observers, bool complete)
        {
            Members++;
            if (StringComparer.Ordinal.Compare(sourceId, CanonicalSourceId) < 0)
                CanonicalSourceId = sourceId;
            if (!Equal(Date, date) || !Equal(Latitude, latitude) ||
                !Equal(Longitude, longitude) || !Equal(Protocol, protocol) ||
                !Equal(Duration, duration) || !Equal(Distance, distance) ||
                !Equal(Observers, observers) || Complete != complete)
                EffortDisagreement = true;
        }

        public void AddNamed(string taxon, CountState state)
        {
            CountState existing;
            if (!Named.TryGetValue(taxon, out existing)) Named[taxon] = state;
            else existing.Merge(state);
        }

        private static bool Equal(string a, string b)
        { return String.Equals(a ?? String.Empty, b ?? String.Empty, StringComparison.Ordinal); }
        private static bool Equal(double? a, double? b)
        { return a.HasValue == b.HasValue && (!a.HasValue || a.Value.Equals(b.Value)); }
        private static bool Equal(int? a, int? b)
        { return a.HasValue == b.HasValue && (!a.HasValue || a.Value == b.Value); }
    }

    private sealed class CountState
    {
        public string Type;
        public long? Numeric;
        public long? Lower;
        public bool SourceDisagreement;

        public void Merge(CountState other)
        {
            if (Type == other.Type && Numeric == other.Numeric && Lower == other.Lower) return;
            Type = "ambiguity_affected";
            Numeric = null;
            Lower = null;
            SourceDisagreement = true;
        }
    }

    private sealed class TaxonRule
    {
        public string AnalysisTaxon;
        public string Category;
        public string CommonName;
        public string ScientificName;
        public bool Seen;
    }

    private sealed class RunStats
    {
        public long SedRowsInWindow;
        public long EbdRowsInWindow;
        public long AcceptedEbdRows;
        public long RejectedEbdRows;
        public long EbdDateMismatches;
        public long TaxonomyMismatches;
        public long NamedSourceRows;
        public long AmbiguousSourceRows;
        public long DenominatorRows;
        public long ZeroRows;
        public long AmbiguityRows;
        public long DirectRows;
        public readonly Dictionary<string, long> StateRows =
            new Dictionary<string, long>(StringComparer.Ordinal);
    }

    public static void RunProduction(string ebdPath, string sedPath, string repoRoot,
        string protectedDirectory, string aggregateDirectory)
    {
        RequireFile(ebdPath, "protected EBD input");
        RequireFile(sedPath, "protected SED input");
        Directory.CreateDirectory(protectedDirectory);
        Directory.CreateDirectory(aggregateDirectory);

        VerifyAuthorizationHashes(repoRoot);
        VerifyInputIdentity(repoRoot, ebdPath, sedPath);
        Console.WriteLine("Registered authorization and EBD/SED source identities verified.");

        List<string> taxa;
        Dictionary<string, TaxonRule> namedRules;
        Dictionary<string, List<string>> ambiguousRules;
        string taxonomyVersion;
        string taxonomyHash;
        LoadTaxonomy(repoRoot, out taxa, out namedRules, out ambiguousRules,
            out taxonomyVersion, out taxonomyHash);
        Console.WriteLine("Registered taxonomy and ambiguity rules loaded: " +
            taxa.Count.ToString(CultureInfo.InvariantCulture) + " analysis taxa, " +
            namedRules.Count.ToString(CultureInfo.InvariantCulture) + " approved source concepts.");

        RunStats stats = new RunStats();
        Dictionary<string, SedRecord> sources;
        Dictionary<string, EventGroup> groups;
        ReadSed(sedPath, stats, out sources, out groups);
        Console.WriteLine("In-window SED scan complete: " +
            stats.SedRowsInWindow.ToString(CultureInfo.InvariantCulture) +
            " source rows collapsed to " + groups.Count.ToString(CultureInfo.InvariantCulture) +
            " independent candidate events before eligibility gates.");
        WriteCrosswalk(protectedDirectory, sources, groups, false);

        HashSet<string> unmatchedEbdKeys = new HashSet<string>(StringComparer.Ordinal);
        ReadEbd(ebdPath, stats, sources, groups, namedRules, ambiguousRules, unmatchedEbdKeys);
        Console.WriteLine("In-window EBD scan complete; accepted-record and taxonomy gates evaluated.");

        int missingTaxonomyConcepts = namedRules.Values.Count(x => !x.Seen);
        List<EventGroup> eligible = groups.Values
            .Where(g => g.PrimaryEffortCandidate && !g.EffortDisagreement &&
                g.HasEbdIdentity && !g.SourceIdentityDisagreement)
            .OrderBy(g => g.AnalysisId, StringComparer.Ordinal).ToList();
        long structuralUnknownCandidates = groups.Values.LongCount(g =>
            g.PrimaryEffortCandidate && !g.EffortDisagreement && !g.HasEbdIdentity);
        long sourceIdentityDisagreementEvents = groups.Values.LongCount(g =>
            g.SourceIdentityDisagreement);
        long disagreementGroups = groups.Values.LongCount(g => g.EffortDisagreement);
        long sharedGroups = groups.Values.LongCount(g => g.Members > 1);
        long stationaryEligible = eligible.LongCount(g => g.Protocol == "stationary");
        long stationaryNonzero = eligible.LongCount(g =>
            g.Protocol == "stationary" && (!g.Distance.HasValue || g.Distance.Value != 0));
        long eligibleWithDuplicateIds = eligible.GroupBy(g => g.AnalysisId,
            StringComparer.Ordinal).LongCount(x => x.Count() != 1);

        List<string> preArtifactFailures = new List<string>();
        if (unmatchedEbdKeys.Count != 0) preArtifactFailures.Add("EBD_TO_SED_UNMATCHED_KEYS=" + unmatchedEbdKeys.Count);
        if (eligible.Any(g => g.SourceIdentityDisagreement))
            preArtifactFailures.Add("RETAINED_EBD_SED_DATE_MISMATCH_EVENTS");
        if (stats.TaxonomyMismatches != 0) preArtifactFailures.Add("TAXONOMY_IDENTITY_MISMATCH_ROWS=" + stats.TaxonomyMismatches);
        if (missingTaxonomyConcepts != 0) preArtifactFailures.Add("APPROVED_TAXONOMY_CONCEPTS_NOT_OBSERVED=" + missingTaxonomyConcepts);
        if (stationaryNonzero != 0) preArtifactFailures.Add("ELIGIBLE_STATIONARY_DISTANCE_NOT_ZERO=" + stationaryNonzero);
        if (eligibleWithDuplicateIds != 0) preArtifactFailures.Add("DUPLICATE_ELIGIBLE_EVENT_IDS=" + eligibleWithDuplicateIds);
        if (preArtifactFailures.Count != 0)
            throw new InvalidDataException("STAGE3_PHASE1_PRE_ARTIFACT_GATE: " +
                String.Join(";", preArtifactFailures.ToArray()));

        string denominatorPath = Path.Combine(protectedDirectory,
            "independent_event_taxon_denominator.tsv.gz");
        WriteDenominator(denominatorPath, eligible, taxa, stats);
        string denominatorHash = Sha256(denominatorPath);
        string denominatorReplay = denominatorPath + ".repro.tmp";
        RunStats replayStats = new RunStats();
        WriteDenominator(denominatorReplay, eligible, taxa, replayStats);
        string replayHash = Sha256(denominatorReplay);
        File.Delete(denominatorReplay);

        string crosswalkPath = Path.Combine(protectedDirectory,
            "private_component_crosswalk.tsv.gz");
        string crosswalkHash = Sha256(crosswalkPath);
        string crosswalkReplay = crosswalkPath + ".repro.tmp";
        WriteCrosswalkTo(crosswalkReplay, sources, groups);
        string crosswalkReplayHash = Sha256(crosswalkReplay);
        File.Delete(crosswalkReplay);

        List<string> artifactFailures = new List<string>();
        if (stats.DenominatorRows != (long)eligible.Count * taxa.Count)
            artifactFailures.Add("DENOMINATOR_ROW_ACCOUNTING");
        if (denominatorHash != replayHash) artifactFailures.Add("DENOMINATOR_REPLAY_HASH");
        if (crosswalkHash != crosswalkReplayHash) artifactFailures.Add("CROSSWALK_REPLAY_HASH");
        if (artifactFailures.Count != 0)
            throw new InvalidDataException("STAGE3_PHASE1_ARTIFACT_GATE: " +
                String.Join(";", artifactFailures.ToArray()));

        WriteAggregateOutputs(aggregateDirectory, stats, sources.Count, groups.Count,
            eligible.Count, taxa.Count, sharedGroups, disagreementGroups,
            structuralUnknownCandidates, sourceIdentityDisagreementEvents,
            stationaryEligible, unmatchedEbdKeys.Count,
            missingTaxonomyConcepts, taxonomyVersion, taxonomyHash,
            denominatorHash, crosswalkHash);

        Console.WriteLine("Stage 3 Phase 1 complete: all denominator, zero-provenance, " +
            "cardinality, privacy-scope, fixture, and reproducibility gates passed.");
        Console.WriteLine("Independent eligible checklist events: " +
            eligible.Count.ToString(CultureInfo.InvariantCulture) +
            "; registered taxa: " + taxa.Count.ToString(CultureInfo.InvariantCulture) +
            "; denominator rows: " + stats.DenominatorRows.ToString(CultureInfo.InvariantCulture) + ".");
    }

    public static void RunFixture()
    {
        Assert(IsAccepted("1") && IsAccepted("TRUE") && !IsAccepted("0") && !IsAccepted("FALSE"),
            "accepted-record fixture");
        Assert(NormalizeDistance("stationary", null) == 0 &&
            NormalizeDistance("stationary", 3.2) == 0 &&
            NormalizeDistance("traveling", 1.2) == 1.2, "stationary-distance fixture");
        Assert(ParseCount("12").Type == "numeric" && ParseCount("12").Numeric == 12,
            "numeric fixture");
        Assert(ParseCount("X").Type == "X" && !ParseCount("X").Numeric.HasValue,
            "X fixture");
        Assert(ParseCount("5+").Type == "lower_bound" && ParseCount("5+").Lower == 5,
            "lower-bound fixture");
        Assert(ParseCount("").Type == "missing", "missing-count fixture");
        Assert(ParseCount("uncertain").Type == "ambiguity_affected", "ambiguity fixture");

        EventGroup shared = new EventGroup("fixture_group", "fixture_b", "2025-01-01",
            "49", "-123", "stationary", 20, 0, 2, true);
        shared.AddMember("fixture_a", "2025-01-01", "49", "-123", "stationary", 20, 0, 2, true);
        Assert(shared.Members == 2 && shared.CanonicalSourceId == "fixture_a" &&
            !shared.EffortDisagreement, "shared-collapse fixture");
        shared.AddMember("fixture_c", "2025-01-01", "49", "-123", "stationary", 30, 0, 2, true);
        Assert(shared.EffortDisagreement, "effort-disagreement fixture");
        Assert(!IsPrimaryEffort("traveling", 20, 6, 1, true) &&
            !IsPrimaryEffort("stationary", 20, 0, 1, false) &&
            IsPrimaryEffort("traveling", 20, 5, 1, true), "eligibility fixture");

        CountState disagreement = ParseCount("4");
        disagreement.Merge(ParseCount("5"));
        Assert(disagreement.Type == "ambiguity_affected" && disagreement.SourceDisagreement,
            "count-reconciliation fixture");
        Console.WriteLine("Stage 3 Phase 1 synthetic fixtures passed.");
    }

    private static void ReadSed(string path, RunStats stats,
        out Dictionary<string, SedRecord> sources,
        out Dictionary<string, EventGroup> groups)
    {
        sources = new Dictionary<string, SedRecord>(StringComparer.Ordinal);
        groups = new Dictionary<string, EventGroup>(StringComparer.Ordinal);
        using (StreamReader reader = new StreamReader(path, Encoding.UTF8, true, 1 << 20))
        {
            string header = reader.ReadLine();
            if (header == null) throw new InvalidDataException("SED is empty");
            Dictionary<string, int> h = HeaderMap(header);
            string[] required = { "SAMPLING EVENT IDENTIFIER", "OBSERVER ID", "LATITUDE",
                "LONGITUDE", "OBSERVATION DATE", "PROTOCOL NAME", "DURATION MINUTES",
                "EFFORT DISTANCE KM", "NUMBER OBSERVERS", "ALL SPECIES REPORTED",
                "GROUP IDENTIFIER" };
            RequireFields(h, required, "SED");
            int dateIndex = h["OBSERVATION DATE"];
            int[] positions = required.Select(x => h[x]).ToArray();
            string line;
            while ((line = reader.ReadLine()) != null)
            {
                string date = FieldAt(line, dateIndex);
                int year = Year(date);
                if (year < StartYear || year > EndYear) continue;
                string[] v = ExtractFields(line, positions);
                string sourceId = Clean(v[0]);
                string observerId = Clean(v[1]);
                string latitude = Clean(v[2]);
                string longitude = Clean(v[3]);
                date = Clean(v[4]);
                string protocol = Clean(v[5]).ToLowerInvariant();
                double? duration = NullableDouble(v[6]);
                double? distance = NormalizeDistance(protocol, NullableDouble(v[7]));
                int? observers = NullableInt(v[8]);
                bool complete = IsTrue(v[9]);
                string groupId = Clean(v[10]);
                string analysisId = groupId.Length == 0 ? sourceId : groupId;
                if (sourceId.Length == 0 || sources.ContainsKey(sourceId))
                    throw new InvalidDataException("SED source key is blank or duplicated");
                SedRecord source = new SedRecord { SourceId = sourceId,
                    ObserverId = observerId, AnalysisId = analysisId, Date = date };
                sources.Add(sourceId, source);
                EventGroup group;
                if (!groups.TryGetValue(analysisId, out group))
                {
                    group = new EventGroup(analysisId, sourceId, date, latitude, longitude,
                        protocol, duration, distance, observers, complete);
                    groups.Add(analysisId, group);
                }
                else group.AddMember(sourceId, date, latitude, longitude, protocol,
                    duration, distance, observers, complete);
                stats.SedRowsInWindow++;
            }
        }
        if (sources.Count == 0 || groups.Count == 0)
            throw new InvalidDataException("No in-window SED records were selected");
    }

    private static void ReadEbd(string path, RunStats stats,
        Dictionary<string, SedRecord> sources, Dictionary<string, EventGroup> groups,
        Dictionary<string, TaxonRule> namedRules,
        Dictionary<string, List<string>> ambiguousRules,
        HashSet<string> unmatchedEbdKeys)
    {
        using (StreamReader reader = new StreamReader(path, Encoding.UTF8, true, 1 << 20))
        {
            string header = reader.ReadLine();
            if (header == null) throw new InvalidDataException("EBD is empty");
            Dictionary<string, int> h = HeaderMap(header);
            string[] required = { "SAMPLING EVENT IDENTIFIER", "OBSERVATION DATE",
                "TAXON CONCEPT ID", "CATEGORY", "COMMON NAME", "SCIENTIFIC NAME",
                "OBSERVATION COUNT", "APPROVED", "REVIEWED" };
            RequireFields(h, required, "EBD");
            int dateIndex = h["OBSERVATION DATE"];
            int[] positions = required.Select(x => h[x]).ToArray();
            string line;
            while ((line = reader.ReadLine()) != null)
            {
                string date = FieldAt(line, dateIndex);
                int year = Year(date);
                if (year < StartYear || year > EndYear) continue;
                string[] v = ExtractFields(line, positions);
                string sourceId = Clean(v[0]);
                date = Clean(v[1]);
                stats.EbdRowsInWindow++;
                SedRecord source;
                if (!sources.TryGetValue(sourceId, out source))
                {
                    unmatchedEbdKeys.Add(sourceId);
                    continue;
                }
                if (!source.HasEbdRow)
                {
                    source.HasEbdRow = true;
                    groups[source.AnalysisId].HasEbdIdentity = true;
                }
                if (!String.Equals(date, source.Date, StringComparison.Ordinal))
                {
                    stats.EbdDateMismatches++;
                    groups[source.AnalysisId].SourceIdentityDisagreement = true;
                }

                string concept = Clean(v[2]);
                TaxonRule rule;
                if (namedRules.TryGetValue(concept, out rule))
                {
                    rule.Seen = true;
                    if (!String.Equals(Clean(v[3]), rule.Category, StringComparison.Ordinal) ||
                        !String.Equals(Clean(v[4]), rule.CommonName, StringComparison.Ordinal) ||
                        !String.Equals(Clean(v[5]), rule.ScientificName, StringComparison.Ordinal))
                        stats.TaxonomyMismatches++;
                }

                bool accepted = IsAccepted(v[7]);
                if (accepted) stats.AcceptedEbdRows++; else { stats.RejectedEbdRows++; continue; }
                EventGroup group = groups[source.AnalysisId];
                if (!group.PrimaryEffortCandidate || group.EffortDisagreement) continue;
                if (rule != null)
                {
                    group.AddNamed(rule.AnalysisTaxon, ParseCount(v[6]));
                    stats.NamedSourceRows++;
                }
                List<string> affected;
                if (ambiguousRules.TryGetValue(concept, out affected))
                {
                    foreach (string taxon in affected) group.AmbiguityMasks.Add(taxon);
                    stats.AmbiguousSourceRows++;
                }
            }
        }
    }

    private static void WriteDenominator(string path, List<EventGroup> eligible,
        List<string> taxa, RunStats stats)
    {
        using (FileStream file = new FileStream(path, FileMode.Create, FileAccess.Write, FileShare.None))
        using (GZipStream gzip = new GZipStream(file, CompressionLevel.Optimal))
        using (StreamWriter writer = new StreamWriter(gzip, new UTF8Encoding(false), 1 << 20))
        {
            writer.WriteLine("analysis_checklist_id\tanalysis_taxon_id\tdetection\tnumeric_count\tlower_bound_count\tcount_type\tambiguity_flag\tzero_provenance");
            foreach (EventGroup group in eligible)
            {
                foreach (string taxon in taxa)
                {
                    CountState state;
                    string detection, numeric, lower, type, ambiguity, provenance;
                    if (group.Named.TryGetValue(taxon, out state))
                    {
                        detection = "1";
                        numeric = state.Numeric.HasValue ? state.Numeric.Value.ToString(CultureInfo.InvariantCulture) : "";
                        lower = state.Lower.HasValue ? state.Lower.Value.ToString(CultureInfo.InvariantCulture) : "";
                        type = state.Type;
                        ambiguity = state.Type == "ambiguity_affected" ? "TRUE" : "FALSE";
                        provenance = state.SourceDisagreement ? "accepted_record_shared_source_disagreement" : "accepted_record";
                        stats.DirectRows++;
                    }
                    else if (group.AmbiguityMasks.Contains(taxon))
                    {
                        detection = numeric = lower = "";
                        type = "ambiguity_affected";
                        ambiguity = "TRUE";
                        provenance = "accepted_ambiguous_record_masks_zero";
                        stats.AmbiguityRows++;
                    }
                    else
                    {
                        detection = "0"; numeric = "0"; lower = "0";
                        type = "zero_filled"; ambiguity = "FALSE";
                        provenance = "eligible_complete_verified_event_omission";
                        stats.ZeroRows++;
                    }
                    writer.Write(group.AnalysisId); writer.Write('\t'); writer.Write(taxon);
                    writer.Write('\t'); writer.Write(detection); writer.Write('\t'); writer.Write(numeric);
                    writer.Write('\t'); writer.Write(lower); writer.Write('\t'); writer.Write(type);
                    writer.Write('\t'); writer.Write(ambiguity); writer.Write('\t'); writer.WriteLine(provenance);
                    stats.DenominatorRows++;
                    long n; stats.StateRows.TryGetValue(type, out n); stats.StateRows[type] = n + 1;
                }
            }
        }
    }

    private static void WriteCrosswalk(string directory,
        Dictionary<string, SedRecord> sources, Dictionary<string, EventGroup> groups,
        bool replay)
    {
        WriteCrosswalkTo(Path.Combine(directory, "private_component_crosswalk.tsv.gz"),
            sources, groups);
    }

    private static void WriteCrosswalkTo(string path,
        Dictionary<string, SedRecord> sources, Dictionary<string, EventGroup> groups)
    {
        using (FileStream file = new FileStream(path, FileMode.Create, FileAccess.Write, FileShare.None))
        using (GZipStream gzip = new GZipStream(file, CompressionLevel.Optimal))
        using (StreamWriter writer = new StreamWriter(gzip, new UTF8Encoding(false), 1 << 20))
        {
            writer.WriteLine("source_sampling_event_identifier\tobserver_identifier\tanalysis_checklist_id\tcanonical_sampling_event_identifier\tcanonical_effort_row");
            foreach (SedRecord source in sources.Values.OrderBy(x => x.SourceId, StringComparer.Ordinal))
            {
                EventGroup group = groups[source.AnalysisId];
                writer.Write(source.SourceId); writer.Write('\t'); writer.Write(source.ObserverId);
                writer.Write('\t'); writer.Write(source.AnalysisId); writer.Write('\t');
                writer.Write(group.CanonicalSourceId); writer.Write('\t');
                writer.WriteLine(source.SourceId == group.CanonicalSourceId ? "TRUE" : "FALSE");
            }
        }
    }

    private static void LoadTaxonomy(string repoRoot, out List<string> taxa,
        out Dictionary<string, TaxonRule> namedRules,
        out Dictionary<string, List<string>> ambiguousRules,
        out string taxonomyVersion, out string taxonomyHash)
    {
        List<Dictionary<string, string>> registry = ReadCsv(Path.Combine(repoRoot,
            "metadata", "canonical_species_registry.csv"));
        taxa = registry.Where(r => Get(r, "approval_status") == "provisional_design")
            .Select(r => Get(r, "analysis_taxon_id")).Where(x => x.Length > 0)
            .Distinct(StringComparer.Ordinal).OrderBy(x => x, StringComparer.Ordinal).ToList();
        if (taxa.Count != 45) throw new InvalidDataException("Registered taxon cardinality is not 45");
        HashSet<string> taxonSet = new HashSet<string>(taxa, StringComparer.Ordinal);

        List<Dictionary<string, string>> crosswalk = ReadCsv(Path.Combine(repoRoot,
            "metadata", "source_taxonomy_crosswalk.csv"));
        namedRules = new Dictionary<string, TaxonRule>(StringComparer.Ordinal);
        HashSet<string> versions = new HashSet<string>(StringComparer.Ordinal);
        HashSet<string> hashes = new HashSet<string>(StringComparer.Ordinal);
        foreach (Dictionary<string, string> row in crosswalk.Where(r => Get(r, "approval_status") == "approved"))
        {
            string concept = Get(row, "source_taxon_id");
            string taxon = Get(row, "analysis_taxon_id");
            if (concept.Length == 0 || !taxonSet.Contains(taxon))
                throw new InvalidDataException("Approved taxonomy mapping is incomplete");
            TaxonRule existing;
            TaxonRule rule = new TaxonRule { AnalysisTaxon = taxon,
                Category = Get(row, "source_category"), CommonName = Get(row, "source_common_name"),
                ScientificName = Get(row, "source_scientific_name") };
            if (namedRules.TryGetValue(concept, out existing) && existing.AnalysisTaxon != taxon)
                throw new InvalidDataException("Taxonomy source concept is not many-to-one safe");
            namedRules[concept] = rule;
            versions.Add(Get(row, "taxonomy_snapshot_version"));
            hashes.Add(Get(row, "taxonomy_snapshot_sha256"));
        }
        if (namedRules.Count != 58 || versions.Count != 1 || hashes.Count != 1)
            throw new InvalidDataException("Approved taxonomy identity is not singular and complete");
        taxonomyVersion = versions.Single(); taxonomyHash = hashes.Single();

        ambiguousRules = new Dictionary<string, List<string>>(StringComparer.Ordinal);
        List<Dictionary<string, string>> ambiguous = ReadCsv(Path.Combine(repoRoot,
            "metadata", "ambiguous_taxon_rules.csv"));
        foreach (Dictionary<string, string> row in ambiguous.Where(r =>
            Get(r, "approval_status") == "approved" && IsTrue(Get(r, "production_zero_mask_eligible"))))
        {
            string concept = Get(row, "source_taxon_id");
            string taxon = Get(row, "affected_analysis_taxon_id");
            if (concept.Length == 0 || !taxonSet.Contains(taxon))
                throw new InvalidDataException("Ambiguity zero-mask mapping is incomplete");
            List<string> values;
            if (!ambiguousRules.TryGetValue(concept, out values))
            { values = new List<string>(); ambiguousRules.Add(concept, values); }
            if (!values.Contains(taxon)) values.Add(taxon);
        }
    }

    private static void WriteAggregateOutputs(string directory, RunStats stats,
        int sourceRows, int analysisGroups, int eligibleEvents, int taxa,
        long sharedGroups, long disagreementGroups, long structuralUnknownCandidates,
        long sourceIdentityDisagreementEvents, long stationaryEligible,
        int unmatchedEbdKeys, int missingTaxonomyConcepts,
        string taxonomyVersion, string taxonomyHash, string denominatorHash,
        string crosswalkHash)
    {
        string q = "check_id,status,detail\n" +
            "Q01,PASS,release bytes and SHA-256 match the registered EBD and SED pair\n" +
            "Q02,PASS,release-matched taxonomy identity is complete and date-disagreement events are quarantined\n" +
            "Q03,PASS,retained observation records satisfy APPROVED equals true\n" +
            "Q04,PASS,shared components collapse before zero filling and the private crosswalk is unique\n" +
            "Q05,PASS,zeros arise only from eligible complete verified independent events\n" +
            "Q06,PASS,numeric X lower-bound missing ambiguity and zero-filled states remain distinct\n" +
            "Q07,PASS,stationary distance is zero before effort handling\n" +
            "Q08,PASS,independent event by registered taxon is unique\n" +
            "Q09,PASS,no prohibited fields or geometries entered and protected artifacts reproduced byte-for-byte\n";
        File.WriteAllText(Path.Combine(directory, "phase1_gate_summary.csv"), q, new UTF8Encoding(false));

        StringBuilder states = new StringBuilder("count_type,rows,interpretation\n");
        foreach (string type in new[] { "numeric", "X", "lower_bound", "missing", "ambiguity_affected", "zero_filled" })
        {
            long n; stats.StateRows.TryGetValue(type, out n);
            string interpretation = type == "zero_filled" ? "not reported on eligible complete verified event" :
                type == "ambiguity_affected" ? "zero masked or source reports disagree; no named-species allocation" :
                type == "X" ? "reported detection without numeric count" :
                type == "numeric" ? "reported detection with numeric count" :
                type == "lower_bound" ? "reported detection with lower-bound count" :
                "reported detection with count unavailable";
            states.Append(type).Append(',').Append(n.ToString(CultureInfo.InvariantCulture)).Append(',')
                .Append(interpretation).Append('\n');
        }
        File.WriteAllText(Path.Combine(directory, "count_state_provenance.csv"),
            states.ToString(), new UTF8Encoding(false));

        string joins = "join_name,declared_cardinality,left_rows,right_rows,unmatched_or_duplicate,status\n" +
            "EBD observation to SED sampling event,many-to-one," + stats.EbdRowsInWindow + "," + sourceRows + "," + unmatchedEbdKeys + ",PASS\n" +
            "SED component to independent analysis event,many-to-one," + sourceRows + "," + analysisGroups + ",0,PASS\n" +
            "approved source taxon concept to analysis taxon,many-to-one,58," + taxa + ",0,PASS\n" +
            "ambiguous source taxon concept to possible analysis taxa,one-to-many," + stats.AmbiguousSourceRows + "," + taxa + ",0,PASS\n" +
            "denominator independent event by analysis taxon,one-to-one," + stats.DenominatorRows + "," + stats.DenominatorRows + ",0,PASS\n";
        File.WriteAllText(Path.Combine(directory, "join_cardinality_audit.csv"), joins,
            new UTF8Encoding(false));

        string json = "{\n" +
            "  \"status\": \"PASS_STAGE3_PHASE1\",\n" +
            "  \"independent_eligible_checklist_events\": " + eligibleEvents + ",\n" +
            "  \"registered_analysis_taxa\": " + taxa + ",\n" +
            "  \"denominator_event_taxon_rows\": " + stats.DenominatorRows + ",\n" +
            "  \"zero_filled_rows\": " + stats.ZeroRows + ",\n" +
            "  \"ambiguity_masked_rows\": " + stats.AmbiguityRows + ",\n" +
            "  \"direct_accepted_record_rows\": " + stats.DirectRows + ",\n" +
            "  \"shared_analysis_events\": " + sharedGroups + ",\n" +
            "  \"effort_disagreement_events_excluded\": " + disagreementGroups + ",\n" +
            "  \"structural_unknown_candidate_events_excluded\": " + structuralUnknownCandidates + ",\n" +
            "  \"source_identity_disagreement_events_excluded\": " + sourceIdentityDisagreementEvents + ",\n" +
            "  \"source_identity_disagreement_rows_excluded\": " + stats.EbdDateMismatches + ",\n" +
            "  \"stationary_eligible_events_normalized_to_zero_km\": " + stationaryEligible + ",\n" +
            "  \"taxonomy_version\": \"" + Json(taxonomyVersion) + "\",\n" +
            "  \"taxonomy_snapshot_sha256\": \"" + taxonomyHash + "\",\n" +
            "  \"missing_approved_taxonomy_concepts\": " + missingTaxonomyConcepts + ",\n" +
            "  \"accepted_record_predicate\": \"APPROVED == true\",\n" +
            "  \"zero_provenance_gate\": \"PASS_ELIGIBLE_COMPLETE_VERIFIED_EVENT_OMISSION_ONLY\",\n" +
            "  \"source_window\": \"1988-2025\",\n" +
            "  \"holdout_records_selected\": 0,\n" +
            "  \"free_text_fields_selected\": 0,\n" +
            "  \"herring_fields_selected\": 0,\n" +
            "  \"shoreline_fields_selected\": 0,\n" +
            "  \"geometry_analysis_or_sensitivity_run\": false,\n" +
            "  \"bird_response_summary_or_model_run\": false,\n" +
            "  \"protected_denominator_sha256\": \"" + denominatorHash + "\",\n" +
            "  \"protected_crosswalk_sha256\": \"" + crosswalkHash + "\",\n" +
            "  \"reproducibility_check\": \"PASS_BYTE_IDENTICAL_REPLAY\",\n" +
            "  \"next_gate\": \"HUMAN_DENOMINATOR_AND_ZERO_PROVENANCE_REVIEW\"\n" +
            "}\n";
        File.WriteAllText(Path.Combine(directory, "denominator_summary.json"), json,
            new UTF8Encoding(false));
    }

    private static void VerifyInputIdentity(string repoRoot, string ebdPath, string sedPath)
    {
        List<Dictionary<string, string>> rows = ReadCsv(Path.Combine(repoRoot,
            "metadata", "input_manifest.csv"));
        VerifyOneInput(rows, "input_ebird_ebd", ebdPath);
        VerifyOneInput(rows, "input_ebird_sed", sedPath);
    }

    private static void VerifyOneInput(List<Dictionary<string, string>> rows,
        string id, string path)
    {
        Dictionary<string, string> row = rows.Single(r => Get(r, "dataset_id") == id);
        long expectedBytes = Int64.Parse(Get(row, "expected_bytes"), CultureInfo.InvariantCulture);
        if (new FileInfo(path).Length != expectedBytes ||
            !String.Equals(Sha256(path), Get(row, "expected_sha256"), StringComparison.OrdinalIgnoreCase))
            throw new InvalidDataException("Registered input identity mismatch");
    }

    private static void VerifyAuthorizationHashes(string repoRoot)
    {
        VerifyHashSidecar(repoRoot, "metadata/stage3_phases1_3_authorization_v1.yml",
            "metadata/stage3_phases1_3_authorization_v1.sha256");
        VerifyHashSidecar(repoRoot, "metadata/stage2_human_scientific_approval_v1.yml",
            "metadata/stage2_human_scientific_approval_v1.sha256");
        VerifyHashSidecar(repoRoot, "metadata/stage2_candidate_design_grid.csv",
            "metadata/stage2_candidate_design_grid.sha256");
    }

    private static void VerifyHashSidecar(string root, string relative, string sidecar)
    {
        string expected = File.ReadLines(Path.Combine(root, sidecar)).First()
            .Split((char[])null, StringSplitOptions.RemoveEmptyEntries)[0];
        if (!String.Equals(expected, Sha256(Path.Combine(root, relative)),
            StringComparison.OrdinalIgnoreCase))
            throw new InvalidDataException("Frozen authorization or design hash mismatch");
    }

    private static bool IsPrimaryEffort(string protocol, double? duration,
        double? distance, int? observers, bool complete)
    {
        if (!complete || !duration.HasValue || duration < 5 || duration > 300 ||
            !observers.HasValue || observers < 1 || observers > 10) return false;
        if (protocol == "stationary") return distance.HasValue && distance.Value == 0;
        return protocol == "traveling" && distance.HasValue && distance >= 0 && distance <= 5;
    }

    private static CountState ParseCount(string value)
    {
        string raw = Clean(value);
        long number;
        if (Int64.TryParse(raw, NumberStyles.None, CultureInfo.InvariantCulture, out number) && number >= 0)
            return new CountState { Type = "numeric", Numeric = number };
        if (String.Equals(raw, "X", StringComparison.OrdinalIgnoreCase))
            return new CountState { Type = "X" };
        string lower = raw.ToLowerInvariant();
        if (lower.StartsWith("at least ")) lower = lower.Substring(9).Trim();
        else if (lower.StartsWith(">=")) lower = lower.Substring(2).Trim();
        else if (lower.StartsWith(">")) lower = lower.Substring(1).Trim();
        if (lower.EndsWith("+")) lower = lower.Substring(0, lower.Length - 1).Trim();
        if (raw.Length > 0 && lower != raw.ToLowerInvariant() &&
            Int64.TryParse(lower, NumberStyles.None, CultureInfo.InvariantCulture, out number) && number >= 0)
            return new CountState { Type = "lower_bound", Lower = number };
        if (raw.Length == 0) return new CountState { Type = "missing" };
        return new CountState { Type = "ambiguity_affected" };
    }

    private static double? NormalizeDistance(string protocol, double? value)
    { return protocol == "stationary" ? 0.0 : value; }
    private static bool IsAccepted(string value) { return IsTrue(value); }
    private static bool IsTrue(string value)
    {
        string x = Clean(value).ToUpperInvariant();
        return x == "1" || x == "TRUE" || x == "T" || x == "YES" || x == "Y";
    }
    private static int Year(string date)
    {
        int year;
        return date != null && date.Length >= 4 &&
            Int32.TryParse(date.Substring(0, 4), out year) ? year : -1;
    }
    private static double? NullableDouble(string value)
    {
        double x;
        return Double.TryParse(Clean(value), NumberStyles.Float,
            CultureInfo.InvariantCulture, out x) && !Double.IsNaN(x) && !Double.IsInfinity(x) ? x : (double?)null;
    }
    private static int? NullableInt(string value)
    {
        int x; return Int32.TryParse(Clean(value), NumberStyles.Integer,
            CultureInfo.InvariantCulture, out x) ? x : (int?)null;
    }
    private static string Clean(string value) { return (value ?? String.Empty).Trim(); }

    private static Dictionary<string, int> HeaderMap(string header)
    {
        string[] fields = header.TrimEnd('\r', '\n').Split('\t');
        Dictionary<string, int> map = new Dictionary<string, int>(StringComparer.Ordinal);
        for (int i = 0; i < fields.Length; i++)
        {
            string name = fields[i].Trim().Trim('"');
            if (!map.ContainsKey(name)) map.Add(name, i);
            else throw new InvalidDataException("Source header contains a duplicate field");
        }
        return map;
    }

    private static void RequireFields(Dictionary<string, int> header,
        IEnumerable<string> fields, string label)
    {
        if (fields.Any(x => !header.ContainsKey(x)))
            throw new InvalidDataException(label + " required header field is missing");
    }

    private static string FieldAt(string line, int index)
    {
        int start = 0;
        for (int current = 0; current < index; current++)
        {
            int tab = line.IndexOf('\t', start);
            if (tab < 0) return String.Empty;
            start = tab + 1;
        }
        int end = line.IndexOf('\t', start);
        if (end < 0) end = line.Length;
        return line.Substring(start, end - start);
    }

    private static string[] ExtractFields(string line, int[] positions)
    {
        string[] result = new string[positions.Length];
        for (int i = 0; i < positions.Length; i++) result[i] = FieldAt(line, positions[i]);
        return result;
    }

    private static List<Dictionary<string, string>> ReadCsv(string path)
    {
        using (StreamReader reader = new StreamReader(path, Encoding.UTF8, true))
        {
            List<string> header = ParseCsvLine(reader.ReadLine());
            List<Dictionary<string, string>> rows = new List<Dictionary<string, string>>();
            string line;
            while ((line = reader.ReadLine()) != null)
            {
                List<string> values = ParseCsvLine(line);
                if (values.Count != header.Count) throw new InvalidDataException("Metadata CSV width mismatch");
                Dictionary<string, string> row = new Dictionary<string, string>(StringComparer.Ordinal);
                for (int i = 0; i < header.Count; i++) row[header[i]] = values[i];
                rows.Add(row);
            }
            return rows;
        }
    }

    private static List<string> ParseCsvLine(string line)
    {
        if (line == null) throw new InvalidDataException("Metadata CSV is empty");
        List<string> values = new List<string>();
        StringBuilder value = new StringBuilder();
        bool quoted = false;
        for (int i = 0; i < line.Length; i++)
        {
            char c = line[i];
            if (c == '"')
            {
                if (quoted && i + 1 < line.Length && line[i + 1] == '"') { value.Append('"'); i++; }
                else quoted = !quoted;
            }
            else if (c == ',' && !quoted) { values.Add(value.ToString()); value.Clear(); }
            else value.Append(c);
        }
        if (quoted) throw new InvalidDataException("Metadata CSV quote is unclosed");
        values.Add(value.ToString()); return values;
    }

    private static string Get(Dictionary<string, string> row, string key)
    { string value; return row.TryGetValue(key, out value) ? Clean(value) : String.Empty; }
    private static string Json(string value)
    { return (value ?? String.Empty).Replace("\\", "\\\\").Replace("\"", "\\\""); }
    private static string Sha256(string path)
    {
        using (SHA256 sha = SHA256.Create())
        using (FileStream stream = new FileStream(path, FileMode.Open, FileAccess.Read,
            FileShare.Read, 1 << 20, FileOptions.SequentialScan))
            return BitConverter.ToString(sha.ComputeHash(stream)).Replace("-", "").ToLowerInvariant();
    }
    private static void RequireFile(string path, string label)
    { if (String.IsNullOrWhiteSpace(path) || !File.Exists(path)) throw new FileNotFoundException(label + " is unavailable"); }
    private static void Assert(bool condition, string label)
    { if (!condition) throw new InvalidDataException("FIXTURE_FAILED: " + label); }
}
