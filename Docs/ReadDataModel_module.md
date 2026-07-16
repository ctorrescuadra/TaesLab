# cReadModel Module

This module covers the complete model-reading pipeline used by TaesLab to transform external thermoeconomic data files into a validated [cDataModel](../Classes/cDataModel.m) object.

The module is organized around a common abstract reader, two intermediate branches for structured and tabular sources, concrete readers for each supported file format, and a table container used during validation.

## Purpose

The reader module makes the following tasks:

1. Load source data from a file or folder.
2. Normalize the raw content into MATLAB structures or table containers.
3. Validate the data against the expected model layout.
4. Build a [cModelData](../Classes/cModelData.m) intermediate object.
5. Convert that intermediate object into a validated [cDataModel](../Classes/cDataModel.m).

This separation keeps file-format details out of the thermoeconomic analysis layer and centralizes validation in one place.

## Module Hierarchy

The module is centered on [cReadModel](../Classes/cReadModel.m), which defines the shared properties and entry points for all readers.

### Base reader classes

- [cReadModel](../Classes/cReadModel.m): abstract base class shared by all model readers.
- [cReadModelStruct](../Classes/cReadModelStruct.m): base class for structured sources such as JSON and XML.
- [cReadModelTable](../Classes/cReadModelTable.m): base class for tabular sources such as XLSX and CSV.

### Concrete readers

- [cReadModelJSON](../Classes/cReadModelJSON.m): reads JSON model files.
- [cReadModelXML](../Classes/cReadModelXML.m): reads XML model files.
- [cReadModelXLS](../Classes/cReadModelXLS.m): reads XLSX workbooks.
- [cReadModelCSV](../Classes/cReadModelCSV.m): reads a directory of CSV files.

### Related validation container

- [cModelTable](../Classes/cModelTable.m): validates and stores one table read from XLSX or CSV.

## Data Flow

### Structured formats

Structured readers follow this path:

source file -> parser -> MATLAB struct -> [cReadModelStruct.buildModelData](../Classes/cReadModelStruct.m) -> [cModelData](../Classes/cModelData.m) -> [cDataModel](../Classes/cDataModel.m)

This path is used by JSON and XML readers.

### Tabular formats

Tabular readers follow this path:

workbook or CSV directory -> raw cells -> [cModelTable](../Classes/cModelTable.m) objects -> [cReadModelTable.buildModelData](../Classes/cReadModelTable.m) -> [cModelData](../Classes/cModelData.m) -> [cDataModel](../Classes/cDataModel.m)

This path is used by XLSX and CSV readers.

## Class Reference

### [cReadModel](../Classes/cReadModel.m)

Abstract base class for all readers.

Responsibilities:

- Stores source metadata in `ModelFile` and `ModelName`.
- Stores the intermediate `ModelData` object.
- Provides `getDataModel()` to convert the intermediate object into a [cDataModel](../Classes/cDataModel.m).
- Provides the protected `setModelProperties()` helper used by subclasses.

Typical use:

- Instantiate a concrete subclass.
- Check `isValid(obj)` after construction.
- Call `getDataModel()` when the reader object is valid.

### [cReadModelStruct](../Classes/cReadModelStruct.m)

Abstract branch for hierarchical, structured inputs.

Responsibilities:

- Converts a parsed MATLAB struct into a [cModelData](../Classes/cModelData.m) object.
- Centralizes the shared struct-to-model conversion logic.

Protected method:

- `buildModelData(data)`: creates the intermediate model object and merges validation messages when the object is invalid.

Concrete subclasses:

- [cReadModelJSON](../Classes/cReadModelJSON.m)
- [cReadModelXML](../Classes/cReadModelXML.m)

### [cReadModelTable](../Classes/cReadModelTable.m)

Abstract branch for tabular inputs.

Responsibilities:

- Reads configuration from `printformat.json`.
- Stores imported tables in `ModelTables`.
- Validates table content and assembles the structured data used by [cModelData](../Classes/cModelData.m).

Protected methods:

- `getDataModelConfig()`: loads the table layout definition.
- `buildModelData(tm)`: validates the imported tables and builds the intermediate model.
- `checkProductiveStructure(tm)`: validates `Flows` and `Processes` tables.
- `checkExergyTable(tm)`: validates the `Exergy` table and builds state data.
- `checkWasteDefinition(tm)`: validates optional waste-definition data.
- `checkResourcesCost(tm)`: validates optional resource-cost data.

Public method:

- `printModelTables()`: prints all loaded tables to the console.

Concrete subclasses:

- [cReadModelXLS](../Classes/cReadModelXLS.m)
- [cReadModelCSV](../Classes/cReadModelCSV.m)

### [cReadModelJSON](../Classes/cReadModelJSON.m)

Concrete JSON reader.

Behavior:

- Uses `importJSON()` to parse the file.
- Delegates model construction to `buildModelData()`.
- Relies on the shared file-metadata setup in `cReadModel`.

Platform support:

- MATLAB and Octave.

### [cReadModelXML](../Classes/cReadModelXML.m)

Concrete XML reader.

Behavior:

- Uses `readstruct()` to parse XML in MATLAB.
- Converts the parsed result through `jsonencode()` / `jsondecode()` to normalize the structure.
- Delegates model construction to `buildModelData()`.

Platform support:

- MATLAB only.
- On Octave, construction logs an error and returns an invalid object.

### [cReadModelXLS](../Classes/cReadModelXLS.m)

Concrete XLSX reader.

Behavior:

- Reads worksheet names from the workbook.
- Imports each configured sheet into a [cModelTable](../Classes/cModelTable.m).
- Skips optional sheets when they are missing.

Platform support:

- MATLAB: `sheetnames()` + `readcell()`.
- Octave: `xlsopen()` + `xls2oct()`.

### [cReadModelCSV](../Classes/cReadModelCSV.m)

Concrete CSV reader.

Behavior:

- Reads a folder descriptor file containing the directory path to the CSV tables.
- Imports each configured CSV file into a [cModelTable](../Classes/cModelTable.m).
- Skips optional files when they are missing.

Platform support:

- MATLAB: `readcell()`.
- Octave: `csv2cell()`.

### [cModelTable](../Classes/cModelTable.m)

Validated container for a single imported table.

Responsibilities:

- Stores the raw cell array, headers, data rows, and row keys.
- Validates field names and value types against the table definition from `printformat.json`.
- Provides table data in multiple representations for the reader pipeline.

Important methods:

- `getStructData()`: returns the data rows as a struct array.
- `getTableData()`: returns a [cTableData](../Classes/cTableData.m) object for display.
- `printTable()`: displays the table in console form.

## Configuration File

Tabular readers depend on the table configuration file `printformat.json`, located in the `Config` folder.

That configuration defines:

- expected table or sheet names,
- whether each section is optional,
- the ordered field list for each table,
- the declared datatype of each field.

The configuration is read by [cReadModelTable.getDataModelConfig](../Classes/cReadModelTable.m) and used to validate every imported table.

## Validation Model

Validation is intentionally layered.

### File-level validation

- Reader constructors verify that the source file or source folder can be accessed.
- XML reading is disabled on Octave.

### Table-level validation

- `cModelTable` checks missing values, field names, key patterns, numeric constraints, and sample blocks.
- `cReadModelTable` validates domain-specific table relationships, such as flow keys, process types, exergy keys, waste definitions, and resource-cost consistency.

### Model-level validation

- Successful table parsing produces [cModelData](../Classes/cModelData.m).
- The final call to `getDataModel()` converts that into [cDataModel](../Classes/cDataModel.m), which is the object used by the analysis layer.

## Error Handling Pattern

The reader classes do not fail silently.

- Construction errors are stored in the logger inherited from [cMessageLogger](../Classes/cMessageLogger.m).
- Validation problems are accumulated so the caller can inspect the full set of issues.
- Use `isValid(obj)` after constructing a reader object.
- Use `isValid(obj.getDataModel())` after converting to [cDataModel](../Classes/cDataModel.m).

## Typical Usage

### JSON

```matlab
reader = cReadModelJSON('Config/plant_model.json');
if isValid(reader)
    dataModel = reader.getDataModel();
end
```

### XML

```matlab
reader = cReadModelXML('Config/plant_model.xml');
if isValid(reader)
    dataModel = reader.getDataModel();
end
```

### XLSX

```matlab
reader = cReadModelXLS('Config/plant_model.xlsx');
if isValid(reader)
    reader.printModelTables();
    dataModel = reader.getDataModel();
end
```

### CSV

```matlab
reader = cReadModelCSV('Config/plant_model.csv');
if isValid(reader)
    reader.printModelTables();
   dataModel = reader.getDataModel();
end
```

## Notes For Maintainers

- Keep class names aligned with the `c` prefix convention used across TaesLab.
- Preserve the split between structured and tabular readers; it keeps parsing code and validation code manageable.
- Update `printformat.json` when adding or removing tables in the tabular readers.
- When adding a new reader format, follow the same pattern: parse source data, normalize it, validate it, and then build [cModelData](../Classes/cModelData.m).
