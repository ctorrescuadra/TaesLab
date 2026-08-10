# TaesLab — Class Dependencies Reference

> Analysis of `Classes/` directory.

---

## Table of Contents

- [TaesLab — Class Dependencies Reference](#taeslab--class-dependencies-reference)
  - [Table of Contents](#table-of-contents)
  - [1. Inheritance Hierarchy](#1-inheritance-hierarchy)
  - [2. Layer Overview](#2-layer-overview)
  - [3. Layer-by-Layer Reference](#3-layer-by-layer-reference)
    - [3.1 Foundation Layer](#31-foundation-layer)
    - [3.2 Utility / Collection Layer](#32-utility--collection-layer)
    - [3.3 Logging Layer](#33-logging-layer)
    - [3.4 Table Registry Layer](#34-table-registry-layer)
    - [3.5 Table Presentation Layer](#35-table-presentation-layer)
    - [3.6 Input Reading Layer](#36-input-reading-layer)
    - [3.7 Domain Data Structures Layer](#37-domain-data-structures-layer)
    - [3.8 Result Identity Layer](#38-result-identity-layer)
    - [3.9 Computation Layer](#39-computation-layer)
    - [3.10 Result Container Layer](#310-result-container-layer)
    - [3.11 Central Data Hub](#311-central-data-hub)
    - [3.12 Top-Level Analysis Engine](#312-top-level-analysis-engine)
    - [3.13 Graph / Visualization Layer](#313-graph--visualization-layer)
    - [3.14 Export / Presentation Layer](#314-export--presentation-layer)
  - [4. Composition \& Dependency Map](#4-composition--dependency-map)
  - [5. Dependency Matrix](#5-dependency-matrix)
    - [**Dependency Bottlenecks**](#dependency-bottlenecks)
    - [**Circular Dependencies** (Managed)](#circular-dependencies-managed)
  - [Optimization Opportunities](#optimization-opportunities)
    - [**Classes for cTaesLab Conversion**](#classes-for-ctaeslab-conversion)
    - [**Dependency Reduction Strategies**](#dependency-reduction-strategies)
  - [System Integration Points](#system-integration-points)
    - [**External Dependencies**](#external-dependencies)
    - [**Internal Coupling**](#internal-coupling)

---

## 1. Inheritance Hierarchy

```text
handle  (MATLAB built-in)
└── cTaesLab
    ├── cQueue
    ├── cSparseRow
    ├── cSummaryOptions
    ├── cSummaryTable
    ├── cViewTable
    └── cMessageLogger
        ├── cDictionary
        │   └── cDataset
        ├── cDigraphAnalysis
        ├── cExergyData
        ├── cWasteData
        ├── cResourceData
        ├── cModelData          [Sealed]
        ├── cModelTable         [Sealed]
        ├── cModelResults       [Sealed]
        ├── cTablesDefinition
        │   └── cFormatData
        │       └── cResultTableBuilder  [Sealed]
        ├── cGraphResults       [Abstract]
        │   ├── cDigraph
        │   ├── cGraphCost
        │   ├── cGraphCostRSC
        │   ├── cGraphDiagnosis
        │   ├── cGraphDiagramFP
        │   ├── cGraphRecycling
        │   ├── cGraphSummary
        │   └── cGraphWaste
        ├── cBuildHTML          [Sealed]
        ├── cBuildLaTeX         [Sealed]
        ├── cBuildMarkdown      [Sealed]
        ├── cTable              [Abstract]
        │   ├── cTableData
        │   ├── cTableIndex
        │   └── cTableResult    [Abstract]
        │       ├── cTableCell  [Sealed]
        │       └── cTableMatrix[Sealed]
        └── cResultId           [Abstract]
            ├── cProductiveStructure [Sealed]
            ├── cExergyModel
            │   └── cExergyCost      [Sealed]
            ├── cDiagnosis           [Sealed]
            ├── cWasteAnalysis       [Sealed]
            ├── cDiagramFP           [Sealed]
            ├── cProductiveDiagram   [Sealed]
            ├── cSummaryResults      [Sealed]
            ├── cReadModel           [Abstract]
            │   ├── cReadModelStruct [Abstract]
            │   │   ├── cReadModelJSON [Sealed]
            │   │   └── cReadModelXML  [Sealed]
            │   └── cReadModelTable  [Abstract]
            │       ├── cReadModelCSV [Sealed]
            │       └── cReadModelXLS [Sealed]
            └── cResultSet           [Abstract]
                ├── cResultInfo
                ├── cDataModel
                └── cThermoeconomicModel [Sealed]

── Static / value classes (no handle inheritance) ──
cMessages        – constant message strings only
cType            – constant enums + static validators
cParseStream     – static stream parsing utilities
cMessageBuilder  – immutable value-class message payload
```

---

## 2. Layer Overview

The classes form **nine conceptual layers** stacked from low-level utilities to the top-level analysis engine:

```text
┌─────────────────────────────────────────────────────────────────┐
│  Layer 0 – Foundation         cTaesLab · cType · cMessages      │
├─────────────────────────────────────────────────────────────────┤
│  Layer 1 – Utilities          cQueue · cSparseRow · cParseStream │
│                               cDictionary · cDataset            │
├─────────────────────────────────────────────────────────────────┤
│  Layer 2 – Logging            cMessageLogger · cMessageBuilder  │
├─────────────────────────────────────────────────────────────────┤
│  Layer 3 – Table Registry     cTablesDefinition → cFormatData   │
│                               → cResultTableBuilder             │
├─────────────────────────────────────────────────────────────────┤
│  Layer 4 – Table Presentation cTable → cTableData / cTableIndex │
│                               → cTableResult → cTableCell /     │
│                               cTableMatrix · cSummaryTable      │
├─────────────────────────────────────────────────────────────────┤
│  Layer 5 – File Reading       cReadModel → cReadModelJSON/XML   │
│                               cReadModelCSV/XLS · cModelData   │
│                               cModelTable                       │
├─────────────────────────────────────────────────────────────────┤
│  Layer 6 – Domain Data        cProductiveStructure · cExergyData│
│                               cWasteData · cResourceData        │
│                               cSummaryOptions                   │
├─────────────────────────────────────────────────────────────────┤
│  Layer 7 – Computation        cExergyModel → cExergyCost        │
│                               cDiagnosis · cWasteAnalysis       │
│                               cDiagramFP · cProductiveDiagram   │
│                               cDigraphAnalysis · cSummaryResults│
├─────────────────────────────────────────────────────────────────┤
│  Layer 8 – Results            cResultId → cResultSet            │
│                               → cResultInfo / cDataModel        │
│                               → cThermoeconomicModel            │
│                               cModelResults                     │
├─────────────────────────────────────────────────────────────────┤
│  Layer 9 – Presentation       cGraphResults → (8 subclasses)    │
│                               cBuildHTML · cBuildLaTeX          │
│                               cBuildMarkdown · cViewTable       │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Layer-by-Layer Reference

### 3.1 Foundation Layer

| Class | Superclass | Role |
| --- | --- | --- |
| `cTaesLab` | `handle` | Root of all TaesLab objects; provides `status` validity flag, auto-increment `objectId`, and `printError/Warning/Info` dispatch. |
| `cType` | *(static)* | Central repository of all enumeration constants (flow types, process types, result IDs, file extensions, table names) and static validators (`checkFlowTypes`, `getFileType`, etc.). |
| `cMessages` | *(static)* | Single source of truth for every user-visible message string. |
| `cMessageBuilder` | *(value class)* | Immutable message payload carrying `Error` level code, `Class` name, and `Text`. Stored in a `cQueue` by `cMessageLogger`. |

---

### 3.2 Utility / Collection Layer

| Class | Superclass | Role |
| --- | --- | --- |
| `cQueue` | `cTaesLab` | Generic FIFO cell-array container; used by `cMessageLogger` and `cParseStream`. |
| `cSparseRow` | `cTaesLab` | Memory-efficient sparse-row matrix; used for waste allocation matrix `TableR` inside `cExergyCost`. Implements Woodbury inversion. |
| `cDictionary` | `cMessageLogger` | Bidirectional string ↔ integer-index dictionary backed by `containers.Map`. Base class for `cDataset`. |
| `cDataset` | `cDictionary` | Keyed object store mapping string names to arbitrary MATLAB objects. Used for state→`cExergyData`, sample→`cResourceData`, and state→`cExergyCost` lookups. |
| `cParseStream` | *(static)* | Validates and parses fuel-product stream strings (e.g., `"A1+A2"`), flow key names, and process key names. |

---

### 3.3 Logging Layer

| Class | Superclass | Role |
| --- | --- | --- |
| `cMessageLogger` | `cTaesLab` | Superclass for every object that accumulates validation/processing messages. Stores a `cQueue` of `cMessageBuilder` objects; exposes `printLogger`, `addLogger`, etc. |

---

### 3.4 Table Registry Layer

These classes load and expose metadata from `Config/printformat.json`.

| Class | Superclass | Role |
| --- | --- | --- |
| `cTablesDefinition` | `cMessageLogger` | Registry of all result table definitions (name, columns, format codes, graph types). Provides `getTableDefinition`, `getTableId`, `getCellTables`, `getMatrixTables`, etc. |
| `cFormatData` | `cTablesDefinition` | Applies model-specific format / unit overrides from `cModelData.Format` onto the global registry defaults. |
| `cResultTableBuilder` | `cFormatData` | **Factory** that assembles `cResultInfo` objects from raw computation results. Creates correctly named and formatted `cTableCell` / `cTableMatrix` instances for every analysis type. |

---

### 3.5 Table Presentation Layer

| Class | Superclass | Role |
| --- | --- | --- |
| `cTable` | `cMessageLogger` | Abstract base; unified display/export/save API via `showTable`, `exportTable`, `saveTable`. Delegates rendering to `cBuildHTML`, `cBuildLaTeX`, `cBuildMarkdown`, `cViewTable`. |
| `cTableResult` | `cTable` | Abstract; adds thermoeconomic metadata: `Format` and `Unit` per column, `NodeType`. |
| `cTableCell` | `cTableResult` | Mixed text+numeric result table (process descriptions, efficiencies, unit costs). |
| `cTableMatrix` | `cTableResult` | Numeric matrix table with optional row/column totals (FP tables, cost matrices, diagnosis matrices). |
| `cTableData` | `cTable` | Input/raw-data table (flow definitions, process fuel-product data, exergy state values). |
| `cTableIndex` | `cTable` | Auto-built catalogue of all tables in a `cResultInfo`; returned by `cResultInfo.getTableIndex`. |
| `cSummaryTable` | `cTaesLab` | Internal numeric value store for one column-growing summary table inside `cSummaryResults`. Not a display table. |

---

### 3.6 Input Reading Layer

| Class | Superclass | Role |
| --- | --- | --- |
| `cModelData` | `cMessageLogger` | Intermediate transfer object carrying raw (unvalidated) model data from a file reader to `cDataModel`. |
| `cModelTable` | `cMessageLogger` | Validated single-sheet/file table container used by `cReadModelXLS` / `cReadModelCSV`. |
| `cReadModel` | `cResultId` | Abstract base; calls `getDataModel()` to construct a `cDataModel`. |
| `cReadModelStruct` | `cReadModel` | Abstract intermediate for structured formats (JSON/XML). |
| `cReadModelJSON` | `cReadModelStruct` | Reads `.json` files via `jsondecode` / `importJSON`. |
| `cReadModelXML` | `cReadModelStruct` | Reads `.xml` files via `readstruct` (MATLAB only). |
| `cReadModelTable` | `cReadModel` | Abstract intermediate for tabular formats (XLSX/CSV). |
| `cReadModelXLS` | `cReadModelTable` | Reads multi-sheet Excel files; creates one `cModelTable` per sheet. |
| `cReadModelCSV` | `cReadModelTable` | Reads a folder of CSV files; creates one `cModelTable` per file. |

---

### 3.7 Domain Data Structures Layer

| Class | Superclass | Role |
| --- | --- | --- |
| `cProductiveStructure` | `cResultId` | Validated productive structure: flow/process dictionaries, incidence matrices, adjacency tables, waste/resource classifications. |
| `cExergyData` | `cMessageLogger` | Thermodynamic state snapshot for one operating condition; computes flow/process/stream exergy arrays and adjacency table from `cProductiveStructure`. |
| `cWasteData` | `cMessageLogger` | Waste flow metadata: types, recycling ratios, allocation values for each waste flow. |
| `cResourceData` | `cMessageLogger` | Resource cost data for one cost sample: unit costs `c0`, capital costs `Z`, derived cost vectors `C0`, `ce`, `Ce`. |
| `cSummaryOptions` | `cTaesLab` | Bitmask option object for summary table scope (states, resources, or both). |

---

### 3.8 Result Identity Layer

| Class | Superclass | Role |
| --- | --- | --- |
| `cResultId` | `cMessageLogger` | Abstract; tags every computation result with `ResultId`, `ModelName`, `State`, `Sample`, `DefaultGraph`. |
| `cResultSet` | `cResultId` | Abstract; adds unified display/export/save API: `showResults`, `saveResults`, `exportResults`, `getTable`, `getTableIndex`. |

---

### 3.9 Computation Layer

All concrete computation classes implement `buildResultInfo()` → `cResultInfo`.

| Class | Superclass | Inputs | Computes |
| --- | --- | --- | --- |
| `cExergyModel` | `cResultId` | `cExergyData` | FP table, Leontief inverse, irreversibilities, efficiencies, unit consumptions. |
| `cExergyCost` | `cExergyModel` | `cExergyData` [+ `cWasteData`] | Direct and generalized thermoeconomic costs; waste allocation operators; `TableR` (`cSparseRow`). |
| `cDiagnosis` | `cResultId` | two `cExergyCost` | Malfunction matrix, induced malfunctions, dysfunction table, impact on resources. |
| `cWasteAnalysis` | `cResultId` | `cExergyCost` [+ `cResourceData`] | Waste recycling cost sensitivity analysis. |
| `cDiagramFP` | `cResultId` | `cExergyCost` | FP diagram edges/nodes and unit-cost FP diagram; uses `cDigraphAnalysis`. |
| `cProductiveDiagram` | `cResultId` | `cProductiveStructure` | FAT, PAT, FPAT, SFPAT, KPAT productive diagram variants; uses `cDigraphAnalysis`. |
| `cDigraphAnalysis` | `cMessageLogger` | adjacency matrix + names | Topological ordering, strongly connected components, kernel, transitive closure. |
| `cSummaryResults` | `cResultId` | `cThermoeconomicModel` | Multi-state / multi-sample summary matrices by calling lazy analysis on each state/sample. |

---

### 3.10 Result Container Layer

| Class | Superclass | Role |
| --- | --- | --- |
| `cResultInfo` | `cResultSet` | Named struct of `cTable` objects for one analysis type, plus the originating `cResultId`. Auto-builds a `cTableIndex`. |
| `cModelResults` | `cMessageLogger` | Fixed-length cache (`MAX_RESULT_INFO` slots) of `cResultInfo` objects inside `cThermoeconomicModel`. Indexed by `ResultId`. |

---

### 3.11 Central Data Hub

| Class | Superclass | Role |
| --- | --- | --- |
| `cDataModel` | `cResultSet` | Validated data warehouse. Builds and owns `cProductiveStructure`, `cResultTableBuilder`, all `cExergyData` instances (in a `cDataset`), all `cResourceData` instances (in a `cDataset`), `cWasteData`, and `cSummaryOptions`. Entry point for all analysis inputs. |

**Construction sequence inside `cDataModel`:**

```text
cModelData  →  cProductiveStructure
            →  cResultTableBuilder (FormatData)
            →  cDataset [state → cExergyData]
            →  cWasteData
            →  cDataset [sample → cResourceData]
            →  cSummaryOptions
```

---

### 3.12 Top-Level Analysis Engine

| Class | Superclass | Role |
| --- | --- | --- |
| `cThermoeconomicModel` | `cResultSet` | Configurable analysis engine that wraps a `cDataModel`. Lazily builds and caches `cExergyCost` per state (stored in a `cDataset`), then creates `cDiagnosis`, `cWasteAnalysis`, `cDiagramFP`, `cProductiveDiagram`, and `cSummaryResults` on demand. |

**Lazy analysis dispatch:**

```text
thermoeconomicAnalysis()   → cExergyCost        → cResultInfo
exergyAnalysis()           → cExergyModel       → cResultInfo
thermoeconomicDiagnosis()  → cDiagnosis         → cResultInfo
wasteAnalysis()            → cWasteAnalysis     → cResultInfo
diagramFP()                → cDiagramFP         → cResultInfo
productiveDiagram()        → cProductiveDiagram → cResultInfo
summaryResults()           → cSummaryResults    → cResultInfo
productiveStructure()      → (from cDataModel)  → cResultInfo
```

---

### 3.13 Graph / Visualization Layer

`cGraphResults` (Abstract, `cMessageLogger`) is the base for all graph renderers.

| Subclass | Input | Graph kind |
| --- | --- | --- |
| `cDigraph` | `cTableCell` + `cProductiveDiagram` or `cDiagramFP` | Directed graph |
| `cGraphCost` | `cTable` (ICT table) | Stacked bar |
| `cGraphCostRSC` | `cTable` + `cExergyCost` | Stacked bar or pie |
| `cGraphDiagnosis` | `cTable` + `cDiagnosis` | Stacked bar |
| `cGraphDiagramFP` | `cTableMatrix` + `cResultId` | Directed graph |
| `cGraphRecycling` | `cTable` | Line plot |
| `cGraphSummary` | `cTable` + `cSummaryResults` | Bar / stacked / line |
| `cGraphWaste` | `cTable` + `cWasteAnalysis` | Pie or bar |

---

### 3.14 Export / Presentation Layer

| Class | Superclass | Input | Output |
| --- | --- | --- | --- |
| `cBuildHTML` | `cMessageLogger` | `cTable` or `cTableIndex` | HTML string / browser preview |
| `cBuildLaTeX` | `cMessageLogger` | `cTable` | LaTeX `tabular` string |
| `cBuildMarkdown` | `cMessageLogger` | `cTable` | GitHub-Flavored Markdown |
| `cViewTable` | `cTaesLab` | `cTable` | MATLAB `uitable` GUI window |

---

## 4. Composition & Dependency Map

Arrows show **creates / depends on** relationships (not inheritance).

```text
File readers
  cReadModelJSON / cReadModelXML  ──creates──► cModelData
  cReadModelXLS / cReadModelCSV   ──creates──► cModelTable, cModelData

cDataModel (central hub)
  ──creates──► cProductiveStructure
  ──creates──► cResultTableBuilder    (stored as FormatData)
  ──creates──► cDataset [cExergyData] (one entry per state)
  ──creates──► cExergyData            (one per state)
  ──creates──► cWasteData
  ──creates──► cDataset [cResourceData] (one entry per sample)
  ──creates──► cResourceData          (one per sample)
  ──creates──► cSummaryOptions

cThermoeconomicModel (analysis engine)
  ──wraps──►   cDataModel
  ──creates──► cModelResults
  ──creates──► cDataset [cExergyCost]  (lazy, one per state)
  ──creates──► cExergyCost             (lazy, one per state)
  ──creates──► cDiagnosis              (lazy)
  ──creates──► cWasteAnalysis          (lazy)
  ──creates──► cDiagramFP              (lazy)
  ──creates──► cProductiveDiagram      (lazy)
  ──creates──► cSummaryResults         (lazy)

Computation classes
  cExergyModel   ──takes──► cExergyData → uses cProductiveStructure
  cExergyCost    ──takes──► cExergyData, [cWasteData]; creates cSparseRow
  cDiagnosis     ──takes──► cExergyCost (reference × 2)
  cWasteAnalysis ──takes──► cExergyCost, [cResourceData]
  cDiagramFP     ──takes──► cExergyCost; creates cDigraphAnalysis (×2)
  cProductiveDiagram ──takes──► cProductiveStructure; creates cDigraphAnalysis

cSummaryResults  ──takes──► cThermoeconomicModel; creates cDataset [cSummaryTable]

cResultTableBuilder ──creates──► cTableCell, cTableMatrix, cResultInfo
cResultInfo         ──creates──► cTableIndex

Logging infrastructure
  cMessageLogger ──uses──► cQueue, cMessageBuilder
  cDictionary    ──uses──► containers.Map  (MATLAB built-in)
```

---

## 5. Dependency Matrix

A simplified matrix showing which classes (rows) **use** which other classes (columns).
`C` = creates/instantiates · `U` = uses reference · `I` = inherits (direct superclass only).

| Class | `cTaesLab` | `cMessageLogger` | `cQueue` | `cMessageBuilder` | `cType` | `cDictionary` | `cDataset` | `cProductiveStructure` | `cExergyData` | `cWasteData` | `cResourceData` | `cExergyModel` | `cExergyCost` | `cDiagnosis` | `cSparseRow` | `cDigraphAnalysis` | `cResultTableBuilder` | `cResultInfo` | `cDataModel` |
| --- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
<!-- markdownlint-disable-next-line MD060 -->
| `cMessageLogger` | I |  | C | C | U |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| `cDictionary` |  | I |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| `cDataset` |  |  |  |  |  | I |  |  |  |  |  |  |  |  |  |  |  |  |  |
| `cTablesDefinition` |  | I |  |  | U | C |  |  |  |  |  |  |  |  |  |  |  |  |  |
| `cResultTableBuilder` |  |  |  |  |  |  |  | U |  |  |  |  |  |  |  |  |  | C | C |
| `cTable` |  | I |  |  | U |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| `cProductiveStructure` |  |  |  |  | U | C |  |  |  |  |  |  |  |  |  |  |  |  |  |
| `cExergyData` |  | I |  |  | U |  |  | U |  |  |  |  |  |  |  |  |  |  |  |
| `cWasteData` |  | I |  |  |  |  |  | U |  |  |  |  |  |  |  |  |  |  |  |
| `cResourceData` |  | I |  |  |  |  |  | U |  |  |  |  |  |  |  |  |  |  |  |
| `cExergyModel` |  |  |  |  |  |  |  | U | U |  |  |  |  |  |  |  | U | C |  |
| `cExergyCost` |  |  |  |  |  |  |  |  | U | U |  | I |  |  | C |  | U | C |  |
| `cDiagnosis` |  |  |  |  |  |  |  |  |  |  |  |  | U |  |  |  | U | C |  |
| `cWasteAnalysis` |  |  |  |  |  |  |  |  |  | U | U |  | U |  |  |  | U | C |  |
| `cDiagramFP` |  |  |  |  |  |  |  |  |  |  |  |  | U |  |  | C | U | C |  |
| `cProductiveDiagram` |  |  |  |  |  |  |  | U |  |  |  |  |  |  |  | C | U | C |  |
| `cSummaryResults` |  |  |  |  |  |  | C |  |  |  |  |  |  |  |  |  | U | C |  |
| `cResultInfo` |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| `cDataModel` |  |  |  |  | U |  | C | C | C | C | C |  |  |  |  |  | C | C |  |
| `cThermoeconomicModel` |  |  |  |  |  |  | C |  |  |  |  |  | C | C |  |  |  |  | U |

---

*Generated from source analysis of `Classes/*.m`.*

### **Dependency Bottlenecks**

1. **`cType`** - Static constants class used by ~90% of other classes
2. **`cMessages`** - Error message definitions used system-wide
3. **`cMessageLogger`** - Required by most functional classes
4. **`cResultId`** - Base for all computation classes

### **Circular Dependencies** (Managed)

- **`cDataModel`** ↔ **`cResultSet`** (both inherit from each other's interfaces)
- **`cTable`** ↔ **`cResultInfo`** (mutual containment)
- **`cExergyModel`** ↔ **`cResultTableBuilder`** (computation ↔ formatting)

---

## Optimization Opportunities

### **Classes for cTaesLab Conversion**

These classes inherit from `cMessageLogger` but may not need full logging:

```matlab
Candidates for cTaesLab conversion:
├── cDigraphAnalysis (graph analysis utility)
├── cModelResults (simple container)  
├── cGraphResults (visualization base)
├── cBuildHTML (export utility)
├── cBuildLaTeX (export utility)
└── cBuildMarkdown (export utility)
```

### **Dependency Reduction Strategies**

1. **Static utilities** could use composition instead of inheritance
2. **Export classes** could be independent of logging hierarchy
3. **Graph classes** might only need `cTaesLab` base functionality
4. **Simple containers** don't require full `cMessageLogger` overhead

---

## System Integration Points

### **External Dependencies**

- **MATLAB Handle Graphics** (for cMessageBuilder)
- **File System** (all cReadModel classes)
- **JSON/XML parsers** (cReadModelJSON, cReadModelXML)
- **MATLAB Table/UI components** (cViewTable, graph classes)

### **Internal Coupling**

- **Tight coupling**: Data Model ↔ Computation Layer
- **Moderate coupling**: Computation ↔ Presentation Layer  
- **Loose coupling**: File Reading ↔ Core System
- **No coupling**: Static utility classes

---

This dependency analysis reveals TaesLab's well-structured architecture with clear separation of concerns, though there are opportunities to optimize inheritance relationships for classes that don't require full logging capabilities.
