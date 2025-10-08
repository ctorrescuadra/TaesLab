classdef  cSparseRow < cMessageLogger
	%cSparseRow - Store and operate with matrices that contain few non-null rows.
	%	This class is used to manage  waste allocation matrices, and provide a set of
	%   algebraic operations. 
	%
	%   cSparseRow properties:
	%     N 		- Number of rows
	%     NR  	- Number of active rows
	%     M		- Number of Columns
	%     mRows   - list containing the non-null rows
	%     mValues - Matrix (NR x M) containing the active value
	%
	%   cSparseRow methods:
	%     scaleCol  - Scale the columns of the matrix by a vector
	%     scaleRow  - Scale the rows of the matrix by a vector
	%     divideCol - Divide the columns of the matrix by a vector
	%     divideRow - Divide the rows of the matrix by a vector
	%     sumRows   - Sum the matrix by rows
	%     sumCols   - sum the matrix by cols
	%
	%   Overloaded operators:
	%     res=a+b (plus)
	%	  res=a-b (minus)	
	%	  res=-a (uminus) 
	%	  res=a*b (mtimes)
	%	  res=size(a)
	%     res=sum(a,dim)
	%     full(a)
	%     sparse(a)
	%     transpose(a)
	%     ctranspose(a)
	%	  disp(a)
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
		%cSparseRow - create an instance of the class
		%   Syntax:
		%     obj = cSparseRow(rows,vals,n)
		%   Input Arguments:
		%     rows - array containing index of the active rows
		%     vals - Matrix containing the values of active rows
		%     n    - Number of rows (optional)
		%   Output Arguments:
		%     obj  - cSparseRow object
		%
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
		%scaleCol - Scale the columns of the matrix by a vector
		%   Overload scaleCol function for cSparseRow objects
		%   Syntax:
		%     nobj=obj.scaleCol(x)
		%   Input Arguments:
		%     x   - vector with the scaling values
		%   Output Arguments:
		%     nobj - cSparseRow object with the scaled values
		%
			nobj=cMessageLogger();
			if nargin==1
				nobj.printError(cMessages.InvaliArguments,'scaleCol');
				return
			end
			if(obj.M~=length(x))
				nobj.printError(cMessages.InvalidSparseRow,obj.M,length(rows));
				return
			end
			B=scaleCol(obj.mValues,x);
			nobj=cSparseRow(obj.mRows,B);
		end

		function nobj=divideCol(obj,x)
		%divideCol - Divide the columns of the matrix by a vector
		%   Overload divideCol function for cSparseRow objects
		%   Syntax:
		%     nobj=obj.divideCol(x)
		%   Input Arguments:
		%     x   - vector with the divisor values
		%   Output Arguments:
		%     nobj - cSparseRow object with the divided values
		%
			nobj=cMessageLogger();
			if nargin==1
				x=obj.sumCols;
			end
			if(obj.M~=length(x))
				nobj.printError(cMessages.InvalidSparseRow,obj.M,length(rows));
				return
			end
			B=divideCol(obj.mValues,x);
			nobj=cSparseRow(obj.mRows,B);
		end

		function nobj=scaleRow(obj,x)
		%scaleRow - Scale the rows of the matrix by a vector
		%   Overload scaleRow function for cSparseRow objects
		%   Syntax:
		%     nobj=obj.scaleRow(x)
		%   Input Arguments:
		%     x   - vector with the scaling values
		%   Output Arguments:
		%     nobj - cSparseRow object with the scaled values
		%
			nobj=cMessageLogger();
			if(obj.N~=length(x))
				nobj.printError(cMessages.InvalidSparseRow,obj.N,length(rows));
				return
			end
			B=scaleRow(obj.mValues,x(obj.mRows));
			nobj=cSparseRow(obj.mRows,B);
		end

		function nobj=divideRow(obj,x)
		%divideRow - Divide the rows of the matrix by a vector
		%   Overload divideRow function for cSparseRow objects
		%   Syntax:
		%     nobj=obj.divideRow(x)
		%   Input Arguments:
		%     x   - vector with the divisor values
		%   Output Arguments:
		%     nobj - cSparseRow object with the divided values
		%
			nobj=cMessageLogger();
			if nargin==1
				x(obj.mRows)=obj.sumRows;
			end
			if(obj.N~=length(x))
				log.printError(cMessages.InvalidSparseRow,obj.N,length(rows));
				return
			end
			B=divideRow(obj.mValues,x(obj.mRows));
			nobj=cSparseRow(obj.mRows,B);
		end

		function x = sumCols(obj)
		%sumCols - Sum the columns of the matrices
		%   Syntax:
		%     x=obj.sumCols()
		%   Output Arguments:
		%     x - row vector with the sum of each column
		%	
			x=sum(obj.mValues,1);
		end

		function x = sumRows(obj)
		%sumRows - Sum the rows of the matrices
		%   Syntax:
		%     x=obj.sumRows()
		%   Output Arguments:
		%     x - column vector with the sum of each row
		%
            x=zeros(obj.N,1);
			x(obj.mRows)=sum(obj.mValues,2);
		end

        function res=sum(obj,dim)
		%sum - Overload sum function for cSparseRow objects
		%   Syntax:
		%     res=sum(obj,dim)
		%   Input Arguments:
		%     dim - Dimension to sum (1 rows, 2 columns). Default is 1
		%   Output Arguments:
		%     res - Result of the sum operation
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
		%plus - Overload the plus operator for cSparseRow objects
		%   Syntax:
		%     nobj=obj1+obj2
		%   Input Arguments:
		%     obj1 - cSparseRow object or scalar
		%     obj2 - cSparseRow object or scalar
		%   Output Arguments:
		%     nobj - cSparseRow object with the result of the addition
		%
			nobj=cMessageLogger();
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
		%minus - Overload the minus operator for cSparseRow objects
		%   Syntax:
		%     nobj=obj1-obj2
		%   Input Arguments:
		%     obj1 - cSparseRow object or scalar
		%     obj2 - cSparseRow object or scalar
		%   Output Arguments:
		%     nobj - cSparseRow object with the result of the subtraction
		%
			% Check dimensions
			nobj=cMessageLogger();
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
		%uminus - Overload the uminus operator for cSparseRow objects
		%   Syntax:
		%     nobj=-obj
		%   Input Arguments:
		%     obj - cSparseRow object
		%   Output Arguments:
		%     nobj - cSparseRow object with the result of the operation
		%
			nobj=cSparseRow(obj.mRows,-obj.mValues,obj.N);
		end

		function nobj=mtimes(obj1,obj2)
		%mtimes - Overload the mtimes operator for cSparseRow objects
		%   Syntax:
		%     nobj=obj1*obj2
		%   Input Arguments:
		%     obj1 - cSparseRow object or scalar
		%     obj2 - cSparseRow object or scalar or matrix
		%   Output Arguments:
		%     nobj - cSparseRow object or matrix with the result of the multiplication
		%
			% Check dimensions
			nobj=cMessageLogger();
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
		%full - Overload full function for cSparseRow objects
		%   Syntax:
		%     res=full(obj)
		%   Input Arguments:
		%     obj - cSparseRow object
		%   Output Arguments:
		%     res - Full matrix
		%
			res=zeros(obj.N,obj.M);
			res(obj.mRows,:)=obj.mValues;
		end

		function res=sparse(obj)
		%sparse - Overload sparse function for cSparseRow objects
		%   Syntax:
		%     res=sparse(obj)
		%   Input Arguments:
		%     obj - cSparseRow object
		%   Output Arguments:
		%     res - Sparse matrix
		%
			res=sparse(obj.mRows,1:obj.M,obj.mValues,obj.N,obj.M);
		end

        function res=size(obj,dim)
		%size - Overload size function for cSparseRow objects
		%   Syntax:
		%     res=size(obj)
		%     res=size(obj,dim)
		%   Input Arguments:
		%     obj - cSparseRow object
		%     dim - Dimension to return (1 rows, 2 columns). Default is both dimensions
		%   Output Arguments:
		%     res - Size of the matrix (if dim is not provided) or size of the specified dimension
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
		%ctranspose - Overload ctranspose operator for cSparseRow objects
		%   Syntax:
		%     res=ctranspose(obj)
		%   Input Arguments:
		%     obj - cSparseRow object
		%   Output Arguments:
		%     res - Transposed matrix
		%
			res=transpose(full(obj));
		end

		function res=transpose(obj)
		%transpose - Overload transpose operator for cSparseRow objects
		%   Syntax:
		%     res=transpose(obj)
		%   Input Arguments:
		%     obj - cSparseRow object
		%   Output Arguments:
		%     res - Transposed matrix
		%
			res=transpose(full(obj));
		end

		function disp(obj)
		%disp - Overload display object for cSparseRow objects
		%   Syntax:
		%     disp(obj)
		%   Input Arguments:
		%     obj - cSparseRow object
		%
			disp(full(obj));
		end
	end
end
