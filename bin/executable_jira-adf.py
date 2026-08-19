#!/usr/bin/env python3
"""Plain text -> Atlassian Document Format (ADF), read from stdin, JSON on stdout.

Conventions:
  blank line            -> new paragraph
  single newline         -> hard break within a paragraph
  consecutive "- "/"* "  -> bulletList
  "Label:" at the start of a block -> bold label
  `code span`            -> inline code mark
"""

import json
import re
import sys

LABEL_RE = re.compile(r"^([A-Za-z][A-Za-z0-9 /]{0,40}:)(\s+)(.*)$")
BARE_LABEL_RE = re.compile(r"^([A-Za-z][A-Za-z0-9 /]{0,40}:)\s*$")
CODE_SPLIT_RE = re.compile(r"(`[^`]+`)")


def tokenize(text):
    nodes = []
    for part in CODE_SPLIT_RE.split(text):
        if not part:
            continue
        if part.startswith("`") and part.endswith("`") and len(part) >= 2:
            inner = part[1:-1]
            if inner:
                nodes.append(
                    {"type": "text", "text": inner, "marks": [{"type": "code"}]}
                )
        else:
            nodes.append({"type": "text", "text": part})
    return nodes


def inline_nodes(line, is_first_line_of_block):
    m = LABEL_RE.match(line) if is_first_line_of_block else None
    if not m:
        return tokenize(line)
    label, sep, rest = m.groups()
    nodes = [{"type": "text", "text": label, "marks": [{"type": "strong"}]}]
    if sep:
        nodes.append({"type": "text", "text": sep})
    nodes.extend(tokenize(rest))
    return nodes


def is_bullet(line):
    return bool(re.match(r"^[-*]\s+", line))


def bullet_list(lines):
    items = []
    for l in lines:
        item_text = re.sub(r"^[-*]\s+", "", l)
        items.append(
            {
                "type": "listItem",
                "content": [
                    {
                        "type": "paragraph",
                        "content": tokenize(item_text)
                        or [{"type": "text", "text": " "}],
                    }
                ],
            }
        )
    return {"type": "bulletList", "content": items}


def paragraph(lines):
    content = []
    for idx, l in enumerate(lines):
        if idx > 0:
            content.append({"type": "hardBreak"})
        content.extend(inline_nodes(l, idx == 0))
    if not content:
        content = [{"type": "text", "text": " "}]
    return {"type": "paragraph", "content": content}


RULE_RE = re.compile(r"^(-{3,}|\*{3,}|_{3,})$")


def build_block(lines):
    if any(RULE_RE.match(l) for l in lines):
        result, current = [], []
        for l in lines:
            if RULE_RE.match(l):
                if current:
                    result.extend(build_block(current))
                    current = []
                result.append({"type": "rule"})
            else:
                current.append(l)
        if current:
            result.extend(build_block(current))
        return result

    # "Label:\n- item\n- item" (bare label line followed by a bullet list) -> two nodes
    if (
        len(lines) > 1
        and BARE_LABEL_RE.match(lines[0])
        and all(is_bullet(l) for l in lines[1:])
    ):
        return [paragraph([lines[0]]), bullet_list(lines[1:])]

    if lines and all(is_bullet(l) for l in lines):
        return [bullet_list(lines)]

    return [paragraph(lines)]


def adf(text):
    text = text.strip("\n")
    if not text:
        return {
            "type": "doc",
            "version": 1,
            "content": [{"type": "paragraph", "content": []}],
        }
    blocks = re.split(r"\n[ \t]*\n+", text)
    content = []
    for block in blocks:
        lines = [l for l in block.split("\n") if l.strip() != ""]
        if not lines:
            continue
        content.extend(build_block(lines))
    if not content:
        content = [{"type": "paragraph", "content": []}]
    return {"type": "doc", "version": 1, "content": content}


def main():
    text = sys.stdin.read()
    json.dump(adf(text), sys.stdout)


if __name__ == "__main__":
    main()
