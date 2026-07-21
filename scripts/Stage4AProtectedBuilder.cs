using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Security.Cryptography;
using System.Text;

public static class Stage4AProtectedBuilder
{
    private const int EndYear = 2025;
    private sealed class EventRow
    {
        public string Token, Block, Observer, Location, Region, ActiveReference, Protocol;
        public int EventFold, ObserverFold, Year, ObserverCount;
        public double Duration, EffortDistance;
        public bool Shared, EffortSet;
        public readonly int[] Time = new int[6];
        public readonly int[] Distance = new int[8];
        public int ConcurrentLinks;
    }
    private sealed class SourceRef { public string Token; public bool Canonical; }

    private static readonly string[] TimeNames = {
        "early_pre", "immediate_pre", "spawn_start", "early_egg", "late_egg", "post" };
    private static readonly string[] DistanceNames = {
        "ring_0_0p5", "ring_0p5_1", "ring_1_2", "ring_2_3", "ring_3_4",
        "ring_4_5", "ring_5_10", "ring_10_20" };

    public static void RunProduction(string sedPath, string repoRoot, string protectedDirectory)
    {
        RequireFile(sedPath, "authorized SED metadata input");
        Directory.CreateDirectory(protectedDirectory);
        string assignments = Path.Combine(repoRoot, "data", "derived",
            "stage3_phase3_protected", "phase3_validation_fold_assignments.tsv.gz");
        string links = Path.Combine(repoRoot, "data", "derived",
            "stage3_phase2_protected", "metadata_source_point_links.tsv.gz");
        string crosswalk = Path.Combine(repoRoot, "data", "derived",
            "stage3_phase1_repair_protected", "private_component_crosswalk.tsv.gz");
        string states = Path.Combine(repoRoot, "data", "derived",
            "stage3_phase1_repair_protected", "reported_count_states.tsv.gz");
        string masks = Path.Combine(repoRoot, "data", "derived",
            "stage3_phase1_repair_protected", "ambiguity_masks.tsv.gz");
        RequireHash(assignments, "8cc6c52033c415d991eb423884d9cacc3da689ec8c98d3448bc0f00e147981b1");
        RequireHash(links, "f26197d0a71fd177e77774ec9e5596563c127ec8eb0f948042aff51ad805567b");
        RequireHash(crosswalk, "1b52cf8fc15f91e89d7b8a64c66d9976e0c2e6e36afef4058909d7aaad3d2f17");
        RequireHash(states, "d4d4b2ee6684c89b2e9331eb190d0cc1045f41ac30ef2f7e6d8c858c4dbc9338");
        RequireHash(masks, "cbcb4a193a273f055f17d168d9bdddcbb29789dd2c356297e0ac6d43bd052e33");

        string eventOutput = Path.Combine(protectedDirectory, "stage4a_event_metadata.tsv.gz");
        string stateOutput = Path.Combine(protectedDirectory, "stage4a_reported_states.tsv.gz");
        string maskOutput = Path.Combine(protectedDirectory, "stage4a_ambiguity_masks.tsv.gz");
        string manifest = Path.Combine(protectedDirectory, "stage4a_cache_manifest.txt");
        FileInfo sedInfo = new FileInfo(sedPath);
        string fingerprint = String.Join("|", new [] { Sha256(assignments), Sha256(links),
            Sha256(crosswalk), Sha256(states), Sha256(masks),
            sedInfo.Length.ToString(CultureInfo.InvariantCulture),
            sedInfo.LastWriteTimeUtc.Ticks.ToString(CultureInfo.InvariantCulture),
            Sha256(Path.Combine(repoRoot, "metadata", "stage4a_core_spec_v1.yml")),
            Sha256(Path.Combine(repoRoot, "metadata", "stage4a_model_specification_matrix_v1.csv")),
            Sha256(Path.Combine(repoRoot, "scripts", "Stage4AProtectedBuilder.cs")) });
        if (File.Exists(eventOutput) && File.Exists(stateOutput) && File.Exists(maskOutput) &&
            File.Exists(manifest) && File.ReadAllText(manifest, Encoding.UTF8).Trim() == fingerprint)
        {
            Console.WriteLine("Protected Stage 4A hash-identical cache reused; no source rescan.");
            Console.WriteLine("STAGE4A_PROTECTED_BUILD=PASS_REUSED");
            return;
        }

        RequireHash(sedPath, "9b5b1893ff5b37c9a4a6faa596e71a5894dcb81bafee214ace33c4beee85b6ed");

        Dictionary<string, EventRow> events = ReadAssignments(assignments);
        ReadLinks(links, events);
        Dictionary<string, SourceRef> sources = ReadCrosswalk(crosswalk, events);
        ReadSedEffort(sedPath, sources, events);
        ValidateEvents(events);
        WriteEvents(eventOutput, events);
        long stateRows = TokenizeStates(states, stateOutput, events);
        long maskRows = TokenizeMasks(masks, maskOutput, events);
        File.WriteAllText(manifest, fingerprint + "\n", new UTF8Encoding(false));
        Console.WriteLine("Protected Stage 4A cache constructed from registered through-2025 fields.");
        Console.WriteLine("Independent linked events: " + events.Count.ToString(CultureInfo.InvariantCulture));
        Console.WriteLine("Sparse reported states retained: " + stateRows.ToString(CultureInfo.InvariantCulture));
        Console.WriteLine("Sparse ambiguity masks retained: " + maskRows.ToString(CultureInfo.InvariantCulture));
        Console.WriteLine("STAGE4A_PROTECTED_BUILD=PASS_CONSTRUCTED");
    }

    public static void RunFixture()
    {
        EventRow x = new EventRow { Token = "fixture", Block = "block", Observer = "observer",
            Location = "location", Region = "SoG", ActiveReference = "active", Protocol = "traveling",
            EventFold = 1, ObserverFold = 2, Year = 2020, ObserverCount = 2, Duration = 30,
            EffortDistance = 2.5, Shared = false, EffortSet = true, ConcurrentLinks = 2 };
        AddLink(x, -7, 1.5); AddLink(x, 8, 7.0);
        Assert(x.Time[1] == 1 && x.Time[3] == 1, "all concurrent time links retained");
        Assert(x.Distance[2] == 1 && x.Distance[6] == 1, "all concurrent distance links retained");
        Assert(Eligible(x, 5), "candidate-primary fixture is eligible");
        Assert(!Eligible(x, 2), "two-kilometre fixture is sensitivity-excluded");
        Console.WriteLine("STAGE4A_PROTECTED_BUILDER_FIXTURE=PASS");
    }

    private static Dictionary<string, EventRow> ReadAssignments(string path)
    {
        Dictionary<string, EventRow> result = new Dictionary<string, EventRow>(StringComparer.Ordinal);
        using (StreamReader reader = GzipReader(path))
        {
            string header = reader.ReadLine();
            Dictionary<string, int> h = HeaderMap(header, '\t');
            string[] required = { "analysis_event_token", "event_block_token", "event_fold",
                "observer_cluster_token", "observer_fold", "location_cluster_token", "primary_region",
                "checklist_year", "active_reference_class", "shared_group" };
            RequireFields(h, required, "Stage 3 fold assignments");
            int[] p = required.Select(z => h[z]).ToArray(); string line;
            while ((line = reader.ReadLine()) != null)
            {
                string[] v = ExtractFields(line, p, '\t');
                EventRow x = new EventRow { Token = Clean(v[0]), Block = Clean(v[1]),
                    EventFold = Int32.Parse(v[2], CultureInfo.InvariantCulture), Observer = Clean(v[3]),
                    ObserverFold = Int32.Parse(v[4], CultureInfo.InvariantCulture), Location = Clean(v[5]),
                    Region = Clean(v[6]), Year = Int32.Parse(v[7], CultureInfo.InvariantCulture),
                    ActiveReference = Clean(v[8]), Shared = IsTrue(v[9]) };
                if (x.Year > EndYear || result.ContainsKey(x.Token))
                    throw new InvalidDataException("Fold-assignment date or cardinality gate failed");
                result.Add(x.Token, x);
            }
        }
        if (result.Count != 239934) throw new InvalidDataException("Stage 4A event cardinality changed");
        return result;
    }

    private static void ReadLinks(string path, Dictionary<string, EventRow> events)
    {
        using (StreamReader reader = GzipReader(path))
        {
            string header = reader.ReadLine(); Dictionary<string, int> h = HeaderMap(header, '\t');
            string[] required = { "analysis_event_token", "region", "checklist_year", "event_day", "distance_km" };
            RequireFields(h, required, "Stage 3 source-point links");
            int[] p = required.Select(z => h[z]).ToArray(); string line;
            while ((line = reader.ReadLine()) != null)
            {
                string[] v = ExtractFields(line, p, '\t'); EventRow x;
                if (!events.TryGetValue(Clean(v[0]), out x)) continue;
                int year = Int32.Parse(v[2], CultureInfo.InvariantCulture);
                if (year != x.Year)
                    throw new InvalidDataException("Event linkage metadata disagreement");
                AddLink(x, Int32.Parse(v[3], CultureInfo.InvariantCulture),
                    Double.Parse(v[4], CultureInfo.InvariantCulture));
                x.ConcurrentLinks++;
            }
        }
    }

    private static void AddLink(EventRow x, int day, double distance)
    {
        int ti = day >= -42 && day <= -29 ? 0 : day >= -28 && day <= -1 ? 1 :
            day >= 0 && day <= 3 ? 2 : day >= 4 && day <= 14 ? 3 :
            day >= 15 && day <= 28 ? 4 : day >= 29 && day <= 56 ? 5 : -1;
        int di = distance >= 0 && distance < .5 ? 0 : distance < 1 ? 1 :
            distance < 2 ? 2 : distance < 3 ? 3 : distance < 4 ? 4 :
            distance < 5 ? 5 : distance < 10 ? 6 : distance <= 20.0001 ? 7 : -1;
        if (day < -90 || day > 120 || di < 0)
            throw new InvalidDataException("Source-point link range failure");
        if (ti >= 0) x.Time[ti]++;
        x.Distance[di]++;
    }

    private static Dictionary<string, SourceRef> ReadCrosswalk(string path,
        Dictionary<string, EventRow> events)
    {
        Dictionary<string, SourceRef> result = new Dictionary<string, SourceRef>(StringComparer.Ordinal);
        using (StreamReader reader = GzipReader(path))
        {
            string header = reader.ReadLine(); Dictionary<string, int> h = HeaderMap(header, '\t');
            string[] required = { "source_sampling_event_identifier", "analysis_checklist_id",
                "canonical_effort_row" }; RequireFields(h, required, "Stage 3 component crosswalk");
            int[] p = required.Select(z => h[z]).ToArray(); string line;
            while ((line = reader.ReadLine()) != null)
            {
                string[] v = ExtractFields(line, p, '\t');
                string token = HashToken("analysis_event", Clean(v[1]));
                if (!events.ContainsKey(token)) continue;
                if (result.ContainsKey(Clean(v[0])))
                    throw new InvalidDataException("Component source cardinality failure");
                result.Add(Clean(v[0]), new SourceRef { Token = token, Canonical = IsTrue(v[2]) });
            }
        }
        return result;
    }

    private static void ReadSedEffort(string path, Dictionary<string, SourceRef> sources,
        Dictionary<string, EventRow> events)
    {
        using (StreamReader reader = new StreamReader(path, Encoding.UTF8, true, 1 << 22))
        {
            string header = reader.ReadLine(); Dictionary<string, int> h = HeaderMap(header, '\t');
            string[] required = { "SAMPLING EVENT IDENTIFIER", "OBSERVATION DATE", "PROTOCOL NAME",
                "DURATION MINUTES", "EFFORT DISTANCE KM", "NUMBER OBSERVERS", "ALL SPECIES REPORTED" };
            RequireFields(h, required, "authorized SED effort metadata");
            int dateIndex = h["OBSERVATION DATE"]; int[] p = required.Select(z => h[z]).ToArray(); string line;
            while ((line = reader.ReadLine()) != null)
            {
                string date = FieldAt(line, dateIndex, '\t'); int year = Year(date);
                if (year < 1988 || year > EndYear) continue;
                string[] v = ExtractFields(line, p, '\t'); SourceRef source;
                if (!sources.TryGetValue(Clean(v[0]), out source) || !source.Canonical) continue;
                EventRow x = events[source.Token];
                if (x.EffortSet || x.Year != year || !IsTrue(v[6]))
                    throw new InvalidDataException("Canonical effort metadata gate failed");
                x.Protocol = NormalizeProtocol(v[2]);
                x.Duration = Double.Parse(Clean(v[3]), CultureInfo.InvariantCulture);
                x.EffortDistance = x.Protocol == "stationary" ? 0 :
                    Double.Parse(Clean(v[4]), CultureInfo.InvariantCulture);
                x.ObserverCount = Int32.Parse(Clean(v[5]), CultureInfo.InvariantCulture);
                x.EffortSet = true;
            }
        }
    }

    private static bool Eligible(EventRow x, double maxDistance)
    {
        return x.EffortSet && (x.Protocol == "stationary" || x.Protocol == "traveling") &&
            x.Duration >= 5 && x.Duration <= 300 && x.ObserverCount >= 1 && x.ObserverCount <= 10 &&
            (x.Protocol == "stationary" || (x.EffortDistance >= 0 && x.EffortDistance <= maxDistance));
    }

    private static void ValidateEvents(Dictionary<string, EventRow> events)
    {
        foreach (EventRow x in events.Values)
        {
            if (!Eligible(x, 5) || x.ConcurrentLinks < 1 || x.EventFold < 1 || x.EventFold > 4 ||
                x.ObserverFold < 1 || x.ObserverFold > 4 || x.Year > EndYear ||
                x.Time.Sum() > x.ConcurrentLinks || x.Distance.Sum() != x.ConcurrentLinks)
                throw new InvalidDataException("Stage 4A registered population gate failed");
        }
    }

    private static void WriteEvents(string path, Dictionary<string, EventRow> events)
    {
        using (StreamWriter w = GzipWriter(path))
        {
            w.Write("analysis_event_token\tevent_block_token\tevent_fold\tobserver_cluster_token\tobserver_fold\tlocation_cluster_token\tregion\tchecklist_year\tactive_reference_class\tshared_group\tprotocol\tduration_minutes\teffort_distance_km\tobserver_count\tconcurrent_links");
            foreach (string n in TimeNames) w.Write("\ttime_" + n);
            foreach (string n in DistanceNames) w.Write("\tdistance_" + n);
            w.WriteLine("\thigh_precision_2km");
            foreach (EventRow x in events.Values.OrderBy(z => z.Token, StringComparer.Ordinal))
            {
                string[] basic = { x.Token, x.Block, x.EventFold.ToString(CultureInfo.InvariantCulture),
                    x.Observer, x.ObserverFold.ToString(CultureInfo.InvariantCulture), x.Location, x.Region,
                    x.Year.ToString(CultureInfo.InvariantCulture), x.ActiveReference, x.Shared ? "true" : "false",
                    x.Protocol, x.Duration.ToString("0.###", CultureInfo.InvariantCulture),
                    x.EffortDistance.ToString("0.###", CultureInfo.InvariantCulture),
                    x.ObserverCount.ToString(CultureInfo.InvariantCulture),
                    x.ConcurrentLinks.ToString(CultureInfo.InvariantCulture) };
                w.Write(String.Join("\t", basic));
                foreach (int n in x.Time) w.Write("\t" + n.ToString(CultureInfo.InvariantCulture));
                foreach (int n in x.Distance) w.Write("\t" + n.ToString(CultureInfo.InvariantCulture));
                w.WriteLine("\t" + (Eligible(x, 2) ? "true" : "false"));
            }
        }
    }

    private static long TokenizeStates(string input, string output, Dictionary<string, EventRow> events)
    {
        long kept = 0; using (StreamReader r = GzipReader(input)) using (StreamWriter w = GzipWriter(output))
        {
            string header = r.ReadLine(); Dictionary<string, int> h = HeaderMap(header, '\t');
            string[] req = { "analysis_checklist_id", "analysis_taxon_id", "detection", "numeric_count",
                "lower_bound_count", "count_type", "ambiguity_flag", "provenance" };
            RequireFields(h, req, "registered sparse count states"); int[] p = req.Select(z => h[z]).ToArray();
            w.WriteLine("analysis_event_token\tanalysis_taxon_id\tdetection\tnumeric_count\tlower_bound_count\tcount_type\tambiguity_flag\tprovenance");
            string line; while ((line = r.ReadLine()) != null)
            {
                string[] v = ExtractFields(line, p, '\t'); string token = HashToken("analysis_event", Clean(v[0]));
                if (!events.ContainsKey(token)) continue;
                w.Write(token); for (int i = 1; i < v.Length; i++) { w.Write('\t'); w.Write(Clean(v[i])); }
                w.Write('\n'); kept++;
            }
        }
        return kept;
    }

    private static long TokenizeMasks(string input, string output, Dictionary<string, EventRow> events)
    {
        long kept = 0; using (StreamReader r = GzipReader(input)) using (StreamWriter w = GzipWriter(output))
        {
            string header = r.ReadLine(); Dictionary<string, int> h = HeaderMap(header, '\t');
            string[] req = { "analysis_checklist_id", "analysis_taxon_id", "provenance" };
            RequireFields(h, req, "registered ambiguity masks"); int[] p = req.Select(z => h[z]).ToArray();
            w.WriteLine("analysis_event_token\tanalysis_taxon_id\tprovenance"); string line;
            while ((line = r.ReadLine()) != null)
            {
                string[] v = ExtractFields(line, p, '\t'); string token = HashToken("analysis_event", Clean(v[0]));
                if (!events.ContainsKey(token)) continue;
                w.WriteLine(token + "\t" + Clean(v[1]) + "\t" + Clean(v[2])); kept++;
            }
        }
        return kept;
    }

    private static StreamReader GzipReader(string path) { return new StreamReader(new GZipStream(File.OpenRead(path), CompressionMode.Decompress), Encoding.UTF8, true, 1 << 20); }
    private static StreamWriter GzipWriter(string path) { return new StreamWriter(new GZipStream(new FileStream(path, FileMode.Create, FileAccess.Write, FileShare.None), CompressionLevel.Optimal), new UTF8Encoding(false), 1 << 20); }
    private static Dictionary<string, int> HeaderMap(string header, char sep) { string[] f = ParseAllFields(header, sep); Dictionary<string, int> x = new Dictionary<string, int>(StringComparer.Ordinal); for (int i=0;i<f.Length;i++) x[Clean(f[i])] = i; return x; }
    private static void RequireFields(Dictionary<string,int> h, IEnumerable<string> req, string label) { string[] m=req.Where(x=>!h.ContainsKey(x)).ToArray(); if(m.Length>0) throw new InvalidDataException(label+" missing required fields: "+String.Join(",",m)); }
    private static string[] ExtractFields(string line, int[] positions, char sep) { string[] all=line.Split(sep); string[] result=new string[positions.Length]; for(int i=0;i<positions.Length;i++) result[i]=positions[i]<all.Length?all[positions[i]]:""; return result; }
    private static string[] ParseAllFields(string line, char sep) { return line.Split(sep); }
    private static string FieldAt(string line, int position, char sep) { string[] f=line.Split(sep); return position<f.Length?f[position]:""; }
    private static string Clean(string x) { return (x??"").Trim().Trim('\uFEFF'); }
    private static int Year(string x) { x=Clean(x); int y; return x.Length>=4&&Int32.TryParse(x.Substring(0,4),out y)?y:-1; }
    private static bool IsTrue(string x) { x=Clean(x).ToUpperInvariant(); return x=="1"||x=="TRUE"||x=="T"||x=="YES"; }
    private static string NormalizeProtocol(string x) { x=Clean(x).ToLowerInvariant(); return x.Contains("stationary")?"stationary":x.Contains("traveling")||x.Contains("travelling")?"traveling":x; }
    private static string HashToken(string domain, string value) { using(SHA256 sha=SHA256.Create()) return HexPrefix(sha.ComputeHash(Encoding.UTF8.GetBytes(domain+"|"+(value??""))),12); }
    private static string HexPrefix(byte[] bytes,int count) { StringBuilder s=new StringBuilder(count*2); for(int i=0;i<count;i++)s.Append(bytes[i].ToString("x2",CultureInfo.InvariantCulture)); return s.ToString(); }
    private static string Sha256(string path) { using(SHA256 sha=SHA256.Create())using(FileStream s=File.OpenRead(path))return BitConverter.ToString(sha.ComputeHash(s)).Replace("-","").ToLowerInvariant(); }
    private static void RequireHash(string path,string expected) { RequireFile(path,"registered protected artifact"); if(Sha256(path)!=expected)throw new InvalidDataException("Registered protected artifact hash mismatch"); }
    private static void RequireFile(string path,string label) { if(String.IsNullOrWhiteSpace(path)||!File.Exists(path))throw new FileNotFoundException(label+" is unavailable"); }
    private static void Assert(bool ok,string message) { if(!ok)throw new InvalidDataException("Fixture assertion failed: "+message); }
}
