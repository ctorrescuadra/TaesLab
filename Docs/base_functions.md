# Thermoeconomic Analysis Toolbox

Version 1.8 (R2024b) 01-Oct-2025

## TaesLab Base Funtions

### Read Data Models

| Function                   | Description                                                 |
| :------------------------- | :---------------------------------------------------------- |
| [ValidateModelTables][]    | Validate the table data model files                         |
| [ReadDataModel][]          | Read a data model file.                                     |
| [CopyDataModel][]          | Creates a copy of a data model file in another format.      |
| [ImportDataModel][]        | Get a cDataModel object from a previous saved MAT file.     |
| [ImportData][]             | Import external data to a cTableData from CSV or XLSX files.|

### Get Thermoeconomic Results

| Function                   | Description                                                        |
| :------------------------- | :----------------------------------------------------------------- |
| [ThermoeconomicModel][]    | Creates a cThermoeconomicModel object from a data model file.      |
| [ProductiveStructure][]    | Get the productive structure of the plant.                         |
| [ProductiveDiagram][]      | Get the productive diagrams of the plant.                          |
| [ExergyAnalysis][]         | Get the exergy analysis for a plant state.                         |
| [ThermoeconomicAnalysis][] | Perform the termoeconomic analysis of a plant state.               |
| [ThermoeconomicDiagnosis][]| Compare two states of the plant and make a thermoeconomic diagnosis|
| [WasteAnalysis][]          | Waste recycling analysis of one state of the plant.                |
| [DiagramFP][]              | Get the FP diagrams for a plant state.                             |
| [SummaryResults][]         | Get the summary results of the plant.                              |

### Save Results Tables

| Function          | Description                            |
| :---------------- | :------------------------------------- |
| [SaveResults][]   | Save the results tables into a file    |
| [SaveSummary][]   | Save the summary results into a file.  |
| [SaveDataModel][] | Save the data model tables into a file.|
| [SaveTable][]     | Save a table content into a file.      |

### Display Results

| Function             | Description                                       |
| :------------------- | :------------------------------------------------ |
| [ListResultTables][] | List the results tables and their properties.     |
| [ShowResults][]      | Display the results tables in different formats.  |
| [ShowTable][]        | Display an individual table.                      |
| [ShowGraph][]        | Display the graph associated with a results table.|
| [ExportResults][]    | Export the results tables in different formats.   |

### GUI functions

| Function          | Description                                                            |
| :---------------- | :--------------------------------------------------------------------- |
| [TaesLab][]       | TaesLab main MATLAB app                                                |
| [TaesTool][]      | Compatible user interface for Matlab/Octave.                           |
| [TaesPanel][]     | Graphical user interface for selecting thermoeconomic model parameters.|
| [ResultsPanel][]  | Graphical user interface for displaying results interactively.         |
| [ViewResults][]   | MATLAB app for displaying results tables.                              |

<!-- Reference Links - Base Directory -->

<!-- Read Data Models -->
[ValidateModelTables]: ../Base/ValidateModelTables.m
[ReadDataModel]: ../Base/ReadDataModel.m
[CopyDataModel]: ../Base/CopyDataModel.m
[ImportDataModel]: ../Base/ImportDataModel.m
[ImportData]: ../Base/ImportData.m

<!-- Get Thermoeconomic Results -->
[ThermoeconomicModel]: ../Base/ThermoeconomicModel.m
[ProductiveStructure]: ../Base/ProductiveStructure.m
[ProductiveDiagram]: ../Base/ProductiveDiagram.m
[ExergyAnalysis]: ../Base/ExergyAnalysis.m
[ThermoeconomicAnalysis]: ../Base/ThermoeconomicAnalysis.m
[ThermoeconomicDiagnosis]: ../Base/ThermoeconomicDiagnosis.m
[WasteAnalysis]: ../Base/WasteAnalysis.m
[DiagramFP]: ../Base/DiagramFP.m
[SummaryResults]: ../Base/SummaryResults.m

<!-- Save Results Tables -->
[SaveResults]: ../Base/SaveResults.m
[SaveSummary]: ../Base/SaveSummary.m
[SaveDataModel]: ../Base/SaveDataModel.m
[SaveTable]: ../Base/SaveTable.m

<!-- Display Results -->
[ListResultTables]: ../Base/ListResultTables.m
[ShowResults]: ../Base/ShowResults.m
[ShowTable]: ../Base/ShowTable.m
[ShowGraph]: ../Base/ShowGraph.m
[ExportResults]: ../Base/ExportResults.m

<!-- GUI Functions -->
[TaesLab]: ../Base/TaesLab.m
[TaesTool]: ../Base/TaesTool.m
[TaesPanel]: ../Base/TaesPanel.m
[ResultsPanel]: ../Base/ResultsPanel.m
[ViewResults]: ../Base/ViewResults.m
