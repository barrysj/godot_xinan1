using System;
using System.IO;
using System.Text;
using System.Collections.Generic;
using System.Security.Cryptography;
using System.Text.RegularExpressions;

// Metadata scan, never reads multi-megabyte images or Git history on a play click.
public static class CampusImportFingerprint {
    public static string Compute(string root, string enginePath) {
        var engine = new FileInfo(enginePath);
        var parts = new List<string> { "imports-v2|" + enginePath + "|" + engine.Length + "|" + engine.LastWriteTimeUtc.Ticks };
        foreach (string line in File.ReadAllLines(Path.Combine(root, "project.godot")))
            if (!String.IsNullOrWhiteSpace(line)) parts.Add(line);
        var extensions = new HashSet<string>(new[] { ".png", ".jpg", ".jpeg", ".webp", ".svg", ".ttf", ".otf", ".wav", ".ogg", ".mp3", ".glb", ".gltf", ".blend", ".import", ".csv" }, StringComparer.OrdinalIgnoreCase);
        var pending = new Stack<string>();
        foreach (string name in new[] { "assets", "game", "scenes", "resources", "addons", "tools", "data" }) {
            string path = Path.Combine(root, name);
            if (Directory.Exists(path)) pending.Push(path);
        }
        pending.Push(root);
        var declaration = new Regex(@"(?m)^class_name\s+[^\r\n]+");
        while (pending.Count > 0) {
            string directory = pending.Pop();
            if (File.Exists(Path.Combine(directory, ".gdignore"))) continue;
            if (directory != root) foreach (string child in Directory.EnumerateDirectories(directory)) pending.Push(child);
            foreach (string file in Directory.EnumerateFiles(directory)) {
                string extension = Path.GetExtension(file);
                if (extensions.Contains(extension)) {
                    var info = new FileInfo(file);
                    parts.Add(file + "|" + info.Length + "|" + info.LastWriteTimeUtc.Ticks);
                } else if (extension == ".gd") {
                    Match match = declaration.Match(File.ReadAllText(file));
                    if (match.Success) parts.Add(file + "|" + match.Value);
                }
            }
        }
        parts.Sort(StringComparer.Ordinal);
        using (var hash = SHA256.Create()) return BitConverter.ToString(hash.ComputeHash(Encoding.UTF8.GetBytes(String.Join("\n", parts)))).Replace("-", "");
    }
}
