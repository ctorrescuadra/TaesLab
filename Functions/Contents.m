% Thermoeconomic Analysis Toolbox
%   Version 1.8 (R2024b) 01-Sep-2025
%
% Functions
%
%  divideCol                  - Divide each column of matrix A by the corresponding element of vector x.
%  divideRow                  - Divide each row of matrix A by the corresponding element of vector x.
%  scaleCol                   - Multiplies each column of matrix A by the corresponding element of vector x.
%  scaleRow                   - Multiplies each row of matrix A by the corresponding element of vector x.
%  vDivide                    - Element-wise right division. Overload operator rdivide when 0/0.
%  zerotol                    - Sets to zero the matrix values near to zero.
%  logicalMatrix              - Convert a real matrix to logical with zero tolerance.
%  fdisplay                   - Display a matrix A using C-like fmt.
%
%  exportCSV                  - Save a cell array as a CSV file.
%  exportMAT                  - Save a cTaesLab object as a MAT file.
%  importDataModel            - Get a cDataModel object from a previously saved MAT file.
%  importMAT                  - Create a cTaesLab object from a previously saved MAT file.
%  readModel                  - Read a data model file according to its extension.
%
%  isFilename                 - Check if file name is valid for read/write mode.
%  isIndex                    - Check if a number belongs to an index range.
%  isInteger                  - Check if the value is an integer number.
%  isMatlab                   - Identifies if the funcion has been executed in MATLAB.
%  isOctave                   - Identifies if the funcion has been executed in Octave.
%  isObject                   - Check is a cTaesLab object belongs  to a specific class.                  
%  isValid                    - Check if it is a valid TaesLab object.
%  isSquareMatrix             - Check if the matrix is square.
%  isNonNegativeMatrix        - Check if the matrix is non-negative.
%  isNonSingularMatrix        - Check if the matrix i-A is non-singular.
%
%  similarDemandMatrix        - Compute the demand-driven adjacency matrix from the resource-driven matrix.
%  similarDemandOperator      - Compute the demand-driven operator from the resource-driven operator.
%  similarResourceMatrix      - Compute the resource-driven adjacency matrix from the demand-driven matrix.
%  similarResourceOperator    - Compute the resource-driven operator from the demmand-drive operator.
%  transitiveClosure.         - Compute the transitive closure of a digraph.
%  inverseMatrixOperator      - Calculate the inverse of the M-Matrix, I-A.
%
