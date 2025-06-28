% Thermoeconomic Analysis Toolbox
%   Version 1.7 (R2024b) 03-Jul-2025
%
% Functions
%
%  divideCol.m                    - Divide each column of matrix A by the corresponding element of vector x.
%  divideRow.m                    - Divide each row of matrix A by the corresponding element of vector x.
%  scaleCol.m                     - Multiplies each column of matrix A by the corresponding element of vector x.
%  scaleRow.m                     - Multiplies each row of matrix A by the corresponding element of vector x.
%  vDivide.m                      - Element-wise right division. Overload operator rdivide when 0/0
%  zerotol.m                      - Sets to zero the matrix values near to zero
%  fdisplay.m                     - Display a matrix A using C-like fmt
%
%  exportCSV.m                    - Save a cell array as a CSV file
%  exportMAT.m                    - Save a cTaesLab object as a MAT file
%  importDataModel.m              - Get a cDataModel object from a previously saved MAT file
%  importMAT.m                    - Create a cTaesLab object from a previously saved MAT file
%  readModel.m                    - Read a data model file according to its extension.
%
%  isFilename.m                   - Check if file name is valid for read/write mode
%  isIndex.m                      - Check if a number belongs to an index range
%  isInteger.m                    - Check if the value is an integer number
%  isMatlab.m                     - Identifies if the funcion has been executed in MATLAB
%  isOctave                       - Identifies if the funcion has been executed in Octave
%  isObject.m                     - Check is a cTaesLab object belongs  to a specific class                   
%  isValid.m                      - Check if a cTaesLab object is valid
%  isNonNegativeMatrix.m          - Check if the matrix is non-negative
%  isNonSingularMatrix.m          - Check if the matrix i-A is non-singular
%
%  logicalMatrix.m                - Convert a real matrix to logical with zero tolerance
%  similarDemandMatrix.m          - Compute the demand-driven sparse adjacency matrix from the resource-driven matrix
%  similarDemandOperator.m        - Compute the demand-driven operator from the resource-driven operator
%  similarResourceMatrix.m        - Compute the resource-driven adjacency matrix from the demand-driven matrix
%  similarResourceOperator.m      - Compute the resource-driven operator from the demmand-drive operator
%  transitiveClosure.m            - Compute the transitive closure of a digraph
%  inverseMatrixOperator          - Calculate the inverse of the M-Matrix, I-A.
%
