% Thermoeconomic Analysis Toolbox
%   Version 1.8 (R2024b) 01-Oct-2025
%
% Import/Export Functions
%   exportCSV                 - Export cell array to CSV file.
%   exportJSON                - Export MATLAB structure to JSON file.
%   exportMAT                 - Export cTaesLab object to MAT file.
%   importCSV                 - Import CSV file contents as cell array.
%   importJSON                - Import JSON file and parse into MATLAB structure.
%   importMAT                 - Import cTaesLab object from MAT file.
%
% Validation Functions
%   isFilename                - Validate if a filename is acceptable for read/write operations.
%   isIndex                   - Check if an integer value is within a valid index range.
%   isInteger                 - Check if the value is an integer number.
%   isMatlab                  - Identifies if the function has been executed in MATLAB.
%   isNonNegativeMatrix       - Check if the matrix is square and non-negative.
%   isObject                  - Check if 'obj' is a valid cTaesLab object belong to a specific class.
%   isOctave                  - Identifies if the function has been executed in Octave.
%   isProductiveMatrix        - Check if a matrix represents a productive matrix.
%   isSquareMatrix            - Check if input is a numeric or logical square matrix.
%   isValid                   - Check if 'obj' is a valid TaesLab object.
%
% Matrix Operation Functions
%   divideCol                 - Divide each column of matrix A by corresponding element of vector x.
%   divideRow                 - Divide each row of matrix A by corresponding element of vector x.
%   inverseMatrixOperator     - Calculate the inverse of a M-Matrix (I-A).
%   logicalMatrix             - Convert numeric matrix to logical with zero tolerance.
%   npinv                     - Compute inverse of a M-matrix (I - A) using Gauss-Jordan elimination.
%   scaleCol                  - Multiply each column of matrix A by corresponding element of vector x.
%   scaleRow                  - Multiply each row of matrix A by corresponding element of vector x.
%   similarDemandMatrix       - Transform resource-driven matrix to demand-driven form.
%   similarDemandOperator     - Convert resource-driven operator to demand-driven operator.
%   similarResourceMatrix     - Compute resource-driven matrix from demand-driven matrix.
%   similarResourceOperator   - Compute resource-driven operator from demand-driven operator.
%   tolerance                 - Compute relative tolerance value for a matrix.
%   vDivide                   - Element-wise division with NaN handling for 0/0 cases.
%   zerotol                   - Set matrix values near zero to exact zero.
%
% Digraph Functions
%   dfs                       - Depth-First Search traversal of a digraph
%   topologicalOrder          - Get topological order indices of a DAG.
%   transitiveClosure         - Compute the transitive closure of a directed graph.
%
% Miscellaneous Functions
%   buildMessage              - Build error messages for TaesLab functions.
%   fdisplay                  - Display a matrix A using C-like formatting.
