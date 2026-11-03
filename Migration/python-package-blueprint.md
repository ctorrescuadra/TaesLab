# TaesLab Python Package Blueprint

This document defines the analyzed Python package structure for migrating TaesLab from MATLAB to Python, based on the class architecture identified in `Classes/`.

## Proposed package layout

```text
taeslab/
  __init__.py

  core/
    __init__.py
    base.py
    logging.py
    constants.py
    parsing.py
    containers.py

  io/
    __init__.py
    readers/
      __init__.py
      base.py
      json_reader.py
      xml_reader.py
      csv_reader.py
      xls_reader.py
      model_table.py

  model/
    __init__.py
    model_data.py
    productive_structure.py
    exergy_data.py
    resource_data.py
    waste_data.py
    format_data.py

  analysis/
    __init__.py
    base.py
    thermoeconomic.py
    exergy_model.py
    exergy_cost.py
    diagnosis.py
    waste_analysis.py
    summary.py
    graph_analysis.py
    productive_diagram.py

  results/
    __init__.py
    info.py
    table_builder.py
    tables/
      __init__.py
      base.py
      index.py
      data.py
      cell.py
      matrix.py

  reporting/
    __init__.py
    builders/
      __init__.py
      html.py
      latex.py
      markdown.py
    view/
      __init__.py
      table_view.py
    graphs/
      __init__.py
      base.py
      cost.py
      diagnosis.py
      diagram_fp.py
      waste.py
      summary.py
      digraph.py
```

## MATLAB to Python class mapping

## 1) Read data classes

| MATLAB class | Python class | Python module |
| --- | --- | --- |
| `cReadModel` | `ReadModel` | `taeslab/io/readers/base.py` |
| `cReadModelStruct` | `ReadModelStruct` | `taeslab/io/readers/base.py` |
| `cReadModelTable` | `ReadModelTable` | `taeslab/io/readers/base.py` |
| `cReadModelJSON` | `JsonReadModel` | `taeslab/io/readers/json_reader.py` |
| `cReadModelXML` | `XmlReadModel` | `taeslab/io/readers/xml_reader.py` |
| `cReadModelCSV` | `CsvReadModel` | `taeslab/io/readers/csv_reader.py` |
| `cReadModelXLS` | `XlsReadModel` | `taeslab/io/readers/xls_reader.py` |
| `cModelTable` | `ModelTable` | `taeslab/io/readers/model_table.py` |

## 2) Data model classes

| MATLAB class | Python class | Python module |
| --- | --- | --- |
| `cDataModel` | `DataModel` | `taeslab/model/model_data.py` |
| `cModelData` | `ModelData` | `taeslab/model/model_data.py` |
| `cProductiveStructure` | `ProductiveStructure` | `taeslab/model/productive_structure.py` |
| `cExergyData` | `ExergyData` | `taeslab/model/exergy_data.py` |
| `cResourceData` | `ResourceData` | `taeslab/model/resource_data.py` |
| `cWasteData` | `WasteData` | `taeslab/model/waste_data.py` |
| `cFormatData` | `FormatData` | `taeslab/model/format_data.py` |
| `cTablesDefinition` | `TablesDefinition` | `taeslab/model/format_data.py` |
| `cResultTableBuilder` | `ResultTableBuilder` | `taeslab/results/table_builder.py` |

## 3) Calculation classes

| MATLAB class | Python class | Python module |
| --- | --- | --- |
| `cResultId` | `ResultBase` | `taeslab/analysis/base.py` |
| `cResultSet` | `ResultSet` | `taeslab/analysis/base.py` |
| `cThermoeconomicModel` | `ThermoeconomicModel` | `taeslab/analysis/thermoeconomic.py` |
| `cExergyModel` | `ExergyModel` | `taeslab/analysis/exergy_model.py` |
| `cExergyCost` | `ExergyCost` | `taeslab/analysis/exergy_cost.py` |
| `cDiagnosis` | `Diagnosis` | `taeslab/analysis/diagnosis.py` |
| `cWasteAnalysis` | `WasteAnalysis` | `taeslab/analysis/waste_analysis.py` |
| `cSummaryResults` | `SummaryResults` | `taeslab/analysis/summary.py` |
| `cSummaryOptions` | `SummaryOptions` | `taeslab/analysis/summary.py` |
| `cSummaryTable` | `SummaryTable` | `taeslab/analysis/summary.py` |
| `cDigraphAnalysis` | `DigraphAnalysis` | `taeslab/analysis/graph_analysis.py` |
| `cProductiveDiagram` | `ProductiveDiagram` | `taeslab/analysis/productive_diagram.py` |
| `cDiagramFP` | `DiagramFP` | `taeslab/analysis/productive_diagram.py` |
| `cResultInfo` | `ResultInfo` | `taeslab/results/info.py` |
| `cModelResults` | `ModelResults` | `taeslab/results/info.py` |

## 4) Reporting and graph classes

| MATLAB class | Python class | Python module |
| --- | --- | --- |
| `cTable` | `Table` | `taeslab/results/tables/base.py` |
| `cTableResult` | `ResultTable` | `taeslab/results/tables/base.py` |
| `cTableIndex` | `TableIndex` | `taeslab/results/tables/index.py` |
| `cTableData` | `DataTable` | `taeslab/results/tables/data.py` |
| `cTableCell` | `CellTable` | `taeslab/results/tables/cell.py` |
| `cTableMatrix` | `MatrixTable` | `taeslab/results/tables/matrix.py` |
| `cBuildHTML` | `HtmlTableBuilder` | `taeslab/reporting/builders/html.py` |
| `cBuildLaTeX` | `LatexTableBuilder` | `taeslab/reporting/builders/latex.py` |
| `cBuildMarkdown` | `MarkdownTableBuilder` | `taeslab/reporting/builders/markdown.py` |
| `cViewTable` | `TableView` | `taeslab/reporting/view/table_view.py` |
| `cGraphResults` | `GraphResults` | `taeslab/reporting/graphs/base.py` |
| `cGraphCost` | `GraphCost` | `taeslab/reporting/graphs/cost.py` |
| `cGraphCostRSC` | `GraphCostRSC` | `taeslab/reporting/graphs/cost.py` |
| `cGraphDiagnosis` | `GraphDiagnosis` | `taeslab/reporting/graphs/diagnosis.py` |
| `cGraphDiagramFP` | `GraphDiagramFP` | `taeslab/reporting/graphs/diagram_fp.py` |
| `cGraphWaste` | `GraphWaste` | `taeslab/reporting/graphs/waste.py` |
| `cGraphRecycling` | `GraphRecycling` | `taeslab/reporting/graphs/waste.py` |
| `cGraphSummary` | `GraphSummary` | `taeslab/reporting/graphs/summary.py` |
| `cDigraph` | `DigraphPlot` | `taeslab/reporting/graphs/digraph.py` |

## 5) Constant classes

| MATLAB class | Python class | Python module |
| --- | --- | --- |
| `cType` | `TypeRegistry` (+ enums) | `taeslab/core/constants.py` |
| `cMessages` | `Messages` | `taeslab/core/constants.py` |
| `cParseStream` | `ParseStream` | `taeslab/core/parsing.py` |

## 6) Other classes (infrastructure/utilities)

| MATLAB class | Python class | Python module |
| --- | --- | --- |
| `cTaesLab` | `TaesLabObject` | `taeslab/core/base.py` |
| `cMessageLogger` | `MessageLogger` | `taeslab/core/logging.py` |
| `cMessageBuilder` | `MessageBuilder` | `taeslab/core/logging.py` |
| `cDictionary` | `DictionaryMap` | `taeslab/core/containers.py` |
| `cDataset` | `Dataset` | `taeslab/core/containers.py` |
| `cQueue` | `Queue` | `taeslab/core/containers.py` |
| `cSparseRow` | `SparseRow` | `taeslab/core/containers.py` |

## Migration conventions

- Drop MATLAB `c` class prefix in Python names (`cDataModel` -> `DataModel`).
- Keep class names in PascalCase and module names in snake_case.
- Replace MATLAB abstract classes with `abc.ABC` + `@abstractmethod`.
- Represent constants and categories with `Enum` and immutable class attributes.
- Preserve validation logic and key naming patterns exactly.
- Preserve architectural layering: `io -> model -> analysis -> results/reporting`.
