# TaesLab Utility Functions Reference Guide

This document provides a comprehensive reference for all utility functions in the TaesLab Functions folder. These functions provide essential validation, file I/O, matrix operations, and platform compatibility utilities.

## Table of Contents

- [Validation Functions](#validation-functions)
- [File I/O Functions](#file-io-functions)
- [Matrix Operations](#matrix-operations)
- [Platform Compatibility](#platform-compatibility)
- [Utility Functions](#utility-functions)
- [Message and Content Functions](#message-and-content-functions)

---

## Validation Functions

Functions for validating objects, data types, and matrix properties.

### `isValid(obj)`

**Purpose**: Check if an object is a valid TaesLab object  
**Syntax**: `res = isValid(obj)`  
**Input**: `obj` - cTaesLab object  
**Output**: `res` - logical (true/false)  
**Description**: Validates that the object is a cTaesLab instance and has valid status  
**Example**:

```matlab
if isValid(model)
    results = model.thermoeconomicAnalysis();
end
```

### `isObject(obj, className)`

**Purpose**: Check if an object is of a specific class type

**Description**: Validates object type and inheritance

**Syntax**: `res = isObject(obj, className)`

**Input**:

- `obj` - Object to validate
- `className` - Expected class name (string)

**Output**:

- `res` - logical (true/false)

**Example**:

```matlab
if isObject(data, 'cDataModel')
    % Process data model
end
```

### `isFilename(filename)`

**Purpose**: Validate filename format and existence  
**Syntax**: `res = isFilename(filename)`  
**Input**: `filename` - File path (char/string)  
**Output**: `res` - logical (true/false)  
**Description**: Checks filename validity before file operations  
**Example**:

```matlab
if isFilename('model.json')
    data = readModel('model.json');
end
```

### `isIndex(value, maxValue)`

**Purpose**: [TODO: Document purpose]  
**Syntax**: `[Add syntax]`  
**Input**: [TODO: Document inputs]  
**Output**: [TODO: Document outputs]  
**Description**: [TODO: Add description]  
**Example**: [TODO: Add example]

### `isInteger(value)`

**Purpose**: [TODO: Document purpose]  
**Syntax**: `[Add syntax]`  
**Input**: [TODO: Document inputs]  
**Output**: [TODO: Document outputs]  
**Description**: [TODO: Add description]  
**Example**: [TODO: Add example]

### Matrix Validation Functions

#### `isNonNegativeMatrix(matrix)`

**Purpose**: [TODO: Document purpose]  
**Syntax**: `[Add syntax]`  
**Input**: [TODO: Document inputs]  
**Output**: [TODO: Document outputs]  
**Description**: [TODO: Add description]  
**Example**: [TODO: Add example]

#### `isNonSingularMatrix(matrix)`

**Purpose**: [TODO: Document purpose]  
**Syntax**: `[Add syntax]`  
**Input**: [TODO: Document inputs]  
**Output**: [TODO: Document outputs]  
**Description**: [TODO: Add description]  
**Example**: [TODO: Add example]

#### `isSquareMatrix(matrix)`

**Purpose**: [TODO: Document purpose]  
**Syntax**: `[Add syntax]`  
**Input**: [TODO: Document inputs]  
**Output**: [TODO: Document outputs]  
**Description**: [TODO: Add description]  
**Example**: [TODO: Add example]

---

## File I/O Functions

Functions for importing and exporting data in various formats.

### Export Functions

#### `exportMAT(obj, filename)`

**Purpose**: Save a valid cTaesLab object as MAT file  
**Syntax**: `log = exportMAT(obj, filename)`  
**Input**:
- `obj` - Valid cTaesLab object
- `filename` - MAT file name (char/string)  
**Output**: `log` - cMessageLogger with status and error messages  
**Description**: Used by SaveResults and SaveTable for MAT file export  
**Example**:

```matlab
log = exportMAT(results, 'analysis.mat');
if log.hasErrors
    disp('Export failed');
end
```

#### `exportCSV(obj, filename)`
**Purpose**: [TODO: Document purpose]  
**Syntax**: `[Add syntax]`  
**Input**: [TODO: Document inputs]  
**Output**: [TODO: Document outputs]  
**Description**: [TODO: Add description]  
**Example**: [TODO: Add example]

### Import Functions

#### `importMAT(filename)`
**Purpose**: [TODO: Document purpose]  
**Syntax**: `[Add syntax]`  
**Input**: [TODO: Document inputs]  
**Output**: [TODO: Document outputs]  
**Description**: [TODO: Add description]  
**Example**: [TODO: Add example]

#### `importCSV(filename)`
**Purpose**: [TODO: Document purpose]  
**Syntax**: `[Add syntax]`  
**Input**: [TODO: Document inputs]  
**Output**: [TODO: Document outputs]  
**Description**: [TODO: Add description]  
**Example**: [TODO: Add example]

---

## Matrix Operations

Functions for matrix manipulation and mathematical operations.

### Basic Matrix Operations

#### `zerotol(A, tol)`
**Purpose**: Set matrix values near zero to exactly zero  
**Syntax**: 
- `B = zerotol(A)`
- `B = zerotol(A, tol)`  
**Input**: 
- `A` - Input matrix
- `tol` - Tolerance (optional, default is cType.EPS)  
**Output**: `B` - Modified matrix with small values set to zero  
**Description**: Eliminates numerical noise by setting values smaller than tolerance to zero  
**Example**: 
```matlab
A = [0.1, 0.2; 0.00001, 0.3];
A = zerotol(A, 0.0001); % Result: [0.1, 0.2; 0, 0.3]
```

#### `scaleCol(matrix, vector)`
**Purpose**: [TODO: Document purpose]  
**Syntax**: `[Add syntax]`  
**Input**: [TODO: Document inputs]  
**Output**: [TODO: Document outputs]  
**Description**: [TODO: Add description]  
**Example**: [TODO: Add example]

#### `scaleRow(matrix, vector)`
**Purpose**: [TODO: Document purpose]  
**Syntax**: `[Add syntax]`  
**Input**: [TODO: Document inputs]  
**Output**: [TODO: Document outputs]  
**Description**: [TODO: Add description]  
**Example**: [TODO: Add example]

#### `divideCol(matrix, vector)`
**Purpose**: [TODO: Document purpose]  
**Syntax**: `[Add syntax]`  
**Input**: [TODO: Document inputs]  
**Output**: [TODO: Document outputs]  
**Description**: [TODO: Add description]  
**Example**: [TODO: Add example]

#### `divideRow(matrix, vector)`
**Purpose**: [TODO: Document purpose]  
**Syntax**: `[Add syntax]`  
**Input**: [TODO: Document inputs]  
**Output**: [TODO: Document outputs]  
**Description**: [TODO: Add description]  
**Example**: [TODO: Add example]

#### `vDivide(vector1, vector2)`
**Purpose**: [TODO: Document purpose]  
**Syntax**: `[Add syntax]`  
**Input**: [TODO: Document inputs]  
**Output**: [TODO: Document outputs]  
**Description**: [TODO: Add description]  
**Example**: [TODO: Add example]

### Advanced Matrix Operations

#### `logicalMatrix(matrix)`
**Purpose**: [TODO: Document purpose]  
**Syntax**: `[Add syntax]`  
**Input**: [TODO: Document inputs]  
**Output**: [TODO: Document outputs]  
**Description**: [TODO: Add description]  
**Example**: [TODO: Add example]

#### `inverseMatrixOperator(matrix)`
**Purpose**: [TODO: Document purpose]  
**Syntax**: `[Add syntax]`  
**Input**: [TODO: Document inputs]  
**Output**: [TODO: Document outputs]  
**Description**: [TODO: Add description]  
**Example**: [TODO: Add example]

#### `transitiveClosure(matrix)`
**Purpose**: [TODO: Document purpose]  
**Syntax**: `[Add syntax]`  
**Input**: [TODO: Document inputs]  
**Output**: [TODO: Document outputs]  
**Description**: [TODO: Add description]  
**Example**: [TODO: Add example]

### Specialized Matrix Functions

#### `similarDemandMatrix(params)`
**Purpose**: [TODO: Document purpose]  
**Syntax**: `[Add syntax]`  
**Input**: [TODO: Document inputs]  
**Output**: [TODO: Document outputs]  
**Description**: [TODO: Add description]  
**Example**: [TODO: Add example]

#### `similarDemandOperator(params)`
**Purpose**: [TODO: Document purpose]  
**Syntax**: `[Add syntax]`  
**Input**: [TODO: Document inputs]  
**Output**: [TODO: Document outputs]  
**Description**: [TODO: Add description]  
**Example**: [TODO: Add example]

#### `similarResourceMatrix(params)`
**Purpose**: [TODO: Document purpose]  
**Syntax**: `[Add syntax]`  
**Input**: [TODO: Document inputs]  
**Output**: [TODO: Document outputs]  
**Description**: [TODO: Add description]  
**Example**: [TODO: Add example]

#### `similarResourceOperator(params)`
**Purpose**: [TODO: Document purpose]  
**Syntax**: `[Add syntax]`  
**Input**: [TODO: Document inputs]  
**Output**: [TODO: Document outputs]  
**Description**: [TODO: Add description]  
**Example**: [TODO: Add example]

---

## Platform Compatibility

Functions for MATLAB/Octave compatibility detection.

### `isMatlab()`
**Purpose**: Identify if code is running in MATLAB  
**Syntax**: `res = isMatlab()`  
**Input**: None  
**Output**: `res` - logical (true if MATLAB, false if Octave)  
**Description**: Used for platform-specific code branches and feature detection  
**Example**: 
```matlab
if isMatlab()
    % Use MATLAB-specific features
    uifigure();
else
    % Use Octave alternatives
    figure();
end
```

### `isOctave()`
**Purpose**: Identify if code is running in Octave  
**Syntax**: `res = isOctave()`  
**Input**: None  
**Output**: `res` - logical (true if Octave, false if MATLAB)  
**Description**: Complement to isMatlab() for Octave-specific functionality  
**Example**: 
```matlab
if isOctave()
    % Load Octave packages
    pkg load statistics;
end
```

---

## Utility Functions

General-purpose utility functions.

### `tolerance(value)`
**Purpose**: [TODO: Document purpose]  
**Syntax**: `[Add syntax]`  
**Input**: [TODO: Document inputs]  
**Output**: [TODO: Document outputs]  
**Description**: [TODO: Add description]  
**Example**: [TODO: Add example]

### `fdisplay(format, values)`
**Purpose**: [TODO: Document purpose]  
**Syntax**: `[Add syntax]`  
**Input**: [TODO: Document inputs]  
**Output**: [TODO: Document outputs]  
**Description**: [TODO: Add description]  
**Example**: [TODO: Add example]

---

## Message and Content Functions

Functions for building documentation and messages.

### `buildContents()`
**Purpose**: [TODO: Document purpose]  
**Syntax**: `[Add syntax]`  
**Input**: [TODO: Document inputs]  
**Output**: [TODO: Document outputs]  
**Description**: [TODO: Add description]  
**Example**: [TODO: Add example]

### `buildMessage(type, message)`
**Purpose**: [TODO: Document purpose]  
**Syntax**: `[Add syntax]`  
**Input**: [TODO: Document inputs]  
**Output**: [TODO: Document outputs]  
**Description**: [TODO: Add description]  
**Example**: [TODO: Add example]

---

## Usage Guidelines

### General Patterns

1. **Validation First**: Always validate inputs using appropriate `is*` functions
```matlab
if ~isValid(obj) || ~isFilename(filename)
    error('Invalid inputs');
end
```

2. **Platform Compatibility**: Use platform detection for conditional features
```matlab
if isMatlab()
    % MATLAB-specific code
else
    % Octave fallback
end
```

3. **Error Handling**: Check return values and handle errors appropriately
```matlab
log = exportMAT(data, 'output.mat');
if log.hasErrors
    log.displayErrors();
end
```

4. **Numerical Tolerance**: Use `zerotol()` for cleaning numerical results
```matlab
cleanMatrix = zerotol(noisyMatrix, cType.EPS);
```

### Best Practices

- **File Operations**: Always validate filenames before I/O operations
- **Matrix Operations**: Use appropriate tolerance functions for numerical stability
- **Object Validation**: Check object validity before method calls
- **Platform Awareness**: Design code to work on both MATLAB and Octave when possible

---

## See Also

- [TaesLab Classes Reference](../Classes/README.md)
- [Base Functions Reference](../Base/README.md)
- [Examples and Tutorials](../Examples/README.md)

---

*Generated on: November 2025*  
*TaesLab Version: 1.8*
