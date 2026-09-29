# cProductiveStructure Guide

`cProductiveStructure` builds and validates the productive structure of a plant from a [`cModelData`](../Classes/cModelData.m) object. It is the core topology object used by the rest of TaesLab to reason about flows, processes, streams, connectivity, and system outputs.

## Recent implementation updates

The current implementation reflects the latest topology validation and graph-generation changes:

- Flow and process keys are validated through dictionaries before the connectivity graph is built, and duplicate definitions are rejected before graph assembly.
- The synthetic environment process is created internally, and resource/output/waste flows are converted into environment streams during `buildEnvironment`.
- The constructor validates both the raw flow definitions (`checkFlowsConnectivity`) and the graph-level connectivity (`checkGraphConnectivity`) before finalizing `StreamMatrix` and `ProcessMatrix`.
- The class builds sparse adjacency tables `AE`, `AS`, `AF`, and `AP` directly from the validated stream definitions, then derives source-target reachability from those matrices.
- Waste detection, resource/output classification, process subsets, and the productive reachability checks all depend on the finalized topology; `ProductiveTable` and `StreamMatrix` are the authoritative views consumed by the exergy layer.

## 1. Input Data Information

The constructor expects a valid [`cModelData`](../Classes/cModelData.m) instance with a populated `ProductiveStructure` section. The raw productive structure must provide these fields:

| Field | Required content | Notes |
| --- | --- | --- |
| `flows` | Struct array | Each element must include `key` and `type`. |
| `processes` | Struct array | Each element must include `key`, `type`, `fuel`, and `product`. |

### Flow data

Each flow entry is used to create the internal `Flows` structure. The class expects a unique flow key and a valid TaesLab flow type. The flow type is resolved through `cType.checkFlowTypes` and must map to one of the supported flow categories:

- `RESOURCE`
- `OUTPUT`
- `WASTE`

### Process data

Each process entry is used to create the internal `Processes` structure. The class resolves the process type through `cType.getProcessId` and expects a valid type such as:

- `PRODUCTIVE`
- `DISSIPATIVE`
- `ENVIRONMENT` is added internally as a synthetic process

The `fuel` and `product` fields are stream expressions. They may contain one or more stream definitions, and each stream definition must reference existing flow keys.

## 2. Input Data Checking and Processing

The constructor performs validation in a strict sequence. If one step fails, the object is marked invalid and construction stops.

| Step | Check or action | Result if invalid |
| --- | --- | --- |
| 1 | Verify that the input is a `cModelData` object | Logs `InvalidObject` and returns. |
| 2 | Verify that `ProductiveStructure` contains `flows` and `processes` | Logs `InvalidDataModel` and returns. |
| 3 | Verify that each flow has `key` and `type` | Logs `InvalidDataModel` and returns. |
| 4 | Verify that each process has `key`, `fuel`, `product`, and `type` | Logs `InvalidDataModel` and returns. |
| 5 | Check that there are enough flows for the process graph (`NrOfFlows >= NrOfProcesses + 1`) | Logs `InvalidDataModel` and returns. |
| 6 | Build the flow structure and validate flow types | Logs invalid flow type messages and stops if the object becomes invalid. |
| 7 | Build the flow key dictionary and check duplicate keys | Logs `DuplicatedFlow` on failure. |
| 8 | Verify that at least one resource flow exists | Logs `NoResources` if none are found. |
| 9 | Verify that at least one final product flow exists | Logs `NoOutputs` if none are found. |
| 10 | Build the process structure and validate process types | Logs invalid process type messages as needed. |
| 11 | Build the process key dictionary and check duplicate keys | Logs `DuplicatedProcess` on failure. |
| 12 | Parse each process fuel and product expression into streams | Uses `cParseStream.checkStream`, `cParseStream.getStreams`, and `cParseStream.getStreamFlows`. |
| 13 | Link each stream to its source and target flows | Checks for invalid flow keys and duplicate stream assignments. |
| 14 | Build environment streams and the synthetic environment process | Classifies resource, waste, and output flows and updates counts. |
| 15 | Check flow connectivity | Detects missing `from` or `to` assignments and flow loops. |
| 16 | Build the productive adjacency matrices | Creates `AE`, `AS`, `AF`, and `AP` inside `ProductiveTable`. |
| 17 | Check graph connectivity | Verifies that all relevant nodes are reached from resources and can reach final products. |

### Processing details

- Each flow is assigned an internal numeric `id`, a dictionary entry, and `from`/`to` stream indices.
- Each process is assigned an internal numeric `id`, a key, a type, and parsed fuel/product stream counts.
- Each declared stream becomes an internal stream record in `Streams` and is classified as fuel or product.
- Environment streams are created automatically for resources, wastes, and final outputs.
- Connectivity is validated twice: first at the flow level, then at the full productive graph level.
- If all checks pass, the object stores the resulting topology and sets `ResultId` to `PRODUCTIVE_STRUCTURE`.

## 3. Output Information: Public Properties

All public properties are read-only from outside the class. They summarize the validated productive structure and the matrices derived from it.

| Property | Description |
| --- | --- |
| `NrOfProcesses` | Number of processes, including the synthetic environment process in internal calculations. |
| `NrOfFlows` | Number of flows in the productive structure. |
| `NrOfStreams` | Number of created streams. |
| `NrOfWastes` | Number of waste flows detected in the model. |
| `NrOfResources` | Number of resource flows detected in the model. |
| `NrOfFinalProducts` | Number of final product flows detected in the model. |
| `NrOfSystemOutputs` | Total number of system outputs, equal to final products plus wastes. |
| `Processes` | Struct array with process metadata, including `id`, `key`, `type`, `typeId`, `fuel`, `product`, `fuelStreams`, and `productStreams`. |
| `Flows` | Struct array with flow metadata, including `id`, `key`, `type`, `typeId`, `from`, and `to`. |
| `Streams` | Struct array with stream metadata, including `id`, `key`, `definition`, `type`, `typeId`, and `process`. |
| `Waste` | Dependent property that returns the indices of waste flows, their streams, and their owning processes. |
| `FlowKeys` | Cell array of all flow keys. |
| `ProcessKeys` | Cell array of all process keys. |
| `StreamKeys` | Cell array of all stream keys. |
| `ProductiveTable` | Struct containing the sparse adjacency matrices `AE`, `AS`, `AF`, and `AP`. |
| `ProcessMatrix` | Logical process adjacency matrix used for graph reachability and connectivity checks. |

### Important derived outputs

- `Waste` is computed on demand and returns `cType.EMPTY` when the object is invalid or when there are no waste flows.
- `ProductiveTable` is the main structural result used by downstream analysis classes.
- `ProcessMatrix` is computed after graph connectivity succeeds and is used by methods such as `ResourceProcesses` and `OutputProcesses`.

## 4. Related Classes

| Class | Relationship |
| --- | --- |
| [`cModelData`](../Classes/cModelData.m) | Raw data container consumed by the constructor. |
| [`cDataModel`](../Classes/cDataModel.m) | Owns the validated `cProductiveStructure` instance and uses it as the base of the analysis pipeline. |
| [`cType`](../Classes/cType.m) | Provides flow and process type identifiers used during validation and classification. |
| [`cParseStream`](../Classes/cParseStream.m) | Parses and validates stream expressions in `fuel` and `product` fields. |
| [`cDictionary`](../Classes/cDictionary.m) | Used to map flow and process keys to numeric indices and detect duplicates. |
| [`cResultId`](../Classes/cResultId.m) | Base class of `cProductiveStructure`; provides result identity and logging infrastructure. |
| [`cResultInfo`](../Classes/cResultInfo.m) | Result container produced by `buildResultInfo`. |
| [`cResultTableBuilder`](../Classes/cResultTableBuilder.m) | Builds the formatted tables for the productive-structure results. |
| [`cWasteData`](../Classes/cWasteData.m) | Uses waste-flow metadata derived from this class. |
| [`cDigraphAnalysis`](../Classes/cDigraphAnalysis.m) | Used to evaluate reachability and connectivity in the productive graph. |
| [`cProductiveDiagram`](../Classes/cProductiveDiagram.m) | Consumes the productive structure to build diagram adjacency tables. |
| [`cExergyData`](../Classes/cExergyData.m) | Uses the productive structure as the topology basis for exergy calculations. |

## 5. Public Methods at a Glance

| Method | Purpose |
| --- | --- |
| `cProductiveStructure(dm)` | Build and validate the productive structure from `cModelData`. |
| `buildResultInfo(fmt)` | Create the `cResultInfo` object for the productive-structure tables. |
| `WasteData` | Return the default waste allocation template. |
| `IncidenceMatrix` | Return the fuel and product incidence matrices. |
| `getStreamMatrix`, `getFlowMatrix`, `getProcessMatrix` | Return the main adjacency matrices of the model. |
| `getProductiveMatrix` | Return the combined productive adjacency matrix. |
| `getFlowId`, `getProcessId` | Map keys to internal numeric identifiers. |
| `ResourceFlows`, `FinalProductFlows`, `SystemOutputFlows` | Return indices for flow subsets. |
| `ResourceProcesses`, `OutputProcesses`, `ProductiveProcesses` | Return indices or logical masks for process subsets. |
| `getResourceNames`, `getProductNames`, `getWasteNames` | Return the names of the corresponding flow subsets. |
| `flows2Streams` | Project per-flow values onto stream values. |

## 6. Public Method Reference

The class exposes a compact but complete public API for validating, querying, and exporting the plant topology. Most methods are intentionally thin wrappers around the validated internal data in `Flows`, `Processes`, `Streams`, and `ProductiveTable`.

### 6.1 Construction and result export

- `cProductiveStructure(dm)`: validates the input `cModelData`, creates the flow/process/stream topology, and builds the internal productive graph matrices. It fails fast when connectivity or typing rules are violated.
- `buildResultInfo(fmt)`: delegates to the table builder and returns the `cResultInfo` object used to present the productive-structure tables.

### 6.2 Waste and environment helpers

- `WasteData()`: builds the default waste allocation template for each waste flow.
- `FlowEdges()`: returns a struct of source/target stream keys for each flow, which is useful when drawing diagrams or checking edge definitions.
- `isModelIO()`: detects whether the model is a pure input-output system without internal recycling between streams.

### 6.3 Matrix and graph queries

- `IncidenceMatrix()`: returns the fuel and product incidence matrices, or their difference when only one output is requested.
- `getStreamMatrix()`: returns the stream adjacency matrix together with optional source/output environment vectors.
- `getFlowMatrix()`: returns the structural-theory flow adjacency matrix.
- `getProcessMatrix()`: returns the process adjacency matrix derived from the productive graph. This is the structure that drives reachability checks.
- `getProductiveMatrix()`: returns the combined adjacency matrix of streams, flows, and processes.
- `getFlowProcessMatrix()`: returns the bipartite flow-process adjacency matrix used in productive-diagram construction.
- `getStreamProcessMatrix()`: returns the stream-process adjacency matrix for graph-level checks.

### 6.4 Flow, process, and stream filtering

- `ProductStreams()`: returns the indices of internal product streams.
- `FuelStreams()`: returns the indices of fuel streams (including environment-linked inputs).
- `ResourceFlows()`: returns all resource-flow indices.
- `FinalProductFlows()`: returns all final-product-flow indices.
- `SystemOutputFlows()`: returns both output and waste flow indices.
- `ResourceProcesses()`: returns processes directly connected to resource flows.
- `OutputProcesses()`: returns processes connected to system outputs.
- `ProductiveProcesses()`: returns a logical mask for productive process nodes.
- `getFlowTypes(typeId)`: selects flows by a flow-type id.
- `getProcessTypes(typeId)`: selects processes by a process-type id.
- `getStreamTypes(typeId)`: selects streams by stream type.

### 6.5 Key lookup and naming helpers

- `getFlowId(key)`: returns the numeric index of a flow by its key, or 0 if it does not exist.
- `getProcessId(key)`: returns the numeric index of a process by its key, or 0 if it does not exist.
- `getResourceNames()`: returns the names of resource flows.
- `getProductNames()`: returns the names of final product flows.
- `getWasteNames()`: returns the names of waste flows.

### 6.6 Conversion and value projection

- `flows2Streams(val)`: projects a vector of per-flow values onto the associated stream graph and returns the stream-level net value; the optional second output returns the total entering value per stream.

This public surface is intentionally designed to support both low-level topology inspection and higher-level energy and cost calculations in the rest of the TaesLab model.

## 7. Practical Notes

- Use `isValid(obj)` before consuming any property or matrix.
- The class is designed to fail fast: any inconsistency in the topology or in the stream definitions is reported through the inherited message logger.
- Downstream analysis classes assume the public properties and matrices are already consistent, so a valid `cProductiveStructure` is the boundary between raw model data and computation.

## 8. Error Handling

`cProductiveStructure` uses construction-time validation and message logging rather than recoverable runtime exceptions. If validation fails, the object status becomes invalid and the constructor stops at the first fatal condition it reaches.

### Common failure cases

| Failure case | Typical message | Meaning |
| --- | --- | --- |
| Wrong input object | `InvalidObject` | The constructor did not receive a `cModelData` object. |
| Missing productive-structure fields | `InvalidDataModel` | One or more mandatory sections or subfields are absent. |
| Duplicate flow keys | `DuplicatedFlow` | Flow keys are not unique. |
| Duplicate process keys | `DuplicatedProcess` | Process keys are not unique. |
| No resource flows | `NoResources` | The model has no input resource flows. |
| No output flows | `NoOutputs` | The model has no final product flows. |
| Invalid flow or process type | `InvalidFlowType`, `InvalidProcessType` | A declared type does not match the supported TaesLab enumerations. |
| Invalid stream definition | `InvalidFuelStream`, `InvalidProductStream`, `InvalidStreamDefinition` | A fuel/product expression cannot be parsed or references unknown flows. |
| Broken connectivity | `InvalidFlowToStream`, `InvalidStreamToFlow`, `InvalidFlowLoop`, `InvalidProductiveGraph` | The productive graph is incomplete, cyclic in an invalid way, or disconnected. |

### Recommended handling pattern

```matlab
ps = cProductiveStructure(dm);
if ~isValid(ps)
    % Inspect the inherited message log before continuing.
    return;
end
```

### Practical rule

Do not rely on partially built properties when the object is invalid. Only consume `Flows`, `Processes`, `Streams`, `ProductiveTable`, and derived matrices after `isValid(ps)` succeeds.

## 9. Source Reference

The implementation and public surface summarized here are defined in [`cProductiveStructure.m`](../Classes/cProductiveStructure.m).
