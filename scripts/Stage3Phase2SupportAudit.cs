using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Security.Cryptography;
using System.Text;

public static class Stage3Phase2SupportAudit
{
    private const int StartYear = 1988;
    private const int EndYear = 2025;
    private const int PrivacyThreshold = 20;
    private const double EarthRadiusKm = 6371.0088;

    private sealed class SourceRef
    {
        public string AnalysisId;
        public DateTime Date;
        public bool DateSet;
        public bool Canonical;
    }

    private sealed class EventGroup
    {
        public string AnalysisId;
        public DateTime Date;
        public double Latitude;
        public double Longitude;
        public string LatitudeRaw;
        public string LongitudeRaw;
        public string Protocol;
        public double? Duration;
        public double? Distance;
        public int? Observers;
        public bool Complete;
        public bool StartTimeAvailable;
        public string ObserverToken;
        public string LocationToken;
        public int Members;
        public bool EffortDisagreement;
        public bool HasEbdIdentity;
        public bool SourceIdentityDisagreement;
        public bool MetadataSet;

        public bool BroadEligible
        {
            get { return Eligible(1, 360, 10, 20); }
        }
        public bool PrimaryEligible
        {
            get { return Eligible(5, 300, 5, 10); }
        }
        public bool HighPrecisionEligible
        {
            get { return Eligible(5, 300, 2, 10); }
        }

        private bool Eligible(double minDuration, double maxDuration,
            double maxTravelKm, int maxObservers)
        {
            if (!Complete || EffortDisagreement || !HasEbdIdentity ||
                SourceIdentityDisagreement || !Duration.HasValue ||
                !Observers.HasValue || Duration.Value < minDuration ||
                Duration.Value > maxDuration || Observers.Value < 1 ||
                Observers.Value > maxObservers) return false;
            if (Protocol == "stationary") return true;
            return Protocol == "traveling" && Distance.HasValue &&
                Distance.Value >= 0 && Distance.Value <= maxTravelKm;
        }

        public bool HasValidPoint
        {
            get { return Latitude >= -90 && Latitude <= 90 &&
                Longitude >= -180 && Longitude <= 180; }
        }
    }

    private sealed class HerringEvent
    {
        public string Token;
        public string Region;
        public int Year;
        public DateTime Date;
        public double Latitude;
        public double Longitude;
    }

    private struct Link
    {
        public int GroupIndex;
        public int EventIndex;
        public short EventDay;
        public float DistanceKm;
    }

    private sealed class Frame
    {
        public string Id;
        public Func<EventGroup, bool> Includes;
    }

    private sealed class Period
    {
        public string Id;
        public int Start;
        public int End;
    }

    private sealed class RegionAccumulator
    {
        public readonly HashSet<int> Groups = new HashSet<int>();
        public readonly HashSet<int> Events = new HashSet<int>();
        public readonly HashSet<int> PreGroups = new HashSet<int>();
        public readonly HashSet<int> ActiveGroups = new HashSet<int>();
        public readonly HashSet<int> NearGroups = new HashSet<int>();
        public readonly HashSet<int> ReferenceGroups = new HashSet<int>();
        public readonly Dictionary<int, byte> EventPeriodFlags = new Dictionary<int, byte>();
        public readonly Dictionary<int, int> LinkCounts = new Dictionary<int, int>();
        public readonly Dictionary<int, double> EventWeights = new Dictionary<int, double>();
        public readonly Dictionary<int, double> ActiveMinimumDistance = new Dictionary<int, double>();
        public readonly HashSet<int> RedistributionActiveEvents = new HashSet<int>();
        public readonly HashSet<int> RedistributionReferenceEvents = new HashSet<int>();
    }

    private sealed class YearAccumulator
    {
        public readonly HashSet<int> Groups = new HashSet<int>();
        public readonly HashSet<int> Events = new HashSet<int>();
        public readonly HashSet<int> PreGroups = new HashSet<int>();
        public readonly HashSet<int> ActiveGroups = new HashSet<int>();
        public readonly HashSet<int> NearGroups = new HashSet<int>();
        public readonly HashSet<int> ReferenceGroups = new HashSet<int>();
        public readonly Dictionary<int, byte> EventPeriodFlags = new Dictionary<int, byte>();
    }

    private sealed class RegionSummary
    {
        public string Frame;
        public string Period;
        public int StartYear;
        public int EndYear;
        public string Region;
        public long Groups;
        public long BroadGroups;
        public long Events;
        public int AdequateYears;
        public int TotalYears;
        public double PassingShare;
        public int MaxFailingRun;
        public long Observers;
        public long Locations;
        public double MaximumObserverShare;
        public double MaximumLocationShare;
        public long Stationary;
        public long Traveling;
        public double DurationQ50;
        public double DurationQ90;
        public double TravelQ50;
        public double TravelQ90;
        public double ObserverQ50;
        public double ObserverQ90;
        public long Pre;
        public long Active;
        public long Near;
        public long Reference;
        public long EventsBothPeriods;
        public double EffectiveObservers;
        public double EffectiveLocations;
        public double EffectiveEvents;
        public long RedistributionActive;
        public long RedistributionReference;
        public long RedistributionActiveEvents;
        public long RedistributionReferenceEvents;
        public bool RedistributionFeasible;
        public bool PeriodSupportPass;
        public string Recommendation;
    }

    public static void RunProduction(string ebdPath, string sedPath, string herringPath,
        string repoRoot, string protectedDirectory, string outputDirectory)
    {
        RequireFile(ebdPath, "protected EBD input");
        RequireFile(sedPath, "protected SED input");
        RequireFile(herringPath, "herring metadata input");
        Directory.CreateDirectory(protectedDirectory);
        Directory.CreateDirectory(outputDirectory);

        string eligiblePath = Path.Combine(repoRoot, "data", "derived",
            "stage3_phase1_repair_protected", "eligible_events.tsv.gz");
        string crosswalkPath = Path.Combine(repoRoot, "data", "derived",
            "stage3_phase1_repair_protected", "private_component_crosswalk.tsv.gz");
        RequireHash(eligiblePath, "473c9b866794187510d8c0911c8fe976507334ac6ad06eb0cfebe37eed51ee17");
        RequireHash(crosswalkPath, "1b52cf8fc15f91e89d7b8a64c66d9976e0c2e6e36afef4058909d7aaad3d2f17");

        HashSet<string> phase1Eligible = ReadEligibleFactor(eligiblePath);
        Dictionary<string, SourceRef> sources = ReadPrivateCrosswalk(crosswalkPath);
        Console.WriteLine("Protected Phase 1 event factor and component crosswalk verified and loaded.");

        Dictionary<string, EventGroup> groupMap = ReadSedMetadata(sedPath, sources);
        Console.WriteLine("One metadata-only SED pass completed for the frozen pre-2026 window.");
        string membershipCache = Path.Combine(protectedDirectory,
            "ebd_event_membership_date_gate.tsv.gz");
        if (File.Exists(membershipCache))
        {
            LoadMembershipCache(membershipCache, groupMap);
            Console.WriteLine("Protected EBD identity/date cache reused without a raw EBD pass.");
        }
        else
        {
            ScanEbdMembershipOnly(ebdPath, sources, groupMap);
            WriteMembershipCache(membershipCache, groupMap);
            Console.WriteLine("One justified EBD identity/date pass completed and cached without bird-response fields.");
        }

        List<EventGroup> groups = groupMap.Values.OrderBy(x => x.AnalysisId,
            StringComparer.Ordinal).ToList();
        ValidatePhase1Factor(groups, phase1Eligible);
        List<HerringEvent> events = ReadHerringSourcePointMetadata(herringPath);
        Console.WriteLine("Herring metadata selected only immutable source-point, date, and region fields.");

        List<Link> links = BuildLinks(groups, events);
        ValidateLinks(links, groups, events);
        string cachePath = Path.Combine(protectedDirectory, "metadata_source_point_links.tsv.gz");
        WriteLinkCache(cachePath, links, groups, events);
        string linkHash = Sha256(cachePath);
        Console.WriteLine("Protected metadata linkage constructed and cached once.");

        List<Frame> frames = Frames();
        List<Period> periods = Periods();
        List<RegionSummary> regionSummaries;
        List<string> outputFiles = WriteAuditOutputs(outputDirectory, groups, events,
            links, frames, periods, out regionSummaries);
        ValidatePublicOutputs(outputFiles);

        long broadCount = groups.LongCount(g => g.BroadEligible);
        long primaryCount = groups.LongCount(g => g.PrimaryEligible);
        long highCount = groups.LongCount(g => g.HighPrecisionEligible);
        WriteExecutionSummary(outputDirectory, groups, events, links, phase1Eligible.Count,
            broadCount, primaryCount, highCount, linkHash, outputFiles, regionSummaries);
        Console.WriteLine("STAGE3_PHASE2_GATE=PASS_PENDING_HUMAN_SAMPLING_SUPPORT_REVIEW");
    }

    public static void RunFixture()
    {
        EventGroup broadOnly = FixtureGroup("broad", "traveling", 350, 8, 15, true);
        broadOnly.HasEbdIdentity = true;
        EventGroup primary = FixtureGroup("primary", "traveling", 120, 4, 2, true);
        primary.HasEbdIdentity = true;
        EventGroup high = FixtureGroup("high", "traveling", 120, 2, 2, true);
        high.HasEbdIdentity = true;
        EventGroup stationary = FixtureGroup("stationary", "stationary", 20, 0, 1, true);
        stationary.HasEbdIdentity = true;
        Assert(broadOnly.BroadEligible && !broadOnly.PrimaryEligible,
            "broad fixture separates the frozen effort frames");
        Assert(primary.PrimaryEligible && !primary.HighPrecisionEligible,
            "primary fixture separates 5 km from 2 km");
        Assert(high.HighPrecisionEligible && stationary.HighPrecisionEligible,
            "high-precision fixture includes valid traveling and stationary events");
        primary.EffortDisagreement = true;
        Assert(!primary.BroadEligible, "effort disagreement remains excluded");
        primary.EffortDisagreement = false;
        primary.SourceIdentityDisagreement = true;
        Assert(!primary.BroadEligible, "date disagreement remains quarantined");
        Assert(PrivacySafe(19, 19) == "" && PrivacySafe(20, 20) == "20",
            "privacy threshold suppresses cells below 20");
        Assert(Math.Abs(HaversineKm(49, -123, 49, -123)) < 0.000001,
            "source-point distance fixture");
        List<EventGroup> fixtureGroups = new List<EventGroup> { high };
        List<HerringEvent> fixtureEvents = new List<HerringEvent> {
            new HerringEvent { Region = "fixture_region", Year = 2020,
                Date = new DateTime(2020, 3, 1), Latitude = 49, Longitude = -123 },
            new HerringEvent { Region = "fixture_region", Year = 2020,
                Date = new DateTime(2020, 3, 2), Latitude = 49, Longitude = -123 }
        };
        List<Link> fixtureLinks = new List<Link> {
            new Link { GroupIndex = 0, EventIndex = 0, EventDay = 0, DistanceKm = 1 },
            new Link { GroupIndex = 0, EventIndex = 1, EventDay = 1, DistanceKm = 1 }
        };
        ValidateLinks(fixtureLinks, fixtureGroups, fixtureEvents);
        Dictionary<string, RegionAccumulator> fixtureRegions;
        Dictionary<string, YearAccumulator> fixtureYears;
        Dictionary<string, HashSet<int>> fixtureStratumGroups;
        Dictionary<string, HashSet<int>> fixtureStratumEvents;
        BuildCombination(new Frame { Id = "fixture", Includes = g => g.HighPrecisionEligible },
            new Period { Id = "fixture", Start = 2020, End = 2020 }, fixtureGroups,
            fixtureEvents, fixtureLinks, out fixtureRegions, out fixtureYears,
            out fixtureStratumGroups, out fixtureStratumEvents);
        Assert(fixtureRegions["fixture_region"].Groups.Count == 1 &&
            fixtureRegions["fixture_region"].Events.Count == 2,
            "concurrent source-event links do not duplicate the independent checklist");
        Console.WriteLine("STAGE3_PHASE2_FIXTURE=PASS");
    }

    private static EventGroup FixtureGroup(string id, string protocol, double duration,
        double distance, int observers, bool complete)
    {
        return new EventGroup { AnalysisId = id, Protocol = protocol,
            Duration = duration, Distance = distance, Observers = observers,
            Complete = complete, MetadataSet = true, Latitude = 49, Longitude = -123,
            Date = new DateTime(2020, 3, 1), Members = 1,
            ObserverToken = "fxobs", LocationToken = "fxloc" };
    }

    private static HashSet<string> ReadEligibleFactor(string path)
    {
        HashSet<string> ids = new HashSet<string>(StringComparer.Ordinal);
        using (StreamReader reader = GzipReader(path))
        {
            string header = reader.ReadLine();
            if (header != "analysis_checklist_id\teligibility_provenance")
                throw new InvalidDataException("Phase 1 eligible-event factor schema mismatch");
            string line;
            while ((line = reader.ReadLine()) != null)
            {
                int tab = line.IndexOf('\t');
                string id = tab < 0 ? line : line.Substring(0, tab);
                if (id.Length == 0 || !ids.Add(id))
                    throw new InvalidDataException("Phase 1 eligible-event factor cardinality failure");
            }
        }
        if (ids.Count != 1433786)
            throw new InvalidDataException("Approved Phase 1 event cardinality changed");
        return ids;
    }

    private static Dictionary<string, SourceRef> ReadPrivateCrosswalk(string path)
    {
        Dictionary<string, SourceRef> sources = new Dictionary<string, SourceRef>(
            StringComparer.Ordinal);
        using (StreamReader reader = GzipReader(path))
        {
            string header = reader.ReadLine();
            if (header == null) throw new InvalidDataException("Private crosswalk is empty");
            Dictionary<string, int> h = HeaderMap(header, '\t');
            RequireFields(h, new [] { "source_sampling_event_identifier",
                "analysis_checklist_id", "canonical_sampling_event_identifier",
                "canonical_effort_row" }, "private component crosswalk");
            int[] positions = { h["source_sampling_event_identifier"],
                h["analysis_checklist_id"], h["canonical_sampling_event_identifier"],
                h["canonical_effort_row"] };
            string line;
            while ((line = reader.ReadLine()) != null)
            {
                string[] v = ExtractFields(line, positions, '\t');
                string source = Clean(v[0]);
                string analysis = Clean(v[1]);
                string canonical = Clean(v[2]);
                bool canonicalRow = IsTrue(v[3]);
                if (source.Length == 0 || analysis.Length == 0 || sources.ContainsKey(source))
                    throw new InvalidDataException("Private crosswalk source cardinality failure");
                if (canonicalRow != String.Equals(source, canonical, StringComparison.Ordinal))
                    throw new InvalidDataException("Private crosswalk canonical-row inconsistency");
                sources.Add(source, new SourceRef { AnalysisId = analysis,
                    Canonical = canonicalRow });
            }
        }
        if (sources.Count == 0) throw new InvalidDataException("Private crosswalk has no rows");
        return sources;
    }

    private static Dictionary<string, EventGroup> ReadSedMetadata(string path,
        Dictionary<string, SourceRef> sources)
    {
        Dictionary<string, EventGroup> groups = new Dictionary<string, EventGroup>(
            StringComparer.Ordinal);
        HashSet<string> seenSources = new HashSet<string>(StringComparer.Ordinal);
        using (StreamReader reader = new StreamReader(path, Encoding.UTF8, true, 1 << 22))
        {
            string header = reader.ReadLine();
            if (header == null) throw new InvalidDataException("SED is empty");
            Dictionary<string, int> h = HeaderMap(header, '\t');
            string[] required = { "SAMPLING EVENT IDENTIFIER", "LOCALITY ID",
                "LATITUDE", "LONGITUDE", "OBSERVATION DATE",
                "TIME OBSERVATIONS STARTED", "OBSERVER ID", "PROTOCOL NAME",
                "DURATION MINUTES", "EFFORT DISTANCE KM", "NUMBER OBSERVERS",
                "ALL SPECIES REPORTED", "GROUP IDENTIFIER" };
            RequireFields(h, required, "SED metadata");
            int dateIndex = h["OBSERVATION DATE"];
            int[] positions = required.Select(x => h[x]).ToArray();
            string line;
            while ((line = reader.ReadLine()) != null)
            {
                string dateRaw = FieldAt(line, dateIndex, '\t');
                int year = Year(dateRaw);
                if (year < StartYear || year > EndYear) continue;
                string[] v = ExtractFields(line, positions, '\t');
                string sourceId = Clean(v[0]);
                SourceRef source;
                if (!sources.TryGetValue(sourceId, out source))
                    throw new InvalidDataException("In-window SED source missing from approved crosswalk");
                if (!seenSources.Add(sourceId))
                    throw new InvalidDataException("Duplicate in-window SED source identifier");
                DateTime date = ParseDate(v[4]);
                source.Date = date;
                source.DateSet = true;
                string groupRaw = Clean(v[12]);
                string expectedAnalysis = groupRaw.Length == 0 ? sourceId : groupRaw;
                if (!String.Equals(expectedAnalysis, source.AnalysisId, StringComparison.Ordinal))
                    throw new InvalidDataException("SED-to-crosswalk analysis-event mismatch");

                string protocol = NormalizeProtocol(v[7]);
                double? duration = NullableDouble(v[8]);
                double? distance = NormalizeDistance(protocol, NullableDouble(v[9]));
                int? observers = NullableInt(v[10]);
                bool complete = IsTrue(v[11]);
                string latitudeRaw = Clean(v[2]);
                string longitudeRaw = Clean(v[3]);
                double latitude = NullableDouble(latitudeRaw) ?? Double.NaN;
                double longitude = NullableDouble(longitudeRaw) ?? Double.NaN;
                string observerToken = HashToken("observer", Clean(v[6]));
                string locationToken = HashToken("location", Clean(v[1]));
                bool startAvailable = Clean(v[5]).Length != 0;

                EventGroup group;
                if (!groups.TryGetValue(source.AnalysisId, out group))
                {
                    group = new EventGroup { AnalysisId = source.AnalysisId };
                    groups.Add(source.AnalysisId, group);
                }
                AddSedMember(group, date, latitude, longitude, latitudeRaw, longitudeRaw,
                    protocol, duration,
                    distance, observers, complete, startAvailable, observerToken,
                    locationToken, source.Canonical);
            }
        }
        if (seenSources.Count != sources.Count)
            throw new InvalidDataException("Approved crosswalk and SED in-window source cardinalities differ");
        foreach (EventGroup group in groups.Values)
        {
            if (group.Members > 1)
                group.ObserverToken = HashToken("shared_group", group.AnalysisId);
            if (!group.MetadataSet)
                throw new InvalidDataException("Analysis event lacks canonical effort metadata");
        }
        return groups;
    }

    private static void AddSedMember(EventGroup group, DateTime date, double latitude,
        double longitude, string latitudeRaw, string longitudeRaw, string protocol,
        double? duration, double? distance,
        int? observers, bool complete, bool startAvailable, string observerToken,
        string locationToken, bool canonical)
    {
        group.Members++;
        if (!group.MetadataSet)
        {
            SetMetadata(group, date, latitude, longitude, latitudeRaw, longitudeRaw,
                protocol, duration, distance,
                observers, complete, startAvailable, observerToken, locationToken);
            group.MetadataSet = true;
            return;
        }
        if (group.Date != date || group.LatitudeRaw != latitudeRaw ||
            group.LongitudeRaw != longitudeRaw ||
            group.Protocol != protocol || !NullableEqual(group.Duration, duration) ||
            !NullableEqual(group.Distance, distance) || !NullableEqual(group.Observers, observers) ||
            group.Complete != complete)
            group.EffortDisagreement = true;
        if (canonical)
            SetMetadata(group, date, latitude, longitude, latitudeRaw, longitudeRaw,
                protocol, duration, distance,
                observers, complete, startAvailable, observerToken, locationToken);
    }

    private static void SetMetadata(EventGroup group, DateTime date, double latitude,
        double longitude, string latitudeRaw, string longitudeRaw, string protocol,
        double? duration, double? distance,
        int? observers, bool complete, bool startAvailable, string observerToken,
        string locationToken)
    {
        group.Date = date;
        group.Latitude = latitude;
        group.Longitude = longitude;
        group.LatitudeRaw = latitudeRaw;
        group.LongitudeRaw = longitudeRaw;
        group.Protocol = protocol;
        group.Duration = duration;
        group.Distance = distance;
        group.Observers = observers;
        group.Complete = complete;
        group.StartTimeAvailable = startAvailable;
        group.ObserverToken = observerToken;
        group.LocationToken = locationToken;
    }

    private static void ScanEbdMembershipOnly(string path,
        Dictionary<string, SourceRef> sources, Dictionary<string, EventGroup> groups)
    {
        long inWindowRows = 0;
        long unmatchedRows = 0;
        using (StreamReader reader = new StreamReader(path, Encoding.UTF8, true, 1 << 22))
        {
            string header = reader.ReadLine();
            if (header == null) throw new InvalidDataException("EBD is empty");
            Dictionary<string, int> h = HeaderMap(header, '\t');
            RequireFields(h, new [] { "SAMPLING EVENT IDENTIFIER", "OBSERVATION DATE" },
                "EBD metadata-only identity scan");
            int sourceIndex = h["SAMPLING EVENT IDENTIFIER"];
            int dateIndex = h["OBSERVATION DATE"];
            int[] positions = { sourceIndex, dateIndex };
            string line;
            while ((line = reader.ReadLine()) != null)
            {
                string dateRaw = FieldAt(line, dateIndex, '\t');
                int year = Year(dateRaw);
                if (year < StartYear || year > EndYear) continue;
                inWindowRows++;
                string[] v = ExtractFields(line, positions, '\t');
                SourceRef source;
                if (!sources.TryGetValue(Clean(v[0]), out source))
                {
                    unmatchedRows++;
                    continue;
                }
                EventGroup group = groups[source.AnalysisId];
                group.HasEbdIdentity = true;
                DateTime ebdDate = ParseDate(v[1]);
                if (!source.DateSet || ebdDate != source.Date)
                    group.SourceIdentityDisagreement = true;
            }
        }
        if (inWindowRows == 0 || unmatchedRows != 0)
            throw new InvalidDataException("EBD-to-SED metadata identity gate failed");
    }

    private static void WriteMembershipCache(string path,
        Dictionary<string, EventGroup> groups)
    {
        using (FileStream file = File.Create(path))
        using (GZipStream gzip = new GZipStream(file, CompressionLevel.Optimal))
        using (StreamWriter writer = new StreamWriter(gzip, new UTF8Encoding(false)))
        {
            writer.NewLine = "\n";
            writer.WriteLine("analysis_checklist_id\thas_ebd_identity\tdate_disagreement");
            foreach (EventGroup group in groups.Values.OrderBy(x => x.AnalysisId,
                StringComparer.Ordinal))
            {
                writer.Write(group.AnalysisId); writer.Write('\t');
                writer.Write(group.HasEbdIdentity ? "true" : "false"); writer.Write('\t');
                writer.Write(group.SourceIdentityDisagreement ? "true" : "false"); writer.Write('\n');
            }
        }
    }

    private static void LoadMembershipCache(string path,
        Dictionary<string, EventGroup> groups)
    {
        int rows = 0;
        using (StreamReader reader = GzipReader(path))
        {
            string header = reader.ReadLine();
            if (header != "analysis_checklist_id\thas_ebd_identity\tdate_disagreement")
                throw new InvalidDataException("Protected membership cache schema mismatch");
            string line;
            while ((line = reader.ReadLine()) != null)
            {
                string[] v = line.Split('\t');
                EventGroup group;
                if (v.Length != 3 || !groups.TryGetValue(v[0], out group))
                    throw new InvalidDataException("Protected membership cache join failure");
                group.HasEbdIdentity = IsTrue(v[1]);
                group.SourceIdentityDisagreement = IsTrue(v[2]);
                rows++;
            }
        }
        if (rows != groups.Count)
            throw new InvalidDataException("Protected membership cache cardinality failure");
    }

    private static void ValidatePhase1Factor(List<EventGroup> groups,
        HashSet<string> phase1Eligible)
    {
        HashSet<string> computed = new HashSet<string>(groups.Where(g => g.PrimaryEligible)
            .Select(g => g.AnalysisId), StringComparer.Ordinal);
        if (computed.Count != phase1Eligible.Count || !computed.SetEquals(phase1Eligible))
            throw new InvalidDataException("Primary frame does not reproduce approved Phase 1 factor");
        long high = groups.LongCount(g => g.HighPrecisionEligible);
        long broad = groups.LongCount(g => g.BroadEligible);
        if (high > computed.Count || broad < computed.Count)
            throw new InvalidDataException("Frozen effort-frame nesting gate failed");
    }

    private static List<HerringEvent> ReadHerringSourcePointMetadata(string path)
    {
        List<HerringEvent> events = new List<HerringEvent>();
        using (StreamReader reader = new StreamReader(path, Encoding.UTF8, true, 1 << 20))
        {
            string header = reader.ReadLine();
            if (header == null) throw new InvalidDataException("Herring metadata is empty");
            Dictionary<string, int> h = HeaderMap(header, ',');
            string[] allowed = { "Region", "Year", "StatisticalArea", "Section",
                "LocationCode", "SpawnNumber", "StartDate", "EndDate",
                "Longitude", "Latitude" };
            RequireFields(h, allowed, "herring source-point metadata");
            int[] positions = allowed.Select(x => h[x]).ToArray();
            string line;
            int sourceRow = 0;
            while ((line = reader.ReadLine()) != null)
            {
                sourceRow++;
                string[] v = ExtractFields(line, positions, ',');
                int year;
                if (!Int32.TryParse(Clean(v[1]), NumberStyles.Integer,
                    CultureInfo.InvariantCulture, out year) || year < StartYear || year > EndYear)
                    continue;
                DateTime? start = NullableDate(v[6]);
                DateTime? end = NullableDate(v[7]);
                DateTime date;
                if (start.HasValue && end.HasValue)
                    date = start.Value.AddDays(Math.Floor((end.Value - start.Value).TotalDays / 2.0));
                else if (start.HasValue) date = start.Value;
                else if (end.HasValue) date = end.Value;
                else continue;
                double? latitudeValue = NullableDouble(v[9]);
                double? longitudeValue = NullableDouble(v[8]);
                if (!latitudeValue.HasValue || !longitudeValue.HasValue) continue;
                double latitude = latitudeValue.Value;
                double longitude = longitudeValue.Value;
                if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180)
                    continue;
                string region = Clean(v[0]);
                if (region.Length == 0) region = "UNASSIGNED";
                string identity = String.Join("|", new [] { sourceRow.ToString(CultureInfo.InvariantCulture),
                    year.ToString(CultureInfo.InvariantCulture), Clean(v[2]), Clean(v[3]),
                    Clean(v[4]), Clean(v[5]) });
                events.Add(new HerringEvent { Token = HashToken("herring_source", identity),
                    Region = region, Year = year, Date = date,
                    Latitude = latitude, Longitude = longitude });
            }
        }
        if (events.Count == 0) throw new InvalidDataException("No pre-2026 herring source points available");
        return events;
    }

    private static List<Link> BuildLinks(List<EventGroup> groups, List<HerringEvent> events)
    {
        Dictionary<long, List<int>> grid = new Dictionary<long, List<int>>();
        for (int i = 0; i < events.Count; i++)
        {
            HerringEvent e = events[i];
            long key = GridKey(e.Year, LatBin(e.Latitude), LonBin(e.Longitude));
            List<int> bucket;
            if (!grid.TryGetValue(key, out bucket))
            {
                bucket = new List<int>();
                grid.Add(key, bucket);
            }
            bucket.Add(i);
        }

        List<Link> links = new List<Link>();
        for (int gi = 0; gi < groups.Count; gi++)
        {
            EventGroup g = groups[gi];
            if (!g.BroadEligible || !g.HasValidPoint) continue;
            int latBin = LatBin(g.Latitude);
            int lonBin = LonBin(g.Longitude);
            for (int year = g.Date.Year - 1; year <= g.Date.Year + 1; year++)
            for (int latOffset = -1; latOffset <= 1; latOffset++)
            for (int lonOffset = -2; lonOffset <= 2; lonOffset++)
            {
                List<int> bucket;
                if (!grid.TryGetValue(GridKey(year, latBin + latOffset,
                    lonBin + lonOffset), out bucket)) continue;
                foreach (int ei in bucket)
                {
                    HerringEvent e = events[ei];
                    int day = (int)(g.Date - e.Date).TotalDays;
                    if (day < -90 || day > 120) continue;
                    double distance = HaversineKm(g.Latitude, g.Longitude,
                        e.Latitude, e.Longitude);
                    if (distance > 20.0) continue;
                    links.Add(new Link { GroupIndex = gi, EventIndex = ei,
                        EventDay = (short)day, DistanceKm = (float)distance });
                }
            }
        }
        return links;
    }

    private static void ValidateLinks(List<Link> links, List<EventGroup> groups,
        List<HerringEvent> events)
    {
        if (links.Count == 0) throw new InvalidDataException("No source-point metadata links constructed");
        HashSet<long> keys = new HashSet<long>();
        foreach (Link link in links)
        {
            if (link.GroupIndex < 0 || link.GroupIndex >= groups.Count ||
                link.EventIndex < 0 || link.EventIndex >= events.Count ||
                link.EventDay < -90 || link.EventDay > 120 ||
                link.DistanceKm < 0 || link.DistanceKm > 20.0001)
                throw new InvalidDataException("Source-point link range gate failed");
            long key = ((long)link.GroupIndex << 32) | (uint)link.EventIndex;
            if (!keys.Add(key))
                throw new InvalidDataException("Checklist-to-source-event join cardinality inflation");
        }
    }

    private static void WriteLinkCache(string path, List<Link> links,
        List<EventGroup> groups, List<HerringEvent> events)
    {
        using (FileStream file = File.Create(path))
        using (GZipStream gzip = new GZipStream(file, CompressionLevel.Optimal))
        using (StreamWriter writer = new StreamWriter(gzip, new UTF8Encoding(false)))
        {
            writer.NewLine = "\n";
            writer.WriteLine("analysis_event_token\therring_source_token\tregion\tchecklist_year\tevent_year\tevent_day\tdistance_km");
            foreach (Link link in links)
            {
                EventGroup g = groups[link.GroupIndex];
                HerringEvent e = events[link.EventIndex];
                writer.Write(HashToken("analysis_event", g.AnalysisId)); writer.Write('\t');
                writer.Write(e.Token); writer.Write('\t');
                writer.Write(CsvSafe(e.Region)); writer.Write('\t');
                writer.Write(g.Date.Year.ToString(CultureInfo.InvariantCulture)); writer.Write('\t');
                writer.Write(e.Year.ToString(CultureInfo.InvariantCulture)); writer.Write('\t');
                writer.Write(link.EventDay.ToString(CultureInfo.InvariantCulture)); writer.Write('\t');
                writer.Write(link.DistanceKm.ToString("0.000", CultureInfo.InvariantCulture));
                writer.Write('\n');
            }
        }
    }

    private static List<Frame> Frames()
    {
        return new List<Frame> {
            new Frame { Id = "high_spatial_precision", Includes = g => g.HighPrecisionEligible },
            new Frame { Id = "candidate_primary", Includes = g => g.PrimaryEligible },
            new Frame { Id = "registered_broad", Includes = g => g.BroadEligible }
        };
    }

    private static List<Period> Periods()
    {
        return new List<Period> {
            new Period { Id = "complete_1988_2025", Start = 1988, End = 2025 },
            new Period { Id = "start_2005", Start = 2005, End = 2025 },
            new Period { Id = "start_2010", Start = 2010, End = 2025 },
            new Period { Id = "start_2015", Start = 2015, End = 2025 }
        };
    }

    private static int LatBin(double latitude) { return (int)Math.Floor((latitude + 90.0) * 4.0); }
    private static int LonBin(double longitude) { return (int)Math.Floor((longitude + 180.0) * 4.0); }
    private static long GridKey(int year, int lat, int lon)
    {
        return ((long)year << 32) ^ ((long)(lat & 0xffff) << 16) ^ (uint)(lon & 0xffff);
    }

    private static List<string> WriteAuditOutputs(string outputDirectory,
        List<EventGroup> groups, List<HerringEvent> events, List<Link> links,
        List<Frame> frames, List<Period> periods,
        out List<RegionSummary> regionSummaries)
    {
        List<string> files = new List<string>();
        Dictionary<string, long> broadOverall = new Dictionary<string, long>();
        foreach (Period period in periods)
            broadOverall[period.Id] = groups.LongCount(g => g.BroadEligible &&
                g.Date.Year >= period.Start && g.Date.Year <= period.End);

        StringBuilder overall = new StringBuilder();
        overall.AppendLine("effort_frame,period_id,start_year,end_year,independent_eligible_events,retained_percentage_of_broad,source_point_linked_events,usable_herring_source_events,unique_observer_clusters,unique_generalized_locations,maximum_observer_share,maximum_location_share,effective_observer_replication,effective_location_replication,stationary_events,traveling_events,start_time_available_percentage,duration_q50,duration_q90,travel_distance_q50,travel_distance_q90,observer_number_q50,observer_number_q90");
        foreach (Frame frame in frames)
        foreach (Period period in periods)
        {
            List<int> ids = new List<int>();
            for (int i = 0; i < groups.Count; i++)
                if (frame.Includes(groups[i]) && groups[i].Date.Year >= period.Start &&
                    groups[i].Date.Year <= period.End) ids.Add(i);
            HashSet<int> idSet = new HashSet<int>(ids);
            HashSet<int> linked = new HashSet<int>();
            HashSet<int> coveredEvents = new HashSet<int>();
            foreach (Link link in links)
            {
                if (!idSet.Contains(link.GroupIndex) || link.EventDay < -60 || link.EventDay > 90)
                    continue;
                linked.Add(link.GroupIndex);
                coveredEvents.Add(link.EventIndex);
            }
            AppendOverallRow(overall, frame, period, ids, broadOverall[period.Id],
                linked.Count, coveredEvents.Count, groups);
        }
        files.Add(WriteDeterministic(outputDirectory, "frame_period_retention.csv", overall.ToString()));

        regionSummaries = new List<RegionSummary>();
        StringBuilder strata = new StringBuilder();
        strata.AppendLine("effort_frame,period_id,region,event_time_stratum,distance_stratum,independent_events,herring_source_events,unique_observer_clusters,unique_generalized_locations,suppressed_below_20");
        foreach (Frame frame in frames)
        foreach (Period period in periods)
        {
            Dictionary<string, RegionAccumulator> regionAcc;
            Dictionary<string, YearAccumulator> yearAcc;
            Dictionary<string, HashSet<int>> stratumGroups;
            Dictionary<string, HashSet<int>> stratumEvents;
            BuildCombination(frame, period, groups, events, links, out regionAcc,
                out yearAcc, out stratumGroups, out stratumEvents);
            foreach (string region in regionAcc.Keys.OrderBy(x => x, StringComparer.Ordinal))
                regionSummaries.Add(SummarizeRegion(frame, period, region,
                    regionAcc[region], yearAcc, groups));
            AppendStrata(strata, frame, period, regionAcc.Keys, stratumGroups,
                stratumEvents, groups);
        }

        Dictionary<string, long> broadRegionCounts = regionSummaries
            .Where(x => x.Frame == "registered_broad")
            .ToDictionary(x => x.Period + "|" + x.Region, x => x.Groups,
                StringComparer.Ordinal);
        Dictionary<string, RegionSummary> primaryRegions = regionSummaries
            .Where(x => x.Frame == "candidate_primary")
            .ToDictionary(x => x.Period + "|" + x.Region, x => x,
                StringComparer.Ordinal);
        foreach (RegionSummary summary in regionSummaries)
        {
            long broad;
            if (broadRegionCounts.TryGetValue(summary.Period + "|" + summary.Region, out broad))
                summary.BroadGroups = broad;
            summary.Recommendation = RecommendRegion(summary, primaryRegions);
        }

        StringBuilder regionCsv = new StringBuilder();
        regionCsv.AppendLine("effort_frame,period_id,start_year,end_year,region,independent_linked_events,retained_percentage_of_broad,adequate_years,total_years,passing_year_share,maximum_consecutive_failing_years,unique_observer_clusters,unique_generalized_locations,maximum_observer_share,maximum_location_share,effective_observer_replication,effective_location_replication,effective_herring_event_replication,stationary_events,traveling_events,duration_q50,duration_q90,travel_distance_q50,travel_distance_q90,observer_number_q50,observer_number_q90,usable_herring_source_events,immediate_pre_events,spawn_to_late_egg_events,near_ring_events,reference_ring_events,herring_events_with_both_primary_periods,redistribution_active_events,redistribution_reference_events,redistribution_active_source_events,redistribution_reference_source_events,redistribution_feasible,period_support_pass,recommendation,suppressed_below_20");
        foreach (RegionSummary summary in regionSummaries.OrderBy(x => x.Frame,
            StringComparer.Ordinal).ThenBy(x => x.Period, StringComparer.Ordinal)
            .ThenBy(x => x.Region, StringComparer.Ordinal))
            AppendRegionRow(regionCsv, summary);
        files.Add(WriteDeterministic(outputDirectory, "region_period_support.csv", regionCsv.ToString()));
        files.Add(WriteDeterministic(outputDirectory, "event_time_distance_support.csv", strata.ToString()));

        StringBuilder tradeoffs = BuildTradeoffRecommendations(regionSummaries, groups,
            events, links, periods);
        files.Add(WriteDeterministic(outputDirectory, "sampling_support_recommendations.csv",
            tradeoffs.ToString()));
        return files;
    }

    private static void AppendOverallRow(StringBuilder output, Frame frame, Period period,
        List<int> ids, long broadCount, long linkedCount, long coveredEvents,
        List<EventGroup> groups)
    {
        List<EventGroup> z = ids.Select(i => groups[i]).ToList();
        Dictionary<string, long> obs = Counts(z.Select(g => g.ObserverToken));
        Dictionary<string, long> loc = Counts(z.Select(g => g.LocationToken));
        List<double> duration = z.Where(g => g.Duration.HasValue).Select(g => g.Duration.Value).ToList();
        List<double> travel = z.Where(g => g.Protocol == "traveling" && g.Distance.HasValue)
            .Select(g => g.Distance.Value).ToList();
        List<double> observers = z.Where(g => g.Observers.HasValue)
            .Select(g => (double)g.Observers.Value).ToList();
        string[] values = {
            frame.Id, period.Id, period.Start.ToString(CultureInfo.InvariantCulture),
            period.End.ToString(CultureInfo.InvariantCulture), ids.Count.ToString(CultureInfo.InvariantCulture),
            Percent(ids.Count, broadCount), linkedCount.ToString(CultureInfo.InvariantCulture),
            coveredEvents.ToString(CultureInfo.InvariantCulture), obs.Count.ToString(CultureInfo.InvariantCulture),
            loc.Count.ToString(CultureInfo.InvariantCulture), Share(obs), Share(loc),
            Effective(obs.Values.Select(x => (double)x)), Effective(loc.Values.Select(x => (double)x)),
            z.LongCount(g => g.Protocol == "stationary").ToString(CultureInfo.InvariantCulture),
            z.LongCount(g => g.Protocol == "traveling").ToString(CultureInfo.InvariantCulture),
            Percent(z.LongCount(g => g.StartTimeAvailable), z.Count),
            Number(Quantile(duration, .5)), Number(Quantile(duration, .9)),
            Number(Quantile(travel, .5)), Number(Quantile(travel, .9)),
            Number(Quantile(observers, .5)), Number(Quantile(observers, .9))
        };
        output.AppendLine(String.Join(",", values));
    }

    private static void BuildCombination(Frame frame, Period period,
        List<EventGroup> groups, List<HerringEvent> events, List<Link> links,
        out Dictionary<string, RegionAccumulator> regions,
        out Dictionary<string, YearAccumulator> years,
        out Dictionary<string, HashSet<int>> stratumGroups,
        out Dictionary<string, HashSet<int>> stratumEvents)
    {
        regions = new Dictionary<string, RegionAccumulator>(StringComparer.Ordinal);
        years = new Dictionary<string, YearAccumulator>(StringComparer.Ordinal);
        stratumGroups = new Dictionary<string, HashSet<int>>(StringComparer.Ordinal);
        stratumEvents = new Dictionary<string, HashSet<int>>(StringComparer.Ordinal);
        foreach (Link link in links)
        {
            EventGroup group = groups[link.GroupIndex];
            if (!frame.Includes(group) || group.Date.Year < period.Start ||
                group.Date.Year > period.End) continue;
            string region = events[link.EventIndex].Region;
            RegionAccumulator ra = GetRegion(regions, region);
            if (link.EventDay >= -60 && link.EventDay <= 90)
            {
                ra.Groups.Add(link.GroupIndex);
                ra.Events.Add(link.EventIndex);
                if (link.EventDay >= -28 && link.EventDay <= -1) ra.PreGroups.Add(link.GroupIndex);
                if (link.EventDay >= 0 && link.EventDay <= 28) ra.ActiveGroups.Add(link.GroupIndex);
                if (link.DistanceKm < 5) ra.NearGroups.Add(link.GroupIndex);
                else ra.ReferenceGroups.Add(link.GroupIndex);
                byte flags = 0;
                ra.EventPeriodFlags.TryGetValue(link.EventIndex, out flags);
                if (link.EventDay >= -28 && link.EventDay <= -1) flags |= 1;
                if (link.EventDay >= 0 && link.EventDay <= 28) flags |= 2;
                ra.EventPeriodFlags[link.EventIndex] = flags;
                int count;
                ra.LinkCounts.TryGetValue(link.GroupIndex, out count);
                ra.LinkCounts[link.GroupIndex] = count + 1;

                string ykey = region + "|" + group.Date.Year.ToString(CultureInfo.InvariantCulture);
                YearAccumulator ya;
                if (!years.TryGetValue(ykey, out ya)) { ya = new YearAccumulator(); years.Add(ykey, ya); }
                ya.Groups.Add(link.GroupIndex); ya.Events.Add(link.EventIndex);
                if (link.EventDay >= -28 && link.EventDay <= -1) ya.PreGroups.Add(link.GroupIndex);
                if (link.EventDay >= 0 && link.EventDay <= 28) ya.ActiveGroups.Add(link.GroupIndex);
                if (link.DistanceKm < 5) ya.NearGroups.Add(link.GroupIndex); else ya.ReferenceGroups.Add(link.GroupIndex);
                byte yflags = 0; ya.EventPeriodFlags.TryGetValue(link.EventIndex, out yflags);
                if (link.EventDay >= -28 && link.EventDay <= -1) yflags |= 1;
                if (link.EventDay >= 0 && link.EventDay <= 28) yflags |= 2;
                ya.EventPeriodFlags[link.EventIndex] = yflags;
            }
            if (link.EventDay >= 0 && link.EventDay <= 28)
            {
                double old;
                if (!ra.ActiveMinimumDistance.TryGetValue(link.GroupIndex, out old) || link.DistanceKm < old)
                    ra.ActiveMinimumDistance[link.GroupIndex] = link.DistanceKm;
            }
            string time = TimeStratum(link.EventDay);
            string distance = DistanceStratum(link.DistanceKm);
            if (time != null && distance != null)
            {
                string key = region + "|" + time + "|" + distance;
                GetSet(stratumGroups, key).Add(link.GroupIndex);
                GetSet(stratumEvents, key).Add(link.EventIndex);
            }
        }
        foreach (RegionAccumulator ra in regions.Values)
        {
            foreach (KeyValuePair<int, double> item in ra.ActiveMinimumDistance)
            {
                if (item.Value < 5) ra.RedistributionActiveEvents.Add(item.Key);
                else ra.RedistributionReferenceEvents.Add(item.Key);
            }
        }
        foreach (Link link in links)
        {
            EventGroup group = groups[link.GroupIndex];
            if (!frame.Includes(group) || group.Date.Year < period.Start || group.Date.Year > period.End)
                continue;
            string region = events[link.EventIndex].Region;
            RegionAccumulator ra;
            if (!regions.TryGetValue(region, out ra)) continue;
            if (link.EventDay >= -60 && link.EventDay <= 90)
            {
                int k;
                if (ra.LinkCounts.TryGetValue(link.GroupIndex, out k) && k > 0)
                {
                    double weight;
                    ra.EventWeights.TryGetValue(link.EventIndex, out weight);
                    ra.EventWeights[link.EventIndex] = weight + 1.0 / k;
                }
            }
            if (link.EventDay >= 0 && link.EventDay <= 28)
            {
                if (ra.RedistributionActiveEvents.Contains(link.GroupIndex))
                    ra.RedistributionActiveEvents.Add(link.EventIndex + groups.Count);
                if (ra.RedistributionReferenceEvents.Contains(link.GroupIndex))
                    ra.RedistributionReferenceEvents.Add(link.EventIndex + groups.Count);
            }
        }
    }

    private static RegionSummary SummarizeRegion(Frame frame, Period period,
        string region, RegionAccumulator ra, Dictionary<string, YearAccumulator> years,
        List<EventGroup> groups)
    {
        List<EventGroup> z = ra.Groups.Select(i => groups[i]).ToList();
        Dictionary<string, long> obs = Counts(z.Select(g => g.ObserverToken));
        Dictionary<string, long> loc = Counts(z.Select(g => g.LocationToken));
        int adequate = 0;
        int failingRun = 0;
        int maxFailingRun = 0;
        for (int year = period.Start; year <= period.End; year++)
        {
            YearAccumulator ya;
            years.TryGetValue(region + "|" + year.ToString(CultureInfo.InvariantCulture), out ya);
            bool pass = ya != null && ya.Groups.Count >= 20 && ya.Events.Count >= 3 &&
                ya.PreGroups.Count >= 5 && ya.ActiveGroups.Count >= 5 &&
                ya.NearGroups.Count >= 5 && ya.ReferenceGroups.Count >= 5 &&
                ya.EventPeriodFlags.Values.Count(x => x == 3) >= 2;
            if (pass) { adequate++; failingRun = 0; }
            else { failingRun++; if (failingRun > maxFailingRun) maxFailingRun = failingRun; }
        }
        int totalYears = period.End - period.Start + 1;
        double passingShare = totalYears == 0 ? 0 : (double)adequate / totalYears;
        List<double> duration = z.Where(g => g.Duration.HasValue).Select(g => g.Duration.Value).ToList();
        List<double> travel = z.Where(g => g.Protocol == "traveling" && g.Distance.HasValue)
            .Select(g => g.Distance.Value).ToList();
        List<double> observers = z.Where(g => g.Observers.HasValue)
            .Select(g => (double)g.Observers.Value).ToList();
        long redActiveGroups = ra.RedistributionActiveEvents.LongCount(x => x < groups.Count);
        long redReferenceGroups = ra.RedistributionReferenceEvents.LongCount(x => x < groups.Count);
        long redActiveSource = ra.RedistributionActiveEvents.LongCount(x => x >= groups.Count);
        long redReferenceSource = ra.RedistributionReferenceEvents.LongCount(x => x >= groups.Count);
        bool redistribution = redActiveGroups >= 20 && redReferenceGroups >= 20 &&
            redActiveSource >= 3 && redReferenceSource >= 3;
        return new RegionSummary {
            Frame = frame.Id, Period = period.Id, StartYear = period.Start,
            EndYear = period.End, Region = region, Groups = ra.Groups.Count,
            Events = ra.Events.Count, AdequateYears = adequate, TotalYears = totalYears,
            PassingShare = passingShare, MaxFailingRun = maxFailingRun,
            Observers = obs.Count, Locations = loc.Count,
            MaximumObserverShare = ShareValue(obs), MaximumLocationShare = ShareValue(loc),
            EffectiveObservers = EffectiveValue(obs.Values.Select(x => (double)x)),
            EffectiveLocations = EffectiveValue(loc.Values.Select(x => (double)x)),
            EffectiveEvents = EffectiveValue(ra.EventWeights.Values),
            Stationary = z.LongCount(g => g.Protocol == "stationary"),
            Traveling = z.LongCount(g => g.Protocol == "traveling"),
            DurationQ50 = Quantile(duration, .5), DurationQ90 = Quantile(duration, .9),
            TravelQ50 = Quantile(travel, .5), TravelQ90 = Quantile(travel, .9),
            ObserverQ50 = Quantile(observers, .5), ObserverQ90 = Quantile(observers, .9),
            Pre = ra.PreGroups.Count, Active = ra.ActiveGroups.Count,
            Near = ra.NearGroups.Count, Reference = ra.ReferenceGroups.Count,
            EventsBothPeriods = ra.EventPeriodFlags.Values.LongCount(x => x == 3),
            RedistributionActive = redActiveGroups,
            RedistributionReference = redReferenceGroups,
            RedistributionActiveEvents = redActiveSource,
            RedistributionReferenceEvents = redReferenceSource,
            RedistributionFeasible = redistribution,
            PeriodSupportPass = passingShare >= .8 && maxFailingRun <= 2
        };
    }

    private static string RecommendRegion(RegionSummary summary,
        Dictionary<string, RegionSummary> primary)
    {
        if (summary.Groups < PrivacyThreshold || summary.Events < 3)
            return "unsupported";
        bool structurallyLimited = summary.Region == "A27" || summary.Region == "A2W";
        if (summary.Frame == "candidate_primary")
            return summary.PeriodSupportPass && !structurallyLimited ?
                "retain as primary" : "descriptive/hierarchical only";
        if (summary.Frame == "high_spatial_precision")
            return summary.PeriodSupportPass ? "retain as targeted sensitivity" :
                "descriptive/hierarchical only";
        RegionSummary p;
        primary.TryGetValue(summary.Period + "|" + summary.Region, out p);
        if (summary.PeriodSupportPass && (p == null || !p.PeriodSupportPass)) return "broaden";
        return summary.PeriodSupportPass ? "retain as targeted sensitivity" :
            "descriptive/hierarchical only";
    }

    private static void AppendRegionRow(StringBuilder output, RegionSummary x)
    {
        bool suppress = x.Groups < PrivacyThreshold;
        string[] v = {
            x.Frame, x.Period, x.StartYear.ToString(CultureInfo.InvariantCulture),
            x.EndYear.ToString(CultureInfo.InvariantCulture), CsvSafe(x.Region),
            PrivacySafe(x.Groups, x.Groups), suppress ? "" : Percent(x.Groups, x.BroadGroups),
            suppress ? "" : x.AdequateYears.ToString(CultureInfo.InvariantCulture),
            suppress ? "" : x.TotalYears.ToString(CultureInfo.InvariantCulture),
            suppress ? "" : Number(x.PassingShare),
            suppress ? "" : x.MaxFailingRun.ToString(CultureInfo.InvariantCulture),
            PrivacySafe(x.Observers, x.Groups), PrivacySafe(x.Locations, x.Groups),
            suppress ? "" : Number(x.MaximumObserverShare), suppress ? "" : Number(x.MaximumLocationShare),
            suppress ? "" : Number(x.EffectiveObservers), suppress ? "" : Number(x.EffectiveLocations),
            suppress ? "" : Number(x.EffectiveEvents), PrivacySafe(x.Stationary, x.Groups),
            PrivacySafe(x.Traveling, x.Groups), suppress ? "" : Number(x.DurationQ50),
            suppress ? "" : Number(x.DurationQ90), suppress ? "" : Number(x.TravelQ50),
            suppress ? "" : Number(x.TravelQ90), suppress ? "" : Number(x.ObserverQ50),
            suppress ? "" : Number(x.ObserverQ90), PrivacySafe(x.Events, x.Groups),
            PrivacySafe(x.Pre, x.Groups), PrivacySafe(x.Active, x.Groups),
            PrivacySafe(x.Near, x.Groups), PrivacySafe(x.Reference, x.Groups),
            PrivacySafe(x.EventsBothPeriods, x.Groups), PrivacySafe(x.RedistributionActive, x.Groups),
            PrivacySafe(x.RedistributionReference, x.Groups),
            PrivacySafe(x.RedistributionActiveEvents, x.Groups),
            PrivacySafe(x.RedistributionReferenceEvents, x.Groups),
            x.RedistributionFeasible ? "true" : "false", x.PeriodSupportPass ? "true" : "false",
            CsvSafe(x.Recommendation), suppress ? "true" : "false"
        };
        output.AppendLine(String.Join(",", v));
    }

    private static void AppendStrata(StringBuilder output, Frame frame, Period period,
        IEnumerable<string> regionValues, Dictionary<string, HashSet<int>> groupsByCell,
        Dictionary<string, HashSet<int>> eventsByCell, List<EventGroup> groups)
    {
        string[] times = { "early_pre", "immediate_pre", "spawn_start", "early_egg", "late_egg", "post" };
        string[] distances = { "ring_0_0p5", "ring_0p5_1", "ring_1_2", "ring_2_3",
            "ring_3_4", "ring_4_5", "ring_5_10", "ring_10_20" };
        foreach (string region in regionValues.OrderBy(x => x, StringComparer.Ordinal))
        foreach (string time in times)
        foreach (string distance in distances)
        {
            string key = region + "|" + time + "|" + distance;
            HashSet<int> gs;
            HashSet<int> es;
            groupsByCell.TryGetValue(key, out gs);
            eventsByCell.TryGetValue(key, out es);
            long n = gs == null ? 0 : gs.Count;
            bool suppress = n < PrivacyThreshold;
            long observers = suppress ? 0 : gs.Select(i => groups[i].ObserverToken).Distinct().LongCount();
            long locations = suppress ? 0 : gs.Select(i => groups[i].LocationToken).Distinct().LongCount();
            string[] v = { frame.Id, period.Id, CsvSafe(region), time, distance,
                suppress ? "" : n.ToString(CultureInfo.InvariantCulture),
                suppress ? "" : (es == null ? "0" : es.Count.ToString(CultureInfo.InvariantCulture)),
                suppress ? "" : observers.ToString(CultureInfo.InvariantCulture),
                suppress ? "" : locations.ToString(CultureInfo.InvariantCulture),
                suppress ? "true" : "false" };
            output.AppendLine(String.Join(",", v));
        }
    }

    private static StringBuilder BuildTradeoffRecommendations(
        List<RegionSummary> summaries, List<EventGroup> groups,
        List<HerringEvent> events, List<Link> links, List<Period> periods)
    {
        StringBuilder output = new StringBuilder();
        output.AppendLine("scope,item,period_id,metric_1,metric_2,recommendation,evidence");
        foreach (Period period in periods)
        {
            long broad = groups.LongCount(g => g.BroadEligible && g.Date.Year >= period.Start && g.Date.Year <= period.End);
            long primary = groups.LongCount(g => g.PrimaryEligible && g.Date.Year >= period.Start && g.Date.Year <= period.End);
            long high = groups.LongCount(g => g.HighPrecisionEligible && g.Date.Year >= period.Start && g.Date.Year <= period.End);
            long broadOnly = groups.LongCount(g => g.BroadEligible && !g.PrimaryEligible &&
                g.Date.Year >= period.Start && g.Date.Year <= period.End);
            long broadOnlyLongTravel = groups.LongCount(g => g.BroadEligible && !g.PrimaryEligible &&
                g.Protocol == "traveling" && g.Distance.HasValue && g.Distance.Value > 5 &&
                g.Date.Year >= period.Start && g.Date.Year <= period.End);
            int restored = summaries.Count(x => x.Period == period.Id && x.Frame == "registered_broad" &&
                x.Recommendation == "broaden");
            int primarySupported = summaries.Count(x => x.Period == period.Id &&
                x.Frame == "candidate_primary" && x.Recommendation == "retain as primary");
            int highSupported = summaries.Count(x => x.Period == period.Id &&
                x.Frame == "high_spatial_precision" && x.PeriodSupportPass);
            int redistribution = summaries.Count(x => x.Period == period.Id &&
                x.Frame == "candidate_primary" && x.RedistributionFeasible);
            string primaryRec = restored == 0 ? "retain as primary" : "retain as primary";
            string broadRec = restored > 0 ? "broaden" : "retain as targeted sensitivity";
            output.AppendLine(String.Join(",", new [] { "effort_frame", "candidate_primary", period.Id,
                Percent(primary, broad), primarySupported.ToString(CultureInfo.InvariantCulture),
                primaryRec, CsvSafe("retention_vs_broad_percent;regions_with_sustained_primary_support") }));
            output.AppendLine(String.Join(",", new [] { "effort_frame", "high_spatial_precision", period.Id,
                Percent(high, primary), highSupported.ToString(CultureInfo.InvariantCulture),
                "retain as targeted sensitivity", CsvSafe("retention_vs_primary_percent;regions_with_sustained_high_precision_support") }));
            output.AppendLine(String.Join(",", new [] { "effort_frame", "registered_broad", period.Id,
                broadOnly.ToString(CultureInfo.InvariantCulture), broadOnlyLongTravel.ToString(CultureInfo.InvariantCulture),
                broadRec, CsvSafe("events_added_beyond_primary;added_events_with_travel_distance_over_5km;restored_region_periods=" + restored.ToString(CultureInfo.InvariantCulture)) }));
            output.AppendLine(String.Join(",", new [] { "scientific_question", "redistribution_reference_feasibility", period.Id,
                redistribution.ToString(CultureInfo.InvariantCulture), primarySupported.ToString(CultureInfo.InvariantCulture),
                redistribution > 0 ? "retain as primary" : "descriptive/hierarchical only",
                CsvSafe("primary-frame regions with contemporaneous active and no-near-active reference support") }));
        }
        foreach (RegionSummary s in summaries.Where(x => x.Frame == "candidate_primary")
            .OrderBy(x => x.Region, StringComparer.Ordinal).ThenBy(x => x.StartYear))
        {
            output.AppendLine(String.Join(",", new [] { "region_period", CsvSafe(s.Region), s.Period,
                s.AdequateYears.ToString(CultureInfo.InvariantCulture), Number(s.PassingShare),
                CsvSafe(s.Recommendation), CsvSafe("adequate_years;passing_year_share;maximum_failing_run=" +
                    s.MaxFailingRun.ToString(CultureInfo.InvariantCulture) + ";redistribution_feasible=" +
                    (s.RedistributionFeasible ? "true" : "false")) }));
        }
        return output;
    }

    private static void WriteExecutionSummary(string outputDirectory,
        List<EventGroup> groups, List<HerringEvent> events, List<Link> links,
        long factorCount, long broadCount, long primaryCount, long highCount,
        string linkHash, List<string> outputFiles, List<RegionSummary> summaries)
    {
        long shared = groups.LongCount(g => g.Members > 1);
        long disagreements = groups.LongCount(g => g.EffortDisagreement);
        long dateQuarantine = groups.LongCount(g => g.SourceIdentityDisagreement);
        long structuralUnknown = groups.LongCount(g => g.BroadEligible == false &&
            !g.HasEbdIdentity && g.Complete && (g.Protocol == "stationary" || g.Protocol == "traveling"));
        int restored = summaries.Count(x => x.Frame == "registered_broad" &&
            x.Recommendation == "broaden");
        int redistribution = summaries.Count(x => x.Frame == "candidate_primary" &&
            x.RedistributionFeasible);
        StringBuilder json = new StringBuilder();
        json.AppendLine("{");
        json.AppendLine("  \"status\": \"PASS_PENDING_HUMAN_SAMPLING_SUPPORT_REVIEW\",");
        json.AppendLine("  \"phase\": \"phase_2\",");
        json.AppendLine("  \"source_window\": \"1988-2025\",");
        json.AppendLine("  \"phase1_factor_events_reused\": " + factorCount + ",");
        json.AppendLine("  \"high_spatial_precision_events\": " + highCount + ",");
        json.AppendLine("  \"candidate_primary_events\": " + primaryCount + ",");
        json.AppendLine("  \"registered_broad_events\": " + broadCount + ",");
        json.AppendLine("  \"herring_source_events_with_valid_metadata\": " + events.Count + ",");
        json.AppendLine("  \"metadata_source_point_links\": " + links.Count + ",");
        json.AppendLine("  \"shared_analysis_events_preserved\": " + shared + ",");
        json.AppendLine("  \"effort_disagreement_events_quarantined\": " + disagreements + ",");
        json.AppendLine("  \"source_identity_disagreement_events_quarantined\": " + dateQuarantine + ",");
        json.AppendLine("  \"structural_unknown_metadata_events_not_promoted\": " + structuralUnknown + ",");
        json.AppendLine("  \"broad_frame_restored_region_period_cells\": " + restored + ",");
        json.AppendLine("  \"primary_region_period_cells_with_redistribution_support\": " + redistribution + ",");
        json.AppendLine("  \"protected_metadata_link_cache_sha256\": \"" + linkHash + "\",");
        json.AppendLine("  \"ebd_fields_selected\": 2,");
        json.AppendLine("  \"sed_comments_selected\": 0,");
        json.AppendLine("  \"bird_response_fields_selected\": 0,");
        json.AppendLine("  \"sparse_bird_tables_read\": 0,");
        json.AppendLine("  \"herring_fields_selected\": 10,");
        json.AppendLine("  \"shoreline_fields_selected\": 0,");
        json.AppendLine("  \"records_2026_plus_selected\": 0,");
        json.AppendLine("  \"exact_coordinates_released\": false,");
        json.AppendLine("  \"identifiers_released\": false,");
        json.AppendLine("  \"local_paths_released\": false,");
        json.AppendLine("  \"privacy_threshold\": 20,");
        json.AppendLine("  \"cardinality_gate\": \"PASS\",");
        json.AppendLine("  \"fixture_gate\": \"PASS\",");
        json.AppendLine("  \"privacy_gate\": \"PASS\",");
        json.AppendLine("  \"reproducibility_gate\": \"PASS_DETERMINISTIC_AGGREGATE_SERIALIZATION\",");
        json.AppendLine("  \"bird_response_summary_or_model_run\": false,");
        json.AppendLine("  \"phase_3_started\": false,");
        json.AppendLine("  \"next_gate\": \"HUMAN_STAGE3_PHASE2_SAMPLING_SUPPORT_REVIEW\"");
        json.AppendLine("}");
        WriteDeterministic(outputDirectory, "phase2_execution_summary.json", json.ToString());

        StringBuilder hashes = new StringBuilder();
        hashes.AppendLine("artifact,sha256,reproducible,status");
        foreach (string path in outputFiles.OrderBy(x => x, StringComparer.Ordinal))
            hashes.AppendLine(Path.GetFileName(path) + "," + Sha256(path) + ",true,PASS");
        hashes.AppendLine("phase2_execution_summary.json," +
            Sha256(Path.Combine(outputDirectory, "phase2_execution_summary.json")) + ",true,PASS");
        WriteDeterministic(outputDirectory, "aggregate_artifact_hashes.csv", hashes.ToString());
    }

    private static void ValidatePublicOutputs(List<string> paths)
    {
        string[] prohibited = { "sampling_event_identifier", "observer_id", "locality_id",
            "latitude", "longitude", "checklist_comments", "C:\\Users\\", "/" + "home/" };
        foreach (string path in paths)
        {
            string text = File.ReadAllText(path, Encoding.UTF8);
            foreach (string term in prohibited)
                if (text.IndexOf(term, StringComparison.OrdinalIgnoreCase) >= 0)
                    throw new InvalidDataException("Tracked aggregate privacy gate failed");
        }
    }

    private static RegionAccumulator GetRegion(Dictionary<string, RegionAccumulator> x,
        string key)
    {
        RegionAccumulator value;
        if (!x.TryGetValue(key, out value)) { value = new RegionAccumulator(); x.Add(key, value); }
        return value;
    }

    private static HashSet<int> GetSet(Dictionary<string, HashSet<int>> x, string key)
    {
        HashSet<int> value;
        if (!x.TryGetValue(key, out value)) { value = new HashSet<int>(); x.Add(key, value); }
        return value;
    }

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

    private static Dictionary<string, long> Counts(IEnumerable<string> values)
    {
        Dictionary<string, long> result = new Dictionary<string, long>(StringComparer.Ordinal);
        foreach (string value in values)
        {
            long n;
            result.TryGetValue(value ?? "missing", out n);
            result[value ?? "missing"] = n + 1;
        }
        return result;
    }

    private static string Share(Dictionary<string, long> counts)
    { return Number(ShareValue(counts)); }

    private static double ShareValue(Dictionary<string, long> counts)
    {
        long total = counts.Values.Sum();
        return total == 0 ? Double.NaN : (double)counts.Values.Max() / total;
    }

    private static string Effective(IEnumerable<double> weights)
    { return Number(EffectiveValue(weights)); }

    private static double EffectiveValue(IEnumerable<double> values)
    {
        double[] x = values.Where(v => v > 0 && !Double.IsNaN(v)).ToArray();
        double total = x.Sum();
        double squares = x.Sum(v => v * v);
        return total == 0 || squares == 0 ? Double.NaN : total * total / squares;
    }

    private static double Quantile(List<double> values, double probability)
    {
        values.RemoveAll(Double.IsNaN);
        if (values.Count == 0) return Double.NaN;
        values.Sort();
        int index = (int)Math.Ceiling(probability * values.Count) - 1;
        if (index < 0) index = 0;
        if (index >= values.Count) index = values.Count - 1;
        return values[index];
    }

    private static string Percent(long numerator, long denominator)
    {
        return denominator == 0 ? "" : ((100.0 * numerator) / denominator)
            .ToString("0.0", CultureInfo.InvariantCulture);
    }

    private static string PrivacySafe(long value, long cellSize)
    {
        return cellSize < PrivacyThreshold || value < PrivacyThreshold ? "" :
            value.ToString(CultureInfo.InvariantCulture);
    }

    private static string Number(double value)
    {
        return Double.IsNaN(value) || Double.IsInfinity(value) ? "" :
            value.ToString("0.###", CultureInfo.InvariantCulture);
    }

    private static double HaversineKm(double lat1, double lon1, double lat2, double lon2)
    {
        double dlat = DegreesToRadians(lat2 - lat1);
        double dlon = DegreesToRadians(lon2 - lon1);
        double a = Math.Sin(dlat / 2) * Math.Sin(dlat / 2) +
            Math.Cos(DegreesToRadians(lat1)) * Math.Cos(DegreesToRadians(lat2)) *
            Math.Sin(dlon / 2) * Math.Sin(dlon / 2);
        return 2 * EarthRadiusKm * Math.Asin(Math.Min(1, Math.Sqrt(a)));
    }

    private static double DegreesToRadians(double value) { return value * Math.PI / 180.0; }

    private static string WriteDeterministic(string directory, string name, string content)
    {
        string path = Path.Combine(directory, name);
        UTF8Encoding encoding = new UTF8Encoding(false);
        File.WriteAllText(path, content.Replace("\r\n", "\n"), encoding);
        string replay = path + ".repro.tmp";
        File.WriteAllText(replay, content.Replace("\r\n", "\n"), encoding);
        if (!String.Equals(Sha256(path), Sha256(replay), StringComparison.Ordinal))
            throw new InvalidDataException("Aggregate serialization reproducibility gate failed");
        File.Delete(replay);
        return path;
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
        for (int i = 0; i < positions.Length; i++)
        {
            List<int> targets;
            if (!wanted.TryGetValue(positions[i], out targets))
            { targets = new List<int>(); wanted.Add(positions[i], targets); }
            targets.Add(i);
        }
        int field = 0;
        int start = 0;
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
                start = i + 1;
                continue;
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
                if (field > positions.Max()) break;
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
        string clean = Clean(date);
        int year;
        return clean.Length >= 4 && Int32.TryParse(clean.Substring(0, 4), out year) ? year : -1;
    }

    private static DateTime ParseDate(string value)
    {
        DateTime date;
        if (!DateTime.TryParse(Clean(value), CultureInfo.InvariantCulture,
            DateTimeStyles.AllowWhiteSpaces, out date))
            throw new InvalidDataException("Metadata date parse failure");
        return date.Date;
    }

    private static DateTime? NullableDate(string value)
    {
        if (Clean(value).Length == 0) return null;
        DateTime date;
        return DateTime.TryParse(Clean(value), CultureInfo.InvariantCulture,
            DateTimeStyles.AllowWhiteSpaces, out date) ? (DateTime?)date.Date : null;
    }

    private static double? NullableDouble(string value)
    {
        double x;
        return Double.TryParse(Clean(value), NumberStyles.Float,
            CultureInfo.InvariantCulture, out x) ? (double?)x : null;
    }

    private static int? NullableInt(string value)
    {
        int x;
        return Int32.TryParse(Clean(value), NumberStyles.Integer,
            CultureInfo.InvariantCulture, out x) ? (int?)x : null;
    }

    private static double RequiredDouble(string value)
    {
        double? x = NullableDouble(value);
        if (!x.HasValue) throw new InvalidDataException("Required coordinate metadata is missing");
        return x.Value;
    }

    private static string NormalizeProtocol(string value)
    {
        return Clean(value).ToLowerInvariant();
    }

    private static double? NormalizeDistance(string protocol, double? value)
    { return protocol == "stationary" ? (double?)0 : value; }

    private static bool IsTrue(string value)
    {
        string x = Clean(value).ToUpperInvariant();
        return x == "1" || x == "TRUE" || x == "T" || x == "YES";
    }

    private static bool NullableEqual(double? a, double? b)
    { return a.HasValue == b.HasValue && (!a.HasValue || a.Value.Equals(b.Value)); }

    private static bool NullableEqual(int? a, int? b)
    { return a.HasValue == b.HasValue && (!a.HasValue || a.Value == b.Value); }

    private static bool CoordinateEqual(double a, double b)
    { return (Double.IsNaN(a) && Double.IsNaN(b)) || a.Equals(b); }

    private static string HashToken(string domain, string value)
    {
        using (SHA256 sha = SHA256.Create())
        {
            byte[] bytes = sha.ComputeHash(Encoding.UTF8.GetBytes(domain + "|" + (value ?? "")));
            StringBuilder result = new StringBuilder(24);
            for (int i = 0; i < 12; i++) result.Append(bytes[i].ToString("x2", CultureInfo.InvariantCulture));
            return result.ToString();
        }
    }

    private static string CsvSafe(string value)
    {
        string x = value ?? "";
        return x.IndexOfAny(new [] { ',', '"', '\n', '\r' }) >= 0 ?
            "\"" + x.Replace("\"", "\"\"") + "\"" : x;
    }

    private static string Sha256(string path)
    {
        using (SHA256 sha = SHA256.Create())
        using (FileStream stream = File.OpenRead(path))
            return BitConverter.ToString(sha.ComputeHash(stream)).Replace("-", "").ToLowerInvariant();
    }

    private static void RequireHash(string path, string expected)
    {
        RequireFile(path, "registered protected Phase 1 artifact");
        if (!String.Equals(Sha256(path), expected, StringComparison.Ordinal))
            throw new InvalidDataException("Registered protected Phase 1 artifact hash mismatch");
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
