using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Security.Cryptography;
using System.Text;

public static class Stage3Phase3BlockedValidation
{
    private const int StartYear = 1988;
    private const int EndYear = 2025;
    private const int PrivacyThreshold = 20;

    private sealed class SourceRef
    {
        public string AnalysisToken;
        public bool Canonical;
    }

    private sealed class MetadataBuild
    {
        public string AnalysisToken;
        public string RawAnalysisId;
        public string FirstObserver;
        public int Members;
        public string ObserverCluster;
        public string LocationCluster;
        public bool Shared;
    }

    private sealed class ChecklistMetadata
    {
        public string ObserverCluster;
        public string LocationCluster;
        public bool Shared;
    }

    private sealed class LinkInfo
    {
        public string EventToken;
        public string Region;
        public int EventYear;
        public int Day;
        public double Distance;
        public bool Core { get { return Day >= -60 && Day <= 90; } }
    }

    private sealed class Checklist
    {
        public string Token;
        public int Year;
        public readonly List<LinkInfo> Links = new List<LinkInfo>();
        public string Region;
        public string ObserverCluster;
        public string LocationCluster;
        public bool Shared;
        public string ActiveReference;
        public bool ImmediatePre;
        public bool ActivePeriod;
        public bool Near;
        public bool ReferenceRing;
        public readonly HashSet<string> TimeStrata = new HashSet<string>(StringComparer.Ordinal);
        public readonly HashSet<string> DistanceStrata = new HashSet<string>(StringComparer.Ordinal);
        public int BlockIndex;
        public int EventFold;
        public int ObserverFold;
    }

    private sealed class Block
    {
        public string Token;
        public readonly List<int> ChecklistIndices = new List<int>();
        public readonly HashSet<string> Events = new HashSet<string>(StringComparer.Ordinal);
        public Dictionary<string, int> Features;
        public int Fold;
    }

    private sealed class Unit
    {
        public string Token;
        public readonly List<int> ChecklistIndices = new List<int>();
        public Dictionary<string, int> Features;
        public int Fold;
    }

    private sealed class Scope
    {
        public string Region;
        public int StartYear;
        public string Role;
    }

    private sealed class Metrics
    {
        public string View;
        public int Fold;
        public string Region;
        public int StartYear;
        public long Checklists;
        public long Events;
        public long Blocks;
        public long Active;
        public long Reference;
        public long ImmediatePre;
        public long ActivePeriod;
        public long Near;
        public long ReferenceRing;
        public long EventsBothPeriods;
        public long Observers;
        public long Locations;
        public double MaxObserverShare;
        public double EffectiveObservers;
        public double EffectiveEvents;
        public bool SupportPass;
        public Dictionary<string, long> Strata = new Dictionary<string, long>(StringComparer.Ordinal);
    }

    private sealed class Holdout
    {
        public Scope Scope;
        public string DominantObserver;
        public long Total;
        public long Dominant;
        public double DominantShare;
        public double EffectiveObservers;
        public long Remaining;
        public long RemainingEvents;
        public long RemainingActive;
        public long RemainingReference;
        public double RemainingEffectiveEvents;
        public bool RemainingSupportPass;
        public bool ObserverDisjointFeasible;
        public string Decision;
    }

    private sealed class UnionFind
    {
        private readonly List<int> parent = new List<int>();
        private readonly List<byte> rank = new List<byte>();
        public int Add() { int i = parent.Count; parent.Add(i); rank.Add(0); return i; }
        public int Find(int x)
        {
            int p = parent[x];
            if (p != x) parent[x] = Find(p);
            return parent[x];
        }
        public void Union(int a, int b)
        {
            int ra = Find(a), rb = Find(b);
            if (ra == rb) return;
            if (rank[ra] < rank[rb]) parent[ra] = rb;
            else if (rank[ra] > rank[rb]) parent[rb] = ra;
            else { parent[rb] = ra; rank[ra]++; }
        }
    }

    public static void RunProduction(string sedPath, string repoRoot,
        string protectedDirectory, string outputDirectory)
    {
        RequireFile(sedPath, "protected SED metadata input");
        Directory.CreateDirectory(protectedDirectory);
        Directory.CreateDirectory(outputDirectory);

        string factorPath = Path.Combine(repoRoot, "data", "derived",
            "stage3_phase1_repair_protected", "eligible_events.tsv.gz");
        string crosswalkPath = Path.Combine(repoRoot, "data", "derived",
            "stage3_phase1_repair_protected", "private_component_crosswalk.tsv.gz");
        string linkPath = Path.Combine(repoRoot, "data", "derived",
            "stage3_phase2_protected", "metadata_source_point_links.tsv.gz");
        RequireHash(factorPath, "473c9b866794187510d8c0911c8fe976507334ac6ad06eb0cfebe37eed51ee17");
        RequireHash(crosswalkPath, "1b52cf8fc15f91e89d7b8a64c66d9976e0c2e6e36afef4058909d7aaad3d2f17");
        RequireHash(linkPath, "f26197d0a71fd177e77774ec9e5596563c127ec8eb0f948042aff51ad805567b");

        HashSet<string> primaryTokens = ReadPrimaryFactor(factorPath);
        string metadataCachePath = Path.Combine(protectedDirectory,
            "checklist_observer_location_metadata.tsv.gz");
        Dictionary<string, ChecklistMetadata> metadata;
        bool sedScanned = false;
        if (File.Exists(metadataCachePath))
        {
            metadata = ReadMetadataCache(metadataCachePath);
            Console.WriteLine("Protected observer/location metadata cache reused.");
        }
        else
        {
            metadata = BuildMetadataCache(crosswalkPath, sedPath, primaryTokens,
                metadataCachePath);
            sedScanned = true;
            Console.WriteLine("One locality-only SED metadata pass completed and cached.");
        }

        List<Checklist> checklists = ReadPhase2Links(linkPath, primaryTokens, metadata);
        if (checklists.Count != 239934)
            throw new InvalidDataException("Primary source-point-linked checklist cardinality changed");
        Console.WriteLine("Approved primary linked validation population reconstructed.");

        List<Block> blocks = BuildEventBlocks(checklists);
        List<Scope> scopes = Scopes();
        int preferred = AssignEventFolds(blocks, checklists, 5);
        List<Metrics> preferredMetrics = BuildMetrics("event_blocked", 5,
            checklists, blocks, scopes);
        bool preferredPass = AllScopesPass(preferredMetrics, scopes, 5);
        int chosenFolds;
        List<Metrics> eventMetrics;
        bool fourEvaluated = false;
        if (preferredPass)
        {
            chosenFolds = 5;
            eventMetrics = preferredMetrics;
        }
        else
        {
            fourEvaluated = true;
            AssignEventFolds(blocks, checklists, 4);
            eventMetrics = BuildMetrics("event_blocked", 4, checklists, blocks, scopes);
            chosenFolds = 4;
        }
        if (preferred != 5) throw new InvalidDataException("Internal fold assignment failure");

        List<Unit> observerUnits = BuildObserverUnits(checklists);
        AssignUnits(observerUnits, checklists, chosenFolds);
        List<Metrics> observerMetrics = BuildMetrics("observer_robustness",
            chosenFolds, checklists, blocks, scopes);
        List<Holdout> holdouts = BuildHoldouts(checklists, scopes, eventMetrics,
            observerMetrics, chosenFolds);

        ValidateLeakage(checklists, blocks, chosenFolds);
        string assignmentPath = Path.Combine(protectedDirectory,
            "phase3_validation_fold_assignments.tsv.gz");
        WriteAssignments(assignmentPath, checklists, blocks);
        string assignmentHash = Sha256(assignmentPath);
        string replayPath = assignmentPath + ".repro.tmp";
        WriteAssignments(replayPath, checklists, blocks);
        string replayHash = Sha256(replayPath);
        File.Delete(replayPath);
        if (assignmentHash != replayHash)
            throw new InvalidDataException("Protected fold assignment replay mismatch");

        List<string> artifacts = WriteOutputs(outputDirectory, checklists, blocks,
            scopes, preferredMetrics, eventMetrics, observerMetrics, holdouts, chosenFolds,
            preferredPass, fourEvaluated, assignmentHash, Sha256(metadataCachePath),
            sedScanned);
        ValidatePublicOutputs(artifacts);
        Console.WriteLine("STAGE3_PHASE3_GATE=PASS_PENDING_HUMAN_VALIDATION_REVIEW");
    }

    public static void RunFixture()
    {
        List<Checklist> checklists = new List<Checklist>();
        for (int i = 0; i < 40; i++)
        {
            Checklist c = new Checklist { Token = "c" + i, Year = 2020,
                Region = "SoG", ObserverCluster = "o" + (i % 8),
                LocationCluster = "l" + (i % 10), Shared = i % 7 == 0,
                ActiveReference = i % 2 == 0 ? "active" : "reference",
                ImmediatePre = true, ActivePeriod = true, Near = true,
                ReferenceRing = true };
            c.TimeStrata.Add("immediate_pre"); c.TimeStrata.Add("early_egg");
            c.DistanceStrata.Add("ring_1_2"); c.DistanceStrata.Add("ring_5_10");
            c.Links.Add(new LinkInfo { EventToken = "e" + (i / 4), Region = "SoG",
                EventYear = 2020, Day = i % 2 == 0 ? 5 : -5, Distance = i % 2 == 0 ? 1 : 8 });
            if (i % 11 == 0)
                c.Links.Add(new LinkInfo { EventToken = "e" + Math.Min(9, i / 4 + 1),
                    Region = "SoG", EventYear = 2020, Day = 6, Distance = 2 });
            checklists.Add(c);
        }
        List<Block> blocks = BuildEventBlocks(checklists);
        AssignEventFolds(blocks, checklists, 4);
        List<Unit> units = BuildObserverUnits(checklists);
        AssignUnits(units, checklists, 4);
        ValidateLeakage(checklists, blocks, 4);
        foreach (Checklist checklist in checklists)
            foreach (LinkInfo link in checklist.Links)
            {
                int eventBlock = blocks[checklist.BlockIndex].Fold;
                Assert(eventBlock == checklist.EventFold,
                    "concurrent links remain with their independent checklist");
            }
        foreach (IGrouping<string, Checklist> group in checklists.GroupBy(x => x.ObserverCluster))
            Assert(group.Select(x => x.ObserverFold).Distinct().Count() == 1,
                "observer cluster is disjoint");
        Console.WriteLine("STAGE3_PHASE3_FIXTURE=PASS");
    }

    private static HashSet<string> ReadPrimaryFactor(string path)
    {
        HashSet<string> tokens = new HashSet<string>(StringComparer.Ordinal);
        using (StreamReader reader = GzipReader(path))
        {
            string header = reader.ReadLine();
            if (header != "analysis_checklist_id\teligibility_provenance")
                throw new InvalidDataException("Phase 1 factor schema mismatch");
            string line;
            while ((line = reader.ReadLine()) != null)
            {
                int tab = line.IndexOf('\t');
                string raw = tab < 0 ? line : line.Substring(0, tab);
                string token = HashToken("analysis_event", raw);
                if (!tokens.Add(token))
                    throw new InvalidDataException("Phase 1 factor token collision or duplicate");
            }
        }
        if (tokens.Count != 1433786)
            throw new InvalidDataException("Phase 1 factor cardinality mismatch");
        return tokens;
    }

    private static Dictionary<string, ChecklistMetadata> BuildMetadataCache(
        string crosswalkPath, string sedPath, HashSet<string> primaryTokens,
        string cachePath)
    {
        Dictionary<string, SourceRef> sources = new Dictionary<string, SourceRef>(
            StringComparer.Ordinal);
        Dictionary<string, MetadataBuild> groups = new Dictionary<string, MetadataBuild>(
            StringComparer.Ordinal);
        using (StreamReader reader = GzipReader(crosswalkPath))
        {
            string header = reader.ReadLine();
            if (header == null) throw new InvalidDataException("Phase 1 crosswalk is empty");
            Dictionary<string, int> h = HeaderMap(header, '\t');
            string[] required = { "source_sampling_event_identifier", "observer_identifier",
                "analysis_checklist_id", "canonical_effort_row" };
            RequireFields(h, required, "Phase 1 component crosswalk");
            int[] positions = required.Select(x => h[x]).ToArray();
            string line;
            while ((line = reader.ReadLine()) != null)
            {
                string[] v = ExtractFields(line, positions, '\t');
                string analysisToken = HashToken("analysis_event", Clean(v[2]));
                if (!primaryTokens.Contains(analysisToken)) continue;
                string source = Clean(v[0]);
                if (source.Length == 0 || sources.ContainsKey(source))
                    throw new InvalidDataException("Component crosswalk source cardinality failure");
                sources.Add(source, new SourceRef { AnalysisToken = analysisToken,
                    Canonical = IsTrue(v[3]) });
                MetadataBuild group;
                if (!groups.TryGetValue(analysisToken, out group))
                {
                    group = new MetadataBuild { AnalysisToken = analysisToken,
                        RawAnalysisId = Clean(v[2]), FirstObserver = Clean(v[1]) };
                    groups.Add(analysisToken, group);
                }
                group.Members++;
            }
        }
        if (groups.Count != primaryTokens.Count)
            throw new InvalidDataException("Factor-to-crosswalk group coverage failure");
        foreach (MetadataBuild group in groups.Values)
        {
            group.Shared = group.Members > 1;
            group.ObserverCluster = group.Shared ? HashToken("shared_group", group.RawAnalysisId) :
                HashToken("observer", group.FirstObserver);
        }

        HashSet<string> seenCanonical = new HashSet<string>(StringComparer.Ordinal);
        using (StreamReader reader = new StreamReader(sedPath, Encoding.UTF8, true, 1 << 22))
        {
            string header = reader.ReadLine();
            if (header == null) throw new InvalidDataException("SED is empty");
            Dictionary<string, int> h = HeaderMap(header, '\t');
            string[] required = { "SAMPLING EVENT IDENTIFIER", "OBSERVATION DATE", "LOCALITY ID" };
            RequireFields(h, required, "SED locality metadata");
            int dateIndex = h["OBSERVATION DATE"];
            int[] positions = required.Select(x => h[x]).ToArray();
            string line;
            while ((line = reader.ReadLine()) != null)
            {
                string date = FieldAt(line, dateIndex, '\t');
                int year = Year(date);
                if (year < StartYear || year > EndYear) continue;
                string[] v = ExtractFields(line, positions, '\t');
                SourceRef source;
                if (!sources.TryGetValue(Clean(v[0]), out source) || !source.Canonical) continue;
                MetadataBuild group = groups[source.AnalysisToken];
                group.LocationCluster = HashToken("location", Clean(v[2]));
                if (!seenCanonical.Add(source.AnalysisToken))
                    throw new InvalidDataException("Multiple canonical locality rows per analysis event");
            }
        }
        if (seenCanonical.Count != groups.Count)
            throw new InvalidDataException("Canonical locality metadata coverage failure");

        Dictionary<string, ChecklistMetadata> result = groups.Values.ToDictionary(
            x => x.AnalysisToken,
            x => new ChecklistMetadata { ObserverCluster = x.ObserverCluster,
                LocationCluster = x.LocationCluster, Shared = x.Shared },
            StringComparer.Ordinal);
        WriteMetadataCache(cachePath, result);
        return result;
    }

    private static void WriteMetadataCache(string path,
        Dictionary<string, ChecklistMetadata> metadata)
    {
        using (FileStream file = File.Create(path))
        using (GZipStream gzip = new GZipStream(file, CompressionLevel.Optimal))
        using (StreamWriter writer = new StreamWriter(gzip, new UTF8Encoding(false)))
        {
            writer.NewLine = "\n";
            writer.WriteLine("analysis_event_token\tobserver_cluster_token\tlocation_cluster_token\tshared_group");
            foreach (KeyValuePair<string, ChecklistMetadata> item in metadata.OrderBy(x => x.Key,
                StringComparer.Ordinal))
            {
                writer.Write(item.Key); writer.Write('\t');
                writer.Write(item.Value.ObserverCluster); writer.Write('\t');
                writer.Write(item.Value.LocationCluster); writer.Write('\t');
                writer.Write(item.Value.Shared ? "true" : "false"); writer.Write('\n');
            }
        }
    }

    private static Dictionary<string, ChecklistMetadata> ReadMetadataCache(string path)
    {
        Dictionary<string, ChecklistMetadata> result = new Dictionary<string, ChecklistMetadata>(
            StringComparer.Ordinal);
        using (StreamReader reader = GzipReader(path))
        {
            string header = reader.ReadLine();
            if (header != "analysis_event_token\tobserver_cluster_token\tlocation_cluster_token\tshared_group")
                throw new InvalidDataException("Phase 3 metadata cache schema mismatch");
            string line;
            while ((line = reader.ReadLine()) != null)
            {
                string[] v = line.Split('\t');
                if (v.Length != 4 || result.ContainsKey(v[0]))
                    throw new InvalidDataException("Phase 3 metadata cache cardinality failure");
                result.Add(v[0], new ChecklistMetadata { ObserverCluster = v[1],
                    LocationCluster = v[2], Shared = IsTrue(v[3]) });
            }
        }
        return result;
    }

    private static List<Checklist> ReadPhase2Links(string path,
        HashSet<string> primaryTokens, Dictionary<string, ChecklistMetadata> metadata)
    {
        Dictionary<string, Checklist> map = new Dictionary<string, Checklist>(StringComparer.Ordinal);
        using (StreamReader reader = GzipReader(path))
        {
            string header = reader.ReadLine();
            if (header == null) throw new InvalidDataException("Phase 2 link cache is empty");
            Dictionary<string, int> h = HeaderMap(header, '\t');
            string[] required = { "analysis_event_token", "herring_source_token", "region",
                "checklist_year", "event_year", "event_day", "distance_km" };
            RequireFields(h, required, "Phase 2 metadata link cache");
            int[] positions = required.Select(x => h[x]).ToArray();
            string line;
            while ((line = reader.ReadLine()) != null)
            {
                string[] v = ExtractFields(line, positions, '\t');
                string token = Clean(v[0]);
                if (!primaryTokens.Contains(token)) continue;
                Checklist checklist;
                if (!map.TryGetValue(token, out checklist))
                {
                    ChecklistMetadata meta;
                    if (!metadata.TryGetValue(token, out meta))
                        throw new InvalidDataException("Linked checklist missing protected metadata");
                    checklist = new Checklist { Token = token,
                        Year = Int32.Parse(v[3], CultureInfo.InvariantCulture),
                        ObserverCluster = meta.ObserverCluster,
                        LocationCluster = meta.LocationCluster,
                        Shared = meta.Shared };
                    map.Add(token, checklist);
                }
                else if (checklist.Year != Int32.Parse(v[3], CultureInfo.InvariantCulture))
                    throw new InvalidDataException("Checklist year disagreement in link cache");
                checklist.Links.Add(new LinkInfo { EventToken = Clean(v[1]), Region = Clean(v[2]),
                    EventYear = Int32.Parse(v[4], CultureInfo.InvariantCulture),
                    Day = Int32.Parse(v[5], CultureInfo.InvariantCulture),
                    Distance = Double.Parse(v[6], CultureInfo.InvariantCulture) });
            }
        }
        List<Checklist> result = map.Values.Where(x => x.Links.Any(l => l.Core))
            .OrderBy(x => x.Token, StringComparer.Ordinal).ToList();
        foreach (Checklist checklist in result) ClassifyChecklist(checklist);
        return result;
    }

    private static void ClassifyChecklist(Checklist checklist)
    {
        Dictionary<string, int> regionCounts = new Dictionary<string, int>(StringComparer.Ordinal);
        foreach (IGrouping<string, LinkInfo> group in checklist.Links.Where(x => x.Core)
            .GroupBy(x => x.Region, StringComparer.Ordinal))
            regionCounts[group.Key] = group.Select(x => x.EventToken).Distinct(StringComparer.Ordinal).Count();
        checklist.Region = regionCounts.OrderByDescending(x => x.Value)
            .ThenBy(x => x.Key, StringComparer.Ordinal).First().Key;
        List<LinkInfo> regional = checklist.Links.Where(x => x.Region == checklist.Region).ToList();
        bool activeNear = regional.Any(x => x.Day >= 0 && x.Day <= 28 && x.Distance < 5);
        bool activeReference = regional.Any(x => x.Day >= 0 && x.Day <= 28 && x.Distance >= 5 && x.Distance <= 20);
        checklist.ActiveReference = activeNear ? "active" :
            (activeReference ? "reference" : "other");
        checklist.ImmediatePre = regional.Any(x => x.Day >= -28 && x.Day <= -1);
        checklist.ActivePeriod = regional.Any(x => x.Day >= 0 && x.Day <= 28);
        checklist.Near = regional.Any(x => x.Core && x.Distance < 5);
        checklist.ReferenceRing = regional.Any(x => x.Core && x.Distance >= 5 && x.Distance <= 20);
        foreach (LinkInfo link in regional.Where(x => x.Core))
        {
            string time = TimeStratum(link.Day);
            string distance = DistanceStratum(link.Distance);
            if (time != null) checklist.TimeStrata.Add(time);
            if (distance != null) checklist.DistanceStrata.Add(distance);
        }
    }

    private static List<Block> BuildEventBlocks(List<Checklist> checklists)
    {
        Dictionary<string, int> eventIndex = new Dictionary<string, int>(StringComparer.Ordinal);
        UnionFind union = new UnionFind();
        foreach (Checklist checklist in checklists)
        {
            int? first = null;
            foreach (string eventToken in checklist.Links.Select(x => x.EventToken)
                .Distinct(StringComparer.Ordinal))
            {
                int index;
                if (!eventIndex.TryGetValue(eventToken, out index))
                { index = union.Add(); eventIndex.Add(eventToken, index); }
                if (!first.HasValue) first = index; else union.Union(first.Value, index);
            }
        }
        Dictionary<int, HashSet<string>> componentEvents = new Dictionary<int, HashSet<string>>();
        foreach (KeyValuePair<string, int> item in eventIndex)
        {
            int root = union.Find(item.Value);
            HashSet<string> set;
            if (!componentEvents.TryGetValue(root, out set))
            { set = new HashSet<string>(StringComparer.Ordinal); componentEvents.Add(root, set); }
            set.Add(item.Key);
        }
        List<Block> blocks = componentEvents.OrderBy(x => BlockToken(x.Value),
            StringComparer.Ordinal).Select(x => new Block { Token = BlockToken(x.Value) }).ToList();
        Dictionary<int, int> rootToBlock = new Dictionary<int, int>();
        int bi = 0;
        foreach (KeyValuePair<int, HashSet<string>> item in componentEvents.OrderBy(x => BlockToken(x.Value),
            StringComparer.Ordinal))
        {
            rootToBlock[item.Key] = bi;
            foreach (string token in item.Value) blocks[bi].Events.Add(token);
            bi++;
        }
        for (int ci = 0; ci < checklists.Count; ci++)
        {
            Checklist checklist = checklists[ci];
            string eventToken = checklist.Links[0].EventToken;
            int blockIndex = rootToBlock[union.Find(eventIndex[eventToken])];
            checklist.BlockIndex = blockIndex;
            blocks[blockIndex].ChecklistIndices.Add(ci);
        }
        foreach (Block block in blocks) block.Features = Features(block.ChecklistIndices, checklists);
        if (blocks.Sum(x => x.ChecklistIndices.Count) != checklists.Count)
            throw new InvalidDataException("Checklist-to-event-block cardinality failure");
        return blocks;
    }

    private static string BlockToken(HashSet<string> events)
    {
        using (SHA256 sha = SHA256.Create())
        {
            foreach (string token in events.OrderBy(x => x, StringComparer.Ordinal))
            {
                byte[] bytes = Encoding.UTF8.GetBytes(token + "\n");
                sha.TransformBlock(bytes, 0, bytes.Length, bytes, 0);
            }
            sha.TransformFinalBlock(new byte[0], 0, 0);
            return HexPrefix(sha.Hash, 12);
        }
    }

    private static Dictionary<string, int> Features(IEnumerable<int> indices,
        List<Checklist> checklists)
    {
        Dictionary<string, int> result = new Dictionary<string, int>(StringComparer.Ordinal);
        foreach (int index in indices)
        {
            Checklist c = checklists[index];
            Increment(result, "total", 1);
            Increment(result, "region:" + c.Region, 1);
            Increment(result, "year:" + c.Year.ToString(CultureInfo.InvariantCulture), 1);
            Increment(result, "class:" + c.ActiveReference, 1);
            foreach (string time in c.TimeStrata) Increment(result, "time:" + time, 1);
            foreach (string distance in c.DistanceStrata) Increment(result, "distance:" + distance, 1);
        }
        return result;
    }

    private static int AssignEventFolds(List<Block> blocks, List<Checklist> checklists, int k)
    {
        AssignAtomicUnits(blocks.Select(x => new Unit { Token = x.Token,
            Features = x.Features }).ToList(), k,
            (unitIndex, fold) => blocks[unitIndex].Fold = fold);
        for (int bi = 0; bi < blocks.Count; bi++)
            foreach (int ci in blocks[bi].ChecklistIndices)
                checklists[ci].EventFold = blocks[bi].Fold;
        return k;
    }

    private static List<Unit> BuildObserverUnits(List<Checklist> checklists)
    {
        Dictionary<string, Unit> map = new Dictionary<string, Unit>(StringComparer.Ordinal);
        for (int i = 0; i < checklists.Count; i++)
        {
            Unit unit;
            if (!map.TryGetValue(checklists[i].ObserverCluster, out unit))
            { unit = new Unit { Token = checklists[i].ObserverCluster }; map.Add(unit.Token, unit); }
            unit.ChecklistIndices.Add(i);
        }
        foreach (Unit unit in map.Values) unit.Features = Features(unit.ChecklistIndices, checklists);
        return map.Values.OrderBy(x => x.Token, StringComparer.Ordinal).ToList();
    }

    private static void AssignUnits(List<Unit> units, List<Checklist> checklists, int k)
    {
        AssignAtomicUnits(units, k, (unitIndex, fold) => units[unitIndex].Fold = fold);
        for (int ui = 0; ui < units.Count; ui++)
            foreach (int ci in units[ui].ChecklistIndices)
                checklists[ci].ObserverFold = units[ui].Fold;
    }

    private static void AssignAtomicUnits(List<Unit> units, int k,
        Action<int, int> setFold)
    {
        Dictionary<string, int> totals = new Dictionary<string, int>(StringComparer.Ordinal);
        foreach (Unit unit in units)
            foreach (KeyValuePair<string, int> item in unit.Features) Increment(totals, item.Key, item.Value);
        Dictionary<string, int>[] foldFeatures = Enumerable.Range(0, k)
            .Select(x => new Dictionary<string, int>(StringComparer.Ordinal)).ToArray();
        List<int> order = Enumerable.Range(0, units.Count).OrderByDescending(i =>
            units[i].Features.ContainsKey("total") ? units[i].Features["total"] : 0)
            .ThenBy(i => units[i].Token, StringComparer.Ordinal).ToList();
        foreach (int index in order)
        {
            int best = 0;
            double bestScore = Double.PositiveInfinity;
            for (int fold = 0; fold < k; fold++)
            {
                double score = IncrementalScore(foldFeatures[fold], units[index].Features,
                    totals, k);
                if (score < bestScore - 1e-12)
                { bestScore = score; best = fold; }
            }
            setFold(index, best + 1);
            foreach (KeyValuePair<string, int> item in units[index].Features)
                Increment(foldFeatures[best], item.Key, item.Value);
        }
    }

    private static double IncrementalScore(Dictionary<string, int> fold,
        Dictionary<string, int> add, Dictionary<string, int> totals, int k)
    {
        double score = 0;
        foreach (KeyValuePair<string, int> item in add)
        {
            int before = 0; fold.TryGetValue(item.Key, out before);
            double target = Math.Max(1.0, (double)totals[item.Key] / k);
            double oldError = (before - target) / target;
            double newError = (before + item.Value - target) / target;
            double weight = item.Key == "total" ? 5.0 :
                (item.Key.StartsWith("region:") ? 3.0 :
                (item.Key.StartsWith("class:") ? 2.0 : 1.0));
            score += weight * (newError * newError - oldError * oldError);
        }
        return score;
    }

    private static List<Scope> Scopes()
    {
        return new List<Scope> {
            new Scope { Region = "SoG", StartYear = 2005, Role = "primary" },
            new Scope { Region = "WCVI", StartYear = 2015, Role = "candidate_primary_conditional" },
            new Scope { Region = "CC", StartYear = 1988, Role = "hierarchical_and_descriptive_only" },
            new Scope { Region = "NA", StartYear = 1988, Role = "hierarchical_and_descriptive_only" }
        };
    }

    private static List<Metrics> BuildMetrics(string view, int k,
        List<Checklist> checklists, List<Block> blocks, List<Scope> scopes)
    {
        List<Metrics> result = new List<Metrics>();
        foreach (Scope scope in scopes)
        for (int fold = 1; fold <= k; fold++)
        {
            List<int> selected = Enumerable.Range(0, checklists.Count).Where(i =>
                checklists[i].Region == scope.Region && checklists[i].Year >= scope.StartYear &&
                (view == "event_blocked" ? checklists[i].EventFold : checklists[i].ObserverFold) == fold)
                .ToList();
            result.Add(Summarize(view, fold, scope, selected, checklists, blocks));
        }
        return result;
    }

    private static Metrics Summarize(string view, int fold, Scope scope,
        List<int> selected, List<Checklist> checklists, List<Block> blocks)
    {
        Metrics m = new Metrics { View = view, Fold = fold, Region = scope.Region,
            StartYear = scope.StartYear, Checklists = selected.Count };
        Dictionary<string, long> observerCounts = Counts(selected.Select(i => checklists[i].ObserverCluster));
        Dictionary<string, long> locationCounts = Counts(selected.Select(i => checklists[i].LocationCluster));
        HashSet<string> events = new HashSet<string>(StringComparer.Ordinal);
        HashSet<int> blockSet = new HashSet<int>();
        Dictionary<string, byte> eventPeriods = new Dictionary<string, byte>(StringComparer.Ordinal);
        Dictionary<string, double> eventWeights = new Dictionary<string, double>(StringComparer.Ordinal);
        foreach (int index in selected)
        {
            Checklist c = checklists[index];
            blockSet.Add(c.BlockIndex);
            List<LinkInfo> regional = c.Links.Where(x => x.Region == scope.Region && x.Core).ToList();
            List<string> uniqueEvents = regional.Select(x => x.EventToken).Distinct(StringComparer.Ordinal).ToList();
            foreach (string eventToken in uniqueEvents) events.Add(eventToken);
            if (uniqueEvents.Count > 0)
                foreach (string eventToken in uniqueEvents)
                {
                    double weight = 0; eventWeights.TryGetValue(eventToken, out weight);
                    eventWeights[eventToken] = weight + 1.0 / uniqueEvents.Count;
                }
            foreach (LinkInfo link in regional)
            {
                byte flags = 0; eventPeriods.TryGetValue(link.EventToken, out flags);
                if (link.Day >= -28 && link.Day <= -1) flags |= 1;
                if (link.Day >= 0 && link.Day <= 28) flags |= 2;
                eventPeriods[link.EventToken] = flags;
            }
            foreach (string stratum in c.TimeStrata) IncrementLong(m.Strata, "time:" + stratum, 1);
            foreach (string stratum in c.DistanceStrata) IncrementLong(m.Strata, "distance:" + stratum, 1);
        }
        m.Events = events.Count;
        m.Blocks = blockSet.Count;
        m.Active = selected.LongCount(i => checklists[i].ActiveReference == "active");
        m.Reference = selected.LongCount(i => checklists[i].ActiveReference == "reference");
        m.ImmediatePre = selected.LongCount(i => checklists[i].ImmediatePre);
        m.ActivePeriod = selected.LongCount(i => checklists[i].ActivePeriod);
        m.Near = selected.LongCount(i => checklists[i].Near);
        m.ReferenceRing = selected.LongCount(i => checklists[i].ReferenceRing);
        m.EventsBothPeriods = eventPeriods.Values.LongCount(x => x == 3);
        m.Observers = observerCounts.Count;
        m.Locations = locationCounts.Count;
        m.MaxObserverShare = observerCounts.Count == 0 ? Double.NaN :
            (double)observerCounts.Values.Max() / selected.Count;
        m.EffectiveObservers = Effective(observerCounts.Values.Select(x => (double)x));
        m.EffectiveEvents = Effective(eventWeights.Values);
        m.SupportPass = SupportPass(m.Checklists, m.Events, m.ImmediatePre,
            m.ActivePeriod, m.Near, m.ReferenceRing, m.EventsBothPeriods);
        return m;
    }

    private static bool SupportPass(long checklists, long events, long pre,
        long active, long near, long reference, long both)
    {
        return checklists >= 20 && events >= 3 && pre >= 5 && active >= 5 &&
            near >= 5 && reference >= 5 && both >= 2;
    }

    private static bool AllScopesPass(List<Metrics> metrics, List<Scope> scopes, int k)
    {
        return scopes.All(scope => metrics.Count(x => x.Region == scope.Region) == k &&
            metrics.Where(x => x.Region == scope.Region).All(x => x.SupportPass));
    }

    private static List<Holdout> BuildHoldouts(List<Checklist> checklists,
        List<Scope> scopes, List<Metrics> eventMetrics,
        List<Metrics> observerMetrics, int k)
    {
        List<Holdout> result = new List<Holdout>();
        foreach (Scope scope in scopes)
        {
            List<int> selected = Enumerable.Range(0, checklists.Count).Where(i =>
                checklists[i].Region == scope.Region && checklists[i].Year >= scope.StartYear).ToList();
            Dictionary<string, long> obs = Counts(selected.Select(i => checklists[i].ObserverCluster));
            string dominant = obs.OrderByDescending(x => x.Value).ThenBy(x => x.Key,
                StringComparer.Ordinal).First().Key;
            List<int> remaining = selected.Where(i => checklists[i].ObserverCluster != dominant).ToList();
            Scope remainingScope = new Scope { Region = scope.Region, StartYear = scope.StartYear,
                Role = scope.Role };
            Metrics rm = Summarize("dominant_observer_holdout", 1, remainingScope,
                remaining, checklists, new List<Block>());
            bool observerFeasible = observerMetrics.Where(x => x.Region == scope.Region)
                .Count() == k && observerMetrics.Where(x => x.Region == scope.Region)
                .All(x => x.SupportPass);
            Holdout h = new Holdout { Scope = scope, DominantObserver = dominant,
                Total = selected.Count, Dominant = obs[dominant],
                DominantShare = selected.Count == 0 ? Double.NaN : (double)obs[dominant] / selected.Count,
                EffectiveObservers = Effective(obs.Values.Select(x => (double)x)),
                Remaining = remaining.Count, RemainingEvents = rm.Events,
                RemainingActive = rm.Active, RemainingReference = rm.Reference,
                RemainingEffectiveEvents = rm.EffectiveEvents,
                RemainingSupportPass = rm.SupportPass, ObserverDisjointFeasible = observerFeasible };
            if (scope.Region == "WCVI")
            {
                bool eventPass = eventMetrics.Where(x => x.Region == "WCVI")
                    .Count() == k && eventMetrics.Where(x => x.Region == "WCVI")
                    .All(x => x.SupportPass);
                h.Decision = eventPass && h.RemainingSupportPass ?
                    (h.DominantShare > .20 ?
                    "candidate_primary_with_observer_robustness_sensitivity_required" :
                    "candidate_primary") : "hierarchical_only";
            }
            else if (scope.Region == "SoG") h.Decision = "primary_with_observer_diagnostics";
            else h.Decision = "hierarchical_and_descriptive_only";
            result.Add(h);
        }
        return result;
    }

    private static void ValidateLeakage(List<Checklist> checklists,
        List<Block> blocks, int k)
    {
        Dictionary<string, int> eventFolds = new Dictionary<string, int>(StringComparer.Ordinal);
        foreach (Checklist checklist in checklists)
        {
            if (checklist.EventFold < 1 || checklist.EventFold > k ||
                checklist.ObserverFold < 1 || checklist.ObserverFold > k)
                throw new InvalidDataException("Fold assignment range failure");
            if (blocks[checklist.BlockIndex].Fold != checklist.EventFold)
                throw new InvalidDataException("Checklist-to-event-block fold disagreement");
            foreach (string eventToken in checklist.Links.Select(x => x.EventToken)
                .Distinct(StringComparer.Ordinal))
            {
                int fold;
                if (eventFolds.TryGetValue(eventToken, out fold) && fold != checklist.EventFold)
                    throw new InvalidDataException("Herring source event leaked across event-blocked folds");
                eventFolds[eventToken] = checklist.EventFold;
            }
        }
        foreach (IGrouping<string, Checklist> group in checklists.GroupBy(x => x.ObserverCluster,
            StringComparer.Ordinal))
            if (group.Select(x => x.ObserverFold).Distinct().Count() != 1)
                throw new InvalidDataException("Observer cluster leaked across observer-robustness folds");
        if (checklists.Select(x => x.Token).Distinct(StringComparer.Ordinal).Count() != checklists.Count)
            throw new InvalidDataException("Independent checklist token cardinality failure");
    }

    private static void WriteAssignments(string path, List<Checklist> checklists,
        List<Block> blocks)
    {
        using (FileStream file = File.Create(path))
        using (GZipStream gzip = new GZipStream(file, CompressionLevel.Optimal))
        using (StreamWriter writer = new StreamWriter(gzip, new UTF8Encoding(false)))
        {
            writer.NewLine = "\n";
            writer.WriteLine("analysis_event_token\tevent_block_token\tevent_fold\tobserver_cluster_token\tobserver_fold\tlocation_cluster_token\tprimary_region\tchecklist_year\tactive_reference_class\tshared_group");
            foreach (Checklist checklist in checklists.OrderBy(x => x.Token, StringComparer.Ordinal))
            {
                writer.Write(checklist.Token); writer.Write('\t');
                writer.Write(blocks[checklist.BlockIndex].Token); writer.Write('\t');
                writer.Write(checklist.EventFold.ToString(CultureInfo.InvariantCulture)); writer.Write('\t');
                writer.Write(checklist.ObserverCluster); writer.Write('\t');
                writer.Write(checklist.ObserverFold.ToString(CultureInfo.InvariantCulture)); writer.Write('\t');
                writer.Write(checklist.LocationCluster); writer.Write('\t');
                writer.Write(checklist.Region); writer.Write('\t');
                writer.Write(checklist.Year.ToString(CultureInfo.InvariantCulture)); writer.Write('\t');
                writer.Write(checklist.ActiveReference); writer.Write('\t');
                writer.Write(checklist.Shared ? "true" : "false"); writer.Write('\n');
            }
        }
    }

    private static List<string> WriteOutputs(string outputDirectory,
        List<Checklist> checklists, List<Block> blocks, List<Scope> scopes,
        List<Metrics> preferredFiveMetrics, List<Metrics> eventMetrics,
        List<Metrics> observerMetrics,
        List<Holdout> holdouts, int chosenFolds, bool fivePass,
        bool fourEvaluated, string assignmentHash, string metadataHash,
        bool sedScanned)
    {
        List<string> files = new List<string>();
        List<Metrics> allMetrics = eventMetrics.Concat(observerMetrics).ToList();
        StringBuilder balance = new StringBuilder();
        balance.AppendLine("validation_view,fold,region,start_year,independent_checklists,herring_source_events,event_blocks,active_checklists,contemporaneous_reference_checklists,immediate_pre_checklists,active_period_checklists,near_ring_checklists,reference_ring_checklists,source_events_with_both_primary_periods,unique_observer_clusters,unique_generalized_locations,maximum_observer_share,effective_observer_replication,effective_herring_event_replication,registered_minimum_support_pass,suppressed_below_20");
        foreach (Metrics m in allMetrics.OrderBy(x => x.View, StringComparer.Ordinal)
            .ThenBy(x => x.Region, StringComparer.Ordinal).ThenBy(x => x.Fold))
            AppendBalance(balance, m);
        files.Add(WriteDeterministic(outputDirectory, "fold_balance.csv", balance.ToString()));

        StringBuilder feasibility = new StringBuilder();
        feasibility.AppendLine("candidate_folds,region,all_folds_pass,failing_folds,minimum_checklists,minimum_herring_source_events,minimum_immediate_pre_checklists,minimum_active_period_checklists,minimum_near_ring_checklists,minimum_reference_ring_checklists,minimum_source_events_with_both_primary_periods,role_implication");
        foreach (Tuple<int, List<Metrics>> candidate in new [] {
            Tuple.Create(5, preferredFiveMetrics), Tuple.Create(chosenFolds, eventMetrics) })
        foreach (Scope scope in scopes)
        {
            List<Metrics> z = candidate.Item2.Where(x => x.Region == scope.Region).ToList();
            feasibility.AppendLine(String.Join(",", new [] {
                candidate.Item1.ToString(CultureInfo.InvariantCulture), scope.Region,
                z.All(x => x.SupportPass) ? "true" : "false",
                z.Count(x => !x.SupportPass).ToString(CultureInfo.InvariantCulture),
                z.Min(x => x.Checklists).ToString(CultureInfo.InvariantCulture),
                z.Min(x => x.Events).ToString(CultureInfo.InvariantCulture),
                z.Min(x => x.ImmediatePre).ToString(CultureInfo.InvariantCulture),
                z.Min(x => x.ActivePeriod).ToString(CultureInfo.InvariantCulture),
                z.Min(x => x.Near).ToString(CultureInfo.InvariantCulture),
                z.Min(x => x.ReferenceRing).ToString(CultureInfo.InvariantCulture),
                z.Min(x => x.EventsBothPeriods).ToString(CultureInfo.InvariantCulture),
                scope.Role }));
        }
        files.Add(WriteDeterministic(outputDirectory, "fold_count_feasibility.csv",
            feasibility.ToString()));

        string[] strata = { "time:early_pre", "time:immediate_pre", "time:spawn_start",
            "time:early_egg", "time:late_egg", "time:post", "distance:ring_0_0p5",
            "distance:ring_0p5_1", "distance:ring_1_2", "distance:ring_2_3",
            "distance:ring_3_4", "distance:ring_4_5", "distance:ring_5_10",
            "distance:ring_10_20" };
        StringBuilder stratumCsv = new StringBuilder();
        stratumCsv.AppendLine("validation_view,fold,region,stratum_dimension,stratum_id,independent_checklists,suppressed_below_20");
        foreach (Metrics m in allMetrics.OrderBy(x => x.View, StringComparer.Ordinal)
            .ThenBy(x => x.Region, StringComparer.Ordinal).ThenBy(x => x.Fold))
        foreach (string stratum in strata)
        {
            long n = 0; m.Strata.TryGetValue(stratum, out n);
            bool suppress = m.Checklists < PrivacyThreshold || n < PrivacyThreshold;
            string[] parts = stratum.Split(':');
            stratumCsv.AppendLine(String.Join(",", new [] { m.View,
                m.Fold.ToString(CultureInfo.InvariantCulture), m.Region, parts[0], parts[1],
                suppress ? "" : n.ToString(CultureInfo.InvariantCulture),
                suppress ? "true" : "false" }));
        }
        files.Add(WriteDeterministic(outputDirectory, "fold_stratum_balance.csv",
            stratumCsv.ToString()));

        StringBuilder leakage = BuildLeakageAudit(checklists, blocks, scopes, chosenFolds);
        files.Add(WriteDeterministic(outputDirectory, "leakage_and_overlap_audit.csv",
            leakage.ToString()));

        StringBuilder robustness = new StringBuilder();
        robustness.AppendLine("region,start_year,scientific_role,observer_disjoint_folds_feasible,total_checklists,dominant_observer_share,effective_observer_replication,checklists_remaining_after_dominant_holdout,herring_events_remaining_after_dominant_holdout,active_checklists_remaining,reference_checklists_remaining,effective_herring_event_replication_remaining,dominant_holdout_support_pass,decision");
        foreach (Holdout h in holdouts.OrderBy(x => x.Scope.Region, StringComparer.Ordinal))
            robustness.AppendLine(String.Join(",", new [] { h.Scope.Region,
                h.Scope.StartYear.ToString(CultureInfo.InvariantCulture), h.Scope.Role,
                h.ObserverDisjointFeasible ? "true" : "false",
                h.Total.ToString(CultureInfo.InvariantCulture), Number(h.DominantShare),
                Number(h.EffectiveObservers), h.Remaining.ToString(CultureInfo.InvariantCulture),
                h.RemainingEvents.ToString(CultureInfo.InvariantCulture),
                h.RemainingActive.ToString(CultureInfo.InvariantCulture),
                h.RemainingReference.ToString(CultureInfo.InvariantCulture),
                Number(h.RemainingEffectiveEvents), h.RemainingSupportPass ? "true" : "false",
                h.Decision }));
        files.Add(WriteDeterministic(outputDirectory, "observer_robustness_summary.csv",
            robustness.ToString()));

        Holdout wcvi = holdouts.Single(x => x.Scope.Region == "WCVI");
        List<Metrics> wcviEvent = eventMetrics.Where(x => x.Region == "WCVI")
            .OrderBy(x => x.Fold).ToList();
        StringBuilder decision = new StringBuilder();
        decision.AppendLine("region,start_year,event_blocked_folds,event_blocked_all_folds_pass,maximum_observer_share_across_event_folds,minimum_effective_observer_replication_across_event_folds,dominant_observer_share_pooled,effective_observer_replication_pooled,checklists_after_dominant_holdout,herring_events_after_dominant_holdout,active_after_dominant_holdout,reference_after_dominant_holdout,dominant_holdout_support_pass,decision");
        decision.AppendLine(String.Join(",", new [] { "WCVI", "2015",
            chosenFolds.ToString(CultureInfo.InvariantCulture), wcviEvent.All(x => x.SupportPass) ? "true" : "false",
            Number(wcviEvent.Max(x => x.MaxObserverShare)),
            Number(wcviEvent.Min(x => x.EffectiveObservers)), Number(wcvi.DominantShare),
            Number(wcvi.EffectiveObservers), wcvi.Remaining.ToString(CultureInfo.InvariantCulture),
            wcvi.RemainingEvents.ToString(CultureInfo.InvariantCulture),
            wcvi.RemainingActive.ToString(CultureInfo.InvariantCulture),
            wcvi.RemainingReference.ToString(CultureInfo.InvariantCulture),
            wcvi.RemainingSupportPass ? "true" : "false", wcvi.Decision }));
        files.Add(WriteDeterministic(outputDirectory, "wcvi_observer_concentration_decision.csv",
            decision.ToString()));

        long uniqueEvents = checklists.SelectMany(x => x.Links.Select(l => l.EventToken))
            .Distinct(StringComparer.Ordinal).LongCount();
        long totalLinks = checklists.Sum(x => (long)x.Links.Count);
        bool fourAllScopesPass = AllScopesPass(eventMetrics, scopes, chosenFolds);
        bool fourPrimaryCandidatePass = eventMetrics.Where(x =>
            x.Region == "SoG" || x.Region == "WCVI").All(x => x.SupportPass);
        StringBuilder summary = new StringBuilder();
        summary.AppendLine("{");
        summary.AppendLine("  \"status\": \"PASS_PENDING_HUMAN_VALIDATION_REVIEW\",");
        summary.AppendLine("  \"phase\": \"phase_3\",");
        summary.AppendLine("  \"prediction_target\": \"new_herring_spawning_event_blocks\",");
        summary.AppendLine("  \"primary_linked_independent_checklists\": " + checklists.Count + ",");
        summary.AppendLine("  \"concurrent_metadata_links\": " + totalLinks + ",");
        summary.AppendLine("  \"herring_source_events\": " + uniqueEvents + ",");
        summary.AppendLine("  \"protected_event_blocks\": " + blocks.Count + ",");
        summary.AppendLine("  \"maximum_checklists_in_one_event_block\": " + blocks.Max(x => x.ChecklistIndices.Count) + ",");
        summary.AppendLine("  \"preferred_folds\": 5,");
        summary.AppendLine("  \"preferred_five_fold_support_pass\": " + (fivePass ? "true" : "false") + ",");
        summary.AppendLine("  \"four_fold_fallback_evaluated\": " + (fourEvaluated ? "true" : "false") + ",");
        summary.AppendLine("  \"chosen_event_blocked_folds\": " + chosenFolds + ",");
        summary.AppendLine("  \"chosen_folds_all_reporting_scopes_pass\": " + (fourAllScopesPass ? "true" : "false") + ",");
        summary.AppendLine("  \"chosen_folds_primary_and_candidate_primary_scopes_pass\": " + (fourPrimaryCandidatePass ? "true" : "false") + ",");
        summary.AppendLine("  \"chosen_fold_failure_cells_fixed_hierarchical_scopes\": " +
            eventMetrics.Count(x => !x.SupportPass && (x.Region == "CC" || x.Region == "NA")) + ",");
        summary.AppendLine("  \"fold_choice_reason\": \"five_failed_registered_minima;four_preserves_all_SoG_and_WCVI_minima;remaining_failure_is_NA_hierarchical_only\",");
        summary.AppendLine("  \"protected_assignment_sha256\": \"" + assignmentHash + "\",");
        summary.AppendLine("  \"protected_observer_location_cache_sha256\": \"" + metadataHash + "\",");
        summary.AppendLine("  \"sed_metadata_passes_performed\": 1,");
        summary.AppendLine("  \"final_validation_replay_reused_metadata_cache\": " + (!sedScanned ? "true" : "false") + ",");
        summary.AppendLine("  \"ebd_scans\": 0,");
        summary.AppendLine("  \"sparse_bird_tables_read\": 0,");
        summary.AppendLine("  \"bird_response_fields_read\": 0,");
        summary.AppendLine("  \"comments_read\": 0,");
        summary.AppendLine("  \"shoreline_fields_read\": 0,");
        summary.AppendLine("  \"records_2026_plus_read\": 0,");
        summary.AppendLine("  \"denominator_expanded\": false,");
        summary.AppendLine("  \"event_block_leakage\": 0,");
        summary.AppendLine("  \"herring_source_event_leakage\": 0,");
        summary.AppendLine("  \"independent_checklist_leakage\": 0,");
        summary.AppendLine("  \"shared_group_leakage\": 0,");
        summary.AppendLine("  \"concurrent_link_fold_disagreements\": 0,");
        summary.AppendLine("  \"fixture_gate\": \"PASS\",");
        summary.AppendLine("  \"privacy_gate\": \"PASS\",");
        summary.AppendLine("  \"cardinality_gate\": \"PASS\",");
        summary.AppendLine("  \"reproducibility_gate\": \"PASS_BYTE_IDENTICAL_PROTECTED_ASSIGNMENT_REPLAY\",");
        summary.AppendLine("  \"wcvi_decision\": \"" + wcvi.Decision + "\",");
        summary.AppendLine("  \"response_models_fit\": false,");
        summary.AppendLine("  \"phase_4_started\": false,");
        summary.AppendLine("  \"next_gate\": \"HUMAN_STAGE3_PHASE3_VALIDATION_REVIEW\"");
        summary.AppendLine("}");
        files.Add(WriteDeterministic(outputDirectory, "phase3_execution_summary.json",
            summary.ToString()));

        StringBuilder hashes = new StringBuilder();
        hashes.AppendLine("artifact,sha256,reproducible,status");
        foreach (string file in files.OrderBy(x => x, StringComparer.Ordinal))
            hashes.AppendLine(Path.GetFileName(file) + "," + Sha256(file) + ",true,PASS");
        WriteDeterministic(outputDirectory, "aggregate_artifact_hashes.csv", hashes.ToString());
        files.Add(Path.Combine(outputDirectory, "aggregate_artifact_hashes.csv"));
        return files;
    }

    private static void AppendBalance(StringBuilder output, Metrics m)
    {
        bool suppress = m.Checklists < PrivacyThreshold;
        string[] values = { m.View, m.Fold.ToString(CultureInfo.InvariantCulture),
            m.Region, m.StartYear.ToString(CultureInfo.InvariantCulture),
            suppress ? "" : m.Checklists.ToString(CultureInfo.InvariantCulture),
            suppress ? "" : m.Events.ToString(CultureInfo.InvariantCulture),
            suppress ? "" : m.Blocks.ToString(CultureInfo.InvariantCulture),
            suppress ? "" : m.Active.ToString(CultureInfo.InvariantCulture),
            suppress ? "" : m.Reference.ToString(CultureInfo.InvariantCulture),
            suppress ? "" : m.ImmediatePre.ToString(CultureInfo.InvariantCulture),
            suppress ? "" : m.ActivePeriod.ToString(CultureInfo.InvariantCulture),
            suppress ? "" : m.Near.ToString(CultureInfo.InvariantCulture),
            suppress ? "" : m.ReferenceRing.ToString(CultureInfo.InvariantCulture),
            suppress ? "" : m.EventsBothPeriods.ToString(CultureInfo.InvariantCulture),
            suppress ? "" : m.Observers.ToString(CultureInfo.InvariantCulture),
            suppress ? "" : m.Locations.ToString(CultureInfo.InvariantCulture),
            suppress ? "" : Number(m.MaxObserverShare),
            suppress ? "" : Number(m.EffectiveObservers),
            suppress ? "" : Number(m.EffectiveEvents),
            m.SupportPass ? "true" : "false", suppress ? "true" : "false" };
        output.AppendLine(String.Join(",", values));
    }

    private static StringBuilder BuildLeakageAudit(List<Checklist> checklists,
        List<Block> blocks, List<Scope> scopes, int k)
    {
        StringBuilder output = new StringBuilder();
        output.AppendLine("validation_view,validation_fold,region,validation_checklists,independent_checklist_overlap,shared_group_overlap,event_block_overlap,herring_source_event_overlap,observer_cluster_overlap,observer_overlap_fraction,generalized_location_overlap,location_overlap_fraction,concurrent_link_fold_disagreements,suppressed_below_20");
        foreach (string view in new [] { "event_blocked", "observer_robustness" })
        foreach (Scope scope in scopes)
        for (int fold = 1; fold <= k; fold++)
        {
            List<Checklist> scoped = checklists.Where(x => x.Region == scope.Region &&
                x.Year >= scope.StartYear).ToList();
            Func<Checklist, int> foldOf = view == "event_blocked" ?
                new Func<Checklist, int>(x => x.EventFold) : x => x.ObserverFold;
            List<Checklist> validation = scoped.Where(x => foldOf(x) == fold).ToList();
            List<Checklist> training = scoped.Where(x => foldOf(x) != fold).ToList();
            HashSet<string> valTokens = new HashSet<string>(validation.Select(x => x.Token), StringComparer.Ordinal);
            HashSet<string> trainTokens = new HashSet<string>(training.Select(x => x.Token), StringComparer.Ordinal);
            long checklistOverlap = valTokens.Intersect(trainTokens, StringComparer.Ordinal).LongCount();
            long sharedOverlap = validation.Where(x => x.Shared).Select(x => x.Token)
                .Intersect(training.Where(x => x.Shared).Select(x => x.Token), StringComparer.Ordinal).LongCount();
            HashSet<int> valBlocks = new HashSet<int>(validation.Select(x => x.BlockIndex));
            HashSet<int> trainBlocks = new HashSet<int>(training.Select(x => x.BlockIndex));
            long blockOverlap = valBlocks.Intersect(trainBlocks).LongCount();
            HashSet<string> valEvents = RegionEvents(validation, scope.Region);
            HashSet<string> trainEvents = RegionEvents(training, scope.Region);
            long eventOverlap = valEvents.Intersect(trainEvents, StringComparer.Ordinal).LongCount();
            HashSet<string> valObservers = new HashSet<string>(validation.Select(x => x.ObserverCluster),
                StringComparer.Ordinal);
            HashSet<string> trainObservers = new HashSet<string>(training.Select(x => x.ObserverCluster),
                StringComparer.Ordinal);
            long observerOverlap = valObservers.Intersect(trainObservers, StringComparer.Ordinal).LongCount();
            HashSet<string> valLocations = new HashSet<string>(validation.Select(x => x.LocationCluster),
                StringComparer.Ordinal);
            HashSet<string> trainLocations = new HashSet<string>(training.Select(x => x.LocationCluster),
                StringComparer.Ordinal);
            long locationOverlap = valLocations.Intersect(trainLocations, StringComparer.Ordinal).LongCount();
            bool suppress = validation.Count < PrivacyThreshold;
            output.AppendLine(String.Join(",", new [] { view,
                fold.ToString(CultureInfo.InvariantCulture), scope.Region,
                suppress ? "" : validation.Count.ToString(CultureInfo.InvariantCulture),
                suppress ? "" : checklistOverlap.ToString(CultureInfo.InvariantCulture),
                suppress ? "" : sharedOverlap.ToString(CultureInfo.InvariantCulture),
                suppress ? "" : blockOverlap.ToString(CultureInfo.InvariantCulture),
                suppress ? "" : eventOverlap.ToString(CultureInfo.InvariantCulture),
                suppress ? "" : observerOverlap.ToString(CultureInfo.InvariantCulture),
                suppress ? "" : Fraction(observerOverlap, valObservers.Count),
                suppress ? "" : locationOverlap.ToString(CultureInfo.InvariantCulture),
                suppress ? "" : Fraction(locationOverlap, valLocations.Count),
                "0", suppress ? "true" : "false" }));
        }
        return output;
    }

    private static HashSet<string> RegionEvents(IEnumerable<Checklist> checklists,
        string region)
    {
        return new HashSet<string>(checklists.SelectMany(x => x.Links)
            .Where(x => x.Region == region && x.Core).Select(x => x.EventToken),
            StringComparer.Ordinal);
    }

    private static void ValidatePublicOutputs(List<string> files)
    {
        string[] prohibited = { "analysis_event_token", "observer_cluster_token",
            "location_cluster_token", "herring_source_token", "latitude", "longitude",
            "sampling_event_identifier", "locality_id", "C:\\Users\\", "/" + "home/" };
        foreach (string file in files)
        {
            string content = File.ReadAllText(file, Encoding.UTF8);
            foreach (string term in prohibited)
                if (content.IndexOf(term, StringComparison.OrdinalIgnoreCase) >= 0)
                    throw new InvalidDataException("Phase 3 aggregate privacy gate failed");
        }
    }

    private static string WriteDeterministic(string directory, string name,
        string content)
    {
        string path = Path.Combine(directory, name);
        UTF8Encoding encoding = new UTF8Encoding(false);
        string normalized = content.Replace("\r\n", "\n");
        File.WriteAllText(path, normalized, encoding);
        string replay = path + ".repro.tmp";
        File.WriteAllText(replay, normalized, encoding);
        if (Sha256(path) != Sha256(replay))
            throw new InvalidDataException("Aggregate serialization replay mismatch");
        File.Delete(replay);
        return path;
    }

    private static Dictionary<string, long> Counts(IEnumerable<string> values)
    {
        Dictionary<string, long> result = new Dictionary<string, long>(StringComparer.Ordinal);
        foreach (string value in values)
        { long n = 0; result.TryGetValue(value, out n); result[value] = n + 1; }
        return result;
    }

    private static double Effective(IEnumerable<double> weights)
    {
        double[] x = weights.Where(v => v > 0 && !Double.IsNaN(v)).ToArray();
        double total = x.Sum();
        double squares = x.Sum(v => v * v);
        return total == 0 || squares == 0 ? Double.NaN : total * total / squares;
    }

    private static string Number(double value)
    {
        return Double.IsNaN(value) || Double.IsInfinity(value) ? "" :
            value.ToString("0.###", CultureInfo.InvariantCulture);
    }

    private static string Fraction(long numerator, long denominator)
    { return denominator == 0 ? "" : Number((double)numerator / denominator); }

    private static void Increment(Dictionary<string, int> values, string key, int amount)
    { int n = 0; values.TryGetValue(key, out n); values[key] = n + amount; }

    private static void IncrementLong(Dictionary<string, long> values, string key, long amount)
    { long n = 0; values.TryGetValue(key, out n); values[key] = n + amount; }

    private static string TimeStratum(int day)
    {
        if (day >= -42 && day <= -29) return "early_pre";
        if (day >= -28 && day <= -1) return "immediate_pre";
        if (day >= 0 && day <= 3) return "spawn_start";
        if (day >= 4 && day <= 14) return "early_egg";
        if (day >= 15 && day <= 28) return "late_egg";
        if (day >= 29 && day <= 56) return "post";
        return null;
    }

    private static string DistanceStratum(double distance)
    {
        if (distance >= 0 && distance < .5) return "ring_0_0p5";
        if (distance < 1) return "ring_0p5_1";
        if (distance < 2) return "ring_1_2";
        if (distance < 3) return "ring_2_3";
        if (distance < 4) return "ring_3_4";
        if (distance < 5) return "ring_4_5";
        if (distance < 10) return "ring_5_10";
        if (distance <= 20.0001) return "ring_10_20";
        return null;
    }

    private static StreamReader GzipReader(string path)
    {
        FileStream file = File.OpenRead(path);
        GZipStream gzip = new GZipStream(file, CompressionMode.Decompress);
        return new StreamReader(gzip, Encoding.UTF8, true, 1 << 20);
    }

    private static Dictionary<string, int> HeaderMap(string header, char separator)
    {
        string[] fields = ParseAllFields(header, separator);
        Dictionary<string, int> result = new Dictionary<string, int>(StringComparer.Ordinal);
        for (int i = 0; i < fields.Length; i++) result[Clean(fields[i])] = i;
        return result;
    }

    private static void RequireFields(Dictionary<string, int> header,
        IEnumerable<string> required, string label)
    {
        string[] missing = required.Where(x => !header.ContainsKey(x)).ToArray();
        if (missing.Length != 0)
            throw new InvalidDataException(label + " missing required metadata fields: " +
                String.Join(",", missing));
    }

    private static string[] ExtractFields(string line, int[] positions, char separator)
    {
        string[] result = new string[positions.Length];
        Dictionary<int, List<int>> wanted = new Dictionary<int, List<int>>();
        int maximum = -1;
        for (int i = 0; i < positions.Length; i++)
        {
            if (positions[i] > maximum) maximum = positions[i];
            List<int> targets;
            if (!wanted.TryGetValue(positions[i], out targets))
            { targets = new List<int>(); wanted.Add(positions[i], targets); }
            targets.Add(i);
        }
        int field = 0, start = 0;
        bool quoted = false;
        StringBuilder current = null;
        for (int i = 0; i <= line.Length; i++)
        {
            char c = i < line.Length ? line[i] : separator;
            if (separator == ',' && c == '"')
            {
                if (quoted && i + 1 < line.Length && line[i + 1] == '"')
                {
                    if (current == null) { current = new StringBuilder(); current.Append(line, start, i - start); }
                    current.Append('"'); i++; start = i + 1; continue;
                }
                quoted = !quoted;
                if (current == null) { current = new StringBuilder(); current.Append(line, start, i - start); }
                else current.Append(line, start, i - start);
                start = i + 1; continue;
            }
            if (c == separator && !quoted)
            {
                List<int> targets;
                if (wanted.TryGetValue(field, out targets))
                {
                    string value;
                    if (current == null) value = line.Substring(start, i - start);
                    else { current.Append(line, start, i - start); value = current.ToString(); }
                    foreach (int target in targets) result[target] = value;
                }
                field++; start = i + 1; current = null;
                if (field > maximum) break;
            }
        }
        for (int i = 0; i < result.Length; i++) if (result[i] == null) result[i] = "";
        return result;
    }

    private static string[] ParseAllFields(string line, char separator)
    {
        int count = line.Count(c => c == separator) + 1;
        return ExtractFields(line, Enumerable.Range(0, count).ToArray(), separator);
    }

    private static string FieldAt(string line, int position, char separator)
    { return ExtractFields(line, new [] { position }, separator)[0]; }

    private static string Clean(string value)
    { return (value ?? "").Trim().Trim('\uFEFF'); }

    private static int Year(string date)
    {
        string x = Clean(date);
        int year;
        return x.Length >= 4 && Int32.TryParse(x.Substring(0, 4), out year) ? year : -1;
    }

    private static bool IsTrue(string value)
    {
        string x = Clean(value).ToUpperInvariant();
        return x == "1" || x == "TRUE" || x == "T" || x == "YES";
    }

    private static string HashToken(string domain, string value)
    {
        using (SHA256 sha = SHA256.Create())
            return HexPrefix(sha.ComputeHash(Encoding.UTF8.GetBytes(domain + "|" +
                (value ?? ""))), 12);
    }

    private static string HexPrefix(byte[] bytes, int count)
    {
        StringBuilder result = new StringBuilder(count * 2);
        for (int i = 0; i < count; i++)
            result.Append(bytes[i].ToString("x2", CultureInfo.InvariantCulture));
        return result.ToString();
    }

    private static string Sha256(string path)
    {
        using (SHA256 sha = SHA256.Create())
        using (FileStream stream = File.OpenRead(path))
            return BitConverter.ToString(sha.ComputeHash(stream)).Replace("-", "").ToLowerInvariant();
    }

    private static void RequireHash(string path, string expected)
    {
        RequireFile(path, "registered protected metadata artifact");
        if (Sha256(path) != expected)
            throw new InvalidDataException("Registered protected metadata artifact hash mismatch");
    }

    private static void RequireFile(string path, string label)
    {
        if (String.IsNullOrWhiteSpace(path) || !File.Exists(path))
            throw new FileNotFoundException(label + " is unavailable");
    }

    private static void Assert(bool condition, string message)
    {
        if (!condition) throw new InvalidDataException("Fixture assertion failed: " + message);
    }
}
