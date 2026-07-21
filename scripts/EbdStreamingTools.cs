using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;

public static class EbdStreamingTools
{
    private const string ChecklistKey = "SAMPLING EVENT IDENTIFIER";

    private static int FieldIndex(string header, string name)
    {
        string[] fields = header.TrimEnd('\r', '\n').Split('\t');
        int index = Array.IndexOf(fields, name);
        if (index < 0) throw new InvalidDataException("Required EBD/SED field is missing");
        return index;
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

    public static void AuditMembership(string ebdPath, string sedPath, string missingOutput, string statsOutput)
    {
        HashSet<string> sedKeys = new HashSet<string>(StringComparer.Ordinal);
        long sedRows = 0;
        using (StreamReader reader = new StreamReader(sedPath, Encoding.UTF8, true, 1 << 20))
        {
            string header = reader.ReadLine();
            if (header == null) throw new InvalidDataException("SED is empty");
            int keyIndex = FieldIndex(header, ChecklistKey);
            string line;
            while ((line = reader.ReadLine()) != null)
            {
                sedRows++;
                string key = FieldAt(line, keyIndex);
                if (String.IsNullOrWhiteSpace(key)) throw new InvalidDataException("SED key is missing or blank");
                if (!sedKeys.Add(key)) throw new InvalidDataException("SED key is duplicated");
            }
        }

        HashSet<string> missing = new HashSet<string>(sedKeys, StringComparer.Ordinal);
        HashSet<string> unmatchedEbd = new HashSet<string>(StringComparer.Ordinal);
        long ebdRows = 0;
        using (StreamReader reader = new StreamReader(ebdPath, Encoding.UTF8, true, 1 << 20))
        {
            string header = reader.ReadLine();
            if (header == null) throw new InvalidDataException("EBD is empty");
            int keyIndex = FieldIndex(header, ChecklistKey);
            string line;
            while ((line = reader.ReadLine()) != null)
            {
                ebdRows++;
                string key = FieldAt(line, keyIndex);
                if (String.IsNullOrWhiteSpace(key)) throw new InvalidDataException("EBD key is missing or blank");
                if (!missing.Remove(key) && !sedKeys.Contains(key)) unmatchedEbd.Add(key);
                if (ebdRows % 5000000L == 0)
                {
                    Console.WriteLine("Membership scan checkpoint: " + ebdRows.ToString(CultureInfo.InvariantCulture) +
                        " EBD rows mechanically scanned; " + missing.Count.ToString(CultureInfo.InvariantCulture) +
                        " SED keys unmatched so far.");
                }
            }
        }

        Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(missingOutput)));
        string temporary = missingOutput + ".tmp";
        using (StreamWriter writer = new StreamWriter(temporary, false, new UTF8Encoding(false)))
        {
            writer.WriteLine(ChecklistKey);
            foreach (string key in missing.OrderBy(value => value, StringComparer.Ordinal)) writer.WriteLine(key);
        }
        if (File.Exists(missingOutput)) File.Delete(missingOutput);
        File.Move(temporary, missingOutput);

        long matched = sedKeys.Count - missing.Count;
        long ebdUnique = matched + unmatchedEbd.Count;
        string json = "{\n" +
            "  \"relationship\": \"global_EBD_SED_key_membership\",\n" +
            "  \"expected_cardinality\": \"EBD_many_to_one_SED_and_bidirectional_membership_audit\",\n" +
            "  \"ebd_rows\": " + ebdRows.ToString(CultureInfo.InvariantCulture) + ",\n" +
            "  \"ebd_unique_keys\": " + ebdUnique.ToString(CultureInfo.InvariantCulture) + ",\n" +
            "  \"sed_unique_keys\": " + sedKeys.Count.ToString(CultureInfo.InvariantCulture) + ",\n" +
            "  \"ebd_keys_unmatched_to_sed\": " + unmatchedEbd.Count.ToString(CultureInfo.InvariantCulture) + ",\n" +
            "  \"sed_keys_without_ebd\": " + missing.Count.ToString(CultureInfo.InvariantCulture) + "\n" +
            "}\n";
        File.WriteAllText(statsOutput, json, new UTF8Encoding(false));
        Console.WriteLine("Membership audit complete: " + ebdUnique.ToString(CultureInfo.InvariantCulture) +
            " unique EBD keys, " + sedKeys.Count.ToString(CultureInfo.InvariantCulture) + " unique SED keys, " +
            unmatchedEbd.Count.ToString(CultureInfo.InvariantCulture) + " EBD-only keys, " +
            missing.Count.ToString(CultureInfo.InvariantCulture) + " SED-only keys.");
    }

    public static void ExtractFocalPre2026(string ebdPath, string patternPath, string outputPath)
    {
        HashSet<string> patterns = new HashSet<string>(
            File.ReadAllLines(patternPath, Encoding.UTF8).Where(value => !String.IsNullOrWhiteSpace(value)),
            StringComparer.Ordinal);
        string[] required = new string[] {
            "CATEGORY", "TAXON CONCEPT ID", "COMMON NAME", "SCIENTIFIC NAME",
            "OBSERVATION COUNT", "BEHAVIOR CODE", "SAMPLING EVENT IDENTIFIER", "OBSERVATION DATE"
        };
        string temporary = outputPath + ".tmp";
        long futureSkipped = 0;
        long focalWritten = 0;
        using (StreamReader reader = new StreamReader(ebdPath, Encoding.UTF8, true, 1 << 20))
        using (StreamWriter writer = new StreamWriter(temporary, false, new UTF8Encoding(false)))
        {
            string header = reader.ReadLine();
            if (header == null) throw new InvalidDataException("EBD is empty");
            int[] positions = required.Select(name => FieldIndex(header, name)).ToArray();
            int datePosition = Array.IndexOf(required, "OBSERVATION DATE");
            int taxonPosition = Array.IndexOf(required, "TAXON CONCEPT ID");
            int commonPosition = Array.IndexOf(required, "COMMON NAME");
            writer.WriteLine(String.Join("\t", required));
            string line;
            while ((line = reader.ReadLine()) != null)
            {
                string date = FieldAt(line, positions[datePosition]);
                int year = 0;
                if (date.Length < 4 || !Int32.TryParse(date.Substring(0, 4), out year) || year > 2025)
                {
                    if (year > 2025) futureSkipped++;
                    continue;
                }
                string taxon = FieldAt(line, positions[taxonPosition]);
                string common = FieldAt(line, positions[commonPosition]);
                if (!patterns.Contains(taxon) && !patterns.Contains(common)) continue;
                writer.WriteLine(String.Join("\t", positions.Select(position => FieldAt(line, position))));
                focalWritten++;
            }
        }
        if (File.Exists(outputPath)) File.Delete(outputPath);
        File.Move(temporary, outputPath);
        Console.WriteLine("EBD focal extraction complete: " + futureSkipped.ToString(CultureInfo.InvariantCulture) +
            " future rows skipped before response selection; " + focalWritten.ToString(CultureInfo.InvariantCulture) +
            " pre-2026 focal rows persisted locally.");
    }
}
