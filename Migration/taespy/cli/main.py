"""taespy CLI skeleton mirroring TaesLab Base functions one-to-one.

This module defines command groups and subcommands that map directly to the
MATLAB functions in Base/.
"""

from __future__ import annotations

from pathlib import Path
from typing import Optional

import typer


app = typer.Typer(
    name="taespy",
    help="TaesPy command line interface (migration skeleton).",
    add_completion=False,
)

model_app = typer.Typer(help="Model I/O and validation commands.")
analysis_app = typer.Typer(help="Thermoeconomic analysis commands.")
results_app = typer.Typer(help="Results listing, rendering, and export commands.")
table_app = typer.Typer(help="Single table render/export commands.")
graph_app = typer.Typer(help="Graph and diagram commands.")
ui_app = typer.Typer(help="Interactive UI compatibility commands.")

app.add_typer(model_app, name="model")
app.add_typer(analysis_app, name="analysis")
app.add_typer(results_app, name="results")
app.add_typer(table_app, name="table")
app.add_typer(graph_app, name="graph")
app.add_typer(ui_app, name="ui")


def _not_implemented(function_name: str) -> None:
    typer.echo(f"[TODO] Implement service binding for Base/{function_name}.m")
    raise typer.Exit(code=0)


# ---------------------------------------------------------------------------
# Base/ReadDataModel.m, SaveDataModel.m, CopyDataModel.m, ImportDataModel.m,
# ImportData.m, ValidateModelTables.m
# ---------------------------------------------------------------------------
@model_app.command("read")
def model_read(
    file: Path = typer.Option(..., "--file", exists=False, readable=True),
    debug: bool = typer.Option(False, "--debug"),
    show: bool = typer.Option(False, "--show"),
    save_as: Optional[Path] = typer.Option(None, "--save-as"),
) -> None:
    """ReadDataModel: load and validate model data."""
    _not_implemented("ReadDataModel")


@model_app.command("save")
def model_save(
    input_model: Path = typer.Option(..., "--input"),
    output: Path = typer.Option(..., "--output"),
) -> None:
    """SaveDataModel: save data model to a target format."""
    _not_implemented("SaveDataModel")


@model_app.command("copy")
def model_copy(
    input_file: Path = typer.Option(..., "--input"),
    output_file: Path = typer.Option(..., "--output"),
) -> None:
    """CopyDataModel: copy/convert model file."""
    _not_implemented("CopyDataModel")


@model_app.command("import-raw")
def model_import_raw(
    file: Path = typer.Option(..., "--file"),
    show: bool = typer.Option(False, "--show"),
) -> None:
    """ImportData: import raw table data."""
    _not_implemented("ImportData")


@model_app.command("import-structured")
def model_import_structured(
    file: Path = typer.Option(..., "--file"),
) -> None:
    """ImportDataModel: import model into internal structure."""
    _not_implemented("ImportDataModel")


@model_app.command("validate")
def model_validate(
    file: Path = typer.Option(..., "--file"),
    save_as: Optional[Path] = typer.Option(None, "--save-as"),
    show: bool = typer.Option(False, "--show"),
) -> None:
    """ValidateModelTables: validate model table definitions."""
    _not_implemented("ValidateModelTables")


# ---------------------------------------------------------------------------
# Base/ThermoeconomicModel.m, ProductiveStructure.m, ExergyAnalysis.m,
# ThermoeconomicAnalysis.m, ThermoeconomicDiagnosis.m, WasteAnalysis.m,
# SummaryResults.m, DiagramFP.m, ProductiveDiagram.m
# ---------------------------------------------------------------------------
@analysis_app.command("create-model")
def analysis_create_model(
    file: Path = typer.Option(..., "--file"),
    debug: bool = typer.Option(False, "--debug"),
) -> None:
    """ThermoeconomicModel: create configured model object."""
    _not_implemented("ThermoeconomicModel")


@analysis_app.command("productive-structure")
def analysis_productive_structure(
    file: Path = typer.Option(..., "--file"),
    state: Optional[str] = typer.Option(None, "--state"),
    show: bool = typer.Option(False, "--show"),
    save_as: Optional[Path] = typer.Option(None, "--save-as"),
) -> None:
    """ProductiveStructure: run productive structure analysis."""
    _not_implemented("ProductiveStructure")


@analysis_app.command("exergy")
def analysis_exergy(
    file: Path = typer.Option(..., "--file"),
    state: Optional[str] = typer.Option(None, "--state"),
    show: bool = typer.Option(False, "--show"),
    save_as: Optional[Path] = typer.Option(None, "--save-as"),
) -> None:
    """ExergyAnalysis: run exergy analysis."""
    _not_implemented("ExergyAnalysis")


@analysis_app.command("thermoeconomic")
def analysis_thermoeconomic(
    file: Path = typer.Option(..., "--file"),
    state: Optional[str] = typer.Option(None, "--state"),
    cost_tables: str = typer.Option("ALL", "--cost-tables"),
    resource_sample: Optional[str] = typer.Option(None, "--resource-sample"),
    show: bool = typer.Option(False, "--show"),
    save_as: Optional[Path] = typer.Option(None, "--save-as"),
) -> None:
    """ThermoeconomicAnalysis: run thermoeconomic cost analysis."""
    _not_implemented("ThermoeconomicAnalysis")


@analysis_app.command("diagnosis")
def analysis_diagnosis(
    file: Path = typer.Option(..., "--file"),
    state: Optional[str] = typer.Option(None, "--state"),
    reference_state: Optional[str] = typer.Option(None, "--reference-state"),
    method: Optional[str] = typer.Option(None, "--method"),
    show: bool = typer.Option(False, "--show"),
    save_as: Optional[Path] = typer.Option(None, "--save-as"),
) -> None:
    """ThermoeconomicDiagnosis: run diagnosis between states."""
    _not_implemented("ThermoeconomicDiagnosis")


@analysis_app.command("waste")
def analysis_waste(
    file: Path = typer.Option(..., "--file"),
    state: Optional[str] = typer.Option(None, "--state"),
    waste_flow: Optional[str] = typer.Option(None, "--waste-flow"),
    recycling: bool = typer.Option(False, "--recycling/--no-recycling"),
    show: bool = typer.Option(False, "--show"),
    save_as: Optional[Path] = typer.Option(None, "--save-as"),
) -> None:
    """WasteAnalysis: run waste allocation/recycling analysis."""
    _not_implemented("WasteAnalysis")


@analysis_app.command("summary")
def analysis_summary(
    file: Path = typer.Option(..., "--file"),
    summary_mode: Optional[str] = typer.Option(None, "--summary-mode"),
    show: bool = typer.Option(False, "--show"),
    save_as: Optional[Path] = typer.Option(None, "--save-as"),
) -> None:
    """SummaryResults: build summary result tables."""
    _not_implemented("SummaryResults")


@analysis_app.command("diagram-fp")
def analysis_diagram_fp(
    file: Path = typer.Option(..., "--file"),
    state: Optional[str] = typer.Option(None, "--state"),
    show: bool = typer.Option(False, "--show"),
    save_as: Optional[Path] = typer.Option(None, "--save-as"),
) -> None:
    """DiagramFP: build fuel-product adjacency outputs."""
    _not_implemented("DiagramFP")


@analysis_app.command("productive-diagram")
def analysis_productive_diagram(
    file: Path = typer.Option(..., "--file"),
    state: Optional[str] = typer.Option(None, "--state"),
    show: bool = typer.Option(False, "--show"),
    save_as: Optional[Path] = typer.Option(None, "--save-as"),
) -> None:
    """ProductiveDiagram: build productive structure diagram outputs."""
    _not_implemented("ProductiveDiagram")


# ---------------------------------------------------------------------------
# Base/ShowResults.m, SaveResults.m, ExportResults.m, ListResultTables.m,
# SaveSummary.m
# ---------------------------------------------------------------------------
@results_app.command("show")
def results_show(
    input_results: Path = typer.Option(..., "--input"),
    table: Optional[str] = typer.Option(None, "--table"),
    view: str = typer.Option("CONSOLE", "--view"),
    panel: bool = typer.Option(False, "--panel"),
    save_as: Optional[Path] = typer.Option(None, "--save-as"),
) -> None:
    """ShowResults: display all/specific results tables."""
    _not_implemented("ShowResults")


@results_app.command("save")
def results_save(
    input_results: Path = typer.Option(..., "--input"),
    output: Path = typer.Option(..., "--output"),
) -> None:
    """SaveResults: save complete result set."""
    _not_implemented("SaveResults")


@results_app.command("export")
def results_export(
    input_results: Path = typer.Option(..., "--input"),
    export_as: str = typer.Option("CELL", "--export-as"),
    output: Optional[Path] = typer.Option(None, "--output"),
) -> None:
    """ExportResults: export result set as Python/MATLAB-like structures."""
    _not_implemented("ExportResults")


@results_app.command("list-tables")
def results_list_tables(
    input_results: Path = typer.Option(..., "--input"),
) -> None:
    """ListResultTables: list available table names and metadata."""
    _not_implemented("ListResultTables")


@results_app.command("save-summary")
def results_save_summary(
    input_model_results: Path = typer.Option(..., "--input"),
    output: Path = typer.Option(..., "--output"),
) -> None:
    """SaveSummary: save model summary output."""
    _not_implemented("SaveSummary")


# ---------------------------------------------------------------------------
# Base/ShowTable.m, SaveTable.m
# ---------------------------------------------------------------------------
@table_app.command("show")
def table_show(
    input_table: Path = typer.Option(..., "--input"),
    view: str = typer.Option("CONSOLE", "--view"),
    export_as: str = typer.Option("CELL", "--export-as"),
    save_as: Optional[Path] = typer.Option(None, "--save-as"),
) -> None:
    """ShowTable: display/export a single table."""
    _not_implemented("ShowTable")


@table_app.command("save")
def table_save(
    input_table: Path = typer.Option(..., "--input"),
    output: Path = typer.Option(..., "--output"),
) -> None:
    """SaveTable: save a single table to file."""
    _not_implemented("SaveTable")


# ---------------------------------------------------------------------------
# Base/ShowGraph.m, SankeyDiagram.m
# ---------------------------------------------------------------------------
@graph_app.command("show")
def graph_show(
    input_results: Path = typer.Option(..., "--input"),
    graph: str = typer.Option(..., "--graph"),
    state: Optional[str] = typer.Option(None, "--state"),
) -> None:
    """ShowGraph: render selected graph from result set."""
    _not_implemented("ShowGraph")


@graph_app.command("sankey")
def graph_sankey(
    input_results: Path = typer.Option(..., "--input"),
    option: Optional[str] = typer.Option(None, "--option"),
) -> None:
    """SankeyDiagram: render Sankey diagram for selected result."""
    _not_implemented("SankeyDiagram")


# ---------------------------------------------------------------------------
# Base/ViewResults.m, ResultsPanel.m, TaesTool.m, TaesPanel.m
# ---------------------------------------------------------------------------
@ui_app.command("view-results")
def ui_view_results(
    input_results: Path = typer.Option(..., "--input"),
) -> None:
    """ViewResults: launch app-like result browser."""
    _not_implemented("ViewResults")


@ui_app.command("results-panel")
def ui_results_panel(
    input_results: Path = typer.Option(..., "--input"),
) -> None:
    """ResultsPanel: launch interactive results panel."""
    _not_implemented("ResultsPanel")


@ui_app.command("taes-tool")
def ui_taes_tool() -> None:
    """TaesTool: launch compatibility UI workflow."""
    _not_implemented("TaesTool")


@ui_app.command("taes-panel")
def ui_taes_panel() -> None:
    """TaesPanel: launch panel-style UI workflow."""
    _not_implemented("TaesPanel")


@app.command("version")
def version() -> None:
    """Print CLI skeleton version."""
    typer.echo("taespy CLI skeleton 0.1.0")


if __name__ == "__main__":
    app()

