"""Validate local Markdown links, anchors, and unique stable feature dossiers."""
import argparse
import re
import sys
from pathlib import Path
from urllib.parse import unquote


def visible_markdown(text):
    return re.sub(r"(?m)^\s*(`{3,}|~{3,})[^\n]*\n.*?^\s*\1\s*$", "", text, flags=re.S)


def slug(text):
    text = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", text)
    text = re.sub(r"<[^>]*>", "", text).strip().lower()
    text = re.sub(r"[^\w\-\s]", "", text)
    return text.replace(" ", "-")


def anchors(text):
    found = set(re.findall(r'<[^>]+\b(?:id|name)=["\']([^"\']+)', text))
    counts = {}
    for heading in re.findall(r"(?m)^#{1,6}\s+(.+)$", visible_markdown(text)):
        base = slug(heading.rstrip("# "))
        count = counts.get(base, 0)
        counts[base] = count + 1
        found.add(base + ("-" + str(count) if count else ""))
    return found


def check(root, include_project=False):
    files = sorted((root / "docs").rglob("*.md"))
    files += [root / "readme.md"]
    if include_project:
        files += [root / "AGENTS.md"]
        files += list((root / ".agents").rglob("*.md"))
        files += list((root / "tools").rglob("README.md"))
        files += list((root / "design").rglob("README.md"))
        files += list((root / "design").rglob("generation*.md"))
        files += list((root / "assets/art").rglob("generation*.md"))
    errors, cache, identities = [], {}, {}
    checked = 0
    for file in files:
        if not file.exists():
            errors.append(str(file.relative_to(root)) + ": missing document")
            continue
        text = file.read_text(encoding="utf-8-sig")
        match = re.match(r"# ([A-Z]+-\d+)\b", text)
        if match:
            identity = match.group(1)
            if identity in identities:
                errors.append(identity + ": duplicate feature dossier")
            identities[identity] = file
        plain = visible_markdown(text)
        links = re.finditer(r"\]\((<[^>]+>|[^\s)]+)(?:\s+[\"'][^)]*)?\)", plain)
        for match in links:
            uri = match.group(1).strip("<>")
            if re.match(r"^[a-zA-Z][\w+.-]*:", uri) or uri.startswith("//"):
                continue
            path, _, fragment = uri.partition("#")
            target = (file.parent / unquote(path)).resolve() if path else file
            checked += 1
            if not target.exists():
                errors.append(str(file.relative_to(root)) + ": missing " + uri)
            elif fragment and target.suffix.lower() == ".md":
                if target not in cache:
                    cache[target] = anchors(target.read_text(encoding="utf-8-sig"))
                if unquote(fragment) not in cache[target]:
                    errors.append(str(file.relative_to(root)) + ": missing anchor " + uri)
    for directory in (root / "docs/implementation", root / "docs/research"):
        if directory.exists() and any(directory.rglob("*.md")):
            errors.append(str(directory.relative_to(root)) + ": obsolete cross-domain directory")
    return files, identities, checked, errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--project", action="store_true", help="Also validate project rules, skills, tool and art source documentation")
    args = parser.parse_args()
    files, ids, links, errors = check(args.root.resolve(), args.project)
    for error in errors:
        print(error)
    print("DOC_LINK_CHECK documents=%d features=%d links=%d errors=%d" % (len(files), len(ids), links, len(errors)))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
