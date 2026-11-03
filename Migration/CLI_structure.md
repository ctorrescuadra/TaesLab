# User Interface functions

In TaesLab, files like `ReadDataModel.m`, `ThermoeconomicAnalysis.m`, `ShowResults.m`, and `ShowTable.m` are already acting as “console API” wrappers — that pattern maps very well to Python.

---

## Recommended migration pattern

## 1) Keep Base functions as Python service functions

Create Python equivalents in the package (from your blueprint in `python-package-blueprint.md`):

- `read_data_model(...)`
- `thermoeconomic_analysis(...)`
- `exergy_analysis(...)`
- `waste_analysis(...)`
- `show_results(...)`
- `show_table(...)`
- `save_results(...)`, `save_table(...)`

These should be **importable functions** (library-first), not tied to CLI internals.

## 2) Add a CLI adapter layer

Add a CLI entrypoint, e.g.:

- `taeslab/cli/main.py`
- command runner: `python -m taeslab` or `taespy ...`

Use:

- `argparse` (stdlib) or
- `typer` (recommended; cleaner command UX)

## 3) Map each MATLAB Base function to a CLI command

Example mapping:

- `ReadDataModel` → `taespy model read`
- `ThermoeconomicAnalysis` → `taespy analysis thermoeconomic`
- `ExergyAnalysis` → `taespy analysis exergy`
- `ThermoeconomicDiagnosis` → `taespy analysis diagnosis`
- `WasteAnalysis` → `taespy analysis waste`
- `ShowResults` → `taespy results show`
- `ShowTable` → `taespy table show`
- `SaveResults` → `taespy results save`
- `SaveTable` → `taespy table save`

---

## Key behavior to preserve from MATLAB Base layer

From `ShowResults.m` and `ShowTable.m`:

- Same options semantics (`Table`, `View`, `SaveAs`, etc.)
- Same defaults (e.g., console view by default)
- Same validation-first flow
- Explicit user-facing errors (don’t silently ignore invalid states)
- Same export format behavior by extension (`.xlsx`, `.csv`, `.json`, `.html`, `.md`, etc.)

---

## Suggested Python command structure

```bash
taespy model read --file rankine_model.json --show --debug
taespy analysis thermoeconomic --file rankine_model.json --state REF --cost-tables ALL
taespy results show --input results.json --table dcost --view console
taespy results save --input results.json --output costs.xlsx
```

---

## What to do with GUI-oriented Base classes

Files like `TaesTool.m`, `TaesPanel.m`, `ResultsPanel.m`, and `ViewResults.m` should be migrated in a **second phase**:

- **Phase 1 (recommended first):** CLI + file exports + plotting
- **Phase 2:** optional GUI (`PySide6`/`PyQt6`) or browser UI (`streamlit`/`dash`)

That avoids blocking core migration on UI framework decisions.

---

## Practical package choices for this Base migration

- CLI: `typer` + `rich`
- Core logic: `numpy`, `pandas`, `pydantic`
- I/O: `openpyxl`, `jsonschema`
- Reporting: `jinja2` (HTML/Markdown templates)
- Graphs: `matplotlib`, `networkx`

---
