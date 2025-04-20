classdef  cSparseRow < cMessageLogger
	% cSparseRow Defines objects to store matrix which contains a few non-null rows.
	%	This class is used to manage  waste allocation matrices, and provide a set of
	%   algebraic operations. 
	%
	% cSparseRow Properties
	%   N 		- Number of rows
	%   NR  	- Number of active rows
	%   M		- Number of Columns
	%   mRows   - list containing the non-null rows
	%   mValues - Matrix (NR x M) containing the active value
	%
	% cSparseRow Methods:
	%   scaleCol  - Scale the columns of the matrix by a vector
	%   scaleRow  - Scale the rows of the matrix by a vector
	%   divideCol - Divide the columns of the matrix by a vector
	%   divideRow - Divide the rows of the matrix by a vector
	%   sumRows   - Sum the matrix by rows
	%   sumCols   - sum the matrix by cols
	%
	% Overloaded operators:
	%   res=a+b (plus)
	%	res=a-b (minus)	
	%	res=-a (uminus) 
	%	res=a*b (mtimes)
	%	res=size(a)
	%   res=sum(a,dim)
	%   full(a)
	%   sparse(a)
	%	disp(a)
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
		% Matrix constructor
		% Syntax:
		%   obj = cSparseRow(rows,vals,n)
		% Input Argument
		%   rows - array containing index of the active rows
		%   vals - Matrix containing the values of active rows
		%   n    - Number of rows
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
		% Overload scaleCol function
			log=cMessageLogger();
			if(obj.M~=length(x))
				log.printError(cMessages.InvalidSparseRow,obj.M,length(rows));
				return
			end
			B=scaleCol(obj.mValues,x);
			nobj=cSparseRow(obj.mRows,B);
		end

		function nobj=divideCol(obj,x)
		% Overload divideCol function
			nobj=cMessageLogger();
			if nargin==1
				x=obj.sumCols;
			end
			if(obj.M~=length(x))
				log.printError(cMessages.InvalidSparseRow,obj.M,length(rows));
				return
			end
			B=divideCol(obj.mValues,x);
			nobj=cSparseRow(obj.mRows,B);
		end

		function nobj=scaleRow(obj,x)
		% Overload scaleRow function
			nobj=cMessageLogger();
			if(obj.N~=length(x))
				log.printError(cMessages.InvalidSparseRow,obj.N,length(rows));
				return
			end
			B=scaleRow(obj.mValues,x(obj.mRows));
			nobj=cSparseRow(obj.mRows,B);
		end

		function nobj=divideRow(obj,x)
		% Overload divideRow function
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
		% Sum the cols of the matrices
			x=sum(obj.mValues,1);
		end

		function x = sumRows(obj)
		% Sum the rows of the matrices
            x=zeros(obj.N,1);
			x(obj.mRows)=sum(obj.mValues,2);
		end

        function res=sum(obj,dim)
		% Overload sum function
            narginchk(1,2);
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
		% overload the plus operator
			nobj=cMessageLogger();
			if (size(obj1,1)~=size(obj2,1)) || (size(obj1,2)~=size(obj2,2))
				nobj.printError(cMessages.InvalidSparseRow);
				return
			end
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
		% overload the minus operator
			nobj=cMessageLogger();
			if (size(obj1,1)~=size(obj2,1)) || (size(obj1,2)~=size(obj2,2))
				nobj.printError(cMessages.InvalidSparseRow);
				return
			end
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
		% overload the uminus operator
			nobj=cSparseRow(obj.mRows,-obj.mValues,obj.N);
		end

		function nobj=mtimes(obj1,obj2)
		% overload the mtimes operator
			nobj=cMessageLogger();
			if (size(obj1,2)~=size(obj2,1))
				nobj.printError(cMessages.InvalidSparseRow);
				return
			end
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

        function res=size(obj,dim)
		% Overload size function
            narginchk(1,2);
			val = [obj.N obj.M];
			if nargin==1
				res=val;
			else
				res=val(dim);
			end
        end

		function mat=full(obj)
		% return the full matriz form
			mat=zeros(obj.N,obj.M);
			mat(obj.mRows,:)=obj.mValues;
		end
	
		function mat=sparse(obj)
		% return the sparse matrix form
			[ix,iy,val]=find(obj.mValues);
			mat=sparse(obj.mRows(ix),iy,val,obj.N,obj.M);
		end
		
		function res=ctranspose(obj)
		% Overload ctranspose operator
			res=transpose(full(obj));
		end

		function res=transpose(obj)
		% Overload ctranspose operator
			res=transpose(full(obj));
		end

		function disp(obj)
		% overload display object
			disp(full(obj));
		end
	end
end
