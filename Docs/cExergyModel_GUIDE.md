# cExergyModel and cExergyCost Guide

This guide documents the exergy-analysis layer built on top of [`cExergyData`](../Classes/cExergyData.m) and the thermoeconomic cost extension in [`cExergyCost`](../Classes/cExergyCost.m).

`cExergyModel` builds the demand-driven flow-process exergy model for one plant state. `cExergyCost` extends it by computing the cost operators and the direct/generalized cost tables used throughout thermoeconomic analysis.

## Recent implementation updates

The current implementation incorporates the latest matrix formulation and cost-operator structure:

- `cExergyModel` now stores the demand-driven matrices as `FlowProcessModel` with `mV`, `mF`, `mF0`, `mP`, `mL`, and `mpL`.
- For IO models, the Leontief inverse is the identity and the recirculation term is forced to zero; for standard models, `mV = AE * AS` is used.
- `TableFP` is built from the productive adjacency structure, and plant totals are exposed via dedicated getters such as `TotalResources`, `FinalProducts`, and `TotalOutput`.
- `cExergyCost` now builds FP and PF operator families and updates waste effects through `updateWasteOperators` and `opR`-based cost propagation.
- Waste allocation and recycling are treated as part of the cost model, not as a separate post-processing step.

---

## 1. Input Data Information

### `cExergyModel`

The constructor expects a validated [`cExergyData`](../Classes/cExergyData.m) instance.

| Input | Type | Description |
| --- | --- | --- |
| `exd` | `cExergyData` | Validated exergy state data containing the productive structure, per-flow exergy values, and adjacency matrices. |

`cExergyModel` consumes the already validated state information created by `cExergyData`, especially:

- `exd.ps` — the associated `cProductiveStructure`
- `exd.FlowsExergy` — per-flow exergy vector
- `exd.ProcessesExergy` — process-level fuel/product/irreversibility values
- `exd.StreamsExergy` — stream-level exergy vectors
- `exd.AdjacencyTable` — exergy-weighted adjacency tables
- `exd.AdjacencyMatrix` — demand-driven matrix representation

### `cExergyCost`

The cost class extends `cExergyModel` and accepts the exergy state plus an optional waste-definition object.

| Input | Type | Description |
| --- | --- | --- |
| `exd` | `cExergyData` | The validated exergy state to analyze. |
| `wd` | `cWasteData` | Optional waste allocation object; used only when the model contains waste processes. |

The constructor checks that the base `cExergyModel` is valid before building the cost operators. If the plant includes dissipative processes, it initializes the waste-allocation matrices and recycling operators.

---

## 2. Checking and Processing

### 2.1 `cExergyModel`

The constructor performs a strict validation and assembly sequence.

| Step | Check or action | Result if invalid |
| --- | --- | --- |
| 1 | Verify that `exd` is a `cExergyData` object. | Logs `InvalidObject` and returns. |
| 2 | Retrieve the productive structure and matrix tables from `exd`. | Stops if the state is not valid. |
| 3 | Build the demand-driven flow-process matrices using the adjacency tables. | Fails if the plant topology is inconsistent. |
| 4 | Build `mgV` and the Leontief inverse `mL` for recirculation handling. | Standard IO models skip the recursive term and use the identity. |
| 5 | Compute the full FP table `TableFP` from the productive structure. | Builds the basis for process-level exergy analysis. |
| 6 | Normalize the process fuel matrix `AF0` and compute `mgF0`. | Used for the demand-driven resource allocation model. |
| 7 | Store the final flow-process model and exergy data in the object. | The object becomes ready for downstream analysis. |
| 8 | Set the result ID and model metadata. | The instance is ready for reporting. |

### 2.2 Processing details

- `mgF = AE * AF` and `mgP = AP * AS` build the flow-process demand model.
- For IO models, the recirculation matrix is zero and `mL = I`.
- For standard models, internal recirculation is captured through `mV = AE * AS`, and the Leontief inverse is computed as `mL = (I - mV)^{-1}`.
- `TableFP` is the full fuel-product table used to compute process production and consumption.
- `ProcessesExergy` values are taken from the upstream validated state object and exposed as process totals.
- `ActiveProcesses` is inherited from the exergy-state data and marks bypassed or inactive processes.

### 2.3 `cExergyCost`

The cost constructor builds the operator matrices needed to calculate thermoeconomic balances and waste recycling.

| Step | Check or action | Result if invalid |
| --- | --- | --- |
| 1 | Validate the base `cExergyModel` instance. | If invalid, constructor exits immediately. |
| 2 | Build the flow-level operator matrix `opB` from the flow-process model. | Used to propagate resource and flow costs. |
| 3 | Build PF-framework operators `mPF`, `mKP`, `opP`, and `opI`. | These define unit cost propagation across the productive network. |
| 4 | Build FP-framework operators `mFP` and `opCP`. | These define product-side cost propagation and recirculation coefficients. |
| 5 | If waste data is supplied and waste processes exist, initialize the waste operators. | Waste recycling and allocation matrices are added. |
| 6 | Update the cost operators with waste allocation rules. | Produces `fpOperators`, `pfOperators`, and `flowOperators` waste entries. |

### Processing details

- `mG = mF(:,1:N) * mP(1:N,:) + mV` builds the internal flow recirculation operator.
- `opB = (I - mG)^{-1}` maps resource-demand conditions to total flow exergy.
- `mPF` is the product-to-fuel ratio matrix; `mKP` scales it by unit consumption.
- `opP = (I - mKP)^{-1}` is the process unit-cost propagation operator.
- `opI` is the irreversibility contribution operator.
- `mFP` is the fuel-to-product ratio matrix; `opCP` is the resource-equivalent cost propagation operator.
- Waste allocation is handled by `updateWasteOperators`, which computes the sparse allocation matrix and the associated cost operators `opR`, `mKR`, and `mRP`.

---

## 3. Output Information (Public Variables)

### `cExergyModel` public properties

| Property | Description |
| --- | --- |
| `NrOfFlows` | Number of flows in the productive structure. |
| `NrOfProcesses` | Number of processes in the productive structure. |
| `NrOfStreams` | Number of productive streams. |
| `NrOfWastes` | Number of waste processes. |
| `FlowsExergy` | Exergy vector of all flows. |
| `ProcessesExergy` | Per-process exergy structure containing `vF`, `vP`, `vI`, `vK`, and `vEf`. |
| `StreamsExergy` | Stream exergy structure containing `E` and `ET`. |
| `FlowProcessModel` | Demand-driven matrices: `mV`, `mF`, `mF0`, `mP`, `mL`, and `mpL`. |
| `AdjacencyTable` | Exergy-scaled adjacency tables `AF`, `AP`, `AE`, and `AS`. |
| `TableFP` | Full fuel-product table matrix. |
| `FuelExergy` | Process fuel exergy vector, excluding the plant-total row. |
| `ProductExergy` | Process product exergy vector, excluding the plant-total row. |
| `Irreversibility` | Process irreversibility vector. |
| `UnitConsumption` | Unit consumption vector `kj = Fj/Pj`. |
| `Efficiency` | Process exergy efficiency vector. |
| `TotalResources` | Total resource exergy entering the plant. |
| `FinalProducts` | Total final product exergy leaving the plant. |
| `TotalOutput` | Total output exergy including waste flows. |
| `TotalIrreversibility` | Total plant irreversibility. |
| `TotalUnitConsumption` | Plant-level unit consumption. |
| `ActiveProcesses` | Logical vector marking active processes. |
| `ps` | Reference to the underlying `cProductiveStructure`. |

### `cExergyCost` public properties

| Property | Description |
| --- | --- |
| `SystemOutput` | Process output exergy delivered to the plant product. |
| `FinalDemand` | Effective final demand after waste-recycling adjustment. |
| `Resources` | External resource exergy consumed by each process. |
| `SystemUnitCost` | Plant-level unit exergy cost. |
| `RecirculationFactor` | Diagonal of the cost propagation operator, measuring process recirculation. |
| `WasteWeight` | Diagonal weights of the waste allocation operator. |
| `fpOperators` | FP-framework structural operators: `mFP`, `mRP`, `opCP`, and `opR`. |
| `pfOperators` | PF-framework structural operators: `mPF`, `mKP`, `opP`, `opI`, and `opR`. |
| `flowOperators` | Flow-level operators: `mG`, `opB`, and `opR`. |
| `isWaste` | Boolean indicating whether waste processes are present. |
| `WasteTable` | `cWasteData` object containing waste-allocation rules. |
| `TableR` | Exergy-weighted waste allocation matrix. |
| `RecycleRatio` | Waste recycle fraction per waste process. |
| `WasteAllocationRatios` | Normalized waste allocation matrix. |

The public properties in both classes are meant to be consumed only after validation has succeeded. If the object is invalid, the inherited `status` flag should be checked before access.

---

## 4. Public Methods

### `cExergyModel` public methods

| Method | Purpose |
| --- | --- |
| `cExergyModel(exd)` | Build the flow-process exergy model from a validated exergy state. |
| `InternalIrreversibility()` | Sum the process irreversibility vector. |
| `ExternalIrreversibility()` | Sum the exergy of waste flows. |
| `FlowProcessTable()` | Build the exergy-scaled flow-process table and optional block matrix. |
| `buildResultInfo(fmt)` | Return the exergy-analysis result container. |
| `get.FuelExergy` | Get fuel exergy for each process. |
| `get.ProductExergy` | Get product exergy for each process. |
| `get.Irreversibility` | Get process irreversibility. |
| `get.UnitConsumption` | Get process unit consumption values. |
| `get.Efficiency` | Get process exergy efficiencies. |
| `get.TotalResources` | Get total resource exergy. |
| `get.FinalProducts` | Get total final product exergy. |
| `get.TotalUnitConsumption` | Get the plant-level unit consumption. |
| `get.TotalIrreversibility` | Get total plant irreversibility. |
| `get.TotalOutput` | Get total output exergy. |

### `cExergyCost` public methods

| Method | Purpose |
| --- | --- |
| `cExergyCost(exd, wd)` | Build the cost operators and waste-allocation structure from the exergy state. |
| `buildResultInfo(fmt, options)` | Build the thermoeconomic analysis result container. |
| `getSpectralRatio()` | Compute the spectral radius used for convergence and solvability checks. |
| `getProcessCost(rsc)` | Get absolute process costs, direct or generalized. |
| `getProcessUnitCost(rsc)` | Get unit process costs, direct or generalized. |
| `getFlowsCost(rsc)` | Get absolute/unit cost of each flow. |
| `getStreamsCost(fcost)` | Get absolute/unit cost of productive streams. |
| `getCostTableFP(ucost)` | Get the FP cost table scaled by process unit costs. |
| `getDirectCostTableFPR(ucost)` | Get the direct-cost FPR table. |
| `getGeneralCostTableFPR(rsc, ucost)` | Get the generalized-cost FPR table. |
| `getIrreversibilityCostTables(rsc)` | Get process and flow irreversibility cost tables. |
| `getResourcesCostDistribution(rsd)` | Decompose resource cost across flows and processes. |
| `updateWasteOperators()` | Recompute waste allocation ratios and the waste cost operators. |
| `get.SystemOutput` | Access the final product exergy delivered by each process. |
| `get.FinalDemand` | Access effective final demand, adjusted for waste recycling. |
| `get.Resources` | Access external resource exergy vector. |
| `get.SystemUnitCost` | Access the plant-level unit cost. |
| `get.RecirculationFactor` | Access the process recirculation factor. |
| `get.WasteWeight` | Access waste cost operator weights. |
| `get.WasteAllocationRatios` | Access the normalized waste allocation matrix. |

### Static utility methods in `cExergyCost`

| Method | Purpose |
| --- | --- |
| `updateOperator(op, opR)` | Add indirect waste cost effects to a base operator. |
| `getOpR(mR, opL)` | Build the waste cost operator from a waste-allocation matrix and a base cost operator. |

---

## 5. Related Classes

| Class | Relationship |
| --- | --- |
| [`cProductiveStructure`](../Classes/cProductiveStructure.m) | Provides the topology, flow mapping, and adjacency matrices used by the exergy-state validation. |
| [`cExergyData`](../Classes/cExergyData.m) | Produces the validated state and the exergy-scaled adjacency tables consumed by `cExergyModel`. |
| [`cWasteData`](../Classes/cWasteData.m) | Defines waste allocation rules and recycling behavior used by `cExergyCost`. |
| [`cResourceData`](../Classes/cResourceData.m) | Supplies external resource unit prices and capital costs for generalized cost calculations. |
| [`cResultId`](../Classes/cResultId.m) | Base class that provides result IDs and common result metadata. |
| [`cResultInfo`](../Classes/cResultInfo.m) | Stores the formatted tables produced by `buildResultInfo`. |
| [`cResultTableBuilder`](../Classes/cResultTableBuilder.m) | Builds the visible analysis tables exposed by the result container. |
| [`cType`](../Classes/cType.m) | Provides flow, process, stream, and result identifiers used across the model. |
| [`cDigraphAnalysis`](../Classes/cDigraphAnalysis.m) | Used when graph reachability and connectivity checks are needed. |
| [`cMessages`](../Classes/cMessages.m) | Provides the standard validation and error messaging constants. |
| [`cMessageLogger`](../Classes/cMessageLogger.m) | Base logging mechanism used to report invalid states and operator failures. |

---

## 6. Error Handling

Both classes use construction-time validation and inherited message logging instead of throwing recoverable exceptions.

### Common failure modes for `cExergyModel`

| Failure case | Typical message | Meaning |
| --- | --- | --- |
| Wrong input object | `InvalidObject` | The input is not a validated `cExergyData` instance. |
| Invalid state data | `InvalidExergyDefinition` | The exergy state is missing required data or contains mismatched arrays. |
| Unreachable productive state | `OutputNotReachedFromNode` | An active process cannot reach the productive output. |
| Non-productive model | `NoProductiveState` | The model does not satisfy the productive-graph assumptions needed for exergy analysis. |

### Common failure modes for `cExergyCost`

| Failure case | Typical message | Meaning |
| --- | --- | --- |
| Invalid waste object | `InvalidObject` | `wd` is not a valid `cWasteData` instance. |
| No waste model | `NoWasteModel` | A waste-operation call was attempted without waste processes. |
| Invalid waste allocation type | `InvalidWasteType` | Waste type not recognized by the allocation engine. |
| Invalid waste allocation values | `NoWasteAllocationValues` | Allocation generated no usable values for a waste process. |
| Invalid argument to a method | `InvalidArgument` | A required cost or data structure is missing or malformed. |
| Invalid waste operator setup | `InvalidWasteOperator` | The waste allocation matrix does not produce a valid operator. |

### Recommended handling pattern

```matlab
exm = cExergyModel(exd);
if ~isValid(exm)
    return;
end

exc = cExergyCost(exd, wd);
if ~isValid(exc)
    return;
end
```

### Practical rule

Do not consume process or cost results unless the object status is valid. The data that is created during initialization (`TableFP`, `FlowProcessModel`, `fpOperators`, `pfOperators`, `WasteTable`, etc.) is only meaningful once the upstream validation chain has succeeded.

---

## 7. Source Reference

The implementation and public API summarized here are defined in:

- [`cExergyModel.m`](../Classes/cExergyModel.m)
- [`cExergyCost.m`](../Classes/cExergyCost.m)
