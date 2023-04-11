classdef cDictionary < handle
% cDictionary implementa a (key, id) dictionary for ExIOLab
%	It implements an supersed some method of containers.Map class 
%	Methods:
%   	res=obj.getKey(index)
%   	res=obj.getIndex(key)
%   	res=obj.existsKey(key)
%		res=obj.getEntries(format)
% See also cMapList, cMapKey
%
	properties (GetAccess=public,SetAccess=protected)
		NrOfEntries % Size of the dictionary
		Keys        % Array Cell with the keys
	end
  
    properties(Access=private)
        map
        values
    end

	methods

        function obj = cDictionary(data)
		% Construct an instance of this class
			obj.Keys=data;
			obj.NrOfEntries=numel(data);
			obj.values=uint16(1:obj.NrOfEntries);
			obj.map=containers.Map(obj.Keys,obj.values);
		end

		function res = existsKey(obj,key)
		% check if key exists
			res=obj.map.isKey(key);
		end
		
        function res = getIndex(obj,key)
		% getIndex return the corresponding index of a key
			res=cType.EMPTY;
			if obj.existsKey(key)
				res=obj.map(key);
			end
		end

        function res = getKey(obj,idx)
		% getKey return the corresponding key of a index
			res='';
			if idx>0 && idx<=obj.NrOfEntries
				res=obj.Keys{idx};
			end
		end

		function res = getEntries(obj,format)
		% get the entries of the dictionary in diferent format
		% 	Input:
		%		format - VarMode options (CELL, STRUCT, TABLE)
			if nargin==1
				format=cType.DEFAULT_VARMODE;
			end
			entries=[obj.Keys', num2cell(obj.values)'];
			colNames={'Key','Id'};
			fid=cType.getVarMode(format);
			if cType.isEmpty(fid)
				fid=cType.VarMode.CELL;
			end
			switch fid
			case cType.VarMode.CELL
				res=[colNames;entries];
			case cType.VarMode.STRUCT
				res=cell2struct(entries,colNames,2);
			case cType.VarMode.TABLE
				tbl=cTableData([colNames;entries]);
				if isMatlab
					res=tbl.getMatlabTable;
				else
					res=tbl;
				end
			end
		end

		function res=size(obj,dim)
		% overload size function
			narginchk(1,2);
			val = [obj.NrOfEntries, 1];
			if nargin==1
				res=val;
			else
				res=val(dim);
			end
		end

		function res=length(obj)
		% Overload length function
			res=obj.NrOfEntries;
		end

	end
end
