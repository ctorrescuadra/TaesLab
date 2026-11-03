% Thermoeconomic Analysis Toolbox
%   Version 1.8 (R2024b) 01-Oct-2025
%
% Import/Export Functions
%   buildMessage              - Build error messages for TaesLab functions.
%   exportCSV                 - Export cell array to CSV file.
%   exportJSON                - Export MATLAB structure to JSON file.
%   exportMAT                 - Export cTaesLab object to MAT file.
%   fdisplay                  - Display a matrix A using C-like formatting.
%   importCSV                 - Import CSV file contents as cell array.
%   importJSON                - Import JSON file and parse into MATLAB structure.
%   importMAT                 - Import cTaesLab object from MAT file.
%
% Matrix Operation Functions
%   logicalMatrix             - Convert numeric matrix to logical with zero tolerance.
%   divideCol                 - Divide each column of matrix A by corresponding element of vector x.
%   divideRow                 - Divide each row of matrix A by corresponding element of vector x.
%   scaleCol                  - Multiply each column of matrix A by corresponding element of vector x.
%   scaleRow                  - Multiply each row of matrix A by corresponding element of vector x.
%   similarDemandMatrix       - Transform resource-driven matrix to demand-driven form.
%   spectralRadius            - Compute the spectral radius of a non-negative matrix
%   similarDemandOperator     - Convert resource-driven operator to demand-driven operator.
%   similarResourceMatrix     - Compute resource-driven matrix from demand-driven matrix.
%   similarResourceOperator   - Compute resource-driven operator from demand-driven operator.
%   tolerance                 - Compute relative tolerance value for a matrix.
%   vDivide                   - Element-wise division with NaN handling for 0/0 cases.
%   zerotol                   - Set matrix values near zero to exact zero.
%
% Validation Functions
%   isFilename                - Validate if a filename is acceptable for read/write operations.
%   isObject                  - Check if 'obj' is a valid cTaesLab object belong to a specific class.
%   isValid                   - Check if 'obj' is a valid TaesLab object.
%   isIndex                   - Check if an integer value is within a valid index range.
%   isInteger                 - Check if the value is an integer number.
%   isMatlab                  - Identifies if the function has been executed in MATLAB.
%   isOctave                  - Identifies if the function has been executed in Octave.
%   isSquareMatrix            - Check if input is a numeric or logical square matrix.
%   isNonNegativeMatrix       - Check if the matrix is square and non-negative.
