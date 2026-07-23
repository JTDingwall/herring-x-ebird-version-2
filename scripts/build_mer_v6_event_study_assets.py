#!/usr/bin/env python3
"""Build manuscript-safe v6 tables and figures from completed event-study outputs.

This script reads only tracked, privacy-safe aggregate CSV files. It refuses to
run until the complete post-Stage 4A execution record has reached its human
review gate.
"""

from __future__ import annotations

import argparse
import math
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import yaml


FINAL_GATE = "PASS_PENDING_HUMAN_POST_STAGE4A_EVENT_STUDY_REVIEW"
MAIN_SPECIES = [
    "Surf Scoter",
    "White-winged Scoter",
    "Harlequin Duck",
    "Glaucous-winged Gull",
    "Short-billed Gull",
    "Common Merganser",
    "Bald Eagle",
    "Hooded Merganser",
    "Mallard",
    "American Crow",
    "Common Raven",
]
TIMING_CONTRASTS = [
    "did_pre_7_day",
    "did_spawn_start",
    "did_early_egg",
    "did_late_egg",
]
PERIOD_TABLE_CONTRASTS = [
    "near_minus_reference_baseline",
    "did_pre_14_day",
    "did_spawn_start",
    "did_early_egg",
    "did_late_egg",
    "did_active_0_14_day",
]
TIMING_LABELS = {
    "did_pre_7_day": "Pre-spawn\n(-7 to -1 d)",
    "did_spawn_start": "Spawn start\n(0 to 3 d)",
    "did_early_egg": "Early egg\n(4 to 14 d)",
    "did_late_egg": "Late egg\n(15 to 28 d)",
}
OUTCOME_LABELS = {
    "detection": "Checklist detection",
    "positive_numeric_count_given_detection": "Positive flock size",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--results-dir",
        type=Path,
        default=Path("outputs/post_stage4a_sog_event_study_v1"),
    )
    parser.add_argument(
        "--manuscript-dir",
        type=Path,
        default=Path(
            "manuscript/journal_submission/marine_environmental_research"
        ),
    )
    return parser.parse_args()


def validate_inputs(results_dir: Path) -> tuple[pd.DataFrame, pd.DataFrame]:
    execution_path = results_dir / "execution_record_v1.yml"
    effects_path = results_dir / "effect_estimates_v1.csv"
    diagnostics_path = results_dir / "model_diagnostics_v1.csv"
    for path in (execution_path, effects_path, diagnostics_path):
        if not path.is_file():
            raise FileNotFoundError(f"Required completed output is missing: {path}")
    execution = yaml.safe_load(execution_path.read_text(encoding="utf-8"))
    if execution.get("final_gate") != FINAL_GATE:
        raise RuntimeError("Event-study execution has not reached its review gate")
    if execution.get("historical_stage4a_outputs_modified") is not False:
        raise RuntimeError("Historical Stage 4A immutability was not verified")
    effects = pd.read_csv(effects_path)
    diagnostics = pd.read_csv(diagnostics_path)
    required = {
        "analysis_taxon_id",
        "unit_label",
        "analysis_role",
        "outcome",
        "contrast",
        "ratio",
        "ratio_conf_low",
        "ratio_conf_high",
        "q_value",
        "status",
    }
    missing = required.difference(effects.columns)
    if missing:
        raise ValueError(f"Effect table is missing columns: {sorted(missing)}")
    if diagnostics.shape[0] != 100:
        raise ValueError(
            f"Expected 100 species-response fits, found {diagnostics.shape[0]}"
        )
    core = effects[effects["analysis_role"].eq("core_species")]
    if core["analysis_taxon_id"].nunique() != 49:
        raise ValueError("Expected the complete 49-species core family")
    comparators = effects[
        effects["analysis_role"].eq("specificity_comparator")
    ]
    if comparators["analysis_taxon_id"].nunique() != 2:
        raise ValueError("Expected two aligned specificity comparators")
    if set(MAIN_SPECIES).difference(set(core["unit_label"])):
        raise ValueError("One or more main ecological species are missing")
    return effects, diagnostics


def ci_text(row: pd.Series) -> str:
    values = [row["ratio"], row["ratio_conf_low"], row["ratio_conf_high"]]
    if not all(math.isfinite(float(value)) for value in values):
        return "Model component unavailable"
    return (
        f"{row['ratio']:.2f} "
        f"({row['ratio_conf_low']:.2f}-{row['ratio_conf_high']:.2f})"
    )


def write_tables(
    effects: pd.DataFrame, tables_dir: Path, generated_dir: Path
) -> None:
    tables_dir.mkdir(parents=True, exist_ok=True)
    generated_dir.mkdir(parents=True, exist_ok=True)
    active = effects[
        effects["contrast"].eq("did_active_0_14_day")
        & effects["unit_label"].isin(MAIN_SPECIES)
    ].copy()
    active["ratio_95_ci"] = active.apply(ci_text, axis=1)
    active["bh_q"] = active["q_value"].map(
        lambda value: "" if pd.isna(value) else f"{value:.3g}"
    )
    active["outcome"] = active["outcome"].map(OUTCOME_LABELS)
    active = active[
        [
            "unit_label",
            "outcome",
            "ratio_95_ci",
            "bh_q",
            "status",
        ]
    ].rename(
        columns={
            "unit_label": "species",
            "ratio_95_ci": "active_0_14_ratio_95_ci",
        }
    )
    active.to_csv(tables_dir / "Table_3_main_species_active_v6.csv", index=False)

    timing = effects[
        effects["contrast"].isin(TIMING_CONTRASTS)
        & effects["unit_label"].isin(MAIN_SPECIES)
    ].copy()
    timing.to_csv(
        tables_dir / "Table_4_main_species_timing_v6.csv", index=False
    )
    periods = effects[
        effects["contrast"].isin(PERIOD_TABLE_CONTRASTS)
        & effects["unit_label"].isin(MAIN_SPECIES)
    ].copy()
    periods.to_csv(
        tables_dir / "Table_4_main_species_periods_v6.csv", index=False
    )
    effects[effects["analysis_role"].eq("core_species")].to_csv(
        tables_dir / "Table_S_event_study_all_49_species_v6.csv", index=False
    )
    effects[effects["analysis_role"].eq("specificity_comparator")].to_csv(
        tables_dir / "Table_S_specificity_comparators_v6.csv", index=False
    )

    completed_active = active[active["status"].str.startswith("completed")]
    supported = completed_active[
        completed_active["bh_q"].ne("")
        & pd.to_numeric(completed_active["bh_q"], errors="coerce").lt(0.05)
    ]
    lines = [
        "# Event-study result handoff",
        "",
        "This text is generated from the complete aggregate output family. It is a "
        "numerical handoff for scientific interpretation, not final manuscript prose.",
        "",
        f"- Main-species active components available: {completed_active.shape[0]}/"
        f"{len(MAIN_SPECIES) * 2}.",
        f"- Main-species active components with BH q < 0.05: {supported.shape[0]}.",
        "- The exponentiated interaction is a ratio of near/reference ratios "
        "relative to the -28 to -15 day baseline.",
        "- Values above one indicate that the near/reference contrast became more "
        "positive than its baseline value.",
        "",
    ]
    for _, row in supported.sort_values(
        ["outcome", "species"]
    ).iterrows():
        lines.append(
            f"- {row['species']} - {row['outcome']}: "
            f"{row['active_0_14_ratio_95_ci']}, BH q={row['bh_q']}."
        )
    (generated_dir / "event_study_results_handoff_v6.md").write_text(
        "\n".join(lines) + "\n", encoding="utf-8"
    )


def plot_active(effects: pd.DataFrame, figures_dir: Path) -> None:
    data = effects[
        effects["contrast"].eq("did_active_0_14_day")
        & effects["unit_label"].isin(MAIN_SPECIES)
    ].copy()
    order = list(reversed(MAIN_SPECIES))
    fig, axes = plt.subplots(1, 2, figsize=(11.0, 7.6), sharey=True)
    for axis, outcome in zip(axes, OUTCOME_LABELS):
        panel = (
            data[data["outcome"].eq(outcome)]
            .set_index("unit_label")
            .reindex(order)
        )
        y = np.arange(len(order))
        ratio = panel["ratio"].to_numpy(dtype=float)
        low = panel["ratio_conf_low"].to_numpy(dtype=float)
        high = panel["ratio_conf_high"].to_numpy(dtype=float)
        finite = (
            np.isfinite(ratio)
            & np.isfinite(low)
            & np.isfinite(high)
            & (ratio > 0)
            & (low > 0)
            & (high > 0)
        )
        axis.axvline(1, color="#666666", linewidth=1, linestyle="--")
        axis.errorbar(
            ratio[finite],
            y[finite],
            xerr=np.vstack(
                [ratio[finite] - low[finite], high[finite] - ratio[finite]]
            ),
            fmt="o",
            color="#1f5d78",
            ecolor="#1f5d78",
            capsize=2,
            markersize=5,
        )
        axis.set_xscale("log")
        axis.set_xlabel("Ratio of near/reference ratios (95% CI)")
        axis.set_title(OUTCOME_LABELS[outcome])
        axis.grid(axis="x", color="#dddddd", linewidth=0.7)
        axis.set_yticks(y)
        axis.set_yticklabels(order)
    fig.suptitle(
        "Bird response during days 0-14 relative to the pre-spawn baseline",
        fontsize=13,
        y=0.99,
    )
    fig.text(
        0.5,
        0.01,
        "Values >1 indicate a more positive near/reference contrast than during "
        "days -28 to -15.",
        ha="center",
        fontsize=9,
    )
    fig.tight_layout(rect=(0, 0.04, 1, 0.96))
    fig.savefig(
        figures_dir / "Figure_3_sog_active_event_study_v6.png",
        dpi=400,
        bbox_inches="tight",
        facecolor="white",
    )
    plt.close(fig)


def plot_timing(effects: pd.DataFrame, figures_dir: Path) -> None:
    data = effects[
        effects["contrast"].isin(TIMING_CONTRASTS)
        & effects["unit_label"].isin(MAIN_SPECIES)
    ].copy()
    species = MAIN_SPECIES
    fig, axes = plt.subplots(1, 2, figsize=(12.2, 8.2), sharey=True)
    finite_logs = np.log(data.loc[data["ratio"].gt(0), "ratio"])
    if finite_logs.empty:
        raise RuntimeError("No finite main-panel timing ratios are available")
    limit = max(0.1, float(np.nanquantile(np.abs(finite_logs), 0.95)))
    for axis, outcome in zip(axes, OUTCOME_LABELS):
        panel = data[data["outcome"].eq(outcome)].pivot(
            index="unit_label", columns="contrast", values="ratio"
        )
        panel = panel.reindex(index=species, columns=TIMING_CONTRASTS)
        q_panel = data[data["outcome"].eq(outcome)].pivot(
            index="unit_label", columns="contrast", values="q_value"
        ).reindex(index=species, columns=TIMING_CONTRASTS)
        image = axis.imshow(
            np.log(panel.to_numpy(dtype=float)),
            cmap="RdBu_r",
            vmin=-limit,
            vmax=limit,
            aspect="auto",
        )
        for row in range(len(species)):
            for column in range(len(TIMING_CONTRASTS)):
                value = panel.iat[row, column]
                q_value = q_panel.iat[row, column]
                label = "" if pd.isna(value) else f"{value:.2f}"
                if not pd.isna(q_value) and q_value < 0.05:
                    label += "*"
                axis.text(
                    column,
                    row,
                    label,
                    ha="center",
                    va="center",
                    fontsize=7.5,
                    color="black",
                )
        axis.set_xticks(range(len(TIMING_CONTRASTS)))
        axis.set_xticklabels(
            [TIMING_LABELS[value] for value in TIMING_CONTRASTS],
            fontsize=8,
        )
        axis.set_yticks(range(len(species)))
        axis.set_yticklabels(species, fontsize=9)
        axis.set_title(OUTCOME_LABELS[outcome])
    colorbar = fig.colorbar(image, ax=axes, fraction=0.025, pad=0.02)
    colorbar.set_label(
        "Log ratio of near/reference ratios",
        fontsize=9,
        labelpad=7,
    )
    fig.suptitle(
        "Species-specific change in the near/reference contrast through spawning",
        fontsize=13,
        y=0.98,
    )
    fig.text(
        0.5,
        0.015,
        "Cells show exponentiated difference-in-differences; * denotes BH q < 0.05 "
        "within the 49-species outcome-contrast family.",
        ha="center",
        fontsize=9,
    )
    fig.subplots_adjust(left=0.19, right=0.84, bottom=0.11, top=0.91, wspace=0.08)
    fig.savefig(
        figures_dir / "Figure_4_sog_event_timing_v6.png",
        dpi=400,
        bbox_inches="tight",
        pad_inches=0.15,
        facecolor="white",
    )
    plt.close(fig)


def main() -> int:
    args = parse_args()
    effects, _ = validate_inputs(args.results_dir)
    tables_dir = args.manuscript_dir / "tables_v6"
    figures_dir = args.manuscript_dir / "figures_v6"
    generated_dir = args.manuscript_dir / "generated_v6"
    figures_dir.mkdir(parents=True, exist_ok=True)
    write_tables(effects, tables_dir, generated_dir)
    plot_active(effects, figures_dir)
    plot_timing(effects, figures_dir)
    print("MER_V6_EVENT_STUDY_ASSETS=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
