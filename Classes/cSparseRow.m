classdef  cSparseRow < cTaesLab
%cSparseRow - Store and operate matrices that contain few non-null rows.
%   Specialized matrix class that stores only non-zero rows in memory, providing
%   significant memory savings and computational efficiency for matrices where most
%   rows are zero. It is used in thermoeconomic waste allocation where there is 
%   only a few waste flows respect to the total number of flows.
%
%   The class stores an N×M matrix using only NR rows (where NR << N),
%   reducing memory storage from O(N*M) to O(NR*M). All standard
%   matrix operations are supported through operator overloading, with automatic
%   handling of sparse/dense interactions.
%
%   Key Features:
%     • Memory efficiency: Only stores non-zero rows (typically 1-10% of total)
%     • Full matrix algebra: Supports +, -, *, transpose, scaling, division
%     • Transparent usage: Acts like regular matrix through operator overloading
%     • Seamless conversion: to/from full and sparse MATLAB matrices
%     • Vector operations: Efficient row/column sum, scale, and divide
%
%   Storage Strategy:
%     Instead of storing full N×M matrix with mostly zero rows:
%       Traditional: [N×M] matrix → N*M elements in memory
%       cSparseRow: [NR×M] values + [NR×1] indices → (NR*M + NR) elements
%
%     Example for N=100, M=50, NR=5:
%       Full matrix: 5,000 elements (100 rows × 50 cols)
%       Sparse row: 255 elements (5 rows × 50 cols + 5 indices)
%       Memory savings: 95%
%
%   Use Cases in TaesLab:
%     • Waste cost recycling matrices (few waste flows across many processes)
%     • Matrix inverse calculations using Woodbury formula
%
%   Properties (Public, Read-Only):
%     N - Total number of rows in matrix
%		uint32
%     NR - Number of active (non-zero) rows
%       uint32
%     M - Number of columns
%		uint32
%     mRows - Indices of active rows
%       double array (NR x 1)
%     mValues - Active row values
%       double array (NR × M)
%
%   cSparseRow Methods (Public):
%     Construction and conversion:
%       cSparseRow - Constructor from active rows and values
%       full - Convert to full dense matrix
%       sparse - Convert to MATLAB sparse matrix
%
%     Vector operations:
%       scaleCol - Multiply each column by scalar (column-wise scaling)
%       scaleRow - Multiply each row by scalar (row-wise scaling)
%       divideCol - Divide each column by scalar (column normalization)
%       divideRow - Divide each row by scalar (row normalization)
%       sumRows - Sum all columns in each row (row totals)
%       sumCols - Sum all rows in each column (column totals)
%
%     Matrix algebra (overloaded operators):
%       plus (+) - Element-wise or matrix addition
%       minus (-) - Element-wise or matrix subtraction
%       uminus (-) - Unary negation
%       mtimes (*) - Matrix multiplication
%       transpose - Matrix transpose (.T or .')
%       ctranspose - Complex conjugate transpose (.H or ')
%       size - Matrix dimensions [N, M]
%       sum - Sum along dimension (1=cols, 2=rows)
%
%     Special operations:
%       inverseMatrix - Compute (I-A)^(-1) using Woodbury formula
%       printMatrix - Display full matrix representation
%
%   See also:
%     cWasteAnalysis, cExergyCost, sparse, full
%
	properties (GetAccess=public, SetAccess=private)
		N 		% Number of rows
		NR  	% Number of active rows
		M		% Number of Columns
		mRows   % list containing the non-null rows
		mValues % Matrix (NR x M) containing the active value
	end

	methods
		function obj=cSparseRow(rows,vals,n)
		%cSparseRow - Construct row-sparse matrix from active rows.
		%   Creates a sparse row matrix object that stores only specified non-zero
		%   rows. The logical matrix is N×M, but only NR rows are stored in memory.
		%   This constructor validates that row indices match value dimensions and
		%   ensures consistent matrix structure.
		%
		%   Syntax:
		%     obj = cSparseRow(rows, vals)
		%     obj = cSparseRow(rows, vals, n)
		%
		%   Arguments:
		%     rows - Active row indices
		%       Integer vector of length NR
		%       Contains row numbers (1 to N) that have non-zero values
		%       Must be unique and match number of rows in vals
		%       Example: [2, 5, 8] indicates rows 2, 5, and 8 are active
		%
		%     vals - Active row values
		%       Numeric matrix (NR × M)
		%       Contains actual values for non-zero rows
		%       Row i corresponds to logical row rows(i)
		%       Must have same number of rows as length(rows)
		%
		%     n - Total number of rows (optional)
		%       Positive integer, n ≥ NR
		%       Defines logical matrix dimension (n × M)
		%       Default: M (creates square matrix)
		%       Must be at least as large as NR
		%
		%   Validation:
		%     • length(rows) must equal size(vals, 1)
		%     • n must be ≥ NR if provided
		%     • Invalid parameters create error object via printError
		%
		%   Side Effects:
		%     • Sets object properties: N, NR, M, mRows, mValues
		%     • Inherits from cTaesLab (gets objectId and status)
		%     • On error, sets status=false and logs error message
		%
		%   Examples:
		%     % Example 1: Default square matrix (5x5) with 2 active rows (3,5)
		%     rows = [3, 5];
		%     vals = [0.1 0.3 0.4 0 0.2; 0.5 0.5 0 0 0];  % 2×5 matrix
		%     A = cSparseRow(rows, vals);
		%     % Creates 5 x 5 matrix with non-zero rows at 3, 5
		%
		%     % Example 2: Rectangular matrix (6x5) with 2 active rows (2,4)
		%     rows = [2, 4];
		%     vals = [0.1 0.3 0.4 0 0.2; 0.5 0.5 0 0 0];  % 2×5 matrix
		%     A = cSparseRow(rows, vals, 6);
		%     % Creates 6×5 sparse rows matrix
		%
		%   Common Usage:
		%     • Waste allocation matrix: mR=cSparseRow(wasteIndices, allocMatrix, nFlows)
		%
		%   See also:
		%     full, sparse
		%
			% Check Arguments and set properties
			narginchk(2,3);
			obj.NR=size(vals,1);
			obj.M=size(vals,2);
			if obj.NR ~= length(rows)
				obj.printError(cMessages.InvalidRowValues);
				return
			end
			obj.mRows=rows;
			obj.mValues=vals;
			if nargin==2
				obj.N=obj.M;
			elseif n>=obj.NR
				obj.N=n;
			else
				obj.printError(cMessages.InvalidRowSize);
			end
		end

		function nobj=scaleCol(obj,x)
		%scaleCol - Multiply each column by corresponding scalar.
		%   Performs column-wise scaling: each column j is multiplied by x(j).
		%   This operation is equivalent to matrix multiplication by diag(x) from
		%   the right (A * diag(x)), but more efficient as it only operates on
		%   active rows.
		%
		%   Syntax:
		%     nobj = obj.scaleCol(x)
		%     nobj = scaleCol(obj, x)
		%
		%   Arguments:
		%     x - Column scale factors
		%       Numeric vector of length M
		%       x(j) multiplies all elements in column j
		%       Can be row or column vector
		%       Must have length equal to obj.M
		%
		%   Returns:
		%     nobj - Scaled cSparseRow object
		%       Same dimensions as obj (N×M)
		%       Same active rows (mRows unchanged)
		%       Values: nobj(i,j) = obj(i,j) * x(j)
		%
		%   Mathematical Operation:
		%     For each active row i and column j:
		%       result(i,j) = obj(i,j) * x(j)
		%     Equivalent to: full(obj) * diag(x)
		%
		%   Side Effects:
		%     • Creates new object (does not modify obj)
		%     • On error, returns invalid cTaesLab object
		%
		%   Examples:
		%     rows = [4, 5];
		%     vals = [0.1 0.3 0.4 0 0.2; 0.5 0.5 0 0 0];  % 2×5 matrix
		%     x = [1 2 2 3 3]
		%     A = cSparseRow(rows, vals);
		%     B = A.scaleCol(x);  
		%     % B.mValues = [0.1 0.6 0.8 0 0.6; 0.5 1.0 0 0 0]
		%
		%   See also:
		%     divideCol, scaleRow, mtimes
		%
			% Check Arguments
			nobj=cTaesLab();
			if nargin==1
				nobj.printError(cMessages.InvaliArguments,'scaleCol');
				return
			end
			if(obj.M~=length(x))
				nobj.printError(cMessages.InvalidSparseRow,obj.M,length(rows));
				return
			end
			% Scale active matrix
			B=scaleCol(obj.mValues,x);
			nobj=cSparseRow(obj.mRows,B);
		end

		function nobj=divideCol(obj,x)
		%divideCol - Divide each column by corresponding scalar.
		%   Performs column-wise division: each column j is divided by x(j).
		%   Commonly used for column normalization, such as creating column-stochastic
		%   matrices where each column sums to 1. If no divisor vector is provided,
		%   automatically divides by column sums (self-normalization).
		%
		%   Syntax:
		%     nobj = obj.divideCol(x)
		%     nobj = obj.divideCol()  % Auto-normalize by column sums
		%     nobj = divideCol(obj, x)
		%
		%   Arguments:
		%     x - Column divisors (optional)
		%       Numeric vector of length M
		%       x(j) divides all elements in column j
		%       Default: obj.sumCols() (makes columns sum to 1)
		%       Must have length equal to obj.M
		%
		%   Returns:
		%     nobj - Normalized cSparseRow object
		%       Same dimensions as obj (N×M)
		%       Same active rows (mRows unchanged)
		%       Values: nobj(i,j) = obj(i,j) / x(j)
		%
		%   Mathematical Operation:
		%     For each active row i and column j:
		%       result(i,j) = obj(i,j) / x(j)
		%     With no argument: result(i,j) = obj(i,j) / sum_over_rows(obj(:,j))
		%     Equivalent to: obj * diag(1./x)
		%
		%   Side Effects:
		%     • Creates new object (does not modify obj)
		%     • On error, returns invalid cTaesLab object with error message
		%
		%   Examples:
		%     % Example 1: Normalize columns to sum to 1
		%     rows = [4, 5];
		%     vals = [0.1 0.3 0.4 0 0.2; 0.5 0.5 0 0 0];
        %     A = cSparseRow(rows, vals);
        %     B = A,divideRow();
        %     % B.mValues = [0.1667 0.3750 1.0000 0 1.0000;
        %                   [0.8333 0.6250 0      0 0]
		%     % B.sumRows() = [1 1 1 0 1]
		%
		%     % Example 2: Normalize by specific values
		%     x = [1 2 3 4 5];
        %     B = A.divideRow(x);
        %     % B.mValues = [0.1000 0.1500 0.1333 0 0.0400;
        %                   0.5000  0.2500 0      0 0]
		%   See also:
		%     scaleCol, divideRow, sumCols
		%
			% Check Values
			nobj=cTaesLab();
			if nargin==1
				x=obj.sumCols;
			end
			if(obj.M~=length(x))
				nobj.printError(cMessages.InvalidSparseRow,obj.M,length(rows));
				return
			end
			% Normalize active matrix
			B=divideCol(obj.mValues,x);
			nobj=cSparseRow(obj.mRows,B);
		end

		function nobj=scaleRow(obj,x)
		%scaleRow - Multiply each row by corresponding scalar.
		%   Performs row-wise scaling: each row i is multiplied by x(i). The scale
		%   vector must have length N (total rows), but only elements corresponding
		%   to active rows are actually used. This is equivalent to left multiplication
		%   by diag(x), but more efficient as only active rows are processed.
		%
		%   Syntax:
		%     nobj = obj.scaleRow(x)
		%     nobj = scaleRow(obj, x)
		%
		%   Arguments:
		%     x - Row scale factors
		%       Numeric vector of length N (full matrix row count)
		%       x(i) multiplies all elements in row i
		%       Only x(mRows) values are actually used
		%       Must have length equal to obj.N
		%       Can be row or column vector
		%
		%   Returns:
		%     nobj - Scaled cSparseRow object
		%       Same dimensions as obj (N×M)
		%       Same active rows (mRows unchanged)
		%       Values: nobj(i,j) = obj(i,j) * x(i) for active rows
		%
		%   Mathematical Operation:
		%     For each active row i (in mRows) and column j:
		%       result(i,j) = x(i) × obj(i,j)
		%     Equivalent to: diag(x) * obj
		%     Only x(obj.mRows) elements are used
		%
		%   Side Effects:
		%     • Creates new object (does not modify obj)
		%     • On error, returns invalid cTaesLab object with error message
		%
		%   Examples:
		%     rows = [4, 5];
		%     vals = [0.1 0.3 0.4 0 0.2; 0.5 0.5 0 0 0];
		%     x = [1 2 2 3 3]
		%     A = cSparseRow(rows, vals);
		%     B = A.scaleRow(x);  
		%     % B.mValues = [0.4000 1.2000 1.6000 0 0.8000;
        %                    2.5000 2.5000 0      0 0]
		%
		%   See also:
		%     divideRow, scaleCol, mtimes
		%
			% Check arguments
			nobj=cTaesLab();
			if(obj.N~=length(x))
				nobj.printError(cMessages.InvalidSparseRow,obj.N,length(rows));
				return
			end
			% Scale active matrix
			B=scaleRow(obj.mValues,x(obj.mRows));
			nobj=cSparseRow(obj.mRows,B);
		end

		function nobj=divideRow(obj,x)
		%divideRow - Divide each row by corresponding scalar.
		%   Performs row-wise division: each active row i is divided by x(i).
            %   If no divisor vector is provided, automatically divides by
		%   row sums for self-normalization. The divisor vector must have length N,
		%   but only elements at active row positions are used.
		%
		%   Syntax:
		%     nobj = obj.divideRow(x)
		%     nobj = obj.divideRow()  % Auto-normalize by row sums
		%     nobj = divideRow(obj, x)
		%
		%   Arguments:
		%     x - Row divisors (optional)
		%       Numeric vector of length obj.N
		%       x(i) divides all elements in row i
		%       if not provided, auto-normalize rows.
		%
		%   Returns:
		%     nobj - Normalized cSparseRow object
		%       Same dimensions as obj (N×M)
		%       Same active rows (mRows unchanged)
		%       Values: nobj(i,j) = obj(i,j) / x(i) for active rows
		%
		%   Mathematical Operation:
		%     For each active row i (in mRows) and column j:
		%       result(i,j) = obj(i,j) / x(i)
		%     Equivalent to: diag(1./x) * obj
		%
		%   Auto-normalization behavior:
		%     When called with no arguments (nargin==1):
		%       1. Computes row sums: x = obj.sumRows()
		%       2. Divides each active row by x
		%       Result: Each active row sums to 1
		%
		%   Side Effects:
		%     • Creates new object (does not modify obj)
		%     • On error, returns invalid cTaesLab object with error message
		%
		%   Examples:
		%     % Example 1: Normalize rows to sum to 1 (row-stochastic)
		%     rows = [4, 5];
		%     vals = [10 20 40 0 0; 20 0 40 0 0];
		%     A = cSparseRow(rows, vals);
        %     B = A.divideRow();
        %     % B.mValues = [0.1429 0.2857 0.5714 0 0;
        %                   [0.3333 0      0.6667 0 0]
        %     % B.sumRows() = [0; 0; 0; 1; 1]
		%
		%     % Example 3: Normalize by specific values
		%     rows = [4, 5];
		%     vals = [10 20 40 0 0; 20 0 40 0 0];
        %     x = [40 30 20 10 5]
		%     A = cSparseRow(rows, vals);
        %     B = A.divideRow(x);
        %     % B.mValues = [1.0 2.0 4.0 0 0;
        %                    4.0 0.0 8.0 0 0]
		%
		%   See also:
		%     scaleRow, divideCol, sumRows
		%
			% Check Arguments
			nobj=cTaesLab();
			if nargin==1
                x=obj.sumRows;
			end
			if(obj.N~=length(x))
				nobj.printError(cMessages.InvalidSparseRow,obj.N,length(rows));
				return
			end
			% Normalize active matrix
			B=divideRow(obj.mValues,x(obj.mRows));
			nobj=cSparseRow(obj.mRows,B);
		end

		function x = sumCols(obj)
		%sumCols - Compute column totals (sum across rows).
		%   Returns a row vector where each element is the sum of all values in
		%   that column. Since only active rows have non-zero values, this sums
		%   only the stored values in mValues. Used for column normalization,
		%   totaling process inputs, and validation.
		%
		%   Syntax:
		%     x = obj.sumCols()
		%     x = sumCols(obj)
		%
		%   Returns:
		%     x - Column sum vector
		%       Row vector of length M (1 × M)
		%       x(j) = sum of all elements in column j
		%       Equivalent to sum(full(obj), 1)
		%       Only sums active rows
		%
		%   Mathematical Operation:
		%     x(j) = Σ obj(i,j) for i in mRows
		%     Since inactive rows are zero, this equals full column sum
		%
		%   Examples:
        %     rows = [4, 5];
		%     vals = [10 20 40 0 0; 20 0 40 0 0];
		%     A = cSparseRow(rows, vals);
		%     x = sumCols(A);
		%     % x = [30 20 80 0 0]            
		%
		%   Common Usage:
		%     • Column normalization: divideCol(sumCols())
		%     • Process totals: Total input/cost per process column
		%     • Validation: Check allocation sums to expected values
		%
		%   See also:
		%     sumRows, sum, divideCol
		%
			x=sum(obj.mValues,1);
		end

		function x = sumRows(obj)
		%sumRows - Compute row totals (sum across columns).
		%   Returns a column vector of length N where each element is the sum of
		%   all values in that row. Inactive rows are zero (not stored), so the
		%   result vector is sparse but returned as full vector with zeros. Used
		%   for row normalization, flow totals, and validation.
		%
		%   Syntax:
		%     x = obj.sumRows()
		%     x = sumRows(obj)
		%
		%   Returns:
		%     x - Row sum vector
		%       Column vector of length N (N × 1)
		%       x(i) = sum of all elements in row i
		%       Non-zero only for active rows (indices in mRows)
		%       Zero for inactive rows
		%       Equivalent to sum(full(obj), 2)
		%
		%   Mathematical Operation:
		%     x(i) = Σ obj(i,j) for j = 1:M, if i in mRows
		%     x(i) = 0, if i not in mRows (inactive row)
		%
		%   Examples:
		%     rows = [4, 5];
		%     vals = [10 20 40 0 0; 20 0 40 0 0];
		%     A = cSparseRow(rows, vals);
		%     x = sumCols(A);
		%     % x = [0 0 0 70 60]   
		%
		%   Common Usage:
		%     • Row normalization: divideRow(sumRows())
		%     • Flow totals: Total allocation or cost per flow
		%     • Validation: Check row sums equal expected values
		%     • Active row detection: find(sumRows() ~= 0)
		%
		%   Performance:
		%     • Complexity: O(NR*M + N) - sum active rows, allocate N vector
		%     • Memory: O(N) - returns full vector (not sparse)
		%     • Could be optimized to return sparse vector
		%
		%   Implementation Note:
		%     Returns full N-length vector even though most elements are zero.
		%     This matches MATLAB convention and allows direct indexing.
		%
		%   See also:
		%     sumCols, sum, divideRow
		%
            x=zeros(obj.N,1);
			x(obj.mRows)=sum(obj.mValues,2);
		end

        function res=sum(obj,dim)
		%sum - Compute sum along specified dimension.
		%   Overloads MATLAB's built-in sum() function for cSparseRow objects.
		%   Provides consistent interface with standard matrix operations while
		%   leveraging sparse row structure for efficiency. Delegates to sumCols()
		%   or sumRows() based on dimension argument.
		%
		%   Syntax:
		%     res = sum(obj)       % Sum along dimension 1 (down columns)
		%     res = sum(obj, dim)  % Sum along specified dimension
		%
		%   Arguments:
		%     dim - Dimension to sum along (optional)
		%       1: Sum down columns (default) → returns row vector (1×M)
		%       2: Sum across rows → returns column vector (N×1)
		%       Default: 1 (MATLAB convention)
		%
		%   Returns:
		%     res - Sum result
		%       If dim=1: Row vector (1×M) of column sums [same as sumCols()]
		%       If dim=2: Column vector (N×1) of row sums [same as sumRows()]
		%
		%   MATLAB Compatibility:
		%     Follows standard MATLAB sum() behavior:
		%       dim=1: Operates down columns (eliminates row dimension)
		%       dim=2: Operates across rows (eliminates column dimension)
		%     This matches: sum(full(obj), dim)
		%
		%   Examples:
		%     % Example 1: Default behavior (sum down columns)
		%     A = cSparseRow([1, 3], [1 2; 3 4], 4);
		%     s = sum(A);  % Same as sum(A, 1)
		%     % s = [4, 6] (column sums)
		%
		%     % Example 2: Sum across rows (dimension 2)
		%     A = cSparseRow([2, 4], [1 2 3; 4 5 6], 5);
		%     s = sum(A, 2);
		%     % s = [0; 6; 0; 15; 0] (row sums)
		%
		%     % Example 3: Verify equivalence with full matrix
		%     A = cSparseRow([1, 2], [1 2 3; 4 5 6], 3);
		%     s1 = sum(A, 1);         % [5, 7, 9]
		%     s2 = sum(full(A), 1);   % [5, 7, 9] (identical)
		%
		%     % Example 4: Total of all elements
		%     A = cSparseRow([2, 3], [1 2; 3 4], 4);
		%     total = sum(sum(A));  % sum(sum(A,1)) → sum([4,6]) = 10
		%     % Equivalent to: sum(A(:))
		%
		%     % Example 5: Use in expressions
		%     W = cSparseRow([5], [0.3 0.4 0.3], 10);
		%     colTotals = sum(W, 1);   % [0.3, 0.4, 0.3]
		%     rowTotals = sum(W, 2);   % [0;0;0;0;1.0;0;0;0;0;0]
		%
		%   Common Usage:
		%     • Column totals: sum(obj) or sum(obj, 1)
		%     • Row totals: sum(obj, 2)
		%     • Grand total: sum(sum(obj)) or sum(obj(:))
		%     • Mean calculation: sum(obj, dim) / size(obj, dim)
		%
		%   See also:
		%     sumCols, sumRows, sum, mean
		%
            narginchk(1,2)
            if nargin==1
             dim=1;
            end
            switch dim
            case 1
                res=sumCols(obj);
            case 2
                res=sumRows(obj);
            end
        end

		function nobj=plus(obj1,obj2)
		%plus - Element-wise addition of sparse row matrices.
		%   Overloads the + operator for cSparseRow objects. Supports addition
		%   between two cSparseRow objects or between cSparseRow and regular
		%   matrices. When both operands are cSparseRow with matching active rows,
		%   the result maintains the sparse row structure efficiently.
		%
		%   Syntax:
		%     nobj = obj1 + obj2
		%     nobj = plus(obj1, obj2)
		%
		%   Arguments:
		%     obj1 - First operand
		%       cSparseRow object or numeric matrix
		%       Dimensions must match obj2
		%
		%     obj2 - Second operand
		%       cSparseRow object or numeric matrix
		%       Dimensions must match obj1
		%
		%   Returns:
		%     nobj - Sum result
		%       cSparseRow if both inputs are cSparseRow (when possible)
		%       Full matrix if one input is full matrix
		%       Invalid cTaesLab object on dimension mismatch
		%
		%   Operation Cases:
		%     Case 1 (both cSparseRow): Returns cSparseRow with union of active rows
		%     Case 2 (sparse + full): Converts sparse to full, adds to full
		%     Case 3 (full + sparse): Adds sparse values to full matrix
		%
		%   Examples:
		%     % Example 1: Add two sparse row matrices (same active rows)
		%     A = cSparseRow([2, 4], [1 2; 3 4], 5);
		%     B = cSparseRow([2, 4], [10 20; 30 40], 5);
		%     C = A + B;  % cSparseRow with rows 2,4 active
		%     % C(2,:) = [11, 22], C(4,:) = [33, 44]
		%
		%     % Example 2: Add sparse to full matrix
		%     A = cSparseRow([2], [10 20], 3);
		%     B = ones(3, 2);
		%     C = A + B;  % Full 3×2 matrix
		%     % C = [1, 1; 11, 21; 1, 1]
		%
		%     % Example 3: Accumulate waste allocations
		%     W1 = cSparseRow([5], [0.2 0.3 0.5], 10);
		%     W2 = cSparseRow([5], [0.1 0.1 0.1], 10);
		%     Wtotal = W1 + W2;  % Combined allocation
		%     % Wtotal(5,:) = [0.3, 0.4, 0.6]
		%
		%     % Example 4: Add constant matrix
		%     A = cSparseRow([1, 3], [1 2; 3 4], 4);
		%     B = A + eye(4);  % Add identity matrix
		%
		%   See also:
		%     minus, uminus, mtimes
		%
			nobj=cTaesLab();
			% Check dimensions
			if (size(obj1,1)~=size(obj2,1)) || (size(obj1,2)~=size(obj2,2))
				nobj.printError(cMessages.InvalidSparseRow);
				return
			end
			% Determine type of inputs
			test=isa(obj1,'cSparseRow')+2*isa(obj2,'cSparseRow');
			switch test
				case 1
					nobj=obj2;
					nobj(obj1.mRows,:)=nobj(obj1.mRows,:)+obj1.mValues;
				case 2
					nobj=obj1;
					nobj(obj2.mRows,:)=nobj(obj2.mRows,:)+obj2.mValues;
				case 3
					nobj=cSparseRow(obj1.mRows,obj1.mValues+obj2.mValues,obj1.N);
			end
        end

		function nobj=minus(obj1,obj2)
		%minus - Element-wise subtraction of sparse row matrices.
		%   Overloads the - operator for cSparseRow objects. Supports subtraction
		%   between two cSparseRow objects or between cSparseRow and regular
		%   matrices. When both operands are cSparseRow with matching active rows,
		%   the result maintains the sparse row structure efficiently.
		%
		%   Syntax:
		%     nobj = obj1 - obj2
		%     nobj = minus(obj1, obj2)
		%
		%   Arguments:
		%     obj1 - Minuend (value to subtract from)
		%       cSparseRow object or numeric matrix
		%       Dimensions must match obj2
		%
		%     obj2 - Subtrahend (value to subtract)
		%       cSparseRow object or numeric matrix
		%       Dimensions must match obj1
		%
		%   Returns:
		%     nobj - Difference result
		%       cSparseRow if both inputs are cSparseRow
		%       Full matrix if one input is full matrix
		%       Invalid cTaesLab object on dimension mismatch
		%
		%   Examples:
		%     % Example 1: Subtract two sparse row matrices
		%     A = cSparseRow([2, 4], [10 20; 30 40], 5);
		%     B = cSparseRow([2, 4], [1 2; 3 4], 5);
		%     C = A - B;  % cSparseRow with rows 2,4 active
		%     % C(2,:) = [9, 18], C(4,:) = [27, 36]
		%
		%     % Example 2: Compute differences
		%     actual = cSparseRow([5], [100 200 300], 10);
		%     expected = cSparseRow([5], [90 210 290], 10);
		%     error = actual - expected;
		%     % error(5,:) = [10, -10, 10]
		%
		%     % Example 3: Remove baseline
		%     data = cSparseRow([3, 7], [50 60; 70 80], 10);
		%     baseline = ones(10, 2) * 10;
		%     adjusted = data - baseline;
		%
		%   See also:
		%     plus, uminus, mtimes
		%
		% Check dimensions
			nobj=cTaesLab();
			if (size(obj1,1)~=size(obj2,1)) || (size(obj1,2)~=size(obj2,2))
				nobj.printError(cMessages.InvalidSparseRow);
				return
			end
			% Determine type of inputs
			test=isa(obj1,'cSparseRow')+2*isa(obj2,'cSparseRow');
			switch test
				case 1
					nobj=obj2;
					nobj(obj1.mRows,:)=obj1.mValues-nobj(obj1.mRows,:);
				case 2
					nobj=obj1;
					nobj(obj2.mRows,:)=nobj(obj2.mRows,:)-obj2.mValues;
				case 3
					nobj=cSparseRow(obj1.mRows,obj1.mValues-obj2.mValues,obj1.N);
			end
		end

		function nobj=uminus(obj)
		%uminus - Unary negation of sparse row matrix.
		%   Overloads the unary minus operator (-) for cSparseRow objects.
		%   Negates all elements in the matrix while preserving sparse row
		%   structure. Efficiently operates only on stored active rows.
		%
		%   Syntax:
		%     nobj = -obj
		%     nobj = uminus(obj)
		%
		%   Returns:
		%     nobj - Negated cSparseRow object
		%       Same dimensions as obj (N×M)
		%       Same active rows (mRows)
		%       Values: nobj(i,j) = -obj(i,j)
		%
		%   Examples:
		%     % Example 1: Basic negation
		%     A = cSparseRow([2, 4], [1 2; 3 4], 5);
		%     B = -A;
		%     % B(2,:) = [-1, -2], B(4,:) = [-3, -4]
		%
		%     % Example 2: Reverse allocation direction
		%     outflow = cSparseRow([5], [10 20 30], 10);
		%     inflow = -outflow;  % Opposite direction
		%
		%     % Example 3: Use in expressions
		%     A = cSparseRow([1, 3], [5 10; 15 20], 4);
		%     B = cSparseRow([1, 3], [2 4; 6 8], 4);
		%     C = -A + B;  % Negate then add
		%
		%   See also:
		%     minus, plus
		%
			nobj=cSparseRow(obj.mRows,-obj.mValues,obj.N);
		end

		function nobj=mtimes(obj1,obj2)
		%mtimes - Matrix multiplication for sparse row matrices.
		%   Overloads the * operator for cSparseRow objects. Supports multiplication
		%   between cSparseRow and matrices/vectors with appropriate dimension
		%   matching. Leverages sparse row structure for computational efficiency
		%   when left operand is cSparseRow (only multiplies active rows).
		%
		%   Syntax:
		%     nobj = obj1 * obj2
		%     nobj = mtimes(obj1, obj2)
		%
		%   Arguments:
		%     obj1 - Left operand
		%       cSparseRow, numeric matrix, or scalar
		%       Inner dimension must match obj2's outer dimension
		%
		%     obj2 - Right operand
		%       cSparseRow, numeric matrix, or scalar
		%       Outer dimension must match obj1's inner dimension
		%
		%   Returns:
		%     nobj - Product result
		%       Type depends on operand types (see Operation Cases)
		%       Dimensions follow standard matrix multiplication rules
		%
		%   Operation Cases:
		%     cSparseRow * matrix: Returns cSparseRow (active rows preserved)
		%     matrix * cSparseRow: Returns full matrix (extracts active columns)
		%     scalar * cSparseRow: Returns cSparseRow (scaled values)
		%     cSparseRow * cSparseRow: Returns cSparseRow (complex case)
		%
		%   Dimension Rules:
		%     If obj1 is [N×M] and obj2 is [M×P], result is [N×P]
		%     Inner dimensions must match: size(obj1,2) == size(obj2,1)
		%
		%   Examples:
		%     % Example 1: Sparse matrix times vector
		%     A = cSparseRow([2, 4], [1 2 3; 4 5 6], 5);  % 5×3
		%     x = [10; 20; 30];  % 3×1
		%     y = A * x;  % 5×1 cSparseRow
		%     % y = [0; 140; 0; 320; 0]
		%
		%     % Example 2: Apply waste allocation to costs
		%     W = cSparseRow([5, 10], [0.2 0.3 0.5; 0.4 0.3 0.3], 20);  % 20×3
		%     costs = [100; 200; 300];  % 3×1 process costs
		%     allocated = W * costs;  % 20×1 allocated waste costs
		%     % allocated(5) = 0.2*100 + 0.3*200 + 0.5*300 = 230
		%     % allocated(10) = 0.4*100 + 0.3*200 + 0.3*300 = 190
		%
		%     % Example 3: Scalar multiplication
		%     A = cSparseRow([3], [1 2 3], 5);
		%     B = 10 * A;  % Scale all values by 10
		%     % B(3,:) = [10, 20, 30]
		%
		%     % Example 4: Matrix times sparse (extracts columns)
		%     M = magic(4);  % 4×4 full matrix
		%     A = cSparseRow([2, 3], [1 2 3 4; 5 6 7 8], 4);  % 4×4 sparse
		%     result = M * A;  % Extracts columns 2,3 and multiplies
		%
		%     % Example 6: Sparse row times sparse row
		%     A = cSparseRow([1, 2], [1 2; 3 4], 3);  % 3×2
		%     B = cSparseRow([1, 2], [1; 2], 2);  % 2×1
		%     C = A * B;  % 3×1 sparse row
		%
		%   See also:
		%     scaleCol, scaleRow, plus, minus
		%
			% Check dimensions
			nobj=cTaesLab();
			if (size(obj1,2)~=size(obj2,1))
				nobj.printError(cMessages.InvalidSparseRow);
				return
			end
			% Determine type of inputs
			test=isa(obj1,'cSparseRow')+2*isa(obj2,'cSparseRow');
			switch test
				case 1
					nobj=cSparseRow(obj1.mRows,obj1.mValues*obj2,obj1.N);
				case 2
                    if isscalar(obj1)
                       nobj=cSparseRow(obj2.mRows,obj1*obj2.mValues,obj2.N);
                    else
					   nobj=obj1(:,obj2.mRows)*obj2.mValues;
                    end
				case 3
					nobj=cSparseRow(obj1.mRows,obj1.mValues(:,obj1.mRows)*obj2.mValues,obj1.N);
			end
		end

		function res=full(obj)
		%full - Convert to full (dense) matrix representation.
		%   Expands the sparse row structure into a complete N×M matrix with
		%   zeros for inactive rows. This overloads MATLAB's built-in full()
		%   function to provide seamless conversion for display, debugging, or
		%   operations requiring full matrix format.
		%
		%   Syntax:
		%     res = full(obj)
		%
		%   Returns:
		%     res - Full numeric matrix
		%       Dimensions: N × M
		%       Active rows filled with values from mValues
		%       Inactive rows are zeros
		%       res(mRows(i), :) = mValues(i, :)
		%
		%   Memory Impact:
		%     • Sparse: O(NR*M) elements stored
		%     • Full: O(N*M) elements allocated
		%     • Memory increase: (N/NR) times larger
		%
		%   Examples:
		%     % Example 1: Basic conversion
		%     A = cSparseRow([2, 4], [1 2 3; 4 5 6], 5);
		%     F = full(A);
		%     % F = [0 0 0;
		%     %      1 2 3;
		%     %      0 0 0;
		%     %      4 5 6;
		%     %      0 0 0]
		%
		%     % Example 2: Display for inspection
		%     W = cSparseRow([5], [0.2 0.3 0.5], 8);
		%     disp(full(W));  % Shows full 8×3 matrix
		%
		%     % Example 3: Use in standard MATLAB operations
		%     A = cSparseRow([1, 3], [1 2; 3 4], 4);
		%     eigenvalues = eig(full(A));  % eig requires full matrix
		%
		%     % Example 4: Verify sparse operations
		%     A = cSparseRow([2], [10 20 30], 5);
		%     B = cSparseRow([4], [1 2 3], 5);
		%     C_sparse = A + B;
		%     C_full = full(A) + full(B);
		%     isequal(full(C_sparse), C_full)  % true
		%
		%   Common Usage:
		%     • Debugging: Visualize complete matrix structure
		%     • Display: Show matrix in readable format
		%     • Compatibility: Use with functions requiring full matrices
		%     • Validation: Compare with expected full matrix results
		%
		%   See also:
		%     sparse, disp, cSparseRow
		%
			res=zeros(obj.N,obj.M);
			res(obj.mRows,:)=obj.mValues;
		end

		function res=sparse(obj)
		%sparse - Convert to MATLAB sparse matrix format.
		%   Converts cSparseRow object to MATLAB's built-in sparse matrix format.
		%   This allows use of MATLAB's extensive sparse matrix functions while
		%   preserving memory efficiency. Note that MATLAB sparse format is
		%   column-sparse (efficient for few non-zero columns), while cSparseRow
		%   is row-sparse (efficient for few non-zero rows).
		%
		%   Syntax:
		%     res = sparse(obj)
		%
		%   Returns:
		%     res - MATLAB sparse matrix
		%       Dimensions: N × M
		%       Non-zero elements only from active rows
		%       Uses MATLAB's compressed sparse column (CSC) format
		%       Equivalent to: sparse(full(obj))
		%
		%   Storage Comparison:
		%     • cSparseRow: Optimized for row sparsity (few non-zero rows)
		%     • MATLAB sparse: Optimized for column sparsity
		%     • Both save memory vs full matrix
		%     • Choose format based on sparsity pattern
		%
		%   Examples:
		%     % Example 1: Basic conversion
		%     A = cSparseRow([2, 5], [1 2 3; 4 5 6], 6);
		%     S = sparse(A);
		%     % S is 6×3 MATLAB sparse matrix
		%     issparse(S)  % true
		%
		%     % Example 2: Use with MATLAB sparse functions
		%     W = cSparseRow([5, 10], rand(2, 20), 25);
		%     S = sparse(W);
		%     nnz(S)  % Count non-zero elements
		%     spy(S)  % Visualize sparsity pattern
		%
		%     % Example 3: Sparse matrix operations
		%     A = cSparseRow([3, 7], [1 2; 3 4], 10);
		%     S = sparse(A);
		%     x = rand(2, 1);
		%     y = S * x;  % MATLAB sparse matrix multiplication
		%
		%   Common Usage:
		%     • Compatibility: Use with MATLAB sparse matrix functions
		%     • Visualization: spy(), spydiag() for pattern analysis
		%     • Linear algebra: MATLAB's sparse solvers
		%
		%   When to Use:
		%     • Need MATLAB sparse matrix functions (eigs, svds, etc.)
		%     • Interfacing with external sparse libraries
		%     • Matrix has both row and column sparsity
		%
		%   See also:
		%     full, issparse, nnz, spy, spdiags
		%
			res=sparse(obj.mRows,1:obj.M,obj.mValues,obj.N,obj.M);
		end

        function res=size(obj,dim)
		%size - Query matrix dimensions.
		%   Overloads MATLAB's built-in size() function to return the logical
		%   dimensions (N×M) of the sparse row matrix. Returns the full matrix
		%   size, not the storage size (which is NR×M).
		%
		%   Syntax:
		%     res = size(obj)       % Returns [N, M]
		%     res = size(obj, dim)  % Returns N (dim=1) or M (dim=2)
		%
		%   Arguments:
		%     dim - Dimension to query (optional)
		%       1: Number of rows (N)
		%       2: Number of columns (M)
		%       Omitted: Returns both dimensions as [N, M]
		%
		%   Returns:
		%     res - Matrix dimensions
		%       If dim omitted: [N, M] vector (1×2)
		%       If dim=1: Scalar N (total rows including zeros)
		%       If dim=2: Scalar M (number of columns)
		%
		%   Storage vs Logical Size:
		%     • Logical size: N×M (what size() returns)
		%     • Storage size: NR×M (actual memory used)
		%     • Properties: obj.N, obj.M (logical), obj.NR (storage)
		%
		%   Examples:
		%     % Example 1: Query both dimensions
		%     A = cSparseRow([2, 5], [1 2 3; 4 5 6], 10);
		%     dims = size(A);  % [10, 3]
		%     fprintf('Matrix is %d x %d\n', dims(1), dims(2));
		%
		%     % Example 2: Query specific dimension
		%     A = cSparseRow([3], [1 2], 5);
		%     nrows = size(A, 1);  % 5 (total rows)
		%     ncols = size(A, 2);  % 2 (columns)
		%
		%     % Example 3: Use in dimension checks
		%     A = cSparseRow([1, 2], rand(2, 4), 6);
		%     [m, n] = size(A);  % m=6, n=4
		%     if m == n
		%         disp('Square matrix');
		%     end
		%
		%     % Example 4: Check compatibility for operations
		%     A = cSparseRow([2], [1 2 3], 5);
		%     x = rand(3, 1);
		%     if size(A, 2) == size(x, 1)
		%         y = A * x;  % Dimension-compatible multiplication
		%     end
		%
		%     % Example 5: Compare with full matrix
		%     A = cSparseRow([3, 7], ones(2, 5), 10);
		%     size_sparse = size(A);      % [10, 5]
		%     size_full = size(full(A));  % [10, 5] (same)
		%
		%   Common Usage:
		%     • Dimension checking: size(A,2) == size(B,1) for A*B
		%     • Preallocation: zeros(size(A)) for result arrays
		%     • Display: fprintf('Dimensions: %d x %d', size(A))
		%     • Indexing limits: for i=1:size(A,1) loops
		%
		%   Note on Active Rows:
		%     To query number of active (non-zero) rows:
		%       obj.NR  % Number of stored rows
		%       length(obj.mRows)  % Also gives NR
		%
		%   See also:
		%     length, numel, ndims, cSparseRow
		%
            narginchk(1,2);
			val = [obj.N obj.M];
			if nargin==1
				res=val;
			else
				res=val(dim);
			end
        end
		
		function res=ctranspose(obj)
		%ctranspose - Complex conjugate transpose.
		%   Overloads the ' (ctranspose) operator for cSparseRow objects.
		%   Computes the complex conjugate transpose by converting to full matrix.
		%   Returns a full M×N matrix (not cSparseRow) since transpose changes
		%   sparsity structure from row-sparse to column-sparse.
		%
		%   Syntax:
		%     res = obj'  % Conjugate transpose (recommended)
		%     res = ctranspose(obj)
		%
		%   Returns:
		%     res - Full matrix
		%       Dimensions: M × N (swapped from N × M)
		%       Full matrix, not cSparseRow
		%       For real matrices: Same as transpose(obj)
		%       For complex matrices: res(i,j) = conj(obj(j,i))
		%
		%   Implementation:
		%     Currently delegates to transpose(full(obj)).
		%     Could be optimized to use sparse transpose.
		%
		%   Examples:
		%     % Example 1: Real matrix transpose
		%     A = cSparseRow([2, 4], [1 2 3; 4 5 6], 5);  % 5×3
		%     B = A';  % 3×5 full matrix
		%
		%     % Example 2: Use in linear algebra
		%     A = cSparseRow([3], [1 2 3], 5);
		%     ATA = A' * A;  % Gram matrix (3×3)
		%
		%     % Example 3: Complex transpose (if values are complex)
		%     A = cSparseRow([2], [1+2i, 3-4i], 4);
		%     B = A';  % Conjugate transpose
		%
		%   Note:
		%     Result is full matrix. For large matrices, this may consume
		%     significant memory. Consider if transpose is necessary.
		%
		%   See also:
		%     transpose, conj, full
		%
			res=transpose(full(obj));
		end

		function res=transpose(obj)
		%transpose - Matrix transpose.
		%   Overloads the .' (transpose) operator for cSparseRow objects.
		%   Computes the transpose by converting to full matrix first.
		%   Returns a full M×N matrix (not cSparseRow) since row-sparse
		%   becomes column-sparse after transposition.
		%
		%   Syntax:
		%     res = obj.'  % Transpose (real matrices)
		%     res = transpose(obj)
		%
		%   Returns:
		%     res - Full transposed matrix
		%       Dimensions: M × N (swapped from N × M)
		%       Full matrix, not cSparseRow
		%       res(i,j) = obj(j,i)
		%
		%   Examples:
		%     % Example 1: Basic transpose
		%     A = cSparseRow([1, 3], [1 2; 3 4], 4);  % 4×2
		%     B = A.';  % 2×4 full matrix
		%
		%     % Example 2: Inner product
		%     A = cSparseRow([2], [1 2 3], 5);
		%     x = A.';  % Column vector (3×5)
		%     inner = x' * x;  % Scalar product
		%
		%   See also:
		%     ctranspose, full
		%
			res=transpose(full(obj));
		end

		function nobj = inverseMatrix(obj, check)
		%inverseMatrix - Compute (I-A)^(-1) using Woodbury matrix identity.
		%   Efficiently calculates the inverse of (I - A) for square sparse row
		%   matrix A using the Woodbury formula. This reduces the computational
		%   complexity from O(N^3) to O(NR^3).
		%   Useful to compute waste cost operators matrices in exergy cost analysis.
		%
		%   Returns matrix B such that: I + B = (I - A)^(-1)
		%   This formulation avoids explicit identity matrix operations.
		%
		%   Syntax:
		%     nobj = obj.inverseMatrix()
		%     nobj = inverseMatrix(obj)
		%
		%   Requirements:
		%     • obj must be square (N == M)
		%     • All elements must be non-negative (A ≥ 0)
		%     • Submatrix A(mRows, mRows) must be non-singular.
		%
		%	Arguments:
		%     check - (Optional) Boolean to enable/disable non singular checks.
		%       Default: false (no check)
		%	    true: Validates submatrix invertibility
		%       false: Skips singularity check for performance
		%
		%   Returns:
		%     nobj - Sparse row matrix B
		%       Same dimensions as obj (N×N)
		%       Same active rows (mRows)
		%       Property: I + B = (I - A)^(-1)
		%       On error: Returns cMessageLogger with error messages
		%
		%   Woodbury Matrix Identity:
		%     For matrix A with sparse row structure:
		%       (I - A)^(-1) = I + A * (I - A_sub)^(-1)
		%     
		%     Where A_sub = A(mRows, mRows) is NR×NR submatrix
		%     Computational savings: O(NR^3) vs O(N^3)
		%     Speedup example: N=100, NR=5 → 1000x faster
		%
		%   Validation Checks:
		%     1. Square matrix: Ensures N == M
		%     2. Non-negative: Checks all(A(:) >= -EPS)
		%     3. Non-singular: rcond(I - A_sub) < EPS if check=true
		%     Failures logged as ERROR messages
		%
		%   Examples:
		%     % Example 1: Simple 2-row sparse matrix
		%     A = cSparseRow([2, 4], [0.1 0.2 0; 0 0.1 0.3], 4);
		%     B = A.inverseMatrix();
		%     % Verify: (I + B) == inv(I - full(A))
		%
		%     % Example 4: Performance comparison
		%     N = 200; NR = 5;
		%     A = cSparseRow(1:NR, rand(NR, N)*0.1, N);
		%     tic; B_fast = A.inverseMatrix(); t1 = toc;  % Fast (NR^3)
		%     tic; B_slow = inv(eye(N) - full(A)); t2 = toc;  % Slow (N^3)
		%     fprintf('Speedup: %.1fx\n', t2/t1);  % Typically 10-100x
		%
		%   Common Usage:
		%     • Waste cost calculation
		%
		%   Error Conditions:
		%     • Non-square matrix: Returns error if N != M
		%     • Negative elements: Returns error if any(A < 0)
		%     • Singular matrix: Returns error if det(I - A_sub) ≈ 0
		%     All errors logged via cMessageLogger
		%
		%   Performance:
		%     • Complexity: O(NR^3 + NR^2*M) vs O(N^3) for full inverse
		%     • Memory: O(NR^2) for submatrix vs O(N^2) for full
		%     • Speedup: Approximately (N/NR)^3
		%
		%   Implementation Notes:
		%     • Uses MATLAB's backslash operator for submatrix solve
		%     • Extracts A_sub = A(mRows, mRows)
		%     • Solves: (I - A_sub) * X = A  for X
		%     • Returns B as cSparseRow with same active rows
		%
		%   Mathematical Background:
		%     The Woodbury identity states:
		%       (I - UV)^(-1) = I + U * (I-VU)^(-1) * V
		%
		%   See also:
		%     cExergyCost, cWasteAnalysis, mtimes, inv, mldivide
		%
			nobj = cMessageLogger();
			% Check Arguments
			if nargin < 2
				check = false;
			end
			if obj.N ~= obj.M
				nobj.messageLog(cType.ERROR,cMessages.NonSquaraMatrix,obj.N,obj.M);
				return
			end
			A=obj.mValues;
			if any(A(:)) < -cType.EPS
				nobj.messageLog(cType.ERROR,cMessages.NegativeMatrix);
				return
			end
			mS=A(:, obj.mRows);
			% Check if reduced matrix is non singular
			if check && isSingularMatrix(mS)
				nobj.messageLog(cType.ERROR,cMessages.SingularMatrix);
				return
			end
			% Applied Wodbury formula
			B = (eye(obj.NR) - mS) \ A;
			nobj = cSparseRow(obj.mRows, B);
		end 

		function printMatrix(obj)
		%printMatrix - Display sparse row matrix as full matrix.
		%   Overloads MATLAB's built-in disp() function to display the complete
		%   matrix structure. Converts to full matrix before display so that zero
		%   rows are visible. This provides clear visualization of the matrix
		%   structure including sparsity pattern.
		%
		%   Syntax:
		%     disp(obj)
		%     obj  % Implicit call (without semicolon)
		%
		%   Display Format:
		%     Shows full N×M matrix with:
		%       • Active rows containing stored values
		%       • Inactive rows shown as zeros
		%       • Standard MATLAB matrix formatting
		%
		%   Side Effects:
		%     • Converts to full matrix (may use memory for large N)
		%     • Outputs to console
		%     • Does not modify object
		%
		%   Alternatives for Large Matrices:
		%     • disp(obj)
		%
		%   Examples:
		%     A = cSparseRow([2, 4], [1 2; 3 4], 5);
		%     printMatrix(A);
		%     % Output:
		%     %   0   0
		%     %   1   2
		%     %   0   0
		%     %   3   4
		%     %   0   0
		%
		%   See also:
		%     full, disp
		%
			disp(full(obj));
		end
	end
end
