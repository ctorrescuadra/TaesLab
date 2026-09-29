# cExergyData Guide

`cExergyData` validates the exergy data of one plant state against a [`cProductiveStructure`](../Classes/cProductiveStructure.m) object and derives the thermodynamic quantities used by the calculation layer.

## Recent implementation updates

This class reflects the current TaesLab state model and the last refactor in the exergy pipeline:

- Validation is performed early and is fail-fast: the constructor exits immediately on invalid topology or missing state data.
- Per-flow exergy values are mapped into stream-level exergy using the productive structure (`flows2Streams`).
- Active-process reachability is checked with a graph-based output-path test, using the demand-driven adjacency matrices and a BFS from the sink node.
- Inactive or bypassed processes are marked explicitly in `ActiveProcesses` and assigned neutral unit-cost/efficiency values (`vK = 1`, `vEf = 100`).
- The class exposes the normalized adjacency tables needed downstream by `cExergyModel` and `cExergyCost`.

## 1. Input Data Information

The constructor expects two inputs:

| Input | Type | Description |
| --- | --- | --- |
| `ps` | `cProductiveStructure` | Valid productive structure used as the topology reference. |
| `data` | `struct` | Exergy-state data for one operating condition. |

### Required `data` fields

| Field | Type | Description |
| --- | --- | --- |
| `stateId` | `char` or `string` | Name of the exergy state being processed. |
| `exergy` | struct array | Per-flow exergy values, one entry per flow in the productive structure. |

### Required `exergy` entry fields

Each entry in `data.exergy` must contain:

| Field | Type | Description |
| --- | --- | --- |
| `key` | `char` | Flow key. |
| `value` | numeric | Exergy value for that flow. |

The number of entries in `data.exergy` must match `ps.NrOfFlows`.

## 2. Checking and Process Input Data

The constructor validates the data in a fixed order and stops at the first fatal problem.

| Step | Check or action | Result if invalid |
| --- | --- | --- |
| 1 | Verify that `ps` is a `cProductiveStructure` object. | Logs `InvalidObject` and returns. |
| 2 | Verify that `data` is a struct. | Logs `InvalidExergyDefinition` and returns. |
| 3 | Verify that `data` contains `stateId` and `exergy`. | Logs `InvalidExergyDefinition` and returns. |
| 4 | Store the state name in `State`. | No validation error by itself. |
| 5 | Check that `numel(data.exergy) == ps.NrOfFlows`. | Logs `InvalidExergyDataSize` and returns. |
| 6 | Verify that every exergy entry contains `key` and `value`. | Logs `InvalidExergyDefinition` and returns. |
| 7 | Convert flow exergy values to stream values using `ps.flows2Streams`. | Produces `StreamsExergy.E` and `StreamsExergy.ET`. |
| 8 | Check that all stream exergies are non-negative. | Logs `NegativeExergyStream` for each invalid stream. |
| 9 | Compute process fuel and product exergies from the structural tables. | Builds `vF` and `vP`. |
| 10 | Check that the model has resources and final outputs. | Logs `NoResources` or `NoOutputs`. |
| 11 | Compute irreversibilities, bypassed processes, unit costs, and efficiencies. | Logs `NegativeIrreversibilty`, `ZeroProduct`, or `ProcessNotActive` as needed. |
| 12 | Build exergy-scaled adjacency tables and normalized adjacency matrices. | Creates `AdjacencyTable` and `AdjacencyMatrix`. |
| 13 | Verify that every active productive process can reach the plant output. | Logs `OutputNotReachedFromNode` or `NoProductiveState`. |

### Processing details

- `FlowsExergy` stores the raw per-flow exergy vector `B`.
- `StreamsExergy` is derived from the productive structure and stores:
  - `E`: net exergy per stream
  - `ET`: total exergy entering each stream node
- `ProcessesExergy` is derived from the stream exergies and stores:
  - `vF`: fuel exergy per process
  - `vP`: product exergy per process
  - `vI`: irreversibility per process
  - `vK`: unit exergy cost per process
  - `vEf`: efficiency per process
- Processes with zero fuel and zero product are treated as bypassed and marked inactive.
- Bypassed processes receive neutral values: `vK = 1` and `vEf = 100`.
- `AdjacencyTable` keeps the exergy-weighted tables.
- `AdjacencyMatrix` keeps the normalized, demand-driven matrices used by later analysis classes.

## 3. Output Processing: Public Properties

All public properties are read-only from outside the class. They summarize the validated state and the derived exergy and connectivity information.

| Property | Description |
| --- | --- |
| `ps` | Reference to the validated `cProductiveStructure` object used as the topology base. |
| `State` | Name of the exergy state currently represented. |
| `FlowsExergy` | Numeric vector with the exergy value of each flow. |
| `StreamsExergy` | Struct with `E` and `ET`, the net and total exergy of streams. |
| `ProcessesExergy` | Struct with `vF`, `vP`, `vI`, `vK`, and `vEf` for each process. |
| `ActiveProcesses` | Logical vector indicating which processes are active and not bypassed. |
| `AdjacencyTable` | Struct with exergy-weighted tables `AF`, `AP`, `AE`, and `AS`. |
| `AdjacencyMatrix` | Struct with normalized tables `AF`, `AP`, `AE`, and `AS` used for productive reachability checks. |

### Output behavior

- The object only populates these properties when the full validation pipeline succeeds.
- If validation fails, the object remains invalid and these properties should not be used.
- Downstream classes such as `cExergyModel` and `cExergyCost` consume these properties directly.

## 4. Error Handling

`cExergyData` uses construction-time validation and logs errors through the inherited `cMessageLogger`. It does not attempt partial recovery when a fatal problem is found.

### Common failure cases

| Failure case | Typical message | Meaning |
| --- | --- | --- |
| Wrong productive structure object | `InvalidObject` | `ps` is not a valid `cProductiveStructure`. |
| Wrong input type | `InvalidExergyDefinition` | `data` is not a struct or is missing required fields. |
| Wrong exergy vector size | `InvalidExergyDataSize` | The number of exergy entries does not match the number of flows. |
| Missing exergy entry fields | `InvalidExergyDefinition` | One or more entries do not contain `key` and `value`. |
| Negative stream exergy | `NegativeExergyStream` | A derived stream exergy is negative. |
| Missing resources or outputs | `NoResources`, `NoOutputs` | The state is inconsistent with the productive structure. |
| Negative irreversibility | `NegativeIrreversibilty` | A process irreversibility became negative after calculation. |
| Zero product with fuel | `ZeroProduct` | A process has fuel but no product, which is invalid. |
| Unreachable active process | `OutputNotReachedFromNode` | An active productive process cannot reach the plant output. |
| Non-productive state | `NoProductiveState` | The full state does not satisfy productive reachability. |

### Recommended handling pattern

```matlab
ed = cExergyData(ps, data);
if ~isValid(ed)
    return;
end
```

### Practical rule

Do not read `FlowsExergy`, `StreamsExergy`, `ProcessesExergy`, `AdjacencyTable`, or `AdjacencyMatrix` unless `isValid(ed)` is true.

## 5. Related Classes

| Class | Relationship |
| --- | --- |
| [`cProductiveStructure`](../Classes/cProductiveStructure.m) | Provides the topology, flow mapping, and adjacency matrices used by the constructor. |
| [`cModelData`](../Classes/cModelData.m) | Supplies the raw state data through `ExergyStates`. |
| [`cDataModel`](../Classes/cDataModel.m) | Builds and stores `cExergyData` objects for each state. |
| [`cExergyModel`](../Classes/cExergyModel.m) | Consumes `cExergyData` to compute the exergy analysis results. |
| [`cExergyCost`](../Classes/cExergyCost.m) | Consumes `cExergyData` to compute cost and thermoeconomic metrics. |
| [`cDigraphAnalysis`](../Classes/cDigraphAnalysis.m) | Used to verify productive reachability from the output side. |
| [`cType`](../Classes/cType.m) | Provides the flow/process identifiers used during validation and classification. |
| [`cMessages`](../Classes/cMessages.m) | Supplies the standardized log messages for failures and warnings. |
| [`cMessageLogger`](../Classes/cMessageLogger.m) | Base class used for validation logging and status tracking. |

## 6. Source Reference

The implementation summarized here is defined in [`cExergyData.m`](../Classes/cExergyData.m).
