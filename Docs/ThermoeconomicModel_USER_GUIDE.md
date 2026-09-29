# ThermoeconomicModel User Guide

**TaesLab Version:** 1.8  
**Purpose:** Create and use a `cThermoeconomicModel` object for thermoeconomic analysis.

## Recent implementation updates

The public model entry point remains centered on the same analysis pipeline, but the latest code reflects these refinements:

- State, reference state, resource sample, and summary-mode selection are all managed through the model object instead of ad hoc configuration variables.
- The object builds and exposes cost-table selection through `setCostTables`, `isDirectCost`, and `isGeneralCost`.
- Waste analysis and recycling configuration are integrated into the same model lifecycle as exergy and thermoeconomic calculations.
- Result access is now oriented around result IDs and table metadata, so the model can expose a consistent `ListOfTables`/`getTable` workflow for GUI and script usage.

## Overview

`ThermoeconomicModel` is the main entry point for interactive thermoeconomic studies in TaesLab. It loads a data model, validates it, creates a `cThermoeconomicModel` object, and prepares the model for analysis, display, and export.

The typical workflow is:

1. Load a data model from file or from an existing `cDataModel` object.
2. Create a `cThermoeconomicModel` instance.
3. Configure the active state, reference state, resource sample, cost options, and summary options.
4. Run analyses such as exergy, thermoeconomic, diagnosis, or waste analysis.
5. Display or export the resulting tables.

## Function: ThermoeconomicModel

### Syntax

```matlab
model = ThermoeconomicModel(arg)
model = ThermoeconomicModel(arg, 'Name', value, ...)
```

### Input Argument

- `arg`: File path to a data model or an existing `cDataModel` object.

### Name-Value Options

- `State`: Active operating state. Default: first available state.
- `ReferenceState`: Reference state used for diagnosis. Default: first available state.
- `ResourceSample`: Active resource-cost sample. Default: empty, or first available sample when resource cost data exists.
- `CostTables`: Cost table mode. Valid values: `DIRECT`, `GENERALIZED`, `ALL`.
- `DiagnosisMethod`: Diagnosis mode. Valid values: `NONE`, `WASTE_EXTERNAL`, `WASTE_INTERNAL`.
- `ActiveWaste`: Active waste-flow key used by waste analysis.
- `Summary`: Summary mode. Valid values: `NONE`, `STATES`, `RESOURCES`, `ALL`.
- `Recycling`: Enable or disable recycling analysis. Default: `false`.
- `Debug`: Enable debug messages. Default: `true` in the base function.

### Output

- `model`: A configured `cThermoeconomicModel` object.

### Basic Example

```matlab
model = ThermoeconomicModel('Examples/rankine/rankine_model.json');
```

### Example with Options

```matlab
model = ThermoeconomicModel('Examples/rankine/rankine_model.json', ...
    'State', 'design', ...
    'ReferenceState', 'design', ...
    'CostTables', 'ALL', ...
    'Summary', 'STATES', ...
    'Debug', false);
```

## Creating a cThermoeconomicModel Object

You can create the object directly through `ThermoeconomicModel`, which is the recommended user-facing entry point.

```matlab
data = ReadDataModel('plant_model.json');
model = ThermoeconomicModel(data);
```

After creation, the object contains the loaded data model, the available states and samples, and the current analysis results.

## Common First Steps

```matlab
% Inspect current configuration
model.showProperties;

% Change the active state
model.setState('design');

% Select a reference state for diagnosis
model.setReferenceState('reference');

% Select a resource sample when resource costs are available
model.setResourceSample('summer');
```

## Method Categories And Examples

The public API of `cThermoeconomicModel` can be read in eight practical groups.

### 1. Configuration Methods

Use these methods to select the state, sample, cost mode, diagnosis mode, summary mode, and debug behavior.

Example:

```matlab
model.setState('design');
model.setReferenceState('reference');
model.setResourceSample('summer');
model.setCostTables('ALL');
model.setDiagnosisMethod('WASTE_INTERNAL');
model.setSummary('STATES');
model.setRecycling(true);
```

### 2. Analysis And Result Methods

Use these methods to compute the main thermoeconomic outputs and retrieve result containers.

Example:

```matlab
structure = model.productiveStructure();
exergy = model.exergyAnalysis();
costs = model.thermoeconomicAnalysis();
diagnosis = model.thermoeconomicDiagnosis();
summary = model.summaryResults();
```

### 3. Information And Validation Methods

Use these methods to inspect the current configuration and check whether a computation is available.

Example:

```matlab
model.showProperties;

if model.isDiagnosis()
    disp('Diagnosis can be computed.');
end
```

### 4. Table And Directory Methods

Use these methods to discover tables and display them in the console, GUI, or HTML view.

Example:

```matlab
tables = model.ListOfTables();
indexTable = model.getTableIndex();
model.showResults('dcost', 'View', 'HTML');
model.showGraph('dict');
```

### 5. Waste Methods

Use these methods when the data model defines waste flows and you want to inspect or modify the waste allocation.

Example:

```matlab
model.wasteAllocation();
model.setActiveWaste('QC');
model.setWasteType(cType.WasteAllocation.COST);
model.setWasteRecycled([0.2 0.8]);
```

### 6. Resource Methods

Use these methods to load or modify resource-cost samples and the cost of flows and processes.

Example:

```matlab
model.addResourceData('winter', flowCosts, processCosts);
model.setResourceSample('winter');
model.setFlowResource(flowCosts);
model.setProcessResource(processCosts);
```

### 7. Exergy Data Methods

Use these methods to add or update the exergy data associated with a state.

Example:

```matlab
model.addExergyData('off_design', exergyValues);
model.setState('off_design');
model.setExergyData(exergyValues);
stateData = model.getExergyData('off_design');
```

### 8. Internal Support And Inherited Result-Set Methods

Use these methods when you need lower-level access to indexes, result containers, or generic result-set behavior.

Example:

```matlab
stateId = model.getStateId('design');
sampleId = model.getSampleId('summer');
wasteId = model.getWasteId('QC');

model.printResults();
model.saveResults('thermoeconomic_results.xlsx');
```

## Public Methods of cThermoeconomicModel

The following methods are publicly available on the class itself. They are grouped by purpose for easier use.

### Configuration Methods

- `setState(state)` - Set the active operating state.
- `setReferenceState(state)` - Set the reference state used by diagnosis.
- `setResourceSample(sample)` - Set the active resource sample.
- `setSummary(value)` - Set the summary mode.
- `setCostTables(value)` - Set the cost-table mode.
- `setDiagnosisMethod(method)` - Set the diagnosis method.
- `setActiveWaste(value)` - Set the active waste flow.
- `setRecycling(value)` - Enable or disable recycling analysis.
- `setDebug(dbg)` - Enable or disable debug output.
- `toggleDebug()` - Toggle the debug state.

### Analysis and Result Methods

- `productiveStructure()` - Get the productive structure results.
- `exergyAnalysis()` - Get the exergy analysis results for the active state.
- `productiveDiagram()` - Get the productive diagram results.
- `diagramFP()` - Get the FP diagram results.
- `thermoeconomicAnalysis()` - Get the thermoeconomic analysis results.
- `thermoeconomicDiagnosis()` - Get the thermoeconomic diagnosis results.
- `summaryDiagnosis()` - Show a diagnosis summary in the console.
- `wasteAnalysis()` - Get the waste analysis results.
- `summaryResults()` - Get the summary results.
- `dataInfo()` - Get the data-model result object.
- `getResultInfo(arg)` - Get a result object by result ID or table name.
- `showResultInfo()` - Return the current result set as a structure.

### Information and Validation Methods

- `showProperties()` - Show the current model configuration.
- `isDiagnosis()` - Check whether diagnosis computation is available.
- `isDirectCost()` - Check whether direct cost tables are enabled.
- `isGeneralCost()` - Check whether generalized cost tables are enabled.
- `isResourceCost()` - Check whether resource cost data exists.
- `isWaste()` - Check whether waste data exists.
- `summaryOptions()` - Return the available summary option names.
- `isSummaryEnable()` - Check whether summaries are available in the model.
- `isSummaryActive()` - Check whether summary results are enabled.
- `isStateSummary()` - Check whether state summary results are enabled.
- `isSampleSummary()` - Check whether resource-sample summary results are enabled.

### Table and Directory Methods

- `getTablesDirectory(cols)` - Return the list of available tables.
- `getTableInfo(name)` - Return table metadata.
- `getTable(name)` - Return a result table by name.
- `showTablesDirectory()` - Display the available tables.
- `showResults(name, varargin)` - Show a specific result table.
- `showGraph(graph, varargin)` - Show a graph result.
- `showSummary(name, varargin)` - Show summary tables.
- `showDataModel(name, varargin)` - Show data-model tables.
- `showTableIndex()` - Show the table index of the result set.

### Waste Methods

- `wasteAllocation()` - Show waste allocation data.
- `setWasteType(wtype)` - Set the waste allocation type.
- `setWasteValues(val)` - Set the waste values.
- `setWasteRecycled(val)` - Set the recycling ratios for waste.
- `updateWasteTable()` - Update the waste table with the current state values.

### Resource Methods

- `addResourceData(sample, c0, varargin)` - Add a new resource sample.
- `getResourceData(sample)` - Get resource-cost data for a sample.
- `setFlowResource(c0)` - Set flow resource costs.
- `setProcessResource(Z)` - Set process resource costs.

### Exergy Data Methods

- `addExergyData(state, values)` - Add a new exergy state.
- `getExergyData(state)` - Get exergy data for a state.
- `setExergyData(values)` - Update exergy data for the active state.

### Internal Support Methods

These methods are public in the class, but are mainly intended for internal or application-level use.

- `updateDataModel()` - Update the underlying data model.
- `getStateId(key)` - Get the state index for a state name.
- `getSampleId(key)` - Get the sample index for a resource-sample name.
- `getWasteId(key)` - Get the waste-flow index.
- `getModelResults()` - Return the current model results as a cell array.
- `getResultState(idx)` - Get the `cExergyCost` object for a state.

### Inherited Public Methods from cResultSet

`cThermoeconomicModel` also exposes the public result-set interface inherited from `cResultSet`.

- `StudyCase()` - Get the current state and sample names.
- `ListOfTables()` - Get the list of available tables.
- `ListOfGraphs()` - Get the list of graph-capable tables.
- `getTableIndex(varargin)` - Get the table index in a selected format.
- `printResults()` - Print all result tables in the console.
- `exportResults(varmode, fmt)` - Export all tables to a MATLAB variable.
- `saveResults(filename)` - Save all result tables to a file.
- `saveTable(tname, filename)` - Save a single table to a file.
- `exportTable(tname, varargin)` - Export a single table to a MATLAB variable.

## Typical Usage Workflow

```matlab
model = ThermoeconomicModel('plant_model.json');

model.setState('design');
model.setReferenceState('reference');
model.setCostTables('ALL');
model.setSummary('STATES');

structure = model.productiveStructure();
costs = model.thermoeconomicAnalysis();
summary = model.summaryResults();

model.showResults('dcost', 'View', 'HTML');
model.saveSummary('summary_results.xlsx');
```

## Base Functions with cResultSet Input

Most result-oriented base functions in TaesLab accept a `cResultSet` object as the first input.
This includes objects such as:

- `cThermoeconomicModel`
- `cResultInfo` returned by analysis functions
- `cDataModel`

### Save Result Tables

Use these base functions to persist results:

- `SaveResults(resultSet, filename)` - Save all tables in a `cResultSet`.
- `SaveTable(tbl, filename)` - Save one table (obtained from a `cResultSet`).
- `SaveSummary(model, filename)` - Save summary comparison tables from a `cThermoeconomicModel`.

Example:

```matlab
model = ThermoeconomicModel('plant_model.json', 'Summary', 'STATES');

% cResultInfo (inherits cResultSet)
costs = model.thermoeconomicAnalysis();

% Save all tables from the result set
SaveResults(costs, 'costs_results.xlsx');

% Save one specific table from the result set
tbl = costs.getTable('dcost');
SaveTable(tbl, 'dcost_table.csv');

% Save model summary tables
SaveSummary(model, 'summary_states.xlsx');
```

### Display Results

Use these base functions to inspect tables and graphs from a `cResultSet`:

- `ShowResults(resultSet, ...)` - Display all tables or one selected table.
- `ListResultTables(resultSet, ...)` - List available tables for that result set.
- `ShowGraph(resultSet, ...)` - Display graph-enabled results.
- `ShowTable(tbl, ...)` - Display one table retrieved from a result set.

Example:

```matlab
model = ThermoeconomicModel('plant_model.json');

% cResultInfo (inherits cResultSet)
results = model.exergyAnalysis();

% List available tables in this result set
ListResultTables(results, 'View', 'CONSOLE');

% Show one table in HTML
ShowResults(results, 'Table', 'pex', 'View', 'HTML');

% Show the default graph (or select one with 'Graph', 'tableName')
ShowGraph(results);

% Retrieve and display one table directly
tbl = results.getTable('pex');
ShowTable(tbl, 'View', 'CONSOLE');
```

## Notes

- If the model has no resource-cost data, generalized cost features are not available.
- Diagnosis requires at least two states and two different active states.
- Summary results are only available when the data model supports them.
- Waste methods are only useful when the data model defines waste flows.

## See Also

- [`ThermoeconomicModel`](../Base/ThermoeconomicModel.m)
- [`cThermoeconomicModel`](../Classes/cThermoeconomicModel.m)
- [`ReadDataModel`](../Base/ReadDataModel.m)
- [`ShowResults`](../Base/ShowResults.m)
- [`SaveResults`](../Base/SaveResults.m)
