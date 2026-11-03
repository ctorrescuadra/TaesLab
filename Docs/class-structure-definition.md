# TaesLab Class Structure Definition (MATLAB)

This document summarizes the class structure in `Classes/` to support migration planning from MATLAB to Python.

## Source analyzed

- `Classes/Contents.m`
- All `classdef` declarations under `Classes/*.m`

## 1) Read data classes

These classes implement model input parsing and table normalization/validation for supported formats.

- `cReadModel` (abstract base)
- `cReadModelStruct` (abstract base for structured formats)
- `cReadModelJSON`
- `cReadModelXML`
- `cReadModelTable` (abstract base for tabular formats)
- `cReadModelCSV`
- `cReadModelXLS`
- `cModelTable` (validated table container)

## 2) Data model classes

These classes store, validate, and organize domain data before running calculations.

- `cDataModel` (central data hub)
- `cModelData` (data model structure container)
- `cProductiveStructure`
- `cExergyData`
- `cResourceData`
- `cWasteData`
- `cFormatData`
- `cTablesDefinition`
- `cResultTableBuilder`

## 3) Calculation classes

These classes implement thermoeconomic computations and result orchestration.

- `cResultId` (calculation base class)
- `cResultSet` (result set base class)
- `cThermoeconomicModel`
- `cExergyModel`
- `cExergyCost`
- `cDiagnosis`
- `cWasteAnalysis`
- `cSummaryResults`
- `cSummaryOptions`
- `cSummaryTable`
- `cDigraphAnalysis`
- `cProductiveDiagram`
- `cDiagramFP`
- `cResultInfo`
- `cModelResults`

## 4) Reporting and graph classes

### Table/report presentation

- `cTable`
- `cTableIndex`
- `cTableData`
- `cTableResult`
- `cTableCell`
- `cTableMatrix`
- `cViewTable`
- `cBuildHTML`
- `cBuildLaTeX`
- `cBuildMarkdown`

### Graph classes

- `cGraphResults`
- `cGraphCost`
- `cGraphCostRSC`
- `cGraphDiagnosis`
- `cGraphDiagramFP`
- `cGraphWaste`
- `cGraphRecycling`
- `cGraphSummary`
- `cDigraph`

## 5) Constant classes

These classes centralize constants, messages, and string validation utilities.

- `cType`
- `cMessages`
- `cParseStream`

## 6) Other classes (infrastructure/utilities)

Cross-cutting classes used by multiple layers.

- `cTaesLab` (root base class)
- `cMessageLogger`
- `cMessageBuilder`
- `cDictionary`
- `cDataset`
- `cQueue`
- `cSparseRow`

## Inheritance backbone (high level)

- `cTaesLab` is the foundational handle-based base class.
- `cMessageLogger` extends `cTaesLab` and is reused across validation/processing classes.
- `cResultId` extends `cMessageLogger` and acts as the base for analysis classes.
- `cResultSet` extends `cResultId` and groups result-oriented objects.
- `cTable` is the base table abstraction (`cTableData`, `cTableResult`, etc.).
- `cGraphResults` is the base graph abstraction for all graph renderers.
