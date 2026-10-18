#!/usr/bin/env python3
"""Check source-catalog completeness and render the readable prompt checklist.

This verifies traceability, never the truth of a PASS or product readiness.
The CSV ledgers remain authoritative for evidence and dispositions.
"""
import argparse
import csv
import hashlib
import json
import re
import zipfile
import xml.etree.ElementTree as ET
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs/PROMPT_VERIFICATION_CHECKLIST.md"
SOURCE_DIGEST = "080d02ca81dc81d368b177facbe7680be0d86035dd1a4e5338f5f59e6db08533"
WORD_DIGEST = "61ba18db9beb2fac9be2e13928c82d4bb933441f3bb2e73ab66834e81494968d"


def verify_word():
    path = ROOT / "WhatsApp_Web_Android_iOS_Application_Plan.docx"
    assert hashlib.sha256(path.read_bytes()).hexdigest() == WORD_DIGEST, "Original Word plan changed"
    ns = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}
    with zipfile.ZipFile(path) as archive:
        body = ET.fromstring(archive.read("word/document.xml")).find("w:body", ns)
        relationships = ET.fromstring(archive.read("word/_rels/document.xml.rels"))
    nonempty = set()
    table_rows = set()
    paragraph = table = 0
    for child in body:
        if child.tag == f"{{{ns['w']}}}p":
            paragraph += 1
            if "".join(child.itertext()).strip():
                nonempty.add(paragraph)
        elif child.tag == f"{{{ns['w']}}}tbl":
            table += 1
            for row, _ in enumerate(child.findall("w:tr", ns), 1):
                if row > 1:
                    table_rows.add(f"T{table:02}R{row:02}")
    crosswalk = (ROOT / "docs/DESIGN_DOCUMENT_TRACEABILITY.md").read_text()
    covered = []
    for first, last in re.findall(r"^\| DOC-\d{3} / P(\d{3})–P(\d{3}) \|", crosswalk, re.M):
        covered.extend(range(int(first), int(last) + 1))
    assert len(covered) == len(set(covered)) and nonempty <= set(covered), "Word paragraph crosswalk omission/overlap"
    mapped_rows = re.findall(r"^\| (T\d{2}R\d{2})(?: /[^|]+)? \|", crosswalk, re.M)
    assert len(mapped_rows) == len(set(mapped_rows)) and set(mapped_rows) == table_rows, "Word table row omission/duplication"
    targets = [r.attrib["Target"] for r in relationships if r.attrib.get("Type", "").endswith("/hyperlink")]
    catalog = (ROOT / "docs/SOURCE_CATALOG.md").read_text()
    assert len(targets) == 37 and all(target in catalog for target in targets), "Word source hyperlink omission"
    assert len(nonempty) == 337 and len(table_rows) == 214 and table == 21, "Word extraction coverage changed"


def read_rows(name):
    with (ROOT / "docs" / name).open(newline="") as stream:
        rows = list(csv.DictReader(stream))
    assert rows and len({row["id"] for row in rows}) == len(rows), name
    assert all(all(value for value in row.values()) for row in rows), f"Blank field: {name}"
    return rows


def verify(requirements, acceptance):
    tuples = [(r["id"], r["source"], r["requirement"]) for r in requirements]
    actual = hashlib.sha256(json.dumps(tuples, ensure_ascii=False).encode()).hexdigest()
    assert actual == SOURCE_DIGEST, "Original requirement identity/source/text changed"
    expected = defaultdict(list)
    titles = {}
    section = 0
    for line in (ROOT / "docs/IMPLEMENTATION_INSTRUCTIONS.md").read_text().splitlines():
        heading = re.match(r"## (\d+) (.*)", line)
        if heading:
            section = int(heading[1])
            titles[section] = heading[2]
        elif section in {*range(1, 15), 16, 17, 18} and line.strip() and not line.startswith("#"):
            expected[section].append(re.sub(r"^\d+\. ", "", line.strip()))
    for number, clauses in expected.items():
        extracted = [re.sub(r"^\d+\. ", "", row["requirement"])
                     for row in requirements if row["source"] == f"Instructions section {number}"]
        assert extracted == clauses, f"Prompt section {number} coverage changed"
    source = (ROOT / "docs/IMPLEMENTATION_INSTRUCTIONS.md").read_text()
    cases = re.findall(r"^- \*\*(AT-[A-Z]\d+):\*\* (.*?) Required outcome: (.*?)$", source, re.M)
    assert len(cases) == len(acceptance) == 70, "Acceptance catalog count"
    assert cases == [(r["id"], r["scenario"], r["expected"]) for r in acceptance], "Acceptance source changed"
    ids = {row["id"] for row in acceptance}
    for row in requirements:
        for case in re.findall(r"AT-[A-Z]\d+", row["acceptance_ids"]):
            assert case in ids, f"Unknown acceptance reference {case}: {row['id']}"
    return titles


def render(requirements, acceptance, titles):
    out = ["# Complete prompt verification checklist", "",
           "Generated from the reviewed requirement and acceptance ledgers. This file retains every clause and all 70 cases. "
           "A PASS applies only to its stated validation scope. Source inspection, unit tests and synthetic fixtures do not close physical, service, elapsed-time or release gates.", "",
           "Start with [the audit report](DESIGN_VERIFICATION_CHECKLIST.md) and [the original Word plan crosswalk](DESIGN_DOCUMENT_TRACEABILITY.md). "
           "The introduction and section 20 state the execution objective; sections 1–14 and 16–18 supply all 374 ledger clauses. "
           "Section 15 is the 70-case catalog below. Section 19 is preserved in [the source catalog](SOURCE_CATALOG.md).", "",
           "Refresh after reviewing CSV changes: `python3 scripts/check_traceability.py --write`. "
           "A normal run checks both source completeness and this generated view, without modifying files.", "",
           "## Requirement dispositions", "", "| Implementation status | Clauses |", "| --- | ---: |"]
    out += [f"| {key} | {value} |" for key, value in sorted(Counter(r["implementation_status"] for r in requirements).items())]
    out += ["", "These overlapping product clauses include process instructions and rationale. Their counts are not a product completion percentage.", ""]
    current = None
    for row in requirements:
        section = int(row["source"].rsplit(" ", 1)[1])
        if section != current:
            current = section
            out += [f"## {section}. {titles[section]}", ""]
        out += [f"### {row['id']}", "", row["requirement"], "",
                f"**Implementation:** {row['implementation_status']} · **Validation:** {row['validation_status']}", "",
                f"Scope: {row['validation_scope']}", "",
                f"Source: {row['code_reference']}", "",
                f"Evidence: {row['evidence']}", "",
                f"Acceptance: {row['acceptance_ids']}. Classification: {row['classification']}. Module: {row['module']}.", "",
                f"Remaining action: {row['next_action']} Owner: {row['owner']}. Dependencies: {row['dependencies']}.", ""]
    out += ["## 15. Complete acceptance catalog", "",
            "Every original case is retained. PASS_UNIT, PASS_SYNTHETIC and PASS_LOCAL describe a limited observation, not a full device/service matrix.", ""]
    for row in acceptance:
        out += [f"### {row['id']}", "", row["scenario"], "",
                f"Required outcome: {row['expected']}", "",
                f"**Status:** {row['validation_status']}. {row['context']}", "",
                f"Evidence: {row['evidence']}", "",
                f"Remaining action: {row['next_action']} Owner: {row['owner']}.", ""]
    return "\n".join(out)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true", help="Regenerate the readable Markdown view")
    args = parser.parse_args()
    requirements = read_rows("requirements.csv")
    acceptance = read_rows("acceptance.csv")
    titles = verify(requirements, acceptance)
    verify_word()
    content = render(requirements, acceptance, titles)
    if args.write:
        OUTPUT.write_text(content)
    else:
        assert OUTPUT.is_file() and OUTPUT.read_text() == content, "Readable checklist is stale; rerun with --write"
    print("PASS: 374 exact prompt clauses, 70 exact acceptance cases, valid case references and current Markdown view.")
    print("PASS: unchanged Word plan; 337 nonempty paragraphs, 214 data rows and 37 source hyperlinks mapped.")
    print("Coverage verification only; does not certify requirement fulfillment.")


if __name__ == "__main__":
    main()
