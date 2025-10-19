# TaesLab Toolbox Utility Functions

Version 1.8 (R2024b) 01-Oct-2025

## Import/Export Functions

| Function  | Description                                                |
| --------- | ---------------------------------------------------------- |
| exportCSV | Save a cell array as a CSV file.                           |
| exportMAT | Save a cTaesLab object as a MAT file                       |
| importCSV | Read a CSV file and return its contents as a cell array.   |
| importMAT | Create a cTaesLab object from a previously saved MAT file. |

## Validation Functions

| Function            | Description                                             |
| ------------------- | ------------------------------------------------------- |
| isFilename          | Check if file name is valid for read/write mode.        |
| isIndex             | Check if a number belongs to an index range.            |
| isInteger           | Check if the value is an integer number.                |
| isMatlab            | Identifies if the function has been executed in MATLAB. |
| isOctave            | Identifies if the function has been executed in Octave. |
| isObject            | Check if a cTaesLab object belongs to a specific class. |
| isValid             | Check if it is a valid cTaesLab object.                 |
| isSquareMatrix      | Check if the matrix is square.                          |
| isNonNegativeMatrix | Check if the matrix is non-negative.                    |
| isNonSingularMatrix | Check if the matrix i-A is non-singular.                |

## Matrix Operations

| Function                | Description                                                                  |
| ----------------------- | ---------------------------------------------------------------------------- |
| divideCol               | Divide each column of matrix A by the corresponding element of vector x.     |
| divideRow               | Divide each row of matrix A by the corresponding element of vector x.        |
| scaleCol                | Multiplies each column of matrix A by the corresponding element of vector x. |
| scaleRow                | Multiplies each row of matrix A by the corresponding element of vector x.    |
| vDivide                 | Element-wise right division. Overload operator rdivide when 0/0.             |
| zerotol                 | Sets to zero the matrix values near to zero.                                 |
| logicalMatrix           | Convert a real matrix to logical with zero tolerance.                        |
| similarDemandMatrix     | Compute the demand-driven adjacency matrix from the resource-driven matrix.  |
| similarDemandOperator   | Compute the demand-driven operator from the resource-driven operator.        |
| similarResourceMatrix   | Compute the resource-driven adjacency matrix from the demand-driven matrix.  |
| similarResourceOperator | Compute the resource-driven operator from the demmand-drive operator.        |
| transitiveClosure.      | Compute the transitive closure of a digraph.                                 |
| inverseMatrixOperator   | Calculate the inverse of the M-Matrix I-A                                    |

## Miscellaneous Functions

| Function     | Description                                 |
| ------------ | ------------------------------------------- |
| fdisplay     | Display a matrix A using C-like formatting. |
| buildMessage | Build error messages for TaesLab functions  |
