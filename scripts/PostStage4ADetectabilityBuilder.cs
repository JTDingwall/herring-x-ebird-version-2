using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Security.Cryptography;
using System.Text;

public static class PostStage4ADetectabilityBuilder
{
    private const int ExpectedSoGChecklists = 217200;
    private const string EventMetadataHash =
        "03eaccdd46b5cba779f596e7ce96dacd5a509f51f6eae4c5c79daf706879a9b2";
    private const string CrosswalkHash =
        "1b52cf8fc15f91e89d7b8a64c66d9976e0c2e6e36afef4058909d7aaad3d2f17";
    private const string SedHash =
        "9b5b1893ff5b37c9a4a6faa596e71a5894dcb81bafee214ace33c4beee85b6ed";

    private sealed class DetectabilityRow
    {
        public string Token;
        public int Year;
        public bool StartTimePresent;
        public bool StartTimeSyntaxValid;
        public bool CoordinateValid;
        public bool CovariatesComplete;
        public string Status;
        public int DayOfYear;
        public double MinutesFromSunrise;
        public double Sin1;
        public double Cos1;
        public double Sin2;
        public double Cos2;
    }

    public static void RunFixture()
    {
        DateTime date = new DateTime(2020, 6, 21);
        double sunrise = SunriseUtcHour(date.DayOfYear, 49.2827, -123.1207);
        Assert(IsFinite(sunrise) && sunrise > 11.0 && sunrise < 14.5,
            "Vancouver summer sunrise must be a plausible UTC hour");
        double angle = 2.0 * Math.PI * date.DayOfYear / 365.0;
        Assert(Math.Abs(Math.Sin(angle) * Math.Sin(angle) +
            Math.Cos(angle) * Math.Cos(angle) - 1.0) < 1e-12,
            "annual harmonic identity");
        TimeSpan parsed;
        Assert(TryParseStartTime("06:15", out parsed) &&
            parsed.Hours == 6 && parsed.Minutes == 15,
            "start-time parser");
        Assert(!TryParseStartTime("", out parsed), "missing time rejection");
        Console.WriteLine("POST_STAGE4A_DETECTABILITY_BUILDER_FIXTURE=PASS");
    }

    public static void RunProduction(
        string sedPath, string repoRoot, string protectedDirectory)
    {
        string eventPath = Path.Combine(repoRoot, "data", "derived",
            "stage4a_protected", "stage4a_event_metadata.tsv.gz");
        string crosswalkPath = Path.Combine(repoRoot, "data", "derived",
            "stage3_phase1_repair_protected", "private_component_crosswalk.tsv.gz");
        string codePath = Path.Combine(repoRoot, "scripts",
            "PostStage4ADetectabilityBuilder.cs");
        RequireHash(eventPath, EventMetadataHash);
        RequireHash(crosswalkPath, CrosswalkHash);
        RequireHash(sedPath, SedHash);
        RequireFile(codePath, "detectability builder source");

        Directory.CreateDirectory(protectedDirectory);
        string outputPath = Path.Combine(protectedDirectory,
            "stage2_detectability_covariates.tsv.gz");
        string manifestPath = Path.Combine(protectedDirectory,
            "stage2_detectability_cache_manifest.txt");
        string fingerprint = String.Join("|", new[] {
            Sha256(eventPath), Sha256(crosswalkPath), Sha256(sedPath),
            Sha256(codePath), "SoG", "2005-2025", "America/Vancouver",
            "NOAA_90.833_v1", "harmonics_365_orders_1_2"
        });
        if (File.Exists(outputPath) && File.Exists(manifestPath))
        {
            string[] manifest = File.ReadAllLines(manifestPath, Encoding.UTF8);
            if (manifest.Length == 2 && manifest[0] == fingerprint &&
                manifest[1] == Sha256(outputPath))
            {
                Console.WriteLine(
                    "Protected Stage 2 detectability cache reused hash-identically.");
                Console.WriteLine(
                    "POST_STAGE4A_DETECTABILITY_BUILD=PASS_REUSED");
                return;
            }
        }

        Dictionary<string, int> expected = ReadExpectedSoGEvents(eventPath);
        Dictionary<string, string> sources =
            ReadCanonicalSources(crosswalkPath, expected);
        Dictionary<string, DetectabilityRow> rows =
            ReadSedDetectability(sedPath, sources, expected);
        ValidateRows(rows, expected);
        WriteRows(outputPath, rows);
        File.WriteAllLines(manifestPath,
            new[] { fingerprint, Sha256(outputPath) }, new UTF8Encoding(false));
        Console.WriteLine(
            "Protected Stage 2 detectability cache constructed without identifiers or coordinates.");
        Console.WriteLine("Eligible SoG checklists: " +
            rows.Count.ToString(CultureInfo.InvariantCulture));
        Console.WriteLine("POST_STAGE4A_DETECTABILITY_BUILD=PASS_CONSTRUCTED");
    }

    private static Dictionary<string, int> ReadExpectedSoGEvents(string path)
    {
        Dictionary<string, int> result =
            new Dictionary<string, int>(StringComparer.Ordinal);
        using (StreamReader reader = GzipReader(path))
        {
            Dictionary<string, int> h = HeaderMap(reader.ReadLine(), '\t');
            string[] required = {
                "analysis_event_token", "region", "checklist_year"
            };
            RequireFields(h, required, "Stage 4A event metadata");
            int[] p = required.Select(x => h[x]).ToArray();
            string line;
            while ((line = reader.ReadLine()) != null)
            {
                string[] v = ExtractFields(line, p, '\t');
                int year;
                if (!Int32.TryParse(Clean(v[2]), NumberStyles.Integer,
                    CultureInfo.InvariantCulture, out year))
                    throw new InvalidDataException(
                        "Stage 4A event year is malformed");
                if (Clean(v[1]) != "SoG" || year < 2005 || year > 2025)
                    continue;
                string token = Clean(v[0]);
                if (result.ContainsKey(token))
                    throw new InvalidDataException(
                        "Stage 4A event token is duplicated");
                result.Add(token, year);
            }
        }
        if (result.Count != ExpectedSoGChecklists)
            throw new InvalidDataException(
                "Expected SoG checklist cardinality changed");
        return result;
    }

    private static Dictionary<string, string> ReadCanonicalSources(
        string path, Dictionary<string, int> expected)
    {
        Dictionary<string, string> result =
            new Dictionary<string, string>(StringComparer.Ordinal);
        HashSet<string> matchedTokens =
            new HashSet<string>(StringComparer.Ordinal);
        using (StreamReader reader = GzipReader(path))
        {
            Dictionary<string, int> h = HeaderMap(reader.ReadLine(), '\t');
            string[] required = {
                "source_sampling_event_identifier", "analysis_checklist_id",
                "canonical_effort_row"
            };
            RequireFields(h, required, "private component crosswalk");
            int[] p = required.Select(x => h[x]).ToArray();
            string line;
            while ((line = reader.ReadLine()) != null)
            {
                string[] v = ExtractFields(line, p, '\t');
                if (!IsTrue(v[2])) continue;
                string token = HashToken("analysis_event", Clean(v[1]));
                if (!expected.ContainsKey(token)) continue;
                string source = Clean(v[0]);
                if (result.ContainsKey(source) || !matchedTokens.Add(token))
                    throw new InvalidDataException(
                        "Canonical source-to-checklist join is not one-to-one");
                result.Add(source, token);
            }
        }
        if (result.Count != expected.Count)
            throw new InvalidDataException(
                "Canonical source coverage for SoG checklists is incomplete");
        return result;
    }

    private static Dictionary<string, DetectabilityRow> ReadSedDetectability(
        string path, Dictionary<string, string> sources,
        Dictionary<string, int> expected)
    {
        Dictionary<string, DetectabilityRow> result =
            new Dictionary<string, DetectabilityRow>(StringComparer.Ordinal);
        TimeZoneInfo pacific = PacificTimeZone();
        using (StreamReader reader =
            new StreamReader(path, Encoding.UTF8, true, 1 << 22))
        {
            Dictionary<string, int> h = HeaderMap(reader.ReadLine(), '\t');
            string[] required = {
                "SAMPLING EVENT IDENTIFIER", "OBSERVATION DATE",
                "TIME OBSERVATIONS STARTED", "LATITUDE", "LONGITUDE"
            };
            RequireFields(h, required, "authorized SED");
            int[] p = required.Select(x => h[x]).ToArray();
            string line;
            while ((line = reader.ReadLine()) != null)
            {
                string[] v = ExtractFields(line, p, '\t');
                string token;
                if (!sources.TryGetValue(Clean(v[0]), out token)) continue;
                if (result.ContainsKey(token))
                    throw new InvalidDataException(
                        "Authorized SED source row duplicated");
                result.Add(token, BuildRow(
                    token, expected[token], v[1], v[2], v[3], v[4], pacific));
            }
        }
        return result;
    }

    private static DetectabilityRow BuildRow(
        string token, int expectedYear, string dateRaw, string timeRaw,
        string latitudeRaw, string longitudeRaw, TimeZoneInfo pacific)
    {
        DetectabilityRow row = new DetectabilityRow {
            Token = token,
            Year = expectedYear,
            StartTimePresent = !String.IsNullOrWhiteSpace(Clean(timeRaw)),
            Status = "not_evaluated",
            MinutesFromSunrise = Double.NaN,
            DayOfYear = -1,
            Sin1 = Double.NaN,
            Cos1 = Double.NaN,
            Sin2 = Double.NaN,
            Cos2 = Double.NaN
        };
        DateTime date;
        if (!DateTime.TryParseExact(Clean(dateRaw),
            new[] { "yyyy-MM-dd", "yyyy/MM/dd", "MM/dd/yyyy" },
            CultureInfo.InvariantCulture, DateTimeStyles.None, out date) ||
            date.Year != expectedYear)
        {
            row.Status = "invalid_observation_date";
            return row;
        }
        row.DayOfYear = date.DayOfYear;
        double angle = 2.0 * Math.PI * row.DayOfYear / 365.0;
        row.Sin1 = Math.Sin(angle);
        row.Cos1 = Math.Cos(angle);
        row.Sin2 = Math.Sin(2.0 * angle);
        row.Cos2 = Math.Cos(2.0 * angle);

        if (!row.StartTimePresent)
        {
            row.Status = "missing_start_time";
            return row;
        }
        TimeSpan start;
        row.StartTimeSyntaxValid = TryParseStartTime(timeRaw, out start);
        if (!row.StartTimeSyntaxValid)
        {
            row.Status = "invalid_start_time";
            return row;
        }
        double latitude = Double.NaN;
        double longitude = Double.NaN;
        row.CoordinateValid =
            Double.TryParse(Clean(latitudeRaw), NumberStyles.Float,
                CultureInfo.InvariantCulture, out latitude) &&
            Double.TryParse(Clean(longitudeRaw), NumberStyles.Float,
                CultureInfo.InvariantCulture, out longitude) &&
            latitude >= -90.0 && latitude <= 90.0 &&
            longitude >= -180.0 && longitude <= 180.0;
        if (!row.CoordinateValid)
        {
            row.Status = "invalid_coordinate";
            return row;
        }

        DateTime local = DateTime.SpecifyKind(date.Date.Add(start),
            DateTimeKind.Unspecified);
        if (pacific.IsInvalidTime(local) || pacific.IsAmbiguousTime(local))
        {
            row.Status = "invalid_or_ambiguous_local_time";
            return row;
        }
        double sunriseHour =
            SunriseUtcHour(row.DayOfYear, latitude, longitude);
        if (!IsFinite(sunriseHour))
        {
            row.Status = "sunrise_unavailable";
            return row;
        }
        DateTime startUtc = TimeZoneInfo.ConvertTimeToUtc(local, pacific);
        DateTime sunriseUtc = new DateTime(
            date.Year, date.Month, date.Day, 0, 0, 0, DateTimeKind.Utc
        ).AddHours(sunriseHour);
        row.MinutesFromSunrise = (startUtc - sunriseUtc).TotalMinutes;
        if (!IsFinite(row.MinutesFromSunrise) ||
            row.MinutesFromSunrise < -1440.0 ||
            row.MinutesFromSunrise > 1800.0)
        {
            row.MinutesFromSunrise = Double.NaN;
            row.Status = "implausible_sunrise_difference";
            return row;
        }
        row.CovariatesComplete = true;
        row.Status = "complete";
        return row;
    }

    private static bool TryParseStartTime(string raw, out TimeSpan result)
    {
        string x = Clean(raw);
        string[] formats = { @"h\:mm", @"hh\:mm", @"h\:mm\:ss", @"hh\:mm\:ss" };
        if (!TimeSpan.TryParseExact(x, formats, CultureInfo.InvariantCulture,
            out result)) return false;
        return result >= TimeSpan.Zero && result < TimeSpan.FromDays(1);
    }

    // Almanac/NOAA sunrise algorithm with the standard 90.833-degree zenith.
    // The result is UTC decimal hours for the local calendar date.
    private static double SunriseUtcHour(
        int dayOfYear, double latitude, double longitude)
    {
        double longitudeHour = longitude / 15.0;
        double t = dayOfYear + ((6.0 - longitudeHour) / 24.0);
        double meanAnomaly = 0.9856 * t - 3.289;
        double trueLongitude = NormalizeDegrees(
            meanAnomaly +
            1.916 * SinDegrees(meanAnomaly) +
            0.020 * SinDegrees(2.0 * meanAnomaly) +
            282.634);
        double rightAscension = NormalizeDegrees(
            RadiansToDegrees(Math.Atan(
                0.91764 * Math.Tan(DegreesToRadians(trueLongitude)))));
        rightAscension +=
            Math.Floor(trueLongitude / 90.0) * 90.0 -
            Math.Floor(rightAscension / 90.0) * 90.0;
        rightAscension /= 15.0;
        double sinDeclination = 0.39782 * SinDegrees(trueLongitude);
        double cosDeclination = Math.Cos(Math.Asin(sinDeclination));
        double cosHour = (Math.Cos(DegreesToRadians(90.833)) -
            sinDeclination * SinDegrees(latitude)) /
            (cosDeclination * CosDegrees(latitude));
        if (cosHour < -1.0 || cosHour > 1.0) return Double.NaN;
        double hourAngle =
            360.0 - RadiansToDegrees(Math.Acos(cosHour));
        hourAngle /= 15.0;
        double localMeanTime =
            hourAngle + rightAscension - 0.06571 * t - 6.622;
        return NormalizeHours(localMeanTime - longitudeHour);
    }

    private static void ValidateRows(
        Dictionary<string, DetectabilityRow> rows,
        Dictionary<string, int> expected)
    {
        if (rows.Count != expected.Count ||
            rows.Keys.Any(x => !expected.ContainsKey(x)))
            throw new InvalidDataException(
                "SED-to-checklist join lost or multiplied rows");
        foreach (DetectabilityRow row in rows.Values)
        {
            if (row.Year > 2025 || row.Year < 2005 ||
                (row.CovariatesComplete &&
                 (!row.StartTimeSyntaxValid || !row.CoordinateValid ||
                  row.DayOfYear < 1 || row.DayOfYear > 366 ||
                  !IsFinite(row.MinutesFromSunrise))))
                throw new InvalidDataException(
                    "Detectability covariate validation failed");
        }
    }

    private static void WriteRows(
        string path, Dictionary<string, DetectabilityRow> rows)
    {
        using (StreamWriter writer = GzipWriter(path))
        {
            writer.WriteLine(
                "analysis_event_token\tchecklist_year\tstart_time_present\t" +
                "start_time_syntax_valid\tcoordinate_valid\t" +
                "stage2_covariates_complete\tmissingness_status\t" +
                "minutes_from_sunrise\tday_of_year\t" +
                "sin_2pi_doy_365\tcos_2pi_doy_365\t" +
                "sin_4pi_doy_365\tcos_4pi_doy_365");
            foreach (DetectabilityRow row in
                rows.Values.OrderBy(x => x.Token, StringComparer.Ordinal))
            {
                writer.Write(row.Token);
                writer.Write("\t" + row.Year.ToString(CultureInfo.InvariantCulture));
                writer.Write("\t" + Bool(row.StartTimePresent));
                writer.Write("\t" + Bool(row.StartTimeSyntaxValid));
                writer.Write("\t" + Bool(row.CoordinateValid));
                writer.Write("\t" + Bool(row.CovariatesComplete));
                writer.Write("\t" + row.Status);
                writer.Write("\t" + Number(row.MinutesFromSunrise));
                writer.Write("\t" + (row.DayOfYear < 0 ? "" :
                    row.DayOfYear.ToString(CultureInfo.InvariantCulture)));
                writer.Write("\t" + Number(row.Sin1));
                writer.Write("\t" + Number(row.Cos1));
                writer.Write("\t" + Number(row.Sin2));
                writer.WriteLine("\t" + Number(row.Cos2));
            }
        }
    }

    private static TimeZoneInfo PacificTimeZone()
    {
        foreach (string id in new[] {
            "America/Vancouver", "Pacific Standard Time"
        })
        {
            try { return TimeZoneInfo.FindSystemTimeZoneById(id); }
            catch (TimeZoneNotFoundException) { }
            catch (InvalidTimeZoneException) { }
        }
        throw new InvalidDataException(
            "America/Vancouver time zone is unavailable");
    }

    private static double NormalizeDegrees(double x)
    {
        x %= 360.0;
        return x < 0.0 ? x + 360.0 : x;
    }
    private static double NormalizeHours(double x)
    {
        x %= 24.0;
        return x < 0.0 ? x + 24.0 : x;
    }
    private static double DegreesToRadians(double x) { return x * Math.PI / 180.0; }
    private static double RadiansToDegrees(double x) { return x * 180.0 / Math.PI; }
    private static double SinDegrees(double x) { return Math.Sin(DegreesToRadians(x)); }
    private static double CosDegrees(double x) { return Math.Cos(DegreesToRadians(x)); }
    private static string Bool(bool x) { return x ? "true" : "false"; }
    private static string Number(double x)
    {
        return IsFinite(x) ?
            x.ToString("G17", CultureInfo.InvariantCulture) : "";
    }
    private static bool IsFinite(double x)
    {
        return !Double.IsNaN(x) && !Double.IsInfinity(x);
    }
    private static StreamReader GzipReader(string path)
    {
        return new StreamReader(new GZipStream(
            File.OpenRead(path), CompressionMode.Decompress),
            Encoding.UTF8, true, 1 << 20);
    }
    private static StreamWriter GzipWriter(string path)
    {
        return new StreamWriter(new GZipStream(
            new FileStream(path, FileMode.Create, FileAccess.Write, FileShare.None),
            CompressionLevel.Optimal), new UTF8Encoding(false), 1 << 20);
    }
    private static Dictionary<string, int> HeaderMap(string header, char separator)
    {
        if (header == null) throw new InvalidDataException("Input is empty");
        string[] fields = header.Split(separator);
        Dictionary<string, int> result =
            new Dictionary<string, int>(StringComparer.Ordinal);
        for (int i = 0; i < fields.Length; i++) result[Clean(fields[i])] = i;
        return result;
    }
    private static void RequireFields(
        Dictionary<string, int> header, IEnumerable<string> required,
        string label)
    {
        string[] missing = required.Where(x => !header.ContainsKey(x)).ToArray();
        if (missing.Length > 0)
            throw new InvalidDataException(label + " missing fields: " +
                String.Join(",", missing));
    }
    private static string[] ExtractFields(
        string line, int[] positions, char separator)
    {
        string[] all = line.Split(separator);
        string[] result = new string[positions.Length];
        for (int i = 0; i < positions.Length; i++)
            result[i] = positions[i] < all.Length ? all[positions[i]] : "";
        return result;
    }
    private static string Clean(string x)
    {
        return (x ?? "").Trim().Trim('\uFEFF');
    }
    private static bool IsTrue(string x)
    {
        string value = Clean(x).ToUpperInvariant();
        return value == "1" || value == "TRUE" || value == "T" ||
            value == "YES";
    }
    private static string HashToken(string domain, string value)
    {
        using (SHA256 sha = SHA256.Create())
            return HexPrefix(sha.ComputeHash(
                Encoding.UTF8.GetBytes(domain + "|" + (value ?? ""))), 12);
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
            return BitConverter.ToString(sha.ComputeHash(stream))
                .Replace("-", "").ToLowerInvariant();
    }
    private static void RequireHash(string path, string expected)
    {
        RequireFile(path, "registered protected input");
        if (Sha256(path) != expected)
            throw new InvalidDataException(
                "Registered protected input hash mismatch");
    }
    private static void RequireFile(string path, string label)
    {
        if (String.IsNullOrWhiteSpace(path) || !File.Exists(path))
            throw new FileNotFoundException(label + " is unavailable");
    }
    private static void Assert(bool condition, string message)
    {
        if (!condition)
            throw new InvalidDataException("Fixture assertion failed: " + message);
    }
}
