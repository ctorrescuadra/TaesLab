**Read Data Models**

| Name                  | Description                                                 |
| :-------------------- | :---------------------------------------------------------- |
| ReadDataModel         | Read and validate a thermoeconomic data model file.         |
| ValidateModelTables   | Validate and convert tabular data model files.              |
| CopyDataModel         | Copy and convert a data model file to a different format.   |
| ImportDataModel       | Load a cDataModel object from a MAT file.                   |
| ImportData            | Import external tabular data from CSV or Excel files.       |

**Thermoeconomic Results**

| Name                      | Description                                                                 |
| :------------------------ | :-------------------------------------------------------------------------- |
| ThermoeconomicModel       | Create a cThermoeconomicModel object from a data model.                     |
| ProductiveStructure       | Extract and display productive structure information from a data model.     |
| ProductiveDiagram         | Generate graph adjacency tables for productive structure visualization.     |
| ExergyAnalysis            | Perform exergy analysis for a specific plant operating state.               |
| ThermoeconomicAnalysis    | Perform thermoeconomic cost analysis of a plant operating state.            |
| ThermoeconomicDiagnosis   | Detect and quantify malfunctions by comparing plant operating states.       |
| DiagramFP                 | Generate annotated fuel-product diagrams with exergy flows and costs.       |
| WasteAnalysis             | Analyze waste cost allocation and recycling optimization strategies.        |
| SummaryResults            | Generate comparative summary tables across multiple operating conditions.   |

**Save Results**

| Name            | Description                                                             |
| :-------------- | :---------------------------------------------------------------------- |
| SaveDataModel   | Save thermoeconomic data model to file in various formats.              |
| SaveResults     | Export result tables to file in multiple formats.                       |
| SaveSummary     | Export summary comparison tables for multiple states or cost samples.   |
| SaveTable       | Export a single table to file in various formats.                       |

**Display Results**

| Name               | Description                                                            |
| :----------------- | :--------------------------------------------------------------------- |
| ListResultTables   | Display catalog of available result tables and their properties.       |
| ShowGraph          | Display graphical visualizations of thermoeconomic analysis results.   |
| ShowResults        | Display and save result tables from thermoeconomic analyses.           |
| ShowTable          | Display, export, and save individual result tables.                    |
| ExportResults      | Export result tables to various MATLAB data formats.                   |

**GUI Functions**

| Name           | Description                                                               |
| :------------- | :------------------------------------------------------------------------ |
| TaesTool       | Compatible user interface App for MATLAB/Octave.                          |
| TaesPanel      | Graphical user interface for selecting thermoeconomic model parameters.   |
| ResultsPanel   | Graphical user interface for displaying results interactively.            |
| ViewResults    | MATLAB app for displaying results tables.                                 |

