# TaesLab cTable Class Interface

## Overview

The `cTable` family provides a unified, layered system for storing and presenting tabular data in TaesLab. All table objects share a common interface — defined by the abstract base class `cTable` — that covers display, export, and persistence operations. Concrete subclasses specialize the storage layout and formatting rules to match the three kinds of tables that appear in the toolbox:

| Class | Kind of data | Concrete |
| :------------- | :------------- | :---------- |
| `cTable` | Base interface | No |
| `cTableData` | Raw input data (flows, processes, exergy states) | Yes |
| `cTableResult` | Computed results — base for the two result types | No |
| `cTableCell` | Mixed-type results (text + numbers per column) | Yes (Sealed) |
| `cTableMatrix` | Fully numeric matrix results (with optional totals) | Yes (Sealed) |
| `cTableIndex` | Result index/catalog table for a `cResultInfo` | Yes |

All classes inherit from `cMessageLogger`, so every table object carries a `status` flag and an internal message queue.

A parallel **table definition** hierarchy drives the construction of result tables at run time:

| Class | Role | Concrete |
| :------------- | :------------- | :---------- |
| `cTablesDefinition` | Registry of all table definitions read from `printformat.json` | Yes |
| `cFormatData` | Extends registry with per-variable format and unit resolution | Yes |
| `cResultTableBuilder` | Uses the registry to instantiate `cTableCell`/`cTableMatrix` objects | Yes (Sealed) |

---

## Inheritance Hierarchy

```text
cTaesLab
  └── cMessageLogger
        ├── cTable  (Abstract)
        │     ├── cTableData
        │     ├── cTableResult  (Abstract)
        │     │     ├── cTableCell  (Sealed)
        │     │     └── cTableMatrix  (Sealed)
        │     └── cTableIndex
        └── cTablesDefinition           ← table definition registry
              └── cFormatData           ← adds format / unit resolution
                    └── cResultTableBuilder  (Sealed)  ← builds cTable instances
```

The two branches are complementary: `cTablesDefinition` / `cFormatData` / `cResultTableBuilder` act as the **factory** that reads `printformat.json` and produces correctly configured `cTableCell` and `cTableMatrix` objects; those objects then conform to the `cTable` interface for display, export, and persistence.

---

## 1. `cTable` — Abstract Base Class

**File:** `Classes/cTable.m`

Abstract class that defines the common interface for all table types. It is not instantiated directly; use one of its concrete subclasses.

### 1.1 Properties

| Property | Access | Description |
| :--------- | :------- | :------------ |
| `NrOfCols` | public / protected | Number of columns |
| `NrOfRows` | public / protected | Number of rows |
| `RowNames` | public / protected | Row key codes (cell array of char) |
| `ColNames` | public / protected | Column header names (cell array of char) |
| `Data` | public / protected | Data values (cell array) |
| `Values` | public (computed) | Full table: `[ColNames; RowNames', Data]` |
| `Name` | public / protected | Internal table identifier |
| `Description` | public / protected | Human-readable header/title |
| `State` | public / protected | Operating state name associated with the data |
| `Sample` | public / protected | Resource cost sample name |
| `Resources` | public / protected | `true` when the table contains resource cost info |
| `GraphType` | public / protected | Graph type constant (`cType.GraphType.*`); `0` means no graph |

### 1.2 Methods

#### Display

| Method | Description |
| :------- | :------------ |
| `showTable(option)` | Display the table. `option` is one of `cType.TableView.{NONE, CONSOLE, GUI, HTML}`. Defaults to `CONSOLE`. |

#### Export / Save

| Method | Description |
| :------- | :------------ |
| `exportTable(varmode)` | Return the table data in the requested variable type. `varmode` is one of `cType.VarMode.{NONE, CELL, STRUCT, TABLE}`. `NONE` returns the `cTable` object itself. |
| `saveTable(filename)` | Write the table to a file. Format is determined by extension. Supported: `CSV`, `XLSX`, `JSON`, `XML`, `TXT`, `HTML`, `LaTeX`, `MD`, `MAT`. Returns a `cMessageLogger`. |

#### Data Access

| Method | Description |
| :------- | :------------ |
| `getProperties()` | Return a struct with `Name`, `Description`, `State`, `Sample`, `Resources`, `GraphType`. |
| `getStructData()` | Return data as a struct array; column names become field names. |
| `getMatlabTable()` | Return a MATLAB `table` object (MATLAB only; Octave returns the `cTable`). |
| `getStructTable()` | Return a struct containing `Name`, `Description`, `State`, and the struct-array data. |
| `getColumnValues(idx)` | Return data from column `idx` as a numeric array or cell array, depending on column type. |
| `getColumnFormat()` | Return the column format vector (`cType.ColumnFormat.{TEXT, NUMERIC}`). |
| `getColumnWidth()` | Return the maximum display width of each column. |
| `formatData()` | Return formatted data (base implementation returns raw `Data`; overridden in subclasses). |

#### Inspection / Mutation

| Method | Description |
| :------- | :------------ |
| `isNumericTable()` | `true` if all data columns are numeric. |
| `isNumericColumn(idx)` | `true` if column `idx` is numeric. |
| `isGraph()` | `true` if `GraphType ~= cType.GraphType.NONE`. |
| `setStudyCase(info)` | Set `State` and `Sample` from a struct with those fields. |
| `setDescription(descr)` | Update the table `Description`. |
| `setColumnValues(idx, values)` | Replace data in a column. |
| `setRowValues(idx, values)` | Replace data in a row. |
| `size(dim)` | Overloaded `size()` — operates on `Values` (includes header row/col). |

---

## 2. `cTableData` — Input Data Tables

**File:** `Classes/cTableData.m`

Stores raw model data: flow definitions, process definitions, exergy state values, resource cost tables, and similar input-layer information. Data cells may be either text or numeric with no per-column type metadata beyond what is inferred automatically.

### 2.1 Constructor

```matlab
obj = cTableData(data, rowNames, colNames, props)
```

| Argument | Type | Description |
| :--------- | :----- | :------------ |
| `data` | cell array | Table data (`NrOfRows × NrOfCols-1`) |
| `rowNames` | cell array of char | Row key labels |
| `colNames` | cell array of char | Column header labels (first element is the row-key column name) |
| `props` | struct | Additional properties: `Name`, `Description` |

### 2.2 Additional Methods

| Method | Description |
| :------- | :------------ |
| `create(values)` | Static — construct a `cTableData` from a full cell array (rows × cols, including headers). |
| `import(filename)` | Static — read a `cTableData` from a CSV or XLSX file. |
| `importMatlabTable(matlabTable)` | Static — convert a MATLAB `table` object into a `cTableData`. |
| `getStructTable()` | Overrides base: returns struct with `Name`, `Description`, `State`, and struct-array data. |
| `printTable()` | Print to the console with column-aligned formatting. |
| `formatData()` | Format numeric values as right-aligned strings for display. |
| `getDescriptionLabel()` | Return a display-ready title string for GUI contexts. |

### 2.3 Typical Usage

```matlab
% cTableData objects are created internally by cReadModel and cDataModel.
% To inspect one:
data = ReadDataModel('plant.json');
tbl  = data.Tables.flows;          % cTableData object
tbl.showTable;                     % print to console
s    = tbl.getStructData;          % struct array, one field per column
```

---

## 3. `cTableResult` — Abstract Result Base

**File:** `Classes/cTableResult.m`

Abstract intermediate class for computed-result tables. It adds per-column metadata (unit labels, format strings, node-type classification) and overrides `exportTable` to accept an optional format flag that controls whether numeric values are rendered as formatted strings.

### 3.1 Additional Properties

| Property | Description |
| :--------- | :------------ |
| `Format` | Cell array of format strings for each data column (e.g., `'%10.4f'`). |
| `Unit` | Cell array of unit labels for each data column (e.g., `'kW'`). |
| `NodeType` | Integer encoding the kind of row key (`cType.NodeType.*`): flow, process, stream, etc. |

### 3.2 Overridden / Added Methods

| Method | Description |
| :------- | :------------ |
| `exportTable(varmode, fmt)` | Extended signature: `fmt` (`true`/`false`) controls formatted vs. raw numeric output. |
| `getCellData(fmt)` | Return the full table as a cell array, optionally with formatted values. |
| `getProperties()` | Return both inherited and result-specific properties as a struct. |

---

## 4. `cTableCell` — Mixed-Type Result Tables

**File:** `Classes/cTableCell.m`  
**Inheritance:** `cTableResult → cTable → cMessageLogger`  
**Modifier:** Sealed (cannot be subclassed)

Stores results tables that mix text and numeric columns, such as process efficiency tables, summary descriptions, or cost breakdown lists. Each column has its own data type, format string, and unit label.

### 4.1 Additional Properties

| Property | Description |
| :--------- | :------------ |
| `DataType` | Integer array — one entry per data column indicating the column's type (`cType.ColumnFormat.*`). |
| `FieldNames` | Optional cell array of programmatic field names for the data columns (used in `getColumnValues`). |
| `ShowNumber` | Logical — when `true`, a leading line-number column is printed. |

### 4.2 Constructor

```matlab
obj = cTableCell(data, rowNames, colNames, props)
```

`props` fields (in addition to the base ones):

| Field | Description |
| :------ | :------------ |
| `DataType` | Array with `cType.ColumnFormat` value for each column |
| `Unit` | Cell array of unit labels |
| `Format` | Cell array of format strings |
| `GraphType` | Associated graph type |
| `FieldNames` | Optional programmatic column names |
| `ShowNumber` | Whether to display row numbers |
| `NodeType` | Type of row key identifier |

### 4.3 Additional Methods

| Method | Description |
| :------- | :------------ |
| `formatData()` | Apply per-column format strings to numeric data; return formatted cell array. |
| `getMatlabTable()` | Overrides base to preserve `DataType` and `Unit` as custom table properties. |
| `getStructData(fmt)` | Return struct array; optionally apply formatting. |
| `getStructTable()` | Return full struct including format metadata. |
| `getDescriptionLabel()` | Return display-ready title for GUI. |
| `getColumnValues(name)` | Retrieve a column by its `FieldName` rather than by index. |
| `printTable(fid)` | Print formatted table to console or to an open file identifier. |

### 4.4 Typical Usage

```matlab
% cTableCell objects appear in ExergyAnalysis, ThermoeconomicAnalysis, etc.
res  = ExergyAnalysis(data);
tbl  = res.Tables.pex;             % cTableCell — process exergy table
tbl.showTable;
m    = tbl.getMatlabTable;         % MATLAB table with units/format metadata
```

---

## 5. `cTableMatrix` — Numeric Matrix Result Tables

**File:** `Classes/cTableMatrix.m`  
**Inheritance:** `cTableResult → cTable → cMessageLogger`  
**Modifier:** Sealed (cannot be subclassed)

Stores fully numeric matrix results such as FP adjacency matrices, cost allocation tables, and diagnosis malfunction matrices. Supports optional row and column total summation and carries graph-display options used by `ShowGraph`.

### 5.1 Additional Properties

| Property | Description |
| :--------- | :------------ |
| `GraphOptions` | Bit-field encoding display options for the associated graph (`cType.GraphOptions.*`). |
| `SummaryType` | Constant identifying the summary aggregation type (`cType.SummaryType.*`). |
| `RowTotal` | `true` when a "Total" row is appended by the constructor. |
| `ColTotal` | `true` when a "Total" column is appended by the constructor. |

### 5.2 Constructor

```matlab
obj = cTableMatrix(data, rowNames, colNames, props)
```

`props` fields (in addition to the base ones):

| Field | Description |
| :------ | :------------ |
| `RowTotal` | `true` to compute and append a row of column sums |
| `ColTotal` | `true` to compute and append a column of row sums |
| `Unit` | Unit label for all data cells |
| `Format` | Format string for all data cells |
| `GraphType` | Associated graph type |
| `GraphOptions` | Graph display option flags |
| `SummaryType` | Summary aggregation type |

When both `RowTotal` and `ColTotal` are `true`, the grand-total cell `(end,end)` is set to zero to avoid double-counting.

### 5.3 Additional Methods

| Method | Description |
| :------- | :------------ |
| `getMatrixValues()` | Return the data portion as a plain numeric matrix. |
| `getStructData(fmt)` | Return struct array; optionally format values. |
| `getMatlabTable()` | MATLAB `table` with row names and custom properties. |
| `getStructTable()` | Struct with data plus format metadata. |
| `getDescriptionLabel()` | Display-ready title for GUI. |
| `printTable(fid)` | Print matrix to console or file with right-aligned numeric columns. |
| `isUnitCostTable()` | `true` when `GraphOptions` marks the table as a unit-cost table. |
| `isFlowsTable()` | `true` when `GraphOptions` marks the table as a flows table. |
| `isGeneralCostTable()` | `true` when `GraphOptions` marks the table as a general-cost table. |
| `isTotalMalfunctionCost()` | `true` when `GraphOptions` marks the table as a total malfunction cost table. |

### 5.4 Typical Usage

```matlab
% cTableMatrix objects appear in ThermoeconomicAnalysis, ThermoeconomicDiagnosis, etc.
res = ThermoeconomicAnalysis(data);
tbl = res.Tables.tfp;              % cTableMatrix — FP table
tbl.showTable;
M   = tbl.getMatrixValues;         % plain double matrix
```

---

## 6. `cTableIndex` — Result Index Table

**File:** `Classes/cTableIndex.m`  
**Inheritance:** `cTable → cMessageLogger`

A read-only catalog table automatically built from a `cResultInfo` object. Each row represents one result table: its key name, description, and whether it has an associated graph. Used by `ListResultTables` and the GUI panels to enumerate available tables.

### 6.1 Additional Properties

| Property | Description |
| :--------- |: ------------ |
| `Content` | Cell array of the actual `cTable` objects from the parent `cResultInfo`. |
| `Info` | Handle to the `cResultId` Info object of the parent result. |

### 6.2 Constructor

```matlab
obj = cTableIndex(res)
```

| Argument | Type | Description |
| :--------- | :----- | :------------ |
| `res` | `cResultInfo` | Source result container |

The three displayed columns are:

| Column | Content |
| :------- | :-------- |
| `Key` | Table name (identifier used in `res.Tables.<Key>`) |
| `Description` | Table description string |
| `Graph` | `'true'` or `'false'` — whether a graph can be plotted |

### 6.3 Additional Methods

| Method | Description |
| :------- | :------------ |
| `printTable(fid)` | Print the index to console or file. |
| `getDescriptionLabel()` | Return `"<ResultName> - Table Index"` for GUI display. |

### 6.4 Typical Usage

```matlab
res = ExergyAnalysis(data);
idx = cTableIndex(res);    % built automatically inside ListResultTables
idx.showTable;
```

---

## 7. Table Definition System

The classes described in this section are not part of the `cTable` hierarchy, but they are closely related: they act as the configuration-driven **factory** that constructs all result `cTable` objects. Understanding this layer explains where column formats, unit labels, graph types, and description strings come from.

### 7.1 `cTablesDefinition` — Table Registry

**File:** `Classes/cTablesDefinition.m`  
**Inheritance:** `cMessageLogger`

Loads `printformat.json` (located in `Config/`) at construction time and provides a queryable registry of every result table defined in TaesLab. The registry records each table's name, description, type (`TABLE`, `MATRIX`, or `SUMMARY`), associated `ResultId`, graph flag, and code name. It also exposes the raw configuration arrays used by `cFormatData` and `cResultTableBuilder` to create `cTable` objects with correct properties.

#### Protected Properties

| Property | Description |
| :--------- | :------------ |
| `cfgDataModel` | Configuration array for data model tables |
| `cfgTables` | Configuration array for cell (`cTableCell`) tables |
| `cfgMatrices` | Configuration array for matrix (`cTableMatrix`) tables |
| `cfgSummary` | Configuration array for summary tables |
| `cfgTypes` | Format type configuration (width, precision, unit per variable type) |
| `tDictionary` | `cDataset` that maps table names to internal indices |
| `tableIndex` | Struct array with per-table metadata |
| `tableNames` | Cell array of all registered table names |
| `tDirectory` | Cell matrix backing `getTablesDirectory` |

#### Constructor

```matlab
obj = cTablesDefinition()
```

No arguments. Reads and parses `Config/printformat.json` automatically. After construction, check `obj.status` before use.

#### Methods

| Method | Description |
| :------- | :------------ |
| `getTablesDirectory(cols)` | Return a `cTableData` listing all registered tables. `cols` selects which columns to include (`DESCRIPTION`, `RESULT_NAME`, `GRAPH`, `TYPE`, `CODE`, `RESULT_CODE`). Prints to console when called with no output argument. |
| `getTableInfo(name)` | Return a struct with the metadata of a single table: `Name`, `Description`, `TableCode`, `ResultId`, `TableType`, `Graph`. |
| `getTableDefinition(name)` | Return the raw configuration struct for a table (cell, matrix, or summary entry from `printformat.json`). |
| `getTableId(name)` | Return the internal numeric index of a table by name. |
| `getResultIdTables(id)` | Return a cell array of all table names that belong to a given `ResultId`. |
| `getDataModelProperties(idx)` | Return data-model table configuration (all entries, or just index `idx`). |
| `getCellTables(idx)` | Return cell-table configuration (all entries, or just index `idx`). |
| `getMatrixTables(idx)` | Return matrix-table configuration (all entries, or just index `idx`). |
| `getSummaryTables(option, rsc)` | Return summary-table configuration filtered by `cType.SummaryId.{ALL, STATES, RESOURCES}` and whether resource tables are included. |

#### Typical Usage

```matlab
% Inspect all registered tables
reg = cTablesDefinition();
reg.getTablesDirectory;                    % prints full directory to console
reg.getTablesDirectory({'DESCRIPTION','GRAPH'});  % selected columns only

% Query a specific table
info = reg.getTableInfo('pex');
fprintf('Result: %s  |  Graph: %s\n', info.ResultId, mat2str(info.Graph));

% List all tables for a given ResultId
names = reg.getResultIdTables(cType.ResultId.EXERGY);
```

---

### 7.2 `cFormatData` — Format and Unit Resolution

**File:** `Classes/cFormatData.m`  
**Inheritance:** `cTablesDefinition → cMessageLogger`

Extends `cTablesDefinition` by resolving format strings and unit labels for each variable type. It is initialised from the `Format` section of the data model (read from the input file), which allows the user to override default widths and precisions on a per-model basis.

#### cFormatData Constructor

```matlab
obj = cFormatData(data)
```

| Argument | Type | Description |
| :--------- | :----- | :------------ |
| `data` | struct | Format definitions struct from `cModelData` (must contain a `definitions` field with entries for `key`, `width`, `precision`, `unit`) |

#### Methods (in addition to those inherited from `cTablesDefinition`)

| Method | Description |
| :------- | :------------ |
| `getFormat(id)` | Return the C-style format string (e.g., `'%12.4f'`) for variable type `id` (`cType.Format.*`). |
| `getUnit(id)` | Return the unit label string (e.g., `'kW'`) for variable type `id`. |
| `getResultId(table)` | Return the `ResultId` constant for the table named `table`. |
| `getTableProperties(name)` | Return a complete `props` struct ready to pass to a `cTableCell` or `cTableMatrix` constructor — name, description, format, unit, graph type, etc. |

---

### 7.3 `cResultTableBuilder` — Table Factory

**File:** `Classes/cResultTableBuilder.m`  
**Inheritance:** `cFormatData → cTablesDefinition → cMessageLogger`  
**Modifier:** Sealed

The concrete factory that uses the registry and format data to instantiate the actual `cResultInfo` objects returned by every analysis function. It is constructed once per data model (inside `cThermoeconomicModel`) and called by all calculation modules (`cExergyModel`, `cExergyCost`, `cDiagnosis`, etc.).

#### cResultTableBuilder Constructor

```matlab
obj = cResultTableBuilder(ps, data)
```

| Argument | Type | Description |
| :--------- | :----- | :------------ |
| `ps` | `cProductiveStructure` | Provides flow, stream, process, and resource key names |
| `data` | `cModelData` | Provides the format definitions passed to `cFormatData` |

#### cResultTable Builder Methods

| Method | Description |
| :------- | :------------ |
| `getProductiveStructure(ps)` | Build and return a `cResultInfo` (`PRODUCTIVE_STRUCTURE`) containing flow, stream, and process `cTableCell` tables. |
| `getExergyResults(em)` | Build and return a `cResultInfo` (`EXERGY`) from a `cExergyModel` object. |
| `getCostResults(ec)` | Build and return a `cResultInfo` (`THERMOECONOMIC`) from a `cExergyCost` object. |
| `getDiagnosisResults(dg)` | Build and return a `cResultInfo` (`DIAGNOSIS`) from a `cDiagnosis` object. |
| `getDiagramFP(dfp)` | Build and return a `cResultInfo` (`DIAGRAM_FP`) from a `cDiagramFP` object. |
| `getProductiveDiagram(pd)` | Build and return a `cResultInfo` (`PRODUCTIVE_DIAGRAM`) from a `cProductiveDiagram` object. |
| `getSummaryResults(sr)` | Build and return a `cResultInfo` (`SUMMARY`) from a `cSummaryResults` object. |

#### Relationship to `cTable`

Every `get*Results` method follows the same internal pattern:

1. Retrieve table definitions from the inherited `cTablesDefinition` registry.
2. Resolve format/unit strings via `cFormatData.getFormat` / `getUnit`.
3. Assemble the `props` struct with the definition data.
4. Call `cTableCell(...)` or `cTableMatrix(...)` constructors to create concrete table objects.
5. Package the tables into a `cResultInfo` and return it.

```text
printformat.json
      │
      ▼
cTablesDefinition  ──► cFormatData  ──► cResultTableBuilder
                                               │
                              ┌────────────────┼────────────────┐
                              ▼                ▼                ▼
                         cTableCell      cTableMatrix      cTableData
                              └────────────────┴────────────────┘
                                               │
                                          cResultInfo
```

---

## 8. Common Usage Patterns

### Displaying a Table

```matlab
tbl.showTable;                         % console (default)
tbl.showTable(cType.TableView.HTML);   % HTML viewer
tbl.showTable(cType.TableView.GUI);    % MATLAB uitable GUI
```

### Exporting Data

```matlab
% As cell array
C = tbl.exportTable(cType.VarMode.CELL);

% As struct array
S = tbl.exportTable(cType.VarMode.STRUCT);

% As MATLAB table (MATLAB only)
T = tbl.exportTable(cType.VarMode.TABLE);
```

### Saving to File

```matlab
log = tbl.saveTable('results.xlsx');   % Excel
log = tbl.saveTable('results.csv');    % CSV
log = tbl.saveTable('results.html');   % HTML
log = tbl.saveTable('results.json');   % JSON
log = tbl.saveTable('results.tex');    % LaTeX
log = tbl.saveTable('results.md');     % Markdown
```

### Checking Table Capabilities

```matlab
tbl.isGraph          % true → can be passed to ShowGraph
tbl.isNumericTable   % true → all columns are numeric
tbl.isNumericColumn(3) % true → column 3 is numeric
```

---

## 9. Export Format Support

All `cTable` objects support the same set of output formats through `saveTable`:

| Extension | Format | Builder class | Notes |
| :---------- | :------- | :-------------- | :------ |
| `.csv` | CSV | _(built-in)_ | One file per table |
| `.xlsx` | Excel | _(built-in)_ | One sheet per table |
| `.json` | JSON | _(built-in)_ | Structured object |
| `.xml` | XML | _(built-in)_ | Element-based |
| `.txt` | Plain text | _(built-in)_ | Console-style layout |
| `.html` | HTML | `cBuildHTML` | Styled with `styles.css` |
| `.tex` | LaTeX | `cBuildLaTeX` | `tabular` environment with `booktabs` |
| `.md` | Markdown | `cBuildMarkdown` | GitHub-flavoured pipe table |
| `.mat` | MATLAB binary | _(built-in)_ | `cTable` object serialised |

The three text-markup formats (HTML, LaTeX, Markdown) are handled by dedicated builder classes that can also be used directly when fine-grained control over the generated markup is needed.

---

### 9.1 `cBuildHTML` — HTML Table Builder

**File:** `Classes/cBuildHTML.m`  
**Inheritance:** `cMessageLogger`  
**Modifier:** Sealed

Converts a `cTable` object into a self-contained HTML page. When given a `cTableIndex` together with an output folder it builds an index page that links to the individual HTML files for every table in the result set.

#### cBuildHTML Constructor

```matlab
obj = cBuildHTML(tbl)           % single table → standalone HTML page
obj = cBuildHTML(index, folder) % cTableIndex → index page with links
```

| Argument | Type | Description |
| :--------- | :----- | :------------ |
| `tbl` | `cTable` or `cTableIndex` | Table to convert |
| `folder` | char | Output folder (only when `tbl` is a `cTableIndex`) |

#### cBuildHTML Methods

| Method | Description |
| :------- | :------------ |
| `getMarkupHTML()` | Return the complete HTML page as a character string |
| `showTable()` | Open the HTML page in the system default web browser (single-table mode only) |
| `saveTable(filename)` | Write the HTML to `filename`; returns a `cMessageLogger` with status |

The generated page embeds the CSS stylesheet from `Config/styles.css` inline so that the file is fully self-contained. When operating in index mode, `showTable` is a no-op; call `saveTable` to write the linked index file.

#### cBuildHTML Typical Usage

```matlab
tbl = res.getTable('pex');
b   = cBuildHTML(tbl);
b.showTable;                     % preview in browser
log = b.saveTable('pex.html');   % write to disk
```

---

### 9.2 `cBuildLaTeX` — LaTeX Table Builder

**File:** `Classes/cBuildLaTeX.m`  
**Inheritance:** `cMessageLogger`  
**Modifier:** Sealed

Converts a `cTable` object into a LaTeX `table` / `tabular` environment using the `booktabs` package for professional horizontal rules. Column alignment (left for text, right for numeric) is determined automatically from `getColumnFormat()`.

#### cBuildLaTeX Constructor

```matlab
obj = cBuildLaTeX(tbl)
```

| Argument | Type | Description |
| :--------- | :----- | :------------ |
| `tbl` | `cTable` | Table to convert |

#### Generated LaTeX structure

```latex
\begin{table}[H]
  \caption{<Description — State/Sample>}
  \label{tab:<Name>}
  \begin{tabular}{ll...r...}
    \toprule
    ColName1 & ColName2 & ... \\
    \midrule
    row1_key & val1 & ... \\
    ...
    \bottomrule
  \end{tabular}
\end{table}
```

#### cBuildLaTeX Methods

| Method | Description |
| :------- | :------------ |
| `getLaTeXcode()` | Return the complete LaTeX snippet as a character string |
| `saveTable(filename)` | Write the LaTeX code to `filename` (`.tex`); returns a `cMessageLogger` |

#### cBuildLaTeX Typical Usage

```matlab
tbl = res.getTable('dcost');
b   = cBuildLaTeX(tbl);
disp(b.getLaTeXcode);            % inspect generated code
log = b.saveTable('dcost.tex');  % write to disk
```

---

### 9.3 `cBuildMarkdown` — Markdown Table Builder

**File:** `Classes/cBuildMarkdown.m`  
**Inheritance:** `cMessageLogger`  
**Modifier:** Sealed

Converts a `cTable` object into a GitHub-flavoured Markdown pipe table. Column alignment markers (`:-` for left, `-:` for right) are inserted automatically in the separator row based on `getColumnFormat()`. An optional bold caption derived from `getDescriptionLabel()` is prepended when the table has a non-empty `Description`.

#### cBuildMarkdown Constructor

```matlab
obj = cBuildMarkdown(tbl)
```

| Argument | Type | Description |
| :--------- | :----- | :------------ |
| `tbl` | `cTable` | Table to convert |

#### Generated Markdown structure

```markdown
**Description — State/Sample**

| ColName1   | ColName2   | ... |
| :--------- | ---------: | ... |
| row1_key   |      val1  | ... |
```

#### cBuildMarkdown Methods

| Method | Description |
| :------- | :------------ |
| `getMarkdownCode()` | Return the complete Markdown snippet as a character string |
| `saveTable(filename)` | Write the Markdown to `filename` (`.md`); returns a `cMessageLogger` |

#### cBuildMarkdown Usage

```matlab
tbl = res.getTable('pex');
b   = cBuildMarkdown(tbl);
disp(b.getMarkdownCode);         % inspect generated markup
log = b.saveTable('pex.md');     % write to disk
```

---

### 9.4 `cViewTable` — GUI Table Viewer

**File:** `Classes/cViewTable.m`  
**Inheritance:** `cTaesLab`  
**Modifier:** Sealed

A lightweight MATLAB figure-based viewer called automatically by `cTable.showTable` when the `GUI` option is selected. It reads the column widths, column formats, row names, and formatted data directly from the `cTable` API to configure a `uitable` component.

#### `cTable` properties it reads

| `cTable` call | Purpose |
| :------------- |: -------- |
| `tbl.getColumnWidth()` | Set `ColumnWidth` for each column |
| `tbl.getColumnFormat()` | Set `ColumnFormat` for each column |
| `tbl.RowNames` | Set `RowName` property of the `uitable` |
| `tbl.ColNames(2:end)` | Set `ColumnName` of the `uitable` |
| `tbl.formatData()` | Populate `Data` property with display-ready values |
| `tbl.getDescriptionLabel()` | Set the figure title bar text |

#### cViewTable Constructor

```matlab
obj = cViewTable(tbl)   % tbl is any cTable object
obj.showTable;          % renders the uitable window
```

This class is not called directly by users; it is invoked internally by `cTable.showTable(cType.TableView.GUI)`.

---

## 10. Classes That Use the `cTable` Interface

The classes in this section are **consumers** of `cTable` objects. They do not extend `cTable`; instead they hold, route, or render table objects to provide the display, export, save, and GUI capabilities visible to the end user.

### 10.1 `cResultSet` — Abstract Result Container

**File:** `Classes/cResultSet.m`  
**Inheritance:** `cResultId → cMessageLogger`  
**Abstract:** Yes

`cResultSet` is the common base for every class that exposes a collection of `cTable` objects. It defines a uniform API so that Base functions (`ShowResults`, `SaveResults`, `ExportResults`, etc.) can operate on any result container without knowing its concrete type.

Three concrete subclasses implement `cResultSet`:

| Class | Role |
| :------ | :----- |
| `cResultInfo` | Single-analysis-type result container |
| `cDataModel` | Data model tables (input data) |
| `cThermoeconomicModel` | Full model with all analysis results |

#### `cResultSet` Interface for `cTable` Consumers

| Method | `cTable` interaction |
| :------- | :-------------------- |
| `ListOfTables()` | Calls `fieldnames(res.Tables)` — returns names of all contained `cTable` objects |
| `ListOfGraphs()` | Calls `tbl.isGraph()` on every table; returns names of tables with a graph |
| `getTableIndex()` | Returns the `cTableIndex` object (itself a `cTable`) built from all contained tables |
| `printResults()` | Calls `tbl.showTable(CONSOLE)` on every `cTable` in the container |
| `showResults(name, option)` | Calls `tbl.showTable(option)` on the named `cTable` |
| `showGraph(name)` | Reads `tbl.GraphType` to select and launch the correct graph renderer |
| `showTableIndex(option)` | Calls `cTableIndex.showTable(option)` |
| `exportResults(varmode, fmt)` | Calls `tbl.exportTable(varmode, fmt)` on every `cTable`; returns struct of converted values |
| `exportTable(name, varmode, fmt)` | Calls `tbl.exportTable(varmode, fmt)` on a single named `cTable` |
| `saveResults(filename)` | Calls `tbl.saveTable(filename)` on every `cTable` |
| `saveTable(name, filename)` | Calls `tbl.saveTable(filename)` on the named `cTable` |
| `getTable(name)` | Returns the named `cTable` object directly |

---

### 10.2 `cResultInfo` — Single-Analysis Result Set

**File:** `Classes/cResultInfo.m`  
**Inheritance:** `cResultSet → cResultId → cMessageLogger`

Holds the complete set of `cTable` objects produced by one analysis run (e.g., all exergy tables, or all thermoeconomic cost tables). Every analysis Base function (`ExergyAnalysis`, `ThermoeconomicAnalysis`, etc.) returns a `cResultInfo`.

#### Key Properties

| Property | Type | Description |
| :--------- | :----- | :------------ |
| `Tables` | struct | Named struct of `cTable` objects (`Tables.pex`, `Tables.tfp`, …) |
| `NrOfTables` | double | Number of tables held |
| `Info` | `cResultId` | Metadata about the analysis type, state, sample, model name |

#### Additional Methods

| Method | Description |
| :------- |: ------------ |
| `cResultInfo(info, tables)` | Constructor — takes a `cResultId` and a named struct of `cTable` objects; builds the internal `cTableIndex` |
| `getResultInfo()` | Return `self` (satisfies the `cResultSet` abstract requirement) |
| `getTable(name)` | Return the `cTable` object for the given key name |
| `getTableIndex()` | Return the auto-built `cTableIndex` (a `cTable` listing all tables) |
| `summaryDiagnosis()` | Return diagnosis summary information |
| `summaryTables()` | Return available summary table names |
| `isStateSummary()` | Check if state-based summary tables are present |
| `isSampleSummary()` | Check if sample-based summary tables are present |

#### cResultInfo Usage

```matlab
res = ExergyAnalysis(data);          % returns cResultInfo
res.ListOfTables                     % {'pex','fex','irr',...}
tbl = res.Tables.pex;                % direct cTable access
tbl = res.getTable('pex');           % via method
res.showResults('pex');              % display one table
res.saveResults('exergy.xlsx');      % save all tables to Excel
```

---

### 10.3 `cDataModel` — Data Model Result Set

**File:** `Classes/cDataModel.m`  
**Inheritance:** `cResultSet → cResultId → cMessageLogger`

The central data hub of TaesLab. As a `cResultSet` subclass it exposes the input data tables (flows, processes, exergy states, resource costs) through the standard `cTable` interface, so they can be inspected, exported, and saved the same way as computed result tables.

#### `cTable`-Related Methods beyond `cResultSet`

| Method | Description |
| : ------- |: ------------ |
| `getTablesDirectory(cols)` | Delegate to `cFormatData.getTablesDirectory` — returns a `cTableData` listing all known result tables in the toolbox |
| `getTableInfo(name)` | Delegate to `cFormatData.getTableInfo` — returns metadata struct for a table by name |
| `showDataModel(option)` | Show the data model tables in the selected view mode |
| `saveDataModel(filename)` | Save data model tables to file |

#### cDataMoel Usage

```matlab
data = ReadDataModel('plant.json');
data.showResults;                        % print all input tables to console
tbl = data.getTable('flows');            % get the flows cTableData
data.saveResults('data_model.xlsx');     % save all input tables
data.getTablesDirectory;                 % print full toolbox table catalog
```

---

### 10.4 `cThermoeconomicModel` — Main Model Class

**File:** `Classes/cThermoeconomicModel.m`  
**Inheritance:** `cResultSet → cResultId → cMessageLogger`  
**Modifier:** Sealed

The top-level class of TaesLab. Each analysis method runs a computation and returns a `cResultInfo` containing the relevant `cTable` objects. As a `cResultSet` itself, `cThermoeconomicModel` also aggregates all results so the complete model can be saved or exported in one call.

#### Analysis Methods (each returns a `cResultInfo` of `cTable` objects)

| Method | `ResultId` | Description |
| :------- | :----------- | :------------ |
| `productiveStructure()` | `PRODUCTIVE_STRUCTURE` | Flow, stream, and process definition tables |
| `exergyAnalysis()` | `EXERGY` | Per-flow and per-process exergy tables |
| `productiveDiagram()` | `PRODUCTIVE_DIAGRAM` | Graph adjacency tables for productive structure |
| `diagramFP()` | `DIAGRAM_FP` | Annotated FP diagram tables |
| `thermoeconomicAnalysis()` | `THERMOECONOMIC` | Direct and generalized cost tables |
| `thermoeconomicDiagnosis()` | `DIAGNOSIS` | Malfunction and dysfunction tables |
| `wasteAnalysis()` | `WASTE` | Waste recycling cost tables |
| `summaryResults()` | `SUMMARY` | Multi-state / multi-sample comparison tables |
| `dataInfo()` | `DATA_MODEL` | Data model input tables |

#### Table Navigation Methods

| Method | Description |
| :------- | :------------ |
| `getTable(name)` | Search across all active `cResultInfo` objects and return the named `cTable` |
| `getTableInfo(name)` | Return the registry metadata for a table (delegates to `cFormatData`) |
| `getTablesDirectory()` | Return a `cTableData` listing all tables available for the current model configuration |
| `showTablesDirectory(option)` | Display the table directory in the selected view mode |

#### Show tables usage

```matlab
model = ThermoeconomicModel('plant.json');

% Compute and inspect results
costs = model.thermoeconomicAnalysis();   % cResultInfo
costs.showResults('dcost');               % display direct cost table

% Access a table from the model directly
tbl = model.getTable('dcost');            % searches all active result sets
tbl.showTable;

% Save everything
model.saveResults('all_results.xlsx');
```

---

### 10.5 Base Functions That Operate on `cTable` Objects

These functions in `Base/` accept `cResultSet` objects (which contain `cTable` collections) or individual `cTable` objects and delegate to the `cTable` interface methods.

| Function | Accepts | `cTable` methods used |
| :--------- | :-------- | :---------------------- |
| `ShowTable(tbl, …)` | Single `cTable` | `showTable`, `exportTable`, `saveTable` |
| `SaveTable(tbl, filename)` | Single `cTable` | `saveTable` |
| `ShowResults(res, …)` | `cResultSet` | `getTable`, `showTable` per table |
| `SaveResults(res, filename)` | `cResultSet` | `saveTable` per table, `saveResults` |
| `ExportResults(res, …)` | `cResultSet` | `exportTable` per table or for a named table |
| `ListResultTables(res, …)` | `cResultSet` or none | `getTablesDirectory`, `cTableIndex.showTable` |
| `ShowGraph(res, …)` | `cResultSet` | `isGraph`, `GraphType`, `GraphOptions` per table |

#### Typical patterns

```matlab
% Individual table operations
tbl = model.getTable('dcost');
ShowTable(tbl, 'View', 'HTML');
SaveTable(tbl, 'direct_costs.xlsx');

% Result-set-level operations
res = model.thermoeconomicAnalysis();
ShowResults(res, 'Table', 'dcost', 'View', 'CONSOLE');
SaveResults(res, 'thermo_results.xlsx');
S = ExportResults(res, 'ExportAs', 'STRUCT');

% Table catalog
ListResultTables(model);                          % all available tables
ListResultTables(model, 'Columns', {'DESCRIPTION','GRAPH'});
```

---

## See Also

- `cResultInfo` — container that holds a collection of `cTable` objects for a single analysis type  
- `cResultSet` — base class for objects that expose a set of `cResultInfo` results  
- `cTablesDefinition` — registry of all table definitions; queries available via `getTableInfo`, `getTablesDirectory`  
- `cFormatData` — extends the registry with per-variable format and unit strings  
- `cResultTableBuilder` — constructs concrete `cTable` instances from calculation-layer results  
- `Config/printformat.json` — JSON configuration file that defines all result tables, formats, and graph types  
- `ShowTable`, `SaveTable` — Base functions that call `showTable` / `saveTable` on behalf of the user  
- `ExportResults` — exports all tables from a result set to MATLAB workspace variables  
- `cType.TableView`, `cType.VarMode`, `cType.GraphType` — enumeration constants used by `cTable` methods
