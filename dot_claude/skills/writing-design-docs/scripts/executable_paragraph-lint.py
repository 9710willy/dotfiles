#!/usr/bin/env python3
"""Lint Confluence storage HTML (or any HTML) for unreadable blocks.
Flags <p>/<li> blocks whose visible text exceeds the word budget, plus
semicolon/parenthetical pileups that read as run-ons. Exit 1 if any FAIL."""
import re, sys

WARN, FAIL = 60, 90

def visible(t):
    t = re.sub(r'<!\[CDATA\[(.*?)\]\]>', r'\1', t, flags=re.S)
    t = re.sub(r'<[^>]+>', ' ', t)
    return re.sub(r'\s+', ' ', t).strip()

def blocks(html):
    # top-level <p> and <li> spans (non-greedy; nested <p> inside macros counted separately)
    for m in re.finditer(r'<(p|li)\b[^>]*>(.*?)</\1>', html, flags=re.S):
        yield m.start(), m.group(1), m.group(2)

def lint(path):
    html = open(path).read()
    bad = 0
    for off, tag, body in blocks(html):
        body = re.sub(r'<(ul|ol)\b.*?</\1>', ' ', body, flags=re.S)  # nested lists lint separately
        txt = visible(body)
        words = len(txt.split())
        semis = txt.count(';')
        parens = txt.count('(')
        level = 'FAIL' if words > FAIL else 'WARN' if words > WARN else None
        if not level and semis >= 4: level = 'WARN'
        if level:
            bad += level == 'FAIL'
            print(f'{level} <{tag}> {words}w {semis};{parens}( @{off}: {txt[:90]}...')
    return bad

if __name__ == '__main__':
    total = 0
    for p in sys.argv[1:]:
        print(f'== {p}')
        total += lint(p)
    sys.exit(1 if total else 0)
