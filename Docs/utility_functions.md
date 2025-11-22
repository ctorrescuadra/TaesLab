# Thermoeconomic Analysis Toolbox

  Version 1.8 (R2024b) 01-Oct-2025

## TaesLab Utility Funtions Reference

### Import/Export Functions

| Name           | Description                                                |
| :------------- | :----------------------------------------------------------|
| [exportCSV][]  | Save a cell array as a CSV file.                           |
| [exportMAT][]  | Save a cTaesLab object as a MAT file                       |
| [importCSV][]  | Read a CSV file and return its contents as a cell array.   |
| [importMAT][]  | Create a cTaesLab object from a previously saved MAT file. |

### Validation Functions

| Name                    | Description                                             |
| :---------------------- | :-------------------------------------------------------|
| [isFilename][]          | Check if file name is valid for read/write mode.        |
| [isIndex][]             | Check if a number belongs to an index range.            |
| [isInteger][]           | Check if the value is an integer number.                |
| [isMatlab][]            | Identifies if the function has been executed in MATLAB. |
| [isOctave][]            | Identifies if the function has been executed in Octave. |
| [isObject][]            | Check if a cTaesLab object belongs to a specific class. |
| [isValid][]             | Check if it is a valid cTaesLab object.                 |
| [isSquareMatrix][]      | Check if the matrix is square.                          |
| [isNonNegativeMatrix][] | Check if the matrix is non-negative.                    |
| [isNonSingularMatrix][] | Check if the matrix I-A is non-singular.                |

### Matrix Operations

| Name                        | Description                                                                  |
| :---------------------------| :----------------------------------------------------------------------------|
| [divideCol][]               | Divide each column of matrix A by the corresponding element of vector x.     |
| [divideRow][]               | Divide each row of matrix A by the corresponding element of vector x.        |
| [scaleCol][]                | Multiplies each column of matrix A by the corresponding element of vector x. |
| [scaleRow][]                | Multiplies each row of matrix A by the corresponding element of vector x.    |
| [vDivide][]                 | Element-wise right division. Overload operator rdivide when 0/0.             |
| [tolerance][]               | Compute the relative tolerance value for a matrix.                           |
| [zerotol][]                 | Sets to zero the matrix values near to zero.                                 |
| [logicalMatrix][]           | Convert a real matrix to logical with zero tolerance.                        |
| [similarDemandMatrix][]     | Compute the demand-driven adjacency matrix from the resource-driven matrix.  |
| [similarDemandOperator][]   | Compute the demand-driven operator from the resource-driven operator.        |
| [similarResourceMatrix][]   | Compute the resource-driven adjacency matrix from the demand-driven matrix.  |
| [similarResourceOperator][] | Compute the resource-driven operator from the demmand-drive operator.        |
| [transitiveClosure][]       | Compute the transitive closure of a digraph.                                 |
| [inverseMatrixOperator][]   | Calculate the inverse of the M-Matrix I-A                                    |

### Miscellaneous Functions

| Name             | Description                                 |
| :----------------| :-------------------------------------------|
| [fdisplay][]     | Display a matrix A using C-like formatting. |
| [buildMessage][] | Build error messages for TaesLab functions. |
| [mt2td][]        | Convert a MATLAB table to cTableData.       |

<!-- Reference Links - Functions Directory -->
[exportCSV]: ../Functions/exportCSV.m
[exportMAT]: ../Functions/exportMAT.m
[importCSV]: ../Functions/importCSV.m
[importMAT]: ../Functions/importMAT.m

<!-- Validation Functions -->
[isFilename]: ../Functions/isFilename.m
[isIndex]: ../Functions/isIndex.m
[isInteger]: ../Functions/isInteger.m
[isMatlab]: ../Functions/isMatlab.m
[isOctave]: ../Functions/isOctave.m
[isObject]: ../Functions/isObject.m
[isValid]: ../Functions/isValid.m
[isSquareMatrix]: ../Functions/isSquareMatrix.m
[isNonNegativeMatrix]: ../Functions/isNonNegativeMatrix.m
[isNonSingularMatrix]: ../Functions/isNonSingularMatrix.m

<!-- Matrix Operations -->
[divideCol]: ../Functions/divideCol.m
[divideRow]: ../Functions/divideRow.m
[scaleCol]: ../Functions/scaleCol.m
[scaleRow]: ../Functions/scaleRow.m
[vDivide]: ../Functions/vDivide.m
[tolerance]: ../Functions/tolerance.m
[zerotol]: ../Functions/zerotol.m
[logicalMatrix]: ../Functions/logicalMatrix.m
[similarDemandMatrix]: ../Functions/similarDemandMatrix.m
[similarDemandOperator]: ../Functions/similarDemandOperator.m
[similarResourceMatrix]: ../Functions/similarResourceMatrix.m
[similarResourceOperator]: ../Functions/similarResourceOperator.m
[transitiveClosure]: ../Functions/transitiveClosure.m
[inverseMatrixOperator]: ../Functions/inverseMatrixOperator.m

<!-- Miscellaneous Functions -->
[fdisplay]: ../Functions/fdisplay.m
[buildMessage]: ../Functions/buildMessage.m
[mt2td]: ../Functions/mt2td.m
