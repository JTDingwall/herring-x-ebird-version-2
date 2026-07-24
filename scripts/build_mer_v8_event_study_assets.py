#!/usr/bin/env python3
"""Build manuscript-safe v8 tables and figures from completed event-study outputs.

This script reads only tracked, privacy-safe aggregate CSV files. It refuses to
run until the complete post-Stage 4A execution record has reached its human
review gate.

Version 8 preserves the released numerical results while replacing
``detection`` and ``flock size`` figure language with ecological observation
terms and labelling the estimand as a baseline-adjusted event-link ratio.
"""

from __future__ import annotations

import argparse
import math
from pathlib import Path

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import yaml
from matplotlib.ticker import FixedLocator, FuncFormatter


FINAL_GATE = "PASS_PENDING_HUMAN_POST_STAGE4A_EVENT_STUDY_REVIEW"

# Guild-grouped so that the figure and the manuscript Table 1 share one order.
MAIN_SPECIES = [
    "Surf Scoter",
    "White-winged Scoter",
    "Harlequin Duck",
    "Common Merganser",
    "Hooded Merganser",
    "Glaucous-winged Gull",
    "Short-billed Gull",
    "Bald Eagle",
    "Mallard",
    "American Crow",
    "Common Raven",
]
TIMING_CONTRASTS = [
    "did_pre_14_day",
    "did_spawn_start",
    "did_early_egg",
    "did_late_egg",
]
PERIOD_TABLE_CONTRASTS = [
    "near_minus_reference_baseline",
    "did_pre_14_day",
    "did_immediate_pre",
    "did_spawn_start",
    "did_early_egg",
    "did_late_egg",
    "did_active_0_14_day",
]
TIMING_LABELS = {
    "did_pre_14_day": "Pre-spawn\n(-14 to -1 d)",
    "did_spawn_start": "Spawn start\n(0 to 3 d)",
    "did_early_egg": "Early egg\n(4 to 14 d)",
    "did_late_egg": "Late egg\n(15 to 28 d)",
}
OUTCOME_LABELS = {
    "detection": "Checklist reporting",
    "positive_numeric_count_given_detection": "Conditional positive\nnumeric count",
}
TABLE_OUTCOME_LABELS = {
    "detection": "Checklist reporting",
    "positive_numeric_count_given_detection": "Conditional positive numeric count",
}
FIGURE_DPI = 500


def use_times_new_roman() -> None:
    """Draw every figure in Times New Roman to match the manuscript body text."""
    plt.rcParams["font.family"] = "serif"
    plt.rcParams["font.serif"] = [
        "Times New Roman",
        "Nimbus Roman",
        "Liberation Serif",
        "DejaVu Serif",
    ]
    plt.rcParams["mathtext.fontset"] = "stix"
    plt.rcParams["axes.unicode_minus"] = False


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
        default=Path("manuscript/journal_submission/marine_environmental_research"),
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
    comparators = effects[effects["analysis_role"].eq("specificity_comparator")]
    if comparators["analysis_taxon_id"].nunique() != 2:
        raise ValueError("Expected two aligned specificity comparators")
    if set(MAIN_SPECIES).difference(set(core["unit_label"])):
        raise ValueError("One or more main ecological species are missing")
    for contrast in set(TIMING_CONTRASTS) | set(PERIOD_TABLE_CONTRASTS):
        if contrast not in set(effects["contrast"]):
            raise ValueError(f"Required contrast is absent from outputs: {contrast}")
    return effects, diagnostics


def ci_text(row: pd.Series) -> str:
    values = [row["ratio"], row["ratio_conf_low"], row["ratio_conf_high"]]
    if not all(math.isfinite(float(value)) for value in values):
        return "Model component unavailable"
    return (
        f"{row['ratio']:.2f} "
        f"({row['ratio_conf_low']:.2f}-{row['ratio_conf_high']:.2f})"
    )


def active_core(effects: pd.DataFrame) -> pd.DataFrame:
    return effects[
        effects["analysis_role"].eq("core_species")
        & effects["contrast"].eq("did_active_0_14_day")
    ].copy()


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
    active["outcome"] = active["outcome"].map(TABLE_OUTCOME_LABELS)
    active = active[
        ["unit_label", "outcome", "ratio_95_ci", "bh_q", "status"]
    ].rename(
        columns={
            "unit_label": "species",
            "ratio_95_ci": "active_0_14_ratio_95_ci",
        }
    )
    active.to_csv(tables_dir / "Table_1_main_species_active_v8.csv", index=False)

    # Table 2 makes the family extremes explicit rather than leaving them in a
    # supplementary CSV: every BH-significant negative interaction, and every
    # BH-significant positive interaction outside the 11-species panel.
    core = active_core(effects)
    core = core[np.isfinite(pd.to_numeric(core["q_value"], errors="coerce"))]
    core["q_numeric"] = pd.to_numeric(core["q_value"], errors="coerce")
    core["in_main_panel"] = core["unit_label"].isin(MAIN_SPECIES)
    significant = core[core["q_numeric"].lt(0.05)].copy()
    significant["direction"] = np.where(
        significant["ratio"].astype(float) > 1, "positive", "negative"
    )
    extremes = significant[
        (significant["direction"].eq("negative"))
        | (~significant["in_main_panel"])
    ].copy()
    extremes["outcome"] = extremes["outcome"].map(TABLE_OUTCOME_LABELS)
    extremes["ratio_95_ci"] = extremes.apply(ci_text, axis=1)
    extremes = extremes[
        [
            "unit_label",
            "outcome",
            "direction",
            "in_main_panel",
            "ratio_95_ci",
            "q_value",
        ]
    ].rename(columns={"unit_label": "species"})
    extremes = extremes.sort_values(
        ["outcome", "direction", "species"]
    ).reset_index(drop=True)
    extremes.to_csv(tables_dir / "Table_2_family_extremes_v8.csv", index=False)

    effects[effects["analysis_role"].eq("core_species")].to_csv(
        tables_dir / "Table_S1_event_study_all_49_species_v8.csv", index=False
    )
    periods = effects[
        effects["contrast"].isin(PERIOD_TABLE_CONTRASTS)
        & effects["unit_label"].isin(MAIN_SPECIES)
    ].copy()
    periods.to_csv(
        tables_dir / "Table_S2_main_species_periods_v8.csv", index=False
    )
    effects[effects["analysis_role"].eq("specificity_comparator")].to_csv(
        tables_dir / "Table_S3_specificity_comparators_v8.csv", index=False
    )

    write_handoff(effects, generated_dir)


def write_handoff(effects: pd.DataFrame, generated_dir: Path) -> None:
    core = active_core(effects)
    core["q_numeric"] = pd.to_numeric(core["q_value"], errors="coerce")
    lines = [
        "# Event-study result handoff (v8)",
        "",
        "Generated from the complete aggregate output family. Numerical handoff "
        "for scientific interpretation, not manuscript prose.",
        "",
    ]
    for outcome, label in TABLE_OUTCOME_LABELS.items():
        panel = core[core["outcome"].eq(outcome)]
        estimable = panel[panel["q_numeric"].notna()]
        positive = estimable[
            estimable["q_numeric"].lt(0.05) & estimable["ratio"].astype(float).gt(1)
        ]
        negative = estimable[
            estimable["q_numeric"].lt(0.05) & estimable["ratio"].astype(float).lt(1)
        ]
        lines.append(
            f"- {label}: {len(positive)} positive and {len(negative)} negative "
            f"at BH q < 0.05, of {len(estimable)} estimable core species."
        )
        for name, subset in (("positive", positive), ("negative", negative)):
            ordered = subset.sort_values("ratio", ascending=(name == "negative"))
            for _, row in ordered.iterrows():
                flag = "" if row["unit_label"] in MAIN_SPECIES else "  [OFF-PANEL]"
                lines.append(
                    f"    - {name}: {row['unit_label']} {ci_text(row)}, "
                    f"q={float(row['q_value']):.3g}{flag}"
                )
        lines.append("")
    while lines and not lines[-1]:
        lines.pop()
    (generated_dir / "event_study_results_handoff_v8.md").write_text(
        "\n".join(lines) + "\n", encoding="utf-8"
    )


def plain_ratio_axis(axis: plt.Axes, ticks: list[float]) -> None:
    axis.xaxis.set_major_locator(FixedLocator(ticks))
    axis.xaxis.set_minor_locator(FixedLocator([]))
    axis.xaxis.set_major_formatter(FuncFormatter(lambda value, _: f"{value:g}"))


def plot_active(effects: pd.DataFrame, figures_dir: Path) -> None:
    data = effects[
        effects["contrast"].eq("did_active_0_14_day")
        & effects["unit_label"].isin(MAIN_SPECIES)
    ].copy()
    order = list(reversed(MAIN_SPECIES))
    fig, axes = plt.subplots(1, 2, figsize=(11.0, 7.0), sharey=True)

    finite_all = data[
        np.isfinite(pd.to_numeric(data["ratio_conf_low"], errors="coerce"))
        & np.isfinite(pd.to_numeric(data["ratio_conf_high"], errors="coerce"))
    ]
    low_limit = float(finite_all["ratio_conf_low"].astype(float).min())
    high_limit = float(finite_all["ratio_conf_high"].astype(float).max())
    pad = 0.03
    shared = (low_limit * (1 - pad), high_limit * (1 + pad))

    for axis, outcome in zip(axes, OUTCOME_LABELS):
        panel = (
            data[data["outcome"].eq(outcome)].set_index("unit_label").reindex(order)
        )
        y = np.arange(len(order))
        ratio = panel["ratio"].to_numpy(dtype=float)
        low = panel["ratio_conf_low"].to_numpy(dtype=float)
        high = panel["ratio_conf_high"].to_numpy(dtype=float)
        q_values = pd.to_numeric(panel["q_value"], errors="coerce").to_numpy(
            dtype=float
        )
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
        # The v6 caption promised these and the v6 figure did not draw them.
        for index in range(len(order)):
            if not finite[index] or not np.isfinite(q_values[index]):
                continue
            if q_values[index] < 0.05:
                axis.text(
                    high[index] * (1 + pad * 0.35),
                    y[index],
                    "*",
                    ha="left",
                    va="center",
                    fontsize=13,
                    color="black",
                )
        axis.set_xscale("log")
        axis.set_xlim(shared)
        plain_ratio_axis(axis, [0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5])
        axis.set_xlabel("Baseline-adjusted event-link ratio (95% CI)")
        axis.set_title(OUTCOME_LABELS[outcome])
        axis.grid(axis="x", color="#dddddd", linewidth=0.7)
        axis.set_yticks(y)
        axis.set_yticklabels(order)
    fig.suptitle(
        "Change in the near/reference contrast during days 0-14, "
        "relative to the -28 to -15 day baseline",
        fontsize=13,
        y=0.99,
    )
    fig.text(
        0.5,
        0.01,
        "Values >1 indicate a more positive near/reference contrast than during "
        "days -28 to -15. * marks BH q < 0.05.",
        ha="center",
        fontsize=9,
    )
    fig.tight_layout(rect=(0, 0.04, 1, 0.95))
    fig.savefig(
        figures_dir / "Figure_1_sog_active_event_study_v8.png",
        dpi=FIGURE_DPI,
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
    fig, axes = plt.subplots(1, 2, figsize=(12.2, 7.6), sharey=True)
    finite_logs = np.log(data.loc[data["ratio"].gt(0), "ratio"])
    if finite_logs.empty:
        raise RuntimeError("No finite main-panel timing ratios are available")
    limit = max(0.1, float(np.nanquantile(np.abs(finite_logs), 0.95)))
    for axis, outcome in zip(axes, OUTCOME_LABELS):
        panel = (
            data[data["outcome"].eq(outcome)]
            .pivot(index="unit_label", columns="contrast", values="ratio")
            .reindex(index=species, columns=TIMING_CONTRASTS)
        )
        q_panel = (
            data[data["outcome"].eq(outcome)]
            .pivot(index="unit_label", columns="contrast", values="q_value")
            .reindex(index=species, columns=TIMING_CONTRASTS)
        )
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
                    fontsize=8,
                    color="black",
                )
        axis.set_xticks(range(len(TIMING_CONTRASTS)))
        axis.set_xticklabels(
            [TIMING_LABELS[value] for value in TIMING_CONTRASTS], fontsize=8
        )
        axis.set_yticks(range(len(species)))
        axis.set_yticklabels(species, fontsize=9)
        axis.set_title(OUTCOME_LABELS[outcome])
    colorbar = fig.colorbar(image, ax=axes, fraction=0.025, pad=0.02)
    colorbar.set_label("Log baseline-adjusted event-link ratio", fontsize=9, labelpad=7)
    fig.suptitle(
        "Species-specific change in the near/reference contrast through spawning",
        fontsize=13,
        y=0.98,
    )
    fig.text(
        0.5,
        0.015,
        "Cells show exponentiated baseline-adjusted near/reference contrasts "
        "of event-link slopes; * denotes BH q < 0.05.",
        ha="center",
        fontsize=9,
    )
    fig.subplots_adjust(left=0.19, right=0.84, bottom=0.11, top=0.91, wspace=0.08)
    fig.savefig(
        figures_dir / "Figure_3_sog_event_timing_v8.png",
        dpi=300,
        bbox_inches="tight",
        pad_inches=0.15,
        facecolor="white",
    )
    plt.close(fig)


def plot_all_species(effects: pd.DataFrame, figures_dir: Path) -> None:
    """Plot the complete 49-species active family.

    The v6 draft showed only the 11-species panel, which excluded both the
    largest positive and the largest negative interactions in the family. This
    figure shows every estimable core species so that the panel is visibly a
    subset rather than an implicit summary.
    """
    core = active_core(effects)
    core["q_numeric"] = pd.to_numeric(core["q_value"], errors="coerce")
    count_order = (
        core[core["outcome"].eq("positive_numeric_count_given_detection")]
        .set_index("unit_label")["ratio"]
        .astype(float)
    )
    detection_order = (
        core[core["outcome"].eq("detection")].set_index("unit_label")["ratio"].astype(float)
    )
    ranking = count_order.combine_first(detection_order).sort_values()
    order = list(ranking.index)

    fig, axes = plt.subplots(1, 2, figsize=(11.5, 13.0), sharey=True)
    finite_all = core[
        np.isfinite(pd.to_numeric(core["ratio_conf_low"], errors="coerce"))
        & np.isfinite(pd.to_numeric(core["ratio_conf_high"], errors="coerce"))
    ]
    shared = (
        float(finite_all["ratio_conf_low"].astype(float).min()) * 0.97,
        float(finite_all["ratio_conf_high"].astype(float).max()) * 1.03,
    )
    for axis, outcome in zip(axes, OUTCOME_LABELS):
        panel = core[core["outcome"].eq(outcome)].set_index("unit_label").reindex(order)
        y = np.arange(len(order))
        ratio = panel["ratio"].to_numpy(dtype=float)
        low = panel["ratio_conf_low"].to_numpy(dtype=float)
        high = panel["ratio_conf_high"].to_numpy(dtype=float)
        q_values = panel["q_numeric"].to_numpy(dtype=float)
        finite = (
            np.isfinite(ratio)
            & np.isfinite(low)
            & np.isfinite(high)
            & (ratio > 0)
            & (low > 0)
            & (high > 0)
        )
        significant = finite & np.isfinite(q_values) & (q_values < 0.05)
        axis.axvline(1, color="#666666", linewidth=1, linestyle="--")
        axis.errorbar(
            ratio[finite],
            y[finite],
            xerr=np.vstack(
                [ratio[finite] - low[finite], high[finite] - ratio[finite]]
            ),
            fmt="none",
            ecolor="#9bb7c4",
            elinewidth=1.0,
            capsize=1.5,
        )
        axis.scatter(
            ratio[finite & ~significant],
            y[finite & ~significant],
            s=22,
            facecolors="white",
            edgecolors="#1f5d78",
            linewidths=1.0,
            zorder=3,
        )
        axis.scatter(
            ratio[significant],
            y[significant],
            s=26,
            color="#1f5d78",
            zorder=3,
        )
        axis.set_xscale("log")
        axis.set_xlim(shared)
        plain_ratio_axis(axis, [0.6, 0.8, 1.0, 1.2, 1.4, 1.6])
        axis.set_xlabel("Baseline-adjusted event-link ratio (95% CI)")
        axis.set_title(OUTCOME_LABELS[outcome])
        axis.grid(axis="x", color="#dddddd", linewidth=0.7)
        axis.set_yticks(y)
        axis.set_yticklabels(order, fontsize=8)
    for label in axes[0].get_yticklabels():
        if label.get_text() in MAIN_SPECIES:
            label.set_fontweight("bold")
    fig.suptitle(
        "Complete 49-species active-period family (days 0-14)", fontsize=13, y=0.995
    )
    fig.text(
        0.5,
        0.006,
        "Filled points are BH q < 0.05; open points are not. Bold species names "
        "are the 11 discussed in the main text.\nSpecies with no point for an "
        "outcome had no estimable model for that component.",
        ha="center",
        fontsize=9,
    )
    fig.tight_layout(rect=(0, 0.035, 1, 0.975))
    fig.savefig(
        figures_dir / "Figure_2_sog_all_species_v8.png",
        dpi=FIGURE_DPI,
        bbox_inches="tight",
        facecolor="white",
    )
    plt.close(fig)


def main() -> int:
    args = parse_args()
    use_times_new_roman()
    effects, _ = validate_inputs(args.results_dir)
    tables_dir = args.manuscript_dir / "tables_v8"
    figures_dir = args.manuscript_dir / "figures_v8"
    generated_dir = args.manuscript_dir / "generated_v8"
    figures_dir.mkdir(parents=True, exist_ok=True)
    write_tables(effects, tables_dir, generated_dir)
    plot_active(effects, figures_dir)
    plot_timing(effects, figures_dir)
    plot_all_species(effects, figures_dir)
    print("MER_V8_EVENT_STUDY_ASSETS=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
