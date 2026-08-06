# -*- coding: utf-8 -*-
"""v45 = v44 with every comment removed. Tracked changes are untouched.

Removing comments from a .docx means four things, not one: delete the comment
parts, drop their content-type overrides, drop their relationships, and strip
the anchors from the document body. Leaving any of them behind produces a file
Word reports as corrupt.
"""
import shutil, zipfile
from lxml import etree

W = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"
CT = "{http://schemas.openxmlformats.org/package/2006/content-types}"
PR = "{http://schemas.openxmlformats.org/package/2006/relationships}"

SRC = "/sessions/keen-confident-allen/mnt/outputs/mer_manuscript_v44.docx"
OUT = "/sessions/keen-confident-allen/mnt/outputs/mer_manuscript_v45.docx"

DROP = {"word/comments.xml", "word/commentsExtended.xml", "word/commentsIds.xml",
        "word/commentsExtensible.xml", "word/people.xml"}
ANCHORS = ("commentRangeStart", "commentRangeEnd", "commentReference")

zin = zipfile.ZipFile(SRC)
parts = {i.filename: zin.read(i.filename) for i in zin.infolist()}
infos = [i for i in zin.infolist() if i.filename not in DROP]

# 1. strip anchors from the body; a run left holding only a reference goes too
doc = etree.fromstring(parts["word/document.xml"])
n_anchor = 0
for tag in ANCHORS:
    for el in doc.findall(".//" + W + tag):
        parent = el.getparent()
        parent.remove(el)
        n_anchor += 1
        if parent.tag == W + "r" and not [c for c in parent if c.tag != W + "rPr"]:
            parent.getparent().remove(parent)
parts["word/document.xml"] = etree.tostring(
    doc, xml_declaration=True, encoding="UTF-8", standalone=True)

# 2. content-type overrides
ct = etree.fromstring(parts["[Content_Types].xml"])
n_ct = 0
for ov in ct.findall(CT + "Override"):
    if ov.get("PartName", "").lstrip("/") in DROP:
        ct.remove(ov)
        n_ct += 1
parts["[Content_Types].xml"] = etree.tostring(
    ct, xml_declaration=True, encoding="UTF-8", standalone=True)

# 3. relationships
rels = etree.fromstring(parts["word/_rels/document.xml.rels"])
n_rel = 0
for r in rels.findall(PR + "Relationship"):
    if ("word/" + (r.get("Target") or "").lstrip("./")) in DROP:
        rels.remove(r)
        n_rel += 1
parts["word/_rels/document.xml.rels"] = etree.tostring(
    rels, xml_declaration=True, encoding="UTF-8", standalone=True)

tmp = OUT + ".tmp"
with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as dst:
    for info in infos:
        dst.writestr(info, parts[info.filename])
shutil.move(tmp, OUT)
print("comment parts removed      : %d" % len(DROP))
print("anchors stripped from body : %d" % n_anchor)
print("content-type overrides     : %d" % n_ct)
print("relationships              : %d" % n_rel)
