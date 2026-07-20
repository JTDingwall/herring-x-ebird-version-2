#!/usr/bin/env python3
"""Build a self-contained HTML design report with illustrative (synthetic) figures.

No raw eBird or herring records are read. The script uses only version-controlled
registries and hard-coded aggregate legacy metadata for planning context.
"""
from __future__ import annotations

import html
import math
from pathlib import Path
from typing import Iterable

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "reports" / "comprehensive_analysis_plan_v2.html"

PALETTE = {
    "navy": "#16324F",
    "blue": "#2A6F97",
    "sky": "#61A5C2",
    "teal": "#2A9D8F",
    "green": "#5FAD56",
    "gold": "#E9C46A",
    "orange": "#F4A261",
    "red": "#E76F51",
    "purple": "#6C5CE7",
    "slate": "#667085",
    "light": "#EEF4F8",
    "grid": "#D9E2E8",
    "ink": "#1C2833",
}


def esc(x: object) -> str:
    return html.escape("" if x is None else str(x))


def watermark(width: int, y: int = 24) -> str:
    return (
        f'<text x="{width-12}" y="{y}" text-anchor="end" '
        f'font-size="12" font-weight="700" fill="{PALETTE["red"]}" opacity="0.80">'
        "ILLUSTRATIVE — NOT EMPIRICAL RESULTS</text>"
    )


def svg_wrap(inner: str, width: int = 760, height: int = 360, title: str = "") -> str:
    return (
        f'<svg class="example-svg" role="img" aria-label="{esc(title)}" '
        f'viewBox="0 0 {width} {height}" xmlns="http://www.w3.org/2000/svg">'
        f'<rect x="0" y="0" width="{width}" height="{height}" rx="14" fill="#ffffff"/>'
        f'{inner}{watermark(width)}</svg>'
    )


def line_chart(title: str, series: list[tuple[str, list[float], str]], xvals: list[float],
               xlabel: str, ylabel: str, width: int = 760, height: int = 360,
               vlines: list[tuple[float, str]] | None = None) -> str:
    left, right, top, bottom = 70, 22, 48, 58
    pw, ph = width - left - right, height - top - bottom
    ys = [v for _, vals, _ in series for v in vals]
    ymin, ymax = min(ys), max(ys)
    pad = (ymax - ymin) * 0.10 or 1
    ymin -= pad
    ymax += pad
    xmin, xmax = min(xvals), max(xvals)

    def sx(x: float) -> float:
        return left + (x - xmin) / (xmax - xmin) * pw

    def sy(y: float) -> float:
        return top + (ymax - y) / (ymax - ymin) * ph

    parts = [
        f'<text x="{left}" y="30" font-size="18" font-weight="700" fill="{PALETTE["navy"]}">{esc(title)}</text>',
        f'<line x1="{left}" y1="{top+ph}" x2="{left+pw}" y2="{top+ph}" stroke="{PALETTE["ink"]}"/>',
        f'<line x1="{left}" y1="{top}" x2="{left}" y2="{top+ph}" stroke="{PALETTE["ink"]}"/>',
    ]
    for i in range(5):
        y = top + ph * i / 4
        val = ymax - (ymax - ymin) * i / 4
        parts.append(f'<line x1="{left}" y1="{y:.1f}" x2="{left+pw}" y2="{y:.1f}" stroke="{PALETTE["grid"]}" stroke-dasharray="3 4"/>')
        parts.append(f'<text x="{left-8}" y="{y+4:.1f}" text-anchor="end" font-size="11" fill="{PALETTE["slate"]}">{val:.1f}</text>')
    for i in range(6):
        x = left + pw * i / 5
        val = xmin + (xmax - xmin) * i / 5
        parts.append(f'<text x="{x:.1f}" y="{top+ph+20}" text-anchor="middle" font-size="11" fill="{PALETTE["slate"]}">{val:.0f}</text>')
    if vlines:
        for xv, lab in vlines:
            x = sx(xv)
            parts.append(f'<line x1="{x:.1f}" y1="{top}" x2="{x:.1f}" y2="{top+ph}" stroke="{PALETTE["orange"]}" stroke-width="1.5" stroke-dasharray="5 4"/>')
            parts.append(f'<text x="{x+4:.1f}" y="{top+14}" font-size="10" fill="{PALETTE["orange"]}">{esc(lab)}</text>')
    for name, vals, color in series:
        pts = " ".join(f"{sx(x):.1f},{sy(y):.1f}" for x, y in zip(xvals, vals))
        parts.append(f'<polyline fill="none" stroke="{color}" stroke-width="3" points="{pts}"/>')
    lx, ly = left + 8, top + 8
    for j, (name, _, color) in enumerate(series):
        yy = ly + j * 20
        parts.append(f'<line x1="{lx}" y1="{yy}" x2="{lx+24}" y2="{yy}" stroke="{color}" stroke-width="3"/>')
        parts.append(f'<text x="{lx+30}" y="{yy+4}" font-size="11" fill="{PALETTE["ink"]}">{esc(name)}</text>')
    parts.append(f'<text x="{left+pw/2}" y="{height-14}" text-anchor="middle" font-size="12" fill="{PALETTE["ink"]}">{esc(xlabel)}</text>')
    parts.append(f'<text x="18" y="{top+ph/2}" transform="rotate(-90 18 {top+ph/2})" text-anchor="middle" font-size="12" fill="{PALETTE["ink"]}">{esc(ylabel)}</text>')
    return svg_wrap("".join(parts), width, height, title)


def flow_diagram() -> str:
    width, height = 920, 430
    boxes = [
        (25, 75, 150, 75, "eBird EBD", "species, counts, taxonomy"),
        (25, 185, 150, 75, "eBird SED", "effort, observer, place"),
        (25, 295, 150, 75, "DFO spawn", "date, point, extent, index"),
        (225, 55, 175, 95, "Metadata & privacy audit", "checksums, schema, restricted fields"),
        (225, 180, 175, 95, "Canonical data products", "checklists, species, events, guilds"),
        (225, 305, 175, 75, "Exposure engineering", "time × distance × intensity"),
        (455, 50, 180, 85, "Count & encounter", "hurdle, NB/Tweedie, upper tail"),
        (455, 160, 180, 85, "Redistribution", "near/far/total and allocation"),
        (455, 270, 180, 85, "Community", "guilds, co-occurrence, JSDM"),
        (700, 105, 190, 85, "Validation", "placebos, holdouts, event bootstrap"),
        (700, 230, 190, 95, "Evidence synthesis", "effect sizes, heterogeneity, lay summaries"),
    ]
    parts = [f'<text x="25" y="32" font-size="20" font-weight="700" fill="{PALETTE["navy"]}">Version 2 analysis architecture</text>']
    for x, y, w, h, title, subtitle in boxes:
        fill = PALETTE["light"] if x < 450 else "#F8FBFC"
        parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="12" fill="{fill}" stroke="{PALETTE["sky"]}"/>')
        parts.append(f'<text x="{x+12}" y="{y+27}" font-size="14" font-weight="700" fill="{PALETTE["navy"]}">{esc(title)}</text>')
        words = subtitle.split()
        line, lines = "", []
        for word in words:
            if len(line + " " + word) > 24:
                lines.append(line)
                line = word
            else:
                line = (line + " " + word).strip()
        if line:
            lines.append(line)
        for i, ln in enumerate(lines[:3]):
            parts.append(f'<text x="{x+12}" y="{y+48+i*15}" font-size="11" fill="{PALETTE["slate"]}">{esc(ln)}</text>')
    arrows = [
        (175,112,225,95),(175,222,225,225),(175,332,225,342),
        (312,150,312,180),(312,275,312,305),
        (400,220,455,92),(400,235,455,202),(400,330,455,312),
        (635,92,700,145),(635,202,700,145),(635,312,700,275),
        (795,190,795,230)
    ]
    for x1,y1,x2,y2 in arrows:
        parts.append(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{PALETTE["slate"]}" stroke-width="2" marker-end="url(#arrow)"/>')
    defs = '<defs><marker id="arrow" markerWidth="10" markerHeight="10" refX="8" refY="3" orient="auto"><path d="M0,0 L0,6 L9,3 z" fill="#667085"/></marker></defs>'
    return svg_wrap(defs + "".join(parts), width, height, "Version 2 analysis architecture")


def hurdle_diagram() -> str:
    width, height = 820, 310
    parts = [f'<text x="28" y="32" font-size="20" font-weight="700" fill="{PALETTE["navy"]}">One checklist contributes information in two stages</text>']
    nodes = [
        (35,110,160,75,"Complete checklist","species absent or reported"),
        (250,65,185,75,"Detection component","P(species reported)"),
        (250,175,185,75,"Positive-count component","flock size when numeric"),
        (515,65,260,75,"Marginal response","probability × expected positive count"),
        (515,175,260,75,"Upper-tail response","P(large flock ≥ threshold)"),
    ]
    for x,y,w,h,t,s in nodes:
        parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="12" fill="#F8FBFC" stroke="{PALETTE["sky"]}"/>')
        parts.append(f'<text x="{x+12}" y="{y+27}" font-size="14" font-weight="700" fill="{PALETTE["navy"]}">{esc(t)}</text>')
        parts.append(f'<text x="{x+12}" y="{y+50}" font-size="11" fill="{PALETTE["slate"]}">{esc(s)}</text>')
    defs = '<defs><marker id="arrow2" markerWidth="10" markerHeight="10" refX="8" refY="3" orient="auto"><path d="M0,0 L0,6 L9,3 z" fill="#667085"/></marker></defs>'
    arrows = [(195,147,250,102),(195,147,250,212),(435,102,515,102),(435,212,515,212),(435,212,515,132)]
    for x1,y1,x2,y2 in arrows:
        parts.append(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{PALETTE["slate"]}" stroke-width="2" marker-end="url(#arrow2)"/>')
    parts.append(f'<text x="35" y="280" font-size="12" fill="{PALETTE["red"]}" font-weight="700">X, lower-bound, ambiguous, and missing counts remain separate—not invented.</text>')
    return svg_wrap(defs + "".join(parts), width, height, "Hurdle model decomposition")


def heatmap_svg(title: str, row_labels: list[str], col_labels: list[str], values: list[list[float]],
                width: int = 820, height: int = 390, diverging: bool = False) -> str:
    left, top, right, bottom = 150, 55, 80, 70
    nrow, ncol = len(row_labels), len(col_labels)
    cw = (width-left-right)/ncol
    ch = (height-top-bottom)/nrow
    vals = [v for row in values for v in row]
    vmin, vmax = min(vals), max(vals)
    vmax_abs = max(abs(vmin), abs(vmax)) if diverging else None

    def color(v: float) -> str:
        if diverging:
            t = (v / vmax_abs + 1)/2 if vmax_abs else .5
            if t < .5:
                a = t/.5
                c1=(42,111,151); c2=(245,248,250)
            else:
                a=(t-.5)/.5
                c1=(245,248,250); c2=(231,111,81)
        else:
            a = (v-vmin)/(vmax-vmin) if vmax>vmin else .5
            c1=(238,244,248); c2=(42,157,143)
        r=int(c1[0]+(c2[0]-c1[0])*a); g=int(c1[1]+(c2[1]-c1[1])*a); b=int(c1[2]+(c2[2]-c1[2])*a)
        return f"#{r:02x}{g:02x}{b:02x}"

    parts=[f'<text x="24" y="30" font-size="19" font-weight="700" fill="{PALETTE["navy"]}">{esc(title)}</text>']
    for i, lab in enumerate(row_labels):
        y=top+(i+.5)*ch
        parts.append(f'<text x="{left-10}" y="{y+4:.1f}" text-anchor="end" font-size="11" fill="{PALETTE["ink"]}">{esc(lab)}</text>')
    for j, lab in enumerate(col_labels):
        x=left+(j+.5)*cw
        parts.append(f'<text x="{x:.1f}" y="{top+nrow*ch+20}" transform="rotate(35 {x:.1f} {top+nrow*ch+20})" text-anchor="start" font-size="10" fill="{PALETTE["ink"]}">{esc(lab)}</text>')
    for i,row in enumerate(values):
        for j,v in enumerate(row):
            x=left+j*cw; y=top+i*ch
            parts.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{cw-1:.1f}" height="{ch-1:.1f}" fill="{color(v)}"/>')
            if nrow<=10 and ncol<=12:
                parts.append(f'<text x="{x+cw/2:.1f}" y="{y+ch/2+4:.1f}" text-anchor="middle" font-size="9" fill="{PALETTE["ink"]}">{v:.2f}</text>')
    parts.append(f'<text x="{left+(ncol*cw)/2}" y="{height-12}" text-anchor="middle" font-size="11" fill="{PALETTE["slate"]}">Columns</text>')
    return svg_wrap("".join(parts), width, height, title)


def stacked_bar_svg() -> str:
    width,height=760,350
    left,top,bottom=80,55,55
    stages=["Early pre","Immediate pre","Spawn","Egg peak","Post"]
    near=[18,20,42,48,30]; mid=[32,31,30,29,32]; far=[50,49,28,23,38]
    parts=[f'<text x="24" y="30" font-size="19" font-weight="700" fill="{PALETTE["navy"]}">Illustrative regional allocation of birds among distance zones</text>']
    pw=width-left-30; ph=height-top-bottom; bw=pw/len(stages)*.55
    for i,s in enumerate(stages):
        x=left+(i+.5)*pw/len(stages)-bw/2
        accum=0
        for val,color,label in [(near,PALETTE['teal'],'0–2 km'),(mid,PALETTE['gold'],'2–5 km'),(far,PALETTE['sky'],'5–20 km')]:
            h=ph*val[i]/100; y=top+ph-h-accum
            parts.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{bw:.1f}" height="{h:.1f}" fill="{color}"/>')
            accum+=h
        parts.append(f'<text x="{x+bw/2:.1f}" y="{top+ph+18}" text-anchor="middle" font-size="10" fill="{PALETTE["ink"]}">{esc(s)}</text>')
    for v in [0,25,50,75,100]:
        y=top+ph*(1-v/100)
        parts.append(f'<line x1="{left}" y1="{y:.1f}" x2="{left+pw}" y2="{y:.1f}" stroke="{PALETTE["grid"]}"/>')
        parts.append(f'<text x="{left-8}" y="{y+4:.1f}" text-anchor="end" font-size="10" fill="{PALETTE["slate"]}">{v}%</text>')
    lx=width-190; ly=70
    for j,(lab,color) in enumerate([('0–2 km',PALETTE['teal']),('2–5 km',PALETTE['gold']),('5–20 km',PALETTE['sky'])]):
        parts.append(f'<rect x="{lx}" y="{ly+j*22}" width="13" height="13" fill="{color}"/>')
        parts.append(f'<text x="{lx+20}" y="{ly+11+j*22}" font-size="11" fill="{PALETTE["ink"]}">{lab}</text>')
    parts.append(f'<text x="18" y="{top+ph/2}" transform="rotate(-90 18 {top+ph/2})" text-anchor="middle" font-size="12">Share of observed regional count</text>')
    return svg_wrap("".join(parts),width,height,"Regional allocation")


def forest_svg() -> str:
    width,height=800,420
    species=["Surf Scoter","White-winged Scoter","Harlequin Duck","Greater Scaup","Glaucous-winged Gull","Short-billed Gull","Bald Eagle","Horned Grebe"]
    est=[0.34,0.20,0.16,0.27,0.41,0.52,0.09,0.12]
    lo=[0.12,-0.02,-0.05,0.05,0.23,0.31,-0.04,-0.08]
    hi=[0.56,0.42,0.37,0.49,0.59,0.73,0.22,0.32]
    left,top=190,50; right=40; bottom=45; pw=width-left-right; ph=height-top-bottom
    xmin,xmax=-0.2,0.8
    sx=lambda x:left+(x-xmin)/(xmax-xmin)*pw
    parts=[f'<text x="24" y="30" font-size="19" font-weight="700" fill="{PALETTE["navy"]}">Illustrative species-level active-spawn count effects</text>']
    parts.append(f'<line x1="{sx(0)}" y1="{top}" x2="{sx(0)}" y2="{top+ph}" stroke="{PALETTE["slate"]}" stroke-dasharray="5 4"/>')
    for i,s in enumerate(species):
        y=top+(i+.5)*ph/len(species)
        parts.append(f'<text x="{left-12}" y="{y+4:.1f}" text-anchor="end" font-size="11" fill="{PALETTE["ink"]}">{esc(s)}</text>')
        parts.append(f'<line x1="{sx(lo[i]):.1f}" y1="{y:.1f}" x2="{sx(hi[i]):.1f}" y2="{y:.1f}" stroke="{PALETTE["blue"]}" stroke-width="2"/>')
        parts.append(f'<circle cx="{sx(est[i]):.1f}" cy="{y:.1f}" r="5" fill="{PALETTE["teal"]}"/>')
    for x in [-.2,0,.2,.4,.6,.8]:
        parts.append(f'<text x="{sx(x):.1f}" y="{height-18}" text-anchor="middle" font-size="10" fill="{PALETTE["slate"]}">{x:.1f}</text>')
    parts.append(f'<text x="{left+pw/2}" y="{height-4}" text-anchor="middle" font-size="11">Log count ratio: active/egg period versus reference</text>')
    return svg_wrap("".join(parts),width,height,"Species forest plot")


def network_svg() -> str:
    width,height=760,390
    nodes={
        "Surf Scoter":(160,110,PALETTE['teal']),"White-winged":(275,75,PALETTE['teal']),"Harlequin":(245,190,PALETTE['teal']),
        "Glaucous-winged":(470,90,PALETTE['gold']),"Short-billed":(560,165,PALETTE['gold']),"Greater Scaup":(360,225,PALETTE['teal']),
        "Pelagic Cormorant":(465,270,PALETTE['blue']),"Bald Eagle":(620,270,PALETTE['orange'])
    }
    edges=[("Surf Scoter","White-winged",3),("Surf Scoter","Harlequin",2),("White-winged","Greater Scaup",2),
           ("Harlequin","Greater Scaup",1.5),("Greater Scaup","Glaucous-winged",1.8),("Glaucous-winged","Short-billed",3),
           ("Short-billed","Bald Eagle",1.8),("Pelagic Cormorant","Bald Eagle",1.2),("Greater Scaup","Pelagic Cormorant",1.1),
           ("Glaucous-winged","Bald Eagle",2.2)]
    parts=[f'<text x="24" y="30" font-size="19" font-weight="700" fill="{PALETTE["navy"]}">Illustrative conditional co-occurrence network during spawn</text>']
    for a,b,w in edges:
        x1,y1,_=nodes[a]; x2,y2,_=nodes[b]
        parts.append(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{PALETTE["slate"]}" stroke-width="{w}" opacity="0.65"/>')
    for name,(x,y,c) in nodes.items():
        parts.append(f'<circle cx="{x}" cy="{y}" r="22" fill="{c}" stroke="#fff" stroke-width="3"/>')
        parts.append(f'<text x="{x}" y="{y+38}" text-anchor="middle" font-size="10" fill="{PALETTE["ink"]}">{esc(name)}</text>')
    parts.append(f'<text x="25" y="365" font-size="11" fill="{PALETTE["slate"]}">Edges represent residual association after herring, effort, season, observer, event, and place are modeled—not proof of direct social attraction.</text>')
    return svg_wrap("".join(parts),width,height,"Conditional co-occurrence network")


def ordination_svg() -> str:
    width,height=760,380
    parts=[f'<text x="24" y="30" font-size="19" font-weight="700" fill="{PALETTE["navy"]}">Illustrative community-composition shift</text>']
    left,top=70,55; pw=650; ph=265
    parts += [f'<line x1="{left}" y1="{top+ph}" x2="{left+pw}" y2="{top+ph}" stroke="{PALETTE["ink"]}"/>',f'<line x1="{left}" y1="{top}" x2="{left}" y2="{top+ph}" stroke="{PALETTE["ink"]}"/>']
    groups={
        'Pre':[(.22,.50),(.27,.57),(.30,.46),(.18,.43),(.34,.53),(.25,.39)],
        'Spawn/egg':[(.60,.62),(.66,.57),(.72,.69),(.58,.72),(.69,.77),(.76,.61)],
        'Post':[(.47,.40),(.52,.47),(.57,.36),(.44,.33),(.61,.43),(.50,.55)]
    }
    colors={'Pre':PALETTE['sky'],'Spawn/egg':PALETTE['red'],'Post':PALETTE['gold']}
    for g,pts in groups.items():
        for x,y in pts:
            parts.append(f'<circle cx="{left+x*pw:.1f}" cy="{top+(1-y)*ph:.1f}" r="5" fill="{colors[g]}" opacity="0.8"/>')
        mx=sum(x for x,_ in pts)/len(pts); my=sum(y for _,y in pts)/len(pts)
        parts.append(f'<circle cx="{left+mx*pw:.1f}" cy="{top+(1-my)*ph:.1f}" r="25" fill="none" stroke="{colors[g]}" stroke-width="3"/>')
        parts.append(f'<text x="{left+mx*pw:.1f}" y="{top+(1-my)*ph-31:.1f}" text-anchor="middle" font-size="11" font-weight="700" fill="{colors[g]}">{g}</text>')
    parts.append(f'<text x="{left+pw/2}" y="{height-18}" text-anchor="middle" font-size="11">Latent community axis 1</text>')
    parts.append(f'<text x="18" y="{top+ph/2}" transform="rotate(-90 18 {top+ph/2})" text-anchor="middle" font-size="11">Latent community axis 2</text>')
    return svg_wrap("".join(parts),width,height,"Community ordination")


def silver_wave_svg() -> str:
    width,height=780,380
    left,top=70,50; pw=660; ph=270
    parts=[f'<text x="24" y="30" font-size="19" font-weight="700" fill="{PALETTE["navy"]}">Illustrative northward resource tracking (“silver wave”)</text>']
    parts += [f'<line x1="{left}" y1="{top+ph}" x2="{left+pw}" y2="{top+ph}" stroke="{PALETTE["ink"]}"/>',f'<line x1="{left}" y1="{top}" x2="{left}" y2="{top+ph}" stroke="{PALETTE["ink"]}"/>']
    lats=[48.5,49.0,49.5,50.0,50.5,51.0,51.5,52.0,52.5,53.0]
    spawn=[55,61,68,75,82,89,96,104,112,121]
    bird=[58,64,70,78,85,92,100,109,116,125]
    sx=lambda d:left+(d-45)/(140-45)*pw
    sy=lambda lat:top+(53.5-lat)/(53.5-48)*ph
    for d,lat in zip(spawn,lats): parts.append(f'<circle cx="{sx(d):.1f}" cy="{sy(lat):.1f}" r="5" fill="{PALETTE["teal"]}"/>')
    for d,lat in zip(bird,lats): parts.append(f'<path d="M {sx(d)-5:.1f} {sy(lat)+5:.1f} L {sx(d):.1f} {sy(lat)-5:.1f} L {sx(d)+5:.1f} {sy(lat)+5:.1f} Z" fill="{PALETTE["orange"]}"/>')
    pts1=' '.join(f'{sx(d):.1f},{sy(lat):.1f}' for d,lat in zip(spawn,lats)); pts2=' '.join(f'{sx(d):.1f},{sy(lat):.1f}' for d,lat in zip(bird,lats))
    parts.append(f'<polyline points="{pts1}" fill="none" stroke="{PALETTE["teal"]}" stroke-width="2"/>')
    parts.append(f'<polyline points="{pts2}" fill="none" stroke="{PALETTE["orange"]}" stroke-width="2" stroke-dasharray="5 4"/>')
    for d in [50,70,90,110,130]: parts.append(f'<text x="{sx(d):.1f}" y="{height-25}" text-anchor="middle" font-size="10">{d}</text>')
    for lat in [48,49,50,51,52,53]: parts.append(f'<text x="{left-8}" y="{sy(lat)+4:.1f}" text-anchor="end" font-size="10">{lat}°N</text>')
    parts.append(f'<text x="{left+pw/2}" y="{height-8}" text-anchor="middle" font-size="11">Day of year</text>')
    parts.append(f'<circle cx="560" cy="65" r="5" fill="{PALETTE["teal"]}"/><text x="572" y="69" font-size="11">Spawn timing</text>')
    parts.append(f'<path d="M 555 88 L 560 78 L 565 88 Z" fill="{PALETTE["orange"]}"/><text x="572" y="87" font-size="11">Bird-response peak</text>')
    return svg_wrap("".join(parts),width,height,"Silver wave phenology")


def triangular_evidence_svg() -> str:
    width,height=800,390
    parts=[f'<text x="24" y="30" font-size="19" font-weight="700" fill="{PALETTE["navy"]}">How evidence will be triangulated rather than selected</text>']
    centers=[(185,165,"Local count","Are flocks larger?",PALETTE['teal']),(400,165,"Spatial allocation","Do birds shift inward?",PALETTE['blue']),(615,165,"Community","Do guilds and associations reorganize?",PALETTE['purple']),(290,300,"Observation process","Did birders shift?",PALETTE['orange']),(510,300,"Validation","Do placebos and holdouts disagree?",PALETTE['red'])]
    for x,y,t,s,c in centers:
        parts.append(f'<circle cx="{x}" cy="{y}" r="80" fill="{c}" opacity="0.13" stroke="{c}" stroke-width="2"/>')
        parts.append(f'<text x="{x}" y="{y-5}" text-anchor="middle" font-size="14" font-weight="700" fill="{PALETTE["navy"]}">{esc(t)}</text>')
        words=s.split(); line1=' '.join(words[:3]); line2=' '.join(words[3:])
        parts.append(f'<text x="{x}" y="{y+17}" text-anchor="middle" font-size="10" fill="{PALETTE["slate"]}">{esc(line1)}</text>')
        parts.append(f'<text x="{x}" y="{y+31}" text-anchor="middle" font-size="10" fill="{PALETTE["slate"]}">{esc(line2)}</text>')
    parts.append(f'<rect x="310" y="78" width="180" height="60" rx="14" fill="#fff" stroke="{PALETTE["gold"]}" stroke-width="3"/>')
    parts.append(f'<text x="400" y="103" text-anchor="middle" font-size="15" font-weight="700" fill="{PALETTE["navy"]}">Supported ecological claim</text>')
    parts.append(f'<text x="400" y="122" text-anchor="middle" font-size="10" fill="{PALETTE["slate"]}">requires agreement across estimands</text>')
    return svg_wrap("".join(parts),width,height,"Evidence triangulation")


def sensitivity_matrix_svg() -> str:
    rows=["Species","Guild","Count family","Distance geometry","Time window","Observer model","Event complex","Region","Placebo date","Placebo location"]
    cols=["Core","Alt 1","Alt 2","Stress","Holdout"]
    vals=[]
    for i in range(len(rows)):
        row=[]
        for j in range(len(cols)):
            v=math.sin((i+1)*(j+2))*0.45
            row.append(v)
        vals.append(row)
    return heatmap_svg("Illustrative robustness dashboard: standardized shift from core estimate",rows,cols,vals,820,440,True)


def model_lay_summary(row: pd.Series) -> str:
    q = str(row.get("scientific_question", ""))
    mapping = {
        "aggregate": "Checks whether birds gather in larger numbers close to spawn.",
        "Which species": "Shows which individual species are driving a broader pattern.",
        "total number": "Asks whether the whole herring-associated bird assemblage grows.",
        "richness": "Asks whether more kinds of herring-associated birds appear together.",
        "radius": "Finds the spatial scale at which the response is strongest.",
        "spatiotemporal": "Maps where and when the response peaks around an event.",
        "move": "Tests whether birds shift from farther shorelines toward spawning shorelines.",
        "redistribution": "Separates local movement from a broader influx of birds.",
        "same eBird locality": "Uses repeated visits to the same place as its own comparison.",
        "repeated observer": "Compares observations made by the same birders.",
        "co-occur": "Tests whether species appear together more often than expected.",
        "community": "Tests whether the whole mix of bird species changes.",
        "large flocks": "Focuses on unusually large aggregations rather than averages.",
    }
    for key, val in mapping.items():
        if key.lower() in q.lower():
            return val
    return "Adds a distinct ecological or observation-process check to the evidence." 


def build_html() -> str:
    models = pd.read_csv(ROOT / "metadata" / "model_registry.csv")
    additions = pd.read_csv(ROOT / "metadata" / "proposed_model_additions.csv")
    all_models = pd.concat([models, additions], ignore_index=True)
    species = pd.read_csv(ROOT / "metadata" / "species_registry.csv")
    guilds = pd.read_csv(ROOT / "metadata" / "guild_registry_v2.csv")

    # Synthetic illustrative curves.
    days=list(range(-42,57,7))
    duck=[18+55*math.exp(-((d-10)/15)**2) for d in days]
    gull=[22+70*math.exp(-((d-3)/12)**2) for d in days]
    pisc=[15+38*math.exp(-((d+1)/10)**2) for d in days]
    event_curve=line_chart("Illustrative reported-count trajectories around spawn",[("Roe-diving sea ducks",duck,PALETTE['teal']),("Gulls",gull,PALETTE['gold']),("Piscivores",pisc,PALETTE['blue'])],days,"Days relative to recorded spawn start","Effort-standardized reported count",vlines=[(0,"spawn start"),(14,"egg window")])

    distances=[.5,1.5,2.5,3.5,4.5,7.5,15]
    count_rr=[1.85,1.62,1.42,1.25,1.13,1.02,.96]
    detect_rr=[1.18,1.15,1.11,1.07,1.03,1.00,.99]
    distance_curve=line_chart("Illustrative distance decay: counts can respond more strongly than detection",[("Count ratio",count_rr,PALETTE['teal']),("Encounter ratio",detect_rr,PALETTE['blue'])],distances,"Distance to spawn exposure (km)","Ratio to outer-zone reference")

    heat_days=["−42","−28","−14","0","+7","+14","+28","+42"]
    heat_rings=["0–1 km","1–2 km","2–3 km","3–4 km","4–5 km","5–10 km","10–20 km"]
    heat=[]
    dmid=[.5,1.5,2.5,3.5,4.5,7.5,15]
    tvals=[-42,-28,-14,0,7,14,28,42]
    for d in dmid:
        heat.append([1.0+1.2*math.exp(-d/4.2)*math.exp(-((t-7)/17)**2) for t in tvals])
    time_distance_heat=heatmap_svg("Illustrative count ratio over event time and distance",heat_rings,heat_days,heat,850,420,False)

    co_names=["Surf Sco.","WW Scoter","Harlequin","G. Scaup","GW Gull","SB Gull","Cormorant","Eagle"]
    co=[]
    for i in range(8):
        row=[]
        for j in range(8):
            if i==j: v=1.0
            else:
                same=(i<4 and j<4) or (4<=i<6 and 4<=j<6)
                v=(0.38 if same else 0.10)+0.08*math.cos((i+1)*(j+1))
            row.append(v)
        co.append(row)
    co_heat=heatmap_svg("Illustrative residual species-correlation matrix",co_names,co_names,co,850,455,True)

    intensity_x=[0,1,2,3,4,5,6]
    low=[1+0.08*x for x in intensity_x]
    high=[1+0.17*x for x in intensity_x]
    intensity_chart=line_chart("Illustrative dose response to relative spawn index",[("Near zone",high,PALETTE['teal']),("Outer zone",low,PALETTE['sky'])],intensity_x,"Standardized log relative spawn index","Expected count ratio")

    observer_days=[-28,-14,0,14,28]
    birds=[1.00,1.02,1.35,1.42,1.15]
    observers=[1.00,1.01,1.10,1.09,1.02]
    observer_chart=line_chart("Illustrative ecological response shown beside observer allocation",[("Bird count index",birds,PALETTE['teal']),("Unique-observer index",observers,PALETTE['orange'])],observer_days,"Days relative to spawn","Index (pre-period = 1)",vlines=[(0,"spawn")])

    # Tables.
    model_rows=[]
    for _,r in all_models.iterrows():
        model_rows.append(
            f'<tr data-priority="{esc(r.priority)}"><td><strong>{esc(r.model_id)}</strong></td><td><span class="badge {esc(r.priority)}">{esc(r.priority)}</span></td>'
            f'<td>{esc(r.model_family)}</td><td>{esc(r.scientific_question)}</td><td>{esc(r.response)}</td><td>{esc(r.candidate_engine)}</td>'
            f'<td>{esc(model_lay_summary(r))}</td><td>{esc(r.main_limitations)}</td></tr>'
        )

    guild_examples = {
        "roe_diving_seaduck":"Surf Scoter; White-winged Scoter; Harlequin Duck; scaup; goldeneyes; Bufflehead",
        "gull_roe":"Glaucous-winged, Short-billed, California, Bonaparte’s and other supported gulls",
        "piscivore_active_spawn":"Mergansers; loons; grebes; cormorants",
        "shoreline_scavenger":"Bald Eagle; American Crow; Great Blue Heron",
        "surface_vegetation_roe":"Brant; Mallard; American Wigeon; Northern Pintail; Canada Goose",
        "intertidal_roe_shorebird":"Black Turnstone; Surfbird; other supported intertidal shorebirds",
        "alcid_piscivore":"Pigeon Guillemot; Rhinoceros Auklet; Common Murre; Marbled Murrelet",
        "falsification":"Gadwall and other taxa retained only after habitat/season comparability checks",
        "excluded_audit":"unsupported or taxonomically unsuitable records retained for audit only",
    }
    guild_rows=[]
    for _,g in guilds.iterrows():
        guild_rows.append(f'<tr><td><strong>{esc(g.guild_label)}</strong></td><td>{esc(guild_examples.get(g.guild_id,"To be assigned by the canonical registry"))}</td><td>{esc(g.mechanism)}</td><td>{esc(g.expected_spatial_response)}</td><td>{esc(g.expected_timing)}</td><td>{esc(g.analysis_priority)}</td></tr>')

    hypothesis_rows = [
        ("H1 Local arrival", "Bird encounter probability rises near active spawn.", "Detection / encounter probability", "Species encounter GAMM; repeated-location and same-observer designs", "More checklists near spawn include the species."),
        ("H2 Numerical aggregation", "Conditional and marginal reported counts increase.", "Positive count, zero-inclusive count, upper tail", "Hurdle, NB/Tweedie, ordinal and exceedance models", "Flocks become larger, even when the species was already present."),
        ("H3 Distance decay", "Response is strongest near the exposed shoreline and weakens outward.", "Ring effects, continuous distance and bird-weighted distance", "Ring event study; time–distance surface; concentration metrics", "Birds gather closest to the eggs or spawning front."),
        ("H4 Event timing", "Responses follow biologically plausible pre, spawn, egg and post phases.", "Event-time curves and change points", "GAMM, stacked event study, interval-aware timing", "The response should peak when herring or eggs are available—not on an arbitrary calendar date."),
        ("H5 Redistribution", "Near-spawn increases coincide with reduced share or counts farther away.", "Near/far/total counts and regional allocation", "Dirichlet-multinomial allocation; mass-balance; fixed-effect panels", "Birds move toward spawn rather than simply becoming easier to see everywhere."),
        ("H6 Herring dose and geometry", "Larger, longer, more extensive or isolated events cause stronger responses.", "Relative index, length, width, duration, isolation, event rank", "Dose response; measurement-error and event-complex sensitivity", "A larger or rarer food pulse should attract more birds."),
        ("H7 Guild and community response", "Functional groups and community composition reorganize.", "Guild totals, richness, diversity, composition", "Guild hurdle models; GLLVM; ordination", "The whole bird community changes, not just one species."),
        ("H8 Co-occurrence", "Species aggregate together beyond shared prevalence and habitat.", "Residual pair association and network structure", "Null co-occurrence; JSDM; differential networks", "Mixed-species feeding flocks become more likely around spawn."),
        ("H9 Phenological tracking", "Mobile birds track the geographic progression of spawn.", "Peak timing by latitude and event date", "Silver-wave and distributed-lag models", "Birds follow the moving resource pulse northward."),
        ("H10 Observation process", "Birders may also shift effort, composition or reporting around spawn.", "Checklist allocation, observers, richness, numeric-vs-X", "Visitation and reporting-process models", "We measure whether the people collecting the data changed their behaviour too."),
    ]
    hyp_html="".join(f'<tr><td><strong>{esc(a)}</strong></td><td>{esc(b)}</td><td>{esc(c)}</td><td>{esc(d)}</td><td>{esc(e)}</td></tr>' for a,b,c,d,e in hypothesis_rows)

    # Figure cards.
    figures = [
        ("Figure A. Data-to-evidence workflow", flow_diagram(), "The two datasets are converted into comparable event-based bird and herring records before any model is run.", "The design separates source measurement, exposure engineering, biological outcomes, observation-process models, and validation so no one regression carries the entire claim."),
        ("Figure B. Hurdle outcome architecture", hurdle_diagram(), "A checklist tells us both whether a species appeared and, when counted, how large the flock was.", "Detection and positive count are distinct estimands. Marginal abundance indices combine them only after each component passes diagnostics."),
        ("Figure C. Event-time trajectories", event_curve, "Different bird groups may peak at different stages of the spawning and egg period.", "Model smooths must be constrained to observed event-time support and separated from absolute spring seasonality."),
        ("Figure D. Distance decay", distance_curve, "Flock size may rise sharply near spawn even if the chance of seeing at least one bird changes only a little.", "This is the central reason count and detection models are both required."),
        ("Figure E. Time × distance response surface", time_distance_heat, "This heat map shows the expected location and timing of the strongest response.", "The fitted surface will be restricted or binned where the two-dimensional support is sparse; unsupported cells will remain blank."),
        ("Figure F. Regional allocation", stacked_bar_svg(), "The key redistribution signal is a larger share of birds close to spawn and a smaller share farther away.", "Conditional allocation separates spatial redistribution from changes in the regional total, subject to effort-denominator and observer-turnover diagnostics."),
        ("Figure G. Species effect forest", forest_svg(), "Species can respond differently, so the analysis shows each estimate instead of forcing one common answer.", "A second-stage hierarchy may summarize guild means while retaining species-specific effects and cross-species covariance."),
        ("Figure H. Guild trajectories", line_chart("Illustrative guild-specific temporal responses",[("Roe-diving ducks",duck,PALETTE['teal']),("Gull roe feeders",gull,PALETTE['gold']),("Shoreline scavengers",[12+25*math.exp(-((d-7)/20)**2) for d in days],PALETTE['orange'])],days,"Days relative to spawn","Expected guild count",vlines=[(0,"spawn")]), "Groups that use herring in different ways may show different timing.", "Guilds are mechanistic summaries, not substitutes for species models; contribution dominance and ambiguous taxa are audited."),
        ("Figure I. Conditional co-occurrence matrix", co_heat, "Some species may appear together more often during spawn than expected from how common they are.", "Residual correlations come from joint models after accounting for herring, effort, calendar, event, observer and place."),
        ("Figure J. Mixed-species network", network_svg(), "A spawn event may create a temporary mixed feeding community with stronger links among birds.", "Network summaries use stable residual associations and event-level uncertainty; edge thresholds are sensitivity-tested."),
        ("Figure K. Community ordination", ordination_svg(), "The overall mix of species may shift during spawn and then partly return afterward.", "Ordination is descriptive/supporting unless permutations respect event, calendar, place and observer dependence."),
        ("Figure L. Herring dose response", intensity_chart, "Larger herring events may generate stronger bird responses, especially close to spawn.", "Surface, Macrocystis, Understory, extent, duration and method are handled separately before any latent/composite exposure."),
        ("Figure M. Phenological tracking", silver_wave_svg(), "Bird peaks may move north through spring in step with herring spawning.", "The model compares local event timing against a fixed-calendar migration explanation and reports region-specific uncertainty."),
        ("Figure N. Observation-process comparison", observer_chart, "A bird response that is much larger than the change in observer activity is more convincing—but observer change still remains visible.", "Checklist and unique-observer allocation are modeled separately; they are not used as post-treatment weights without a defensible choice denominator."),
        ("Figure O. Robustness dashboard", sensitivity_matrix_svg(), "A conclusion is stronger when it stays similar across reasonable choices and fails false-date or false-location tests.", "Sensitivities are grouped by dimension so one dimension with many variants cannot dominate the grade."),
        ("Figure P. Evidence triangulation", triangular_evidence_svg(), "The final claim will depend on several different kinds of evidence agreeing, not on one significant model.", "Count, allocation, community, observation-process and validation estimands remain separate and are synthesized transparently."),
    ]
    fig_html="".join(
        f'<article class="figure-card"><h3>{esc(title)}</h3>{svg}<div class="lay"><strong>Plain-language reading:</strong> {esc(lay)}</div><div class="technical"><strong>Technical purpose:</strong> {esc(tech)}</div></article>'
        for title,svg,lay,tech in figures
    )

    # Legacy count motivation table.
    legacy_rows=[
        ("Surf Scoter","+0.706","+0.690"),("White-winged Scoter","+0.430","+0.434"),("Harlequin Duck","+0.317","+0.297"),("Glaucous-winged Gull","+0.719","+0.663"),("Short-billed Gull","+1.174","+1.160")
    ]
    legacy_html="".join(f'<tr><td>{esc(a)}</td><td>{b}</td><td>{c}</td></tr>' for a,b,c in legacy_rows)

    # Output shells.
    result_shell_rows=[
        ("Species/guild","Model/estimand","Effect scale","Estimate (95% interval)","Events / years","Diagnostics","Lay conclusion"),
        ("Surf Scoter","Hurdle count: marginal mean","Count ratio","[to be filled]","[to be filled]","[pass/warn/fail]","[plain language]"),
        ("Gull guild","Regional allocation","Near-zone share difference","[to be filled]","[to be filled]","[pass/warn/fail]","[plain language]"),
        ("Community","JSDM/GLLVM","Mean guild response + residual network","[to be filled]","[to be filled]","[pass/warn/fail]","[plain language]"),
    ]
    result_table='<table><thead><tr>'+''.join(f'<th>{esc(x)}</th>' for x in result_shell_rows[0])+'</tr></thead><tbody>'+''.join('<tr>'+''.join(f'<td>{esc(x)}</td>' for x in row)+'</tr>' for row in result_shell_rows[1:])+'</tbody></table>'

    css = f"""
    :root {{ --navy:{PALETTE['navy']}; --blue:{PALETTE['blue']}; --teal:{PALETTE['teal']}; --gold:{PALETTE['gold']}; --orange:{PALETTE['orange']}; --red:{PALETTE['red']}; --purple:{PALETTE['purple']}; --ink:{PALETTE['ink']}; --slate:{PALETTE['slate']}; --light:{PALETTE['light']}; --grid:{PALETTE['grid']}; }}
    * {{ box-sizing:border-box; }}
    html {{ scroll-behavior:smooth; }}
    body {{ margin:0; font-family:Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; color:var(--ink); background:#F4F7F9; line-height:1.58; }}
    header {{ background:linear-gradient(135deg,var(--navy),#255B7D); color:white; padding:54px 5vw 42px; }}
    header h1 {{ margin:0 0 10px; font-size:clamp(2.1rem,4vw,4rem); line-height:1.05; max-width:1100px; }}
    header p {{ max-width:1000px; font-size:1.15rem; opacity:.94; }}
    .warning {{ background:#FFF4E8; border-left:6px solid var(--orange); padding:16px 18px; border-radius:10px; margin:20px 0; }}
    .stats {{ display:grid; grid-template-columns:repeat(auto-fit,minmax(150px,1fr)); gap:12px; margin-top:28px; max-width:1050px; }}
    .stat {{ background:rgba(255,255,255,.12); border:1px solid rgba(255,255,255,.25); border-radius:12px; padding:16px; }}
    .stat strong {{ display:block; font-size:1.6rem; }}
    nav {{ position:sticky; top:0; z-index:20; background:white; border-bottom:1px solid #D9E2E8; box-shadow:0 2px 7px rgba(22,50,79,.08); }}
    nav .navinner {{ max-width:1280px; margin:auto; padding:9px 22px; display:flex; gap:14px; overflow:auto; white-space:nowrap; }}
    nav a {{ color:var(--navy); text-decoration:none; font-size:.88rem; font-weight:650; }}
    main {{ max-width:1280px; margin:0 auto; padding:28px 22px 80px; }}
    section {{ background:white; border-radius:16px; padding:30px; margin:22px 0; box-shadow:0 7px 28px rgba(22,50,79,.07); }}
    h2 {{ color:var(--navy); font-size:2rem; margin:0 0 14px; border-bottom:3px solid var(--teal); padding-bottom:8px; }}
    h3 {{ color:var(--navy); margin-top:24px; }}
    h4 {{ color:var(--blue); }}
    .lead {{ font-size:1.14rem; }}
    .lay {{ background:#EAF8F4; border-left:5px solid var(--teal); padding:14px 16px; margin:14px 0; border-radius:9px; }}
    .technical {{ background:#F2F5FA; border-left:5px solid var(--blue); padding:14px 16px; margin:14px 0; border-radius:9px; }}
    .grid2 {{ display:grid; grid-template-columns:repeat(auto-fit,minmax(320px,1fr)); gap:18px; }}
    .grid3 {{ display:grid; grid-template-columns:repeat(auto-fit,minmax(240px,1fr)); gap:15px; }}
    .card {{ border:1px solid #DCE6EC; border-radius:13px; padding:18px; background:#FCFEFF; }}
    .card h3,.card h4 {{ margin-top:0; }}
    .badge {{ display:inline-block; border-radius:999px; padding:3px 9px; font-size:.76rem; font-weight:750; background:#E8EEF3; color:var(--navy); }}
    .badge.core {{ background:#DDF4ED; color:#116B5A; }} .badge.supporting {{ background:#E6F0FA; color:#255B7D; }} .badge.exploratory {{ background:#F1EAFE; color:#5A42B8; }} .badge.diagnostic,.badge.validation {{ background:#FFF0E7; color:#A34D1B; }}
    table {{ width:100%; border-collapse:collapse; font-size:.90rem; }}
    th {{ text-align:left; color:white; background:var(--navy); padding:10px; position:sticky; top:42px; }}
    td {{ padding:9px 10px; border-bottom:1px solid #E4EBEF; vertical-align:top; }}
    tbody tr:nth-child(even) {{ background:#F8FAFB; }}
    .tablewrap {{ overflow:auto; max-height:650px; border:1px solid #DCE6EC; border-radius:10px; }}
    .figure-grid {{ display:grid; grid-template-columns:repeat(auto-fit,minmax(520px,1fr)); gap:20px; }}
    .figure-card {{ border:1px solid #DCE6EC; border-radius:14px; padding:16px; background:#FCFEFF; overflow:hidden; }}
    .figure-card h3 {{ margin:0 0 10px; }}
    .example-svg {{ width:100%; height:auto; display:block; }}
    code,pre {{ font-family:"SFMono-Regular",Consolas,monospace; }}
    pre {{ background:#132738; color:#E8F0F5; padding:16px; border-radius:10px; overflow:auto; }}
    .controls {{ display:flex; gap:10px; flex-wrap:wrap; margin:12px 0; }}
    .controls input,.controls select,.controls button {{ padding:9px 11px; border:1px solid #C9D5DC; border-radius:8px; background:white; }}
    .controls button {{ cursor:pointer; color:var(--navy); font-weight:650; }}
    details {{ border:1px solid #DCE6EC; border-radius:10px; padding:10px 14px; margin:10px 0; }}
    summary {{ cursor:pointer; font-weight:700; color:var(--navy); }}
    .phase {{ display:flex; align-items:stretch; gap:0; overflow:auto; margin:14px 0; }}
    .phase div {{ min-width:135px; padding:12px; color:#fff; text-align:center; }}
    .phase div:nth-child(1){{background:#5B7C99}} .phase div:nth-child(2){{background:#3E7CA6}} .phase div:nth-child(3){{background:#2A9D8F}} .phase div:nth-child(4){{background:#E9A23B}} .phase div:nth-child(5){{background:#E76F51}} .phase div:nth-child(6){{background:#8D6CAB}}
    .gate {{ border-left:6px solid var(--gold); padding:14px; background:#FFF9E8; margin:12px 0; border-radius:8px; }}
    .small {{ font-size:.86rem; color:var(--slate); }}
    .kicker {{ color:var(--teal); font-weight:800; text-transform:uppercase; letter-spacing:.08em; font-size:.78rem; }}
    footer {{ max-width:1280px; margin:0 auto 40px; padding:0 22px; color:var(--slate); font-size:.88rem; }}
    @media (max-width:700px) {{ section{{padding:20px 14px}} .figure-grid{{grid-template-columns:1fr}} th{{position:static}} }}
    @media print {{ nav,.controls{{display:none}} body{{background:white}} section{{box-shadow:none;break-inside:avoid}} .figure-card{{break-inside:avoid}} }}
    """

    js = """
    function filterModels(){
      const text=document.getElementById('modelFilter').value.toLowerCase();
      const priority=document.getElementById('priorityFilter').value;
      document.querySelectorAll('#modelTable tbody tr').forEach(row=>{
        const okText=row.innerText.toLowerCase().includes(text);
        const okPriority=priority==='all'||row.dataset.priority===priority;
        row.style.display=(okText&&okPriority)?'':'none';
      });
    }
    function expandAll(open){document.querySelectorAll('details').forEach(d=>d.open=open);}
    """

    html_doc=f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Herring × eBird Version 2 — Comprehensive Analysis Plan</title><style>{css}</style></head>
<body>
<header>
<div class="kicker" style="color:#BFEBDD">Design specification</div>
<h1>Herring × eBird Version 2:<br>Comprehensive Multi-Model Analysis Plan</h1>
<p>A metadata-first plan for using eBird checklists and DFO Pacific herring spawn records to estimate bird arrival, flock size, spatial redistribution, community change, mixed-species aggregation, phenological tracking, and the observation process that generated the citizen-science data.</p>
<div class="warning"><strong>Every figure and numeric result labelled “illustrative” is synthetic.</strong> It shows the intended analysis and reporting format, not a Version 2 empirical finding. Aggregate Version 1 values are explicitly labelled as legacy context.</div>
<div class="stats"><div class="stat"><strong>{len(species)}</strong>candidate species</div><div class="stat"><strong>{len(guilds)}</strong>functional guilds</div><div class="stat"><strong>{len(all_models)}</strong>planned model modules</div><div class="stat"><strong>2</strong>primary datasets</div><div class="stat"><strong>1988–2025</strong>modern herring era</div><div class="stat"><strong>0</strong>Version 2 outcomes fitted</div></div>
</header>
<nav><div class="navinner"><a href="#summary">Summary</a><a href="#legacy">Why V2</a><a href="#data">Data</a><a href="#hypotheses">Hypotheses</a><a href="#engineering">Engineering</a><a href="#species">Species & guilds</a><a href="#exposure">Exposure</a><a href="#outcomes">Outcomes</a><a href="#models">Models</a><a href="#figures">Example figures</a><a href="#cooccurrence">Co-occurrence</a><a href="#redistribution">Redistribution</a><a href="#validation">Validation</a><a href="#implementation">Implementation</a><a href="#deliverables">Deliverables</a></div></nav>
<main>
<section id="summary"><h2>1. Executive summary</h2>
<p class="lead">Version 2 will not ask only whether a bird was reported within one radius before versus after a single event date. It will estimate several linked but distinct ecological quantities, then judge whether they tell a coherent story.</p>
<div class="lay"><strong>Plain-language plan:</strong> We will test whether more birds arrive, whether flocks become larger, whether birds move closer to spawning shorelines, whether other places lose birds at the same time, and whether species gather in mixed flocks. We will also test whether birders changed where or how they reported birds, because that could imitate an ecological response.</div>
<div class="technical"><strong>Technical plan:</strong> The inferential core is a triangulation of hurdle count models, event-time and distance-response models, regional allocation/mass-balance models, repeated-place and same-observer panels, guild/community models, a detection-first JSDM/GLLVM, and separate observation-process diagnostics. Claims will be based on effect sizes, uncertainty, predictive validation, placebo performance, support, and agreement across estimands—not on selecting the smallest p-value.</div>
<div class="grid3"><div class="card"><h3>Primary biological endpoint</h3><p>Effort-standardized <strong>reported bird count</strong>, decomposed into detection and positive flock size.</p></div><div class="card"><h3>Primary spatial endpoint</h3><p>The <strong>share and concentration of birds near spawn</strong> relative to farther zones and the regional total.</p></div><div class="card"><h3>Primary community endpoint</h3><p>Guild totals, richness, composition, and <strong>conditional co-occurrence</strong> after shared environment and observation effects are modeled.</p></div></div>
</section>

<section id="legacy"><h2>2. Why Version 2 is scientifically justified</h2>
<p>The original project established strong data governance and a defensible event-linked design, but its main estimand was narrow: encounter probability during days 0–14 versus days −14 to −1 at a recorded event, within 5 km, for five species. That estimand can miss ecological aggregation when birds were already present before spawning or when flock size changes much more than encounter probability.</p>
<div class="lay"><strong>Plain-language implication:</strong> A beach can go from 10 birds to 1,000 birds without changing the answer to “was this species present?” We therefore need to use the actual counts as well as presence.</div>
<h3>Legacy count diagnostic motivating the new design</h3>
<p class="small">Legacy Prompt 9 positive-count coefficients, conditional on a positive numeric report. These are context only, not Version 2 results or confirmation.</p>
<div class="tablewrap"><table><thead><tr><th>Species</th><th>Active-period coefficient</th><th>After excluding top 1% of counts</th></tr></thead><tbody>{legacy_html}</tbody></table></div>
<p>The new project also addresses the unresolved regional pattern: comparison locations often changed during the same calendar period, and observer turnover differed between active and comparison areas. Version 2 therefore treats ecological redistribution, regional seasonality, and birder response as separate processes.</p>
</section>

<section id="data"><h2>3. Data assets and information inventory</h2>
<div class="grid2"><div><h3>eBird EBD + SED</h3><ul><li>species identity, count token, taxonomic concept, date, media/review flags, behaviour and age/sex fields;</li><li>checklist completeness, protocol, duration, distance, number of observers, start time, observer, locality and coordinates;</li><li>complete checklists permit zero-filled non-detections;</li><li>repeated observers and localities permit within-person and within-place comparisons;</li><li>comments can support a restricted spawn-awareness sensitivity but never enter public outputs.</li></ul></div><div><h3>DFO Pacific herring spawn data</h3><ul><li>year, area, section, location and spawn number;</li><li>start/end dates and event interval uncertainty;</li><li>point coordinates, length, width and survey method;</li><li>Surface, Macrocystis and Understory relative spawn-index components;</li><li>event recurrence, isolation, overlap, adjacency, rank and regional concurrency can be derived.</li></ul></div></div>
<h3>Legacy aggregate baseline for planning</h3>
<div class="tablewrap"><table><thead><tr><th>Quantity</th><th>Legacy aggregate</th><th>Version 2 use</th><th>Caveat</th></tr></thead><tbody>
<tr><td>Raw BC SED rows profiled</td><td>2,961,400</td><td>Coverage, effort, observer and locality audit</td><td>Source profile, not the final analysis set</td></tr>
<tr><td>Raw complete-checklist code = 1</td><td>2,288,405</td><td>Potential zero-fill universe</td><td>Must revalidate the May 2026 release locally</td></tr>
<tr><td>Legacy eligible Strait of Georgia checklists</td><td>412,775</td><td>Planning benchmark only</td><td>Version 2 may broaden geography, dates and effort rules</td></tr>
<tr><td>Legacy zero-filled checklist–taxon rows</td><td>18,574,875 for 45 taxa</td><td>Demonstrates feasible community-scale processing</td><td>Version 2 registry and analysis window differ</td></tr>
<tr><td>Post-1988 herring source records</td><td>13,332</td><td>Source-record and event-complex analyses</td><td>Version 1 excluded 3,959 under a strict union rule</td></tr>
<tr><td>Herring location codes / sections</td><td>987 / 95</td><td>Recurrence, regional context and panel designs</td><td>Support varies greatly across space and time</td></tr>
</tbody></table></div>
<div class="figure-card" style="margin-top:20px">{flow_diagram()}<div class="lay"><strong>Plain-language reading:</strong> The analysis does not join two files and immediately run a regression. It first builds audited bird, herring, event, place and exposure records, then uses several models that answer different questions.</div></div>
</section>

<section id="hypotheses"><h2>4. Hypotheses, estimands and plain-language predictions</h2>
<div class="tablewrap"><table><thead><tr><th>Hypothesis</th><th>Technical prediction</th><th>Main outcome</th><th>Primary analyses</th><th>Plain-language meaning</th></tr></thead><tbody>{hyp_html}</tbody></table></div>
<div class="technical"><strong>Interpretation rule:</strong> “Herring spawn = more birds” is not one estimand. More birds may mean higher detection probability, larger positive counts, higher marginal count, a larger regional total, a larger near-spawn share, greater spatial concentration, more species, or stronger mixed-species association. These quantities must be reported separately.</div>
</section>

<section id="engineering"><h2>5. Metadata-first data engineering</h2>
<div class="grid2"><div class="card"><h3>5.1 eBird checklist construction</h3><ol><li>Verify EBD/SED release pairing, SHA-256, headers and many-to-one checklist keys.</li><li>Resolve shared/group checklist copies without pseudoreplication.</li><li>Retain complete stationary and travelling checklists under configurable effort rules; assess other interpretable protocols separately.</li><li>Parse numeric counts, X, lower bounds, ambiguity and missing values as separate states.</li><li>Zero-fill every supported named species and generate guild lower/upper bounds.</li><li>Create strictly prior observer experience and locality-accessibility features.</li><li>Preserve restricted fields locally; publish aggregate QA only.</li></ol></div><div class="card"><h3>5.2 Herring event construction</h3><ol><li>Preserve every source row and its original fields.</li><li>Assign quality tiers rather than excluding every imperfect record from all analyses.</li><li>Build alternative event complexes at 1 km/3 d, 2 km/7 d and 5 km/14 d.</li><li>Represent timing with start, end, midpoint and interval uncertainty.</li><li>Represent geometry with source point, shoreline anchor, section shoreline and extent uncertainty.</li><li>Derive duration, extent proxies, component pattern, recurrence, isolation, rank and concurrent-event context.</li></ol></div></div>
<h3>5.3 Information currently underused but potentially valuable</h3>
<div class="tablewrap"><table><thead><tr><th>Field or structure</th><th>Potential analysis</th><th>Role</th><th>Safeguard</th></tr></thead><tbody>
<tr><td>Behaviour codes / species comments</td><td>Feeding or spawn-awareness substudy</td><td>Mechanism / observer-awareness diagnostic</td><td>Audit feasibility first; raw text never committed</td></tr>
<tr><td>Age/sex field</td><td>Scoter/duck demographic composition</td><td>Exploratory mechanism</td><td>Only species and years with consistent structured support</td></tr>
<tr><td>Media and reviewed flags</td><td>Reporting-interest and data-quality diagnostics</td><td>Observation process</td><td>Never interpreted as bird abundance</td></tr>
<tr><td>Repeated observer</td><td>Within-observer matched model</td><td>Bias reduction</td><td>Transportability limited to repeated observers</td></tr>
<tr><td>Repeated locality</td><td>Fixed-effect panel / dense-site state-space model</td><td>Bias reduction and time series</td><td>Requires sufficient within-place exposure changes</td></tr>
<tr><td>Herring length and width</td><td>Extent and geometry-error sensitivity</td><td>Exposure measurement</td><td>Unknown orientation cannot be invented</td></tr>
<tr><td>Concurrent herring events</td><td>Resource dilution versus concentration</td><td>Mechanism</td><td>Preserve all candidate links; avoid nearest-event-only simplification</td></tr>
<tr><td>Event recurrence</td><td>Predictable site versus novel pulse response</td><td>Mechanism / site fidelity</td><td>Separate recurrence from access and baseline bird use</td></tr>
</tbody></table></div>
</section>

<section id="species"><h2>6. Species, guilds and community structure</h2>
<p>Version 2 begins with {len(species)} candidate species and {len(guilds)} guild categories. Species-level models remain primary where support is strong; guild models increase power and test mechanisms; community models identify assemblage-level change.</p>
<div class="tablewrap"><table><thead><tr><th>Guild</th><th>Example candidate species</th><th>Mechanism</th><th>Expected spatial response</th><th>Expected timing</th><th>Priority</th></tr></thead><tbody>{''.join(guild_rows)}</tbody></table></div>
<h3>Outcome-blind species eligibility</h3><p>Each taxon receives a separate support decision for detection, positive count, upper-tail count, rings, event-time, regions and joint-community models. Screening uses only sample size and design support—not whether the estimated herring coefficient is favourable.</p>
<div class="grid3"><div class="card"><h4>Species models</h4><p>Retain individual ecological differences, taxonomy, count reliability and event timing.</p></div><div class="card"><h4>Guild models</h4><p>Combine species that share a feeding mechanism, while auditing which species dominate the total.</p></div><div class="card"><h4>Community models</h4><p>Estimate composition and residual association without forcing every species into one response.</p></div></div>
</section>

<section id="exposure"><h2>7. Exposure architecture: time, space, event quality and resource context</h2>
<h3>7.1 Non-overlapping core event periods</h3>
<div class="phase"><div>Early pre<br><small>−42 to −29</small></div><div>Immediate pre<br><small>−28 to −1</small></div><div>Spawn start<br><small>0 to +3</small></div><div>Early egg<br><small>+4 to +14</small></div><div>Late egg / hatch<br><small>+15 to +28</small></div><div>Post<br><small>+29 to +56</small></div></div>
<p class="small">Exact windows remain configurable after outcome-blind timing support and biological review. Continuous analyses may use −90 to +120 days, but must never extrapolate through unsupported regions of event time.</p>
<h3>7.2 Spatial exposure representations</h3>
<div class="tablewrap"><table><thead><tr><th>Representation</th><th>Primary question</th><th>Strength</th><th>Main limitation</th></tr></thead><tbody>
<tr><td>Concentric rings: 0–1, 1–2, 2–3, 3–4, 4–5, 5–10, 10–20 km</td><td>At what distance does response attenuate?</td><td>Transparent and easy to communicate</td><td>Boundary sensitivity and variable support</td></tr>
<tr><td>Continuous point distance</td><td>What is the smooth distance-response shape?</td><td>Uses more spatial information</td><td>Source point may not represent long spawn footprint</td></tr>
<tr><td>Shoreline-anchor distance</td><td>How close is the checklist to the relevant shoreline?</td><td>More ecologically aligned for eggs</td><td>Requires deterministic shoreline assignment</td></tr>
<tr><td>Extent/uncertainty footprint</td><td>Could length/width change exposure classification?</td><td>Represents geometry uncertainty</td><td>Orientation often unknown</td></tr>
<tr><td>Event-complex distance</td><td>Does fragmented source recording dilute the signal?</td><td>Approximates larger biological pulses</td><td>Complex definition is uncertain</td></tr>
<tr><td>Multi-event kernel</td><td>What is cumulative exposure to all active events?</td><td>Avoids arbitrary nearest-event assignment</td><td>Kernel scale and correlated events</td></tr>
</tbody></table></div>
<h3>7.3 Event context modifiers</h3><ul><li>relative spawn-index components and component completeness;</li><li>length, width, extent proxy and interval duration;</li><li>survey method and quality tier;</li><li>event isolation and nearest concurrent event;</li><li>number and total index of concurrent events in the region;</li><li>event rank within section/region/year;</li><li>site recurrence, previous-year spawn and years since last spawn;</li><li>phenological anomaly relative to the section’s typical timing.</li></ul>
<div class="lay"><strong>Plain-language reason:</strong> A single, isolated, large spawn may concentrate birds differently from one of many simultaneous spawns. Version 2 will measure that context instead of treating every event as equivalent.</div>
</section>

<section id="outcomes"><h2>8. Outcome architecture</h2>
<div class="figure-card">{hurdle_diagram()}<div class="lay"><strong>Plain-language reading:</strong> Presence and flock size can tell different stories. Both are useful.</div></div>
<div class="tablewrap"><table><thead><tr><th>Outcome</th><th>Unit</th><th>Interpretation</th><th>Candidate family</th><th>Key diagnostic</th></tr></thead><tbody>
<tr><td>Detection</td><td>Checklist × species/guild</td><td>Probability of a report on an eligible complete checklist</td><td>Binomial GAMM/GLMM</td><td>Calibration, observer and effort effects</td></tr>
<tr><td>Positive numeric count</td><td>Detected checklist</td><td>Reported flock size conditional on a numeric report</td><td>Lognormal/Gamma/NB</td><td>Heaping, tail influence, residual dispersion</td></tr>
<tr><td>Marginal zero-inclusive count</td><td>Checklist</td><td>Combined encounter and reported-count index</td><td>Hurdle combination, NB, Tweedie</td><td>Simulation and family comparison</td></tr>
<tr><td>Upper-tail flock response</td><td>Checklist</td><td>Probability of counts above registered thresholds or high quantiles</td><td>Exceedance / ordinal / quantile</td><td>Threshold stability and event leverage</td></tr>
<tr><td>Guild total / associated-bird total</td><td>Checklist</td><td>Total reported individuals in a mechanism group</td><td>Hurdle, Tweedie, NB</td><td>Dominant-species sensitivity</td></tr>
<tr><td>Richness and Hill diversity</td><td>Checklist</td><td>Number and evenness of associated species</td><td>Count/diversity models</td><td>Effort and observer-skill dependence</td></tr>
<tr><td>Community composition</td><td>Checklist × species</td><td>Multivariate species mix</td><td>GLLVM/JSDM, ordination</td><td>Residual covariance, dispersion and predictive fit</td></tr>
<tr><td>Regional allocation</td><td>Event-day-zone</td><td>Share of observed regional birds in distance zones</td><td>Multinomial / Dirichlet-multinomial</td><td>Effort denominator and spatial support</td></tr>
<tr><td>Bird-weighted distance / concentration</td><td>Event-day</td><td>How close and spatially concentrated the observed birds are</td><td>Panel/GAMM/bootstrap</td><td>Coverage and zero-zone handling</td></tr>
<tr><td>Residual co-occurrence</td><td>Species pairs / network</td><td>Conditional association after shared environment is modeled</td><td>Null models and JSDM</td><td>Prevalence, multiplicity and stability</td></tr>
<tr><td>Observer/checklist process</td><td>Event-area-day or checklist</td><td>How sampling and reporting changed</td><td>Count/allocation/binomial models</td><td>Choice-set completeness</td></tr>
</tbody></table></div>
</section>

<section id="models"><h2>9. Comprehensive model program</h2>
<p>The registry contains {len(all_models)} planned modules. They are not {len(all_models)} attempts to obtain significance. Each module answers a distinct estimand, serves a specific triangulation or diagnostic role, and has a predeclared support gate.</p>
<div class="controls"><input id="modelFilter" placeholder="Search model, question, outcome…" oninput="filterModels()"><select id="priorityFilter" onchange="filterModels()"><option value="all">All priorities</option><option value="core">Core</option><option value="supporting">Supporting</option><option value="exploratory">Exploratory</option><option value="diagnostic">Diagnostic</option><option value="validation">Validation</option></select><button onclick="expandAll(true)">Expand technical notes</button><button onclick="expandAll(false)">Collapse notes</button></div>
<div class="tablewrap"><table id="modelTable"><thead><tr><th>ID</th><th>Priority</th><th>Model family</th><th>Question</th><th>Response</th><th>Candidate engine</th><th>Plain-language role</th><th>Main limitation</th></tr></thead><tbody>{''.join(model_rows)}</tbody></table></div>
<h3>Priority sequence</h3><div class="grid3"><div class="card"><h4>Tier 1: Core inference</h4><p>Hurdle counts, event-time/distance, regional allocation, mass balance, repeated location, same observer, bird-weighted distance and the detection-first JSDM.</p></div><div class="card"><h4>Tier 2: Mechanism and triangulation</h4><p>Intensity, event complexes, footprint uncertainty, multi-event exposure, traits, co-occurrence, upper tail, event isolation and coastwide synthesis.</p></div><div class="card"><h4>Tier 3: Exploratory/future</h4><p>Ordination, networks, synthetic controls, dense-site state-space, age/sex, behaviour, comment awareness and prospective future holdouts.</p></div></div>
</section>

<section id="figures"><h2>10. Intended figure portfolio</h2><p>These synthetic examples show how final results should be communicated. Each final figure will include support, uncertainty and a lay interpretation—not only a coefficient.</p><div class="figure-grid">{fig_html}</div></section>

<section id="cooccurrence"><h2>11. Co-occurrence, mixed flocks and community dependence</h2>
<div class="lay"><strong>Plain-language question:</strong> When herring attract one species, do other species appear alongside it more often? Are these mixed groups simply responding to the same food and habitat, or is there extra association after those shared causes are accounted for?</div>
<h3>11.1 Four complementary levels</h3>
<div class="grid2"><div class="card"><h4>Pairwise descriptive</h4><p>Co-detection frequency, Jaccard similarity, phi correlation and odds ratios by event phase and distance ring.</p></div><div class="card"><h4>Null-adjusted pairs</h4><p>Compare observed pairs with randomizations preserving species prevalence and checklist richness within year, region, calendar, protocol and effort strata.</p></div><div class="card"><h4>JSDM / GLLVM</h4><p>Species-specific herring effects plus multiple latent factors and residual species correlations after effort, observer, event, place and year are modeled.</p></div><div class="card"><h4>Differential network</h4><p>Compare residual association, modularity and guild mixing between pre, spawn, egg and post periods and between near and outer zones.</p></div></div>
<h3>11.2 Interpretation boundaries</h3><ul><li>Positive raw co-detection may reflect high prevalence or checklist effort.</li><li>Positive residual association is conditional co-occurrence, not automatic evidence of facilitation, social attraction or shared travel.</li><li>The contemporaneous count of “other birds” is not a routine covariate in primary models because it is another outcome and may create endogeneity or collider bias.</li><li>A leave-one-species-out assemblage measure may be used only as a labelled exploratory/mediational sensitivity.</li><li>Mixed-species flock reporting may itself alter observer behaviour, so reporting-process models appear beside ecological network results.</li></ul>
<div class="figure-grid"><article class="figure-card">{co_heat}<div class="lay"><strong>Plain-language reading:</strong> Darker positive cells indicate species that still tend to occur together after shared conditions are accounted for.</div></article><article class="figure-card">{network_svg()}<div class="lay"><strong>Plain-language reading:</strong> The network summarizes which conditional associations are stable enough to report.</div></article></div>
</section>

<section id="redistribution"><h2>12. Redistribution, regional influx and spatial concentration</h2>
<p>A local increase is not automatically movement. Version 2 explicitly separates three quantities:</p>
<div class="grid3"><div class="card"><h4>Near-spawn change</h4><p>Did counts or encounter rise in 0–2 or 0–5 km zones?</p></div><div class="card"><h4>Far-zone change</h4><p>Did simultaneous 5–20 km or comparison-shoreline counts fall, stay stable or rise?</p></div><div class="card"><h4>Regional-total change</h4><p>Did the total observed bird index across the supported region change?</p></div></div>
<div class="lay"><strong>Interpretation:</strong> Near up + far down + total stable is most consistent with redistribution. Near up + far stable + total up suggests regional influx or broader availability. Similar changes everywhere point toward seasonal migration, regional conditions or sampling changes.</div>
<div class="figure-grid"><article class="figure-card">{stacked_bar_svg()}</article><article class="figure-card">{line_chart("Illustrative near–far–total mass balance",[("Near-zone count",[20,22,45,50,31],PALETTE['teal']),("Far-zone count",[75,74,55,49,66],PALETTE['sky']),("Regional total",[95,96,100,99,97],PALETTE['navy'])],[-28,-14,0,14,28],"Days relative to spawn","Effort-standardized count index",vlines=[(0,"spawn")])}</article></div>
<h3>Additional spatial statistics</h3><ul><li>bird-weighted mean distance to active spawn;</li><li>share of regional count inside 1, 2, 3, 4 and 5 km;</li><li>spatial entropy, Gini concentration and effective number of occupied zones;</li><li>arrival/departure turnover among repeatedly sampled localities;</li><li>event-centered centre of mass along the shoreline where support allows;</li><li>event-isolation and regional-resource-dilution interactions.</li></ul>
</section>

<section id="validation"><h2>13. Observation process, validation and falsification</h2>
<h3>13.1 Observation-process analyses</h3><div class="grid2"><div class="card"><h4>Visitation allocation</h4><p>Checklist submissions and unique observers at active versus supported comparison areas, with event-cluster uncertainty.</p></div><div class="card"><h4>Observer continuity</h4><p>Same-observer overlap, retention and within-observer contrasts across periods and roles.</p></div><div class="card"><h4>Reporting intensity</h4><p>Checklist richness, numeric-versus-X reporting, media/review flags and count heaping as functions of effort, skill and spawn exposure.</p></div><div class="card"><h4>Spawn awareness</h4><p>Restricted local classification of comments mentioning herring/spawn/roe/milt; re-fit core models after excluding explicitly aware checklists.</p></div></div>
<h3>13.2 Validation matrix</h3>
<div class="tablewrap"><table><thead><tr><th>Validation dimension</th><th>Required test</th><th>Failure interpretation</th><th>Claim consequence</th></tr></thead><tbody>
<tr><td>Event generalization</td><td>Leave-event-out or event-grouped cross-validation</td><td>Model depends on specific events</td><td>Restrict claim to observed events</td></tr>
<tr><td>Temporal stability</td><td>Leave-year-out and early/late-period fits</td><td>Effect is year-specific or calendar-confounded</td><td>Report heterogeneity; no general annual claim</td></tr>
<tr><td>Spatial stability</td><td>Leave-region/section out; spatial blocks</td><td>Effect depends on a small area</td><td>Regional rather than coastwide interpretation</td></tr>
<tr><td>False dates</td><td>±14, ±28 and random-year event dates</td><td>Ordinary seasonality recreates the result</td><td>Weaken spawn-specific interpretation</td></tr>
<tr><td>False locations</td><td>Matched shoreline-shifted pseudo-events</td><td>General habitat/access pattern recreates result</td><td>Weaken location-specific interpretation</td></tr>
<tr><td>Non-spawn years</td><td>Same-place, same-calendar years without recorded spawn</td><td>Persistent site seasonality explains pattern</td><td>Restrict to association; no event attribution</td></tr>
<tr><td>Count family</td><td>Hurdle, lognormal, NB, Tweedie, ordinal and tail sensitivities</td><td>Result is distribution-dependent</td><td>Report only robust component</td></tr>
<tr><td>Exposure measurement</td><td>Point, shoreline, footprint and event-complex alternatives</td><td>Geometry drives classification</td><td>Report measurement uncertainty explicitly</td></tr>
<tr><td>Observer process</td><td>Same-observer and visitation/reporting diagnostics</td><td>Sampling shift could explain outcome</td><td>Separate ecological and observer interpretations</td></tr>
<tr><td>Prospective confirmation</td><td>Frozen models on later eBird/DFO releases</td><td>Out-of-sample effect not reproduced</td><td>No confirmatory claim</td></tr>
</tbody></table></div>
<div class="figure-card" style="margin-top:20px">{sensitivity_matrix_svg()}<div class="lay"><strong>Plain-language reading:</strong> The dashboard shows whether conclusions stay similar when reasonable assumptions change.</div></div>
<h3>13.3 Multiplicity and synthesis</h3><ul><li>Separate confirmatory core families from supporting and exploratory families.</li><li>Use hierarchical shrinkage or family-wise/FDR control where many species or pairs are reported.</li><li>Do not count dozens of closely related sensitivity rows as independent evidence.</li><li>Grade conclusions across dimensions: direction, magnitude, diagnostics, predictive performance, placebo performance and support.</li><li>Report contrary results and failure gates as scientific findings.</li></ul>
</section>

<section id="implementation"><h2>14. Implementation and computational plan</h2>
<div class="grid2"><div class="card"><h3>14.1 Scalable data architecture</h3><ul><li>Stream EBD/SED with `data.table`.</li><li>Store ignored derived products as partitioned Parquet.</li><li>Use DuckDB for large joins and support queries where benchmarked.</li><li>Use `targets` dynamic branching by species, guild, region and model.</li><li>Hash source files, configurations, data contracts and model specifications.</li><li>Keep public aggregate outputs separate from restricted local QA.</li></ul></div><div class="card"><h3>14.2 Model progression</h3><ol><li>Synthetic fixture and simulation benchmark.</li><li>Small hash-identical pilot.</li><li>Outcome-blind support review.</li><li>Core models on frozen data contracts.</li><li>Grouped validation and event-cluster uncertainty.</li><li>Supporting mechanism models.</li><li>Community/JSDM after single-species and guild pipelines are stable.</li><li>Cross-model synthesis and manuscript-ready report.</li></ol></div></div>
<h3>14.3 Decision gates</h3>
<div class="gate"><strong>G0 — Privacy and source integrity:</strong> checksums, schemas, restricted-field scans and clean repository history pass.</div>
<div class="gate"><strong>G1 — Taxonomy and count states:</strong> canonical species/guild crosswalk and numeric/X/ambiguity rules pass.</div>
<div class="gate"><strong>G2 — Herring measurement:</strong> event quality tiers, timing, geometry and complex definitions are approved without bird outcomes.</div>
<div class="gate"><strong>G3 — Support and identifiability:</strong> event-time, ring, observer, locality, region and count support pass; calendar/event-time separation is defensible.</div>
<div class="gate"><strong>G4 — Model-family pilot:</strong> simulations and small pilots show convergence, calibration and interpretable estimands.</div>
<div class="gate"><strong>G5 — Core inference:</strong> count, distance/time, allocation, repeat-place and observation-process models pass diagnostics.</div>
<div class="gate"><strong>G6 — Community/co-occurrence:</strong> JSDM/GLLVM and network models reproduce no-pooling comparators and pass predictive checks.</div>
<div class="gate"><strong>G7 — Synthesis:</strong> placebos, holdouts, multiplicity and robustness grades are complete before claim writing.</div>
<h3>14.4 Public and restricted products</h3>
<div class="tablewrap"><table><thead><tr><th>Product</th><th>Local restricted?</th><th>Tracked/public form</th></tr></thead><tbody>
<tr><td>Raw EBD/SED and DFO inputs</td><td>Yes</td><td>Checksums, source citations and schema only</td></tr>
<tr><td>Checklist/species/event rows</td><td>Yes</td><td>Aggregate counts and disclosure-safe summaries</td></tr>
<tr><td>Observer/locality IDs and comments</td><td>Yes</td><td>Anonymized concentration statistics only</td></tr>
<tr><td>Model objects containing row data</td><td>Yes</td><td>Coefficient/effect tables, validation and hashes</td></tr>
<tr><td>Figures</td><td>Depends</td><td>No exact checklist points; aggregate spatial units only</td></tr>
<tr><td>Registries, code and tests</td><td>No</td><td>Tracked and archived</td></tr>
</tbody></table></div>
</section>

<section id="deliverables"><h2>15. Intended final deliverables</h2>
<h3>15.1 Main scientific figures</h3><ol><li>Data coverage and event support map.</li><li>Event-time count and encounter trajectories by guild.</li><li>Distance-decay curves and time × distance surfaces.</li><li>Species-level effect forest plot with support and diagnostics.</li><li>Near/far/total mass-balance and regional allocation.</li><li>Bird-weighted distance and spatial concentration.</li><li>Herring extent/intensity/isolation modifiers.</li><li>Community ordination and guild contribution decomposition.</li><li>Residual co-occurrence matrix and stable mixed-flock network.</li><li>Phenological tracking across latitude.</li><li>Observer visitation/reporting diagnostics beside bird response.</li><li>Placebo and robustness dashboard.</li><li>Cross-model evidence synthesis.</li></ol>
<h3>15.2 Main tables</h3><ol><li>Source metadata and filtering accounting.</li><li>Species/guild registry, support and taxonomy decisions.</li><li>Herring event quality and measurement alternatives.</li><li>Core estimands and model specifications.</li><li>Species and guild effect sizes on detection, positive count and marginal count scales.</li><li>Redistribution and regional-total results.</li><li>Community/co-occurrence results with multiplicity control.</li><li>Validation, placebo, influence and holdout results.</li><li>Claim-to-evidence matrix with plain-language conclusions.</li></ol>
<h3>15.3 Result table shell</h3>{result_table}
<h3>15.4 Lay-summary template for every major result</h3>
<div class="card"><p><strong>Question:</strong> What did this model ask?</p><p><strong>Answer in ordinary language:</strong> Did bird presence, flock size, spatial concentration or species mix change?</p><p><strong>Magnitude:</strong> How large was the estimated change on an understandable scale?</p><p><strong>Uncertainty:</strong> What range of values is compatible with the data?</p><p><strong>Alternative explanation:</strong> Could seasonality, place, herring measurement or birder behaviour explain it?</p><p><strong>Robustness:</strong> Did the conclusion survive other windows, geometries, count families, events and placebos?</p><p><strong>Boundary:</strong> What does this result not prove?</p></div>
</section>

<section id="closing"><h2>16. What a strong final conclusion would look like</h2>
<div class="lay"><strong>Strong ecological evidence:</strong> counts increase in biologically plausible event-time windows; the effect is strongest close to spawn; the near-zone share rises while farther zones decline or stay lower; community and co-occurrence changes align with expected feeding guilds; observer activity changes are smaller or separately accounted for; and false dates/locations do not reproduce the pattern.</div>
<div class="technical"><strong>Equally valuable alternative conclusions:</strong> only flock size changes while encounter does not; effects occur only for certain guilds or regions; birds aggregate before the recorded start date; regional totals rise rather than redistribute; herring event geometry dominates classification; or observation-process changes are too large to isolate an ecological effect. Each outcome improves understanding of the datasets and the ecology.</div>
<p>The goal is not to force every analysis to support the hypothesis. The goal is to use the full information content of these large datasets while making the observation process, measurement uncertainty, model dependence and failed predictions visible.</p>
</section>

<section id="sources"><h2>17. Provenance and sources</h2><ul><li>Legacy repository: <code>JTDingwall/ebird_herring_analysis</code>, audited at commit <code>f3387d58f6d55a070b86f41ef41e11512dcf7688</code>.</li><li>eBird Basic Dataset and matching Sampling Event Data, British Columbia, May 2026 release, subject to eBird data-access terms.</li><li>DFO Pacific Herring Spawn Index Data, 2025 release, plus DFO herring sections and BC coastline layers.</li><li><em>Integrating Bird Response Data with Pacific Herring Spawn Information</em>, uploaded project literature review.</li><li>All example figures in this document are simulated design illustrations.</li></ul></section>
</main>
<footer>Generated from version-controlled registries by <code>scripts/build_comprehensive_analysis_plan.py</code>. No raw or row-level data were read.</footer>
<script>{js}</script></body></html>"""
    return html_doc


if __name__ == "__main__":
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(build_html(), encoding="utf-8")
    print(OUT)
