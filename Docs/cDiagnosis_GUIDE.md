# cDiagnosis Guide

`cDiagnosis` performs a thermoeconomic diagnosis of a plant state change by comparing two `cExergyCost` models of the same productive structure: a reference state and an operating state. The class quantifies how the change in resource consumption and product demand is explained by process malfunctions, disfunctions, waste effects, and demand variations.

The class is part of the TaesLab diagnosis layer and is intended to answer the question:

> How much of the observed change in system fuel consumption is caused by process degradation, demand changes, and waste variation?

## 1. Purpose and objective

The objective of `cDiagnosis` is to decompose the total change in system resource consumption between two states into interpretable terms:

- process malfunction (intrinsic efficiency degradation)
- internal and external disfunction contributions
- final demand variation cost
- waste variation and waste malfunction cost
- total fuel impact and technical saving

This decomposition is performed from the variation of the unit consumption matrix:

```matlab
DKP = mKP1 - mKP0
```

where `mKP` is the process matrix of unit consumption. The class compares the reference and operation states and computes the cost-impact structure of the change, which is then exposed as analysis tables and vectors.

### Supported diagnosis modes

The class supports two diagnosis modes:

- `cType.DiagnosisMethod.WASTE_EXTERNAL`
  - waste flows are treated as additional system outputs
  - waste variation is kept separate from propagated cost operators
- `cType.DiagnosisMethod.WASTE_INTERNAL`
  - waste costs are internalized through the waste allocation operator
  - external disfunctions are propagated into the productive structure

## 2. Input parameters

The constructor signature is:

```matlab
obj = cDiagnosis(fp0, fp1, method)
```

### Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| `fp0` | `cExergyCost` | The reference-state thermoeconomic model. |
| `fp1` | `cExergyCost` | The operation-state thermoeconomic model. |
| `method` | `cType.DiagnosisMethod` | Diagnosis method used: external or internal waste handling. |

### Required conditions

The constructor validates the following before building the diagnosis object:

- `fp0` and `fp1` are both valid `cExergyCost` objects
- both models share the same productive structure (`fp0.ps == fp1.ps`)
- both models have the same active-process configuration
- the selected diagnosis method is valid
- for internal waste diagnosis, `fp1.isWaste` must be true
- the two states are not thermodynamically identical (`DKP != 0`)

If any check fails, the object is not initialized and the message logger records the error.

## 3. Public properties

The public properties are the main outputs of the diagnosis object.

| Property | Type | Description |
| --- | --- | --- |
| `NrOfProcesses` | `double` | Number of productive processes in the diagnosed system. |
| `NrOfWastes` | `double` | Number of waste processes. |
| `FuelImpact` | `double` | Total variation in resource consumption between the operation and reference states. |
| `TechnicalSaving` | `double` | Malfunction cost net of demand-variation cost. |
| `Method` | `cType.DiagnosisMethod` | Diagnosis method used by the object. |

### Internal state variables used by the class

These are private properties used internally to compute the output quantities:

| Property | Purpose |
| --- | --- |
| `DKP` | Unit consumption variation matrix (`mKP1 - mKP0`) |
| `DW0` | System output variation vector |
| `DWt` | Final demand variation vector |
| `DWr` | Waste variation vector |
| `tMF` | Malfunction table |
| `vMF` | Malfunction vector |
| `DFin` | Internal disfunction matrix |
| `DFex` | External disfunction matrix |
| `tDI` | Total disfunction table |
| `tMC` | Malfunction cost table |
| `tMCR` | Waste malfunction cost table |
| `DCW` | Demand variation cost vector |

## 4. Public methods

### Constructor

```matlab
obj = cDiagnosis(fp0, fp1, method)
```

Creates the diagnosis object and computes all relevant decomposition terms from the two exergy-cost states.

### `buildResultInfo(obj, fmt)`

Builds a `cResultInfo` object for the diagnosis output and delegates table construction to `cResultTableBuilder`.

**Syntax:**

```matlab
res = obj.buildResultInfo(fmt)
```

**Input arguments:**

- `fmt` - result-table builder/format object

**Output arguments:**

- `res` - `cResultInfo` containing diagnosis results

### `getDiagnosisTable(obj)`

Returns all diagnosis column vectors in a single struct:

- `MF`
- `DI`
- `DR`
- `DPs`
- `MFC`
- `MRC`
- `DCPs`

### Vector and matrix reports

#### `getUnitConsumptionVariation(obj)`

Returns the net change in unit consumption for each process.

#### `getUnitCostVariation(obj)`

Returns the difference in operation/reference unit process costs.

#### `getIrreversibilityVariation(obj)`

Returns the irreversibility variation vector with the total appended as the last element.

#### `getOutputVariation(obj)`

Returns the system output variation vector.

#### `getDemandVariation(obj)`

Returns the final demand variation vector.

#### `getWasteVariation(obj)`

Returns the portion of output variation attributable to waste change.

#### `getDemandVariationCost(obj)`

Returns the demand variation cost for each process plus total cost.

#### `getMalfunction(obj)`

Returns the process malfunction vector.

#### `getMalfunctionCost(obj)`

Returns the malfunction cost vector.

#### `getWasteMalfunctionCost(obj)`

Returns the waste malfunction cost vector.

### Table builders

#### `getIrreversibilityTable(obj)`

Builds the irreversibility variation table.

#### `getMalfunctionTable(obj)`

Returns the full malfunction table with system output variation appended.

#### `getWasteMalfunctionCostTable(obj)`

Returns the waste malfunction cost matrix.

#### `getMalfunctionCostTable(obj)`

Returns the full malfunction cost table with demand variation information.

#### `getInternalDisfunction(obj)`

Returns the internal disfunction matrix.

#### `getExternalDisfunction(obj)`

Returns the external disfunction matrix.

### Demand correction analysis

#### `getDemandCorrectionCost(obj)`

Returns the cost increment associated with demand changes valued at the unit cost variation.

## 5. Diagnosis equations represented by the class

The class follows the decomposition logic used in thermoeconomic diagnosis:

- `DKP = mKP1 - mKP0`
- `DFin = opI * tMF(1:N,:)`
- `tMF = scaleCol(DKP, ProductExergy0)`
- `DWr = DW0 - DWt`
- `tDI = DFin + diag(DWr)` or `DFin + DFex` depending on the diagnosis method
- `tMC = DFin + diag(vMCR)` or `DFin + tMCR` depending on the diagnosis method

The exact decomposition depends on the chosen waste treatment method, but the output is always structured as a diagnostic summary of how much of the observed change is attributable to efficiency degradation, demand change, and waste effects.

## 6. Related classes and functions

| Class / Function | Relationship |
| --- | --- |
| [`../Classes/cExergyCost.m`](../Classes/cExergyCost.m) | The primary input objects used to compare the reference and operating states. |
| [`../Classes/cResultId.m`](../Classes/cResultId.m) | Base class that provides result identity and object metadata. |
| [`../Classes/cResultInfo.m`](../Classes/cResultInfo.m) | Result container used to package diagnosis tables for display/export. |
| [`../Classes/cResultTableBuilder.m`](../Classes/cResultTableBuilder.m) | Builds formatted tables for the diagnosis output. |
| [`../Classes/cProductiveStructure.m`](../Classes/cProductiveStructure.m) | Defines the productive structure shared by both `cExergyCost` objects. |
| [`../Classes/cType.m`](../Classes/cType.m) | Supplies diagnosis method enumerations and type constants. |

## 7. Error handling

The class follows the TaesLab validation model: it fails fast by logging errors and returning an invalid object status when the inputs do not satisfy the structural assumptions.

### Constructor validation checks

The constructor explicitly validates these conditions before creating the diagnosis object:

1. `fp0` and `fp1` are valid `cExergyCost` instances
   - constant: `cMessages.ExergyCostRequired`
   - message: `Input parameters are NOT cExergyCost objects`
2. both states share the same productive structure (`fp0.ps == fp1.ps`)
   - constant: `cMessages.InvalidDiagnosisStruct`
   - message: `Compare two different productive structures`
3. both states use the same active-process configuration
   - constant: `cMessages.InvalidDiagnosisConf`
   - message: `Compare two different plant configurations`
4. the diagnosis method is supported
   - constant: `cMessages.InvalidDiagnosisMethod`
   - message pattern: `Invalid Diagnosis Method %s`
5. for `WASTE_INTERNAL`, `fp1.isWaste` must be true
   - same constant and same validation error as above: `cMessages.InvalidDiagnosisMethod`
6. the states are not identical in the unit consumption matrix
   - constant: `cMessages.InvalidDiagnosisStruct`
   - message: `Compare two different productive structures`

### Error behavior

When a validation fails, the constructor calls:

```matlab
obj.messageLog(cType.ERROR, ...)
return
```

This aborts initialization and prevents the object from proceeding with diagnosis tables based on invalid or meaningless state comparisons. The class does not create a usable diagnosis object until all checks pass.

### Numerical safeguards

The class also normalizes matrix differences through `zerotol(...)` before using them in the decomposition. This avoids numerical noise creating artificial malfunction or disfunction terms when the states are effectively equal.

## 8. Summary

`cDiagnosis` is the thermoeconomic diagnosis engine of TaesLab. It compares two states of the same productive system, decomposes their resource consumption change into malfunction, disfunction, demand, and waste components, and exposes the result as vectors and tables ready for reporting or export.
