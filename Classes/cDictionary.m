classdef cDictionary < cStatusLogger
% cDictionary implementa a (key, id) dictionary for TaesLab
%	It implements an supersed some method of containers.Map class 
%	Methods:
%   	res=obj.getKey(index)
%   	res=obj.getIndex(key)
%   	res=obj.existsKey(key)
%		res=obj.getEntries(format)
% See also cMapList, cMapKey
%
  
    properties(Access=private)
        map
        values
		keys
    end

	methods

        function obj = cDictionary(data)
		% Construct an instance of this class
			obj=obj@cStatusLogger(cType.VALID);
			obj.map=containers.Map('KeyType','char','ValueType','uint8');
			for i=1:numel(data)
				if obj.map.isKey(data{i})
					obj.messageLog(cType.ERROR,'Key %s is duplicated',data{i});
				else
					obj.map(data{i})=i;
				end
				if ~isValid(obj)
					return
				end
			end
			obj.keys=obj.map.keys;
			obj.values=obj.map.values;
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
			if idx>0 && idx<=length(obj)
				res=obj.keys{idx};
			end
		end

		function res = getEntries(obj,format)
		% get the entries of the dictionary in diferent format
		% 	Input:
		%		format - VarMode options (CELL, STRUCT, TABLE)
			if nargin==1
				format=cType.DEFAULT_VARMODE;
			end
			rowNames=obj.keys;
			data=obj.values;
			entries=[rowNames; data]';
			colNames={'Key','Id'};
			fid=cType.getVarMode(format);
			if cType.isEmpty(fid)
				fid=cType.VarMode.CELL;
			end
			switch fid
                case cType.VarMode.NONE
                    res=[colNames;entries];
			    case cType.VarMode.CELL
				    res=[colNames;entries];
			    case cType.VarMode.STRUCT
				    res=cell2struct(entries,colNames,2);
			    case cType.VarMode.TABLE
				    tbl=cTableData(data,rowNames,colNames);
				    if isMatlab
					    res=tbl.getMatlabTable;
				    else
					    res=tbl;
				    end
			end
		end

        function res=size(obj)
        % Overload size function
           res=size(obj.map);
        end
        
        function res=length(obj)
		% Overload length function
			res=obj.map.Count;
		end
	end
end
