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
    end

	methods

        function obj = cDictionary(data)
		% Construct an instance of this class
			obj=obj@cStatusLogger(cType.VALID);
			m=containers.Map('KeyType','char','ValueType','uint8');
			for i=1:numel(data)
				if m.isKey(data{i})
					obj.messageLog(cType.ERROR,'Key %s is duplicated',data{i});
				else
					m(data{i})=i;
				end
				if ~isValid(obj)
					return
				end
			end
			obj.map=m;
		end

		function res = existsKey(obj,key)
		% check if key exists
			res=obj.map.isKey(key);
		end
		
        function res = getIndex(obj,key)
		% getIndex return the corresponding index of a key
			res=cType.EMPTY;
			if obj.map.isKey(key)
				res=obj.map(key);
			end
		end

        function res = getKey(obj,idx)
		% getKey return the corresponding key of a index
			res='';
			if idx>0 && idx<=length(obj)
				res=obj.map.keys{idx};
			end
		end

		function res = getEntries(obj,format)
		% get the entries of the dictionary in diferent format
		% 	Input:
		%		format - VarMode options (CELL, STRUCT, TABLE)
			if nargin==1
				format=cType.DEFAULT_VARMODE;
			end
			rowNames=obj.map.keys;
			data=obj.map.values';
			colNames={'Key','Id'};
			tbl=cTableData(data,rowNames,colNames);
			res=exportTable(tbl,format);
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
