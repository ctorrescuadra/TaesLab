# Packages dependcies

Based on your class architecture (future **taespy**), I’d recommend a **layered dependency strategy**: keep core dependencies minimal, add optional extras per feature.

## 1) Core runtime (recommended baseline)

Use these first:

- **`numpy`** — matrix/vector operations for exergy and cost calculations.
- **`pandas`** — tabular model/results handling (good fit for `cModelTable`, `cTable*` classes).
- **`pydantic`** (or `attrs` + validators) — robust model validation for `DataModel`, `ExergyData`, etc.
- **`typing-extensions`** (if needed) — forward compatibility for typing features.
- **`scipy`** (optional but likely useful) — numerical methods/solvers for advanced analysis.

## 2) I/O and schema validation

For your `ReadModel*` classes:

- **Stdlib first**: `json`, `csv`, `xml.etree.ElementTree`, `pathlib`.
- **`openpyxl`** — XLSX read/write backend.
- **`jsonschema`** — validate input JSON against schemas (you already have schema mindset).
- **`lxml`** (optional) — stronger XML handling than stdlib when needed.
- **`defusedxml`** — safe XML parsing (recommended security hardening).

## 3) Calculation/analysis layer

For `ExergyModel`, `ExergyCost`, `Diagnosis`, etc.:

- **`numpy`** (mandatory)
- **`scipy`** (if optimization/linear algebra beyond numpy is needed)
- **`networkx`** — productive structure/digraph analysis (`cDigraphAnalysis`, `cProductiveDiagram`).

## 4) Reporting and export

For table builders and result presentation:

- **`jinja2`** — HTML/Markdown/LaTeX templating (`BuildHTML`, `BuildMarkdown`, `BuildLaTeX`).
- **`tabulate`** (optional) — quick text/markdown table rendering.
- **`pandas`** — export to CSV/XLSX.
- **`xlsxwriter`** (optional) — high-quality formatted Excel output.
- **`weasyprint`** or `reportlab` (optional) — if PDF output becomes a requirement.

## 5) Graphs and visualization

For `Graph*` classes and diagrams:

- **`matplotlib`** — baseline scientific plotting.
- **`seaborn`** (optional) — improved statistical styling.
- **`plotly`** (optional) — interactive graphs for apps/web.
- **`networkx` + `pygraphviz`/`graphviz`** — digraph rendering.
- **`matplotlib.sankey`** or **`plotly` Sankey** — Sankey diagram support.

## 6) Logging and infrastructure

For `MessageLogger`-style behavior:

- **Stdlib `logging`** — should be enough for most cases.
- **`structlog`** (optional) — structured logs if you need machine-parsable logs.

## 7) Testing, quality, and packaging (highly recommended)

Even if not runtime deps, these are key for migration quality:

- **`pytest`** — test framework.
- **`pytest-cov`** — coverage.
- **`hypothesis`** (optional) — property-based tests for validators/parsers.
- **`ruff`** — lint + import/order + many checks.
- **`black`** — formatting.
- **`mypy`** — static type checking.
- **`build`**, **`twine`** — package build/publish.
- **`hatchling`** or **`setuptools`** — build backend in `pyproject.toml`.

---

## Practical recommendation for taespy v1

If you want a lean but solid first release, start with:

`numpy`, `pandas`, `pydantic`, `openpyxl`, `jsonschema`, `networkx`, `matplotlib`, plus dev tools (`pytest`, `ruff`, `mypy`, `black`).

Then add optional extras:

- `taespy[xml]` → `lxml`, `defusedxml`
- `taespy[viz]` → `plotly`, `pygraphviz`
- `taespy[report]` → `jinja2`, `xlsxwriter`
