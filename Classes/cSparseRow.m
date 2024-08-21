classdef  cSparseRow < cStatus
	% cSparseRow Defines objects to store matrix which contains a few non-null rows.
	%	This class is used to manage  waste allocation matrices, and provide a set of
	%   algebraic operations. 
	%	Methods:
	% 		obj=cSparseRow(rows,vals,n)
	%		mat=obj.full
	%		mat=obj.sparse
	%		res=obj.scaleCol(x)
	%		res=obj.scaleRow(x)
	%		res=obj.divideCol(x)
	%		res=obj.divideRow(x)
	%		res=obj.sumRows
	%		res=obj.sumCols
	% 	Overloaded operators:
	%		res=a+b (plus)
	%		res=a-b (minus)	
	%		res=-a (uminus) 
	%		res=a*b (mtimes)
	%		res=size(a)
	%		disp(a)
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
		% matrix constructor
		% rows: list containing the active rows
		% vals: Matrix containing the values
		% n [optional]: Number of rows. if it is not provided N=M.
			narginchk(2,3);
			obj.NR=size(vals,1);
			obj.M=size(vals,2);
			if (obj.NR ~= length(rows))
				obj.printError('Invalid cSparseRow Parameters')
				return
			end
			obj.mRows=rows;
			obj.mValues=vals;
			if nargin==2
				obj.N=obj.M;
			else
				obj.N=n;
			end
		end
        
		function disp(obj)
		%print object
	        disp(full(obj));
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

		function nobj=scaleCol(obj,x)
		% Scale Columns function
			log=cStatus();
			if(obj.M~=length(x))
				log.printError('Matrix dimensions must agree: %d %d',obj.NR,length(rows));
				return
			end
			B=scaleCol(obj.mValues,x);
			nobj=cSparseRow(obj.mRows,B);
		end

		function nobj=divideCol(obj,x)
		% Divide Columns function
			nobj=cStatus();
			if nargin==1
				x=obj.sumCols;
			end
			if(obj.M~=length(x))
				nobj.printError('Matrix dimensions must agree: %d %d',obj.NR,length(rows));
				return
			end
			B=divideCol(obj.mValues,x);
			nobj=cSparseRow(obj.mRows,B);
		end

		function nobj=scaleRow(obj,x)
		% Scale Rows function
			nobj=cStatus();
			if(obj.N~=length(x))
				nobj.printError('Matrix dimensions must agree: %d %d',obj.NR,length(rows));
				return
			end
			B=scaleRow(obj.mValues,x(obj.mRows));
			nobj=cSparseRow(obj.mRows,B);
		end

		function nobj=divideRow(obj,x)
		% Divide Rows
			nobj=cStatus();
			if nargin==1
				x(obj.mRows)=obj.sumRows;
			end
			if(obj.N~=length(x))
				nobj.printError('Matrix dimensions must agree: %d %d',obj.NR,length(rows));
				return
			end
			B=divideRow(obj.mValues,x(obj.mRows));
			nobj=cSparseRow(obj.mRows,B);
		end

		function x = sumCols(obj)
		% sum the cols of the matrices
			x=sum(obj.mValues,1);
		end

		function x = sumRows(obj)
		% sum the rows of the matrices
			x=sum(obj.mValues,2);
		end

        function res=sum(obj,dim)
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
			test=isa(obj1,'cSparseRow')+2*isa(obj2,'cSparseRow');
			switch test
				case 1
					nobj=obj2;
					nobj(obj1.mRows,:)=nobj(obj1.mRows,:)+obj1.mValues;
				case 2
					nobj=obj1;
					nobj(obj2.mRows,:)=nobj(obj2.mRows,:)+obj2.mValues;
				case 3
					nobj=cSparseRow(obj1.mRows,obj1.mValues+obj2.mValues);
			end
        end

		function nobj=minus(obj1,obj2)
		% overload the minus operator
			test=isa(obj1,'cSparseRow')+2*isa(obj2,'cSparseRow');
			switch test
				case 1
					nobj=obj2;
					nobj(obj1.mRows,:)=obj1.mValues-nobj(obj1.mRows,:);
				case 2
					nobj=obj1;
					nobj(obj2.mRows,:)=nobj(obj2.mRows,:)-obj2.mValues;
				case 3
					nobj=cSparseRow(obj1.mRows,obj1.mValues-obj2.mValues);
			end
		end

		function nobj=uminus(obj)
		% overload the uminus operator
			nobj=cSparseRow(obj.mRows,-obj.mValues);
		end

		function obj=mtimes(obj1,obj2)
		% overload the mtimes operator
			test=isa(obj1,'cSparseRow')+2*isa(obj2,'cSparseRow');
			switch test
				case 1
					obj=cSparseRow(obj1.mRows,obj1.mValues*obj2);
				case 2
                    if isscalar(obj1)
                        obj=cSparseRow(obj2.mRows,obj1*obj2.mValues);
                    else
					    obj=obj1(:,obj2.mRows)*obj2.mValues;
                    end
				case 3
					obj=cSparseRow(obj1.mRows,obj1.mValues(:,obj1.mRows)*obj2.mValues);
			end
		end

        function res=size(obj,dim)
		% overload size function
            narginchk(1,2);
			val = [obj.N obj.M];
			if nargin==1
				res=val;
			else
				res=val(dim);
			end
        end
	end
end
