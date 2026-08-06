# -*- coding: utf-8 -*-
"""v42: v41 with every tracked change accepted.

Accepting means: unwrap w:ins so the inserted text becomes ordinary text, drop
w:del and its content outright, and remove any paragraph whose mark was deleted
and which is now empty. Resolved comments are carried through; strip them
separately if a comment-free copy is wanted.
"""
import shutil, sys, zipfile
from lxml import etree

sys.path.insert(0, "/sessions/keen-confident-allen/mnt/outputs/v32")
import tracklib as T
from tracklib import w

SRC = "/sessions/keen-confident-allen/mnt/outputs/mer_manuscript_v41.docx"
OUT = "/sessions/keen-confident-allen/mnt/outputs/mer_manuscript_v42.docx"

zin = zipfile.ZipFile(SRC)
parts = {i.filename: zin.read(i.filename) for i in zin.infolist()}
infos = list(zin.infolist())

root = etree.fromstring(parts["word/document.xml"])
before = (len(root.findall(".//" + w("ins"))), len(root.findall(".//" + w("del"))))
n_para_before = len(root.find(w("body")).findall(w("p")))

T.accept_all(root)

# Word keeps revision-view settings in settings.xml; clear any that would make
# the file open in "show markup" mode with nothing to show.
if "word/settings.xml" in parts:
    st = etree.fromstring(parts["word/settings.xml"])
    for tag in ("trackChanges", "revisionView"):
        for el in st.findall(w(tag)):
            el.getparent().remove(el)
    parts["word/settings.xml"] = etree.tostring(
        st, xml_declaration=True, encoding="UTF-8", standalone=True)

after = (len(root.findall(".//" + w("ins"))), len(root.findall(".//" + w("del"))))
n_para_after = len(root.find(w("body")).findall(w("p")))
parts["word/document.xml"] = etree.tostring(
    root, xml_declaration=True, encoding="UTF-8", standalone=True)

tmp = OUT + ".tmp"
with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as dst:
    for info in infos:
        dst.writestr(info, parts[info.filename])
shutil.move(tmp, OUT)

print("insertions accepted : %d" % before[0])
print("deletions applied   : %d" % before[1])
print("remaining revisions : %d ins, %d del" % after)
print("paragraphs          : %d -> %d" % (n_para_before, n_para_after))
