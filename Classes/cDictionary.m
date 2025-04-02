classdef cDictionary < cMessageLogger
%cDictionary implementa a (key, id) dictionary for TaesLab
%	It uses the containers.Map class
%
%   cDictionary constructor:
%     obj = cDataset(list)
%
%   cDictionary methods:
%     getKey     - Get the key associated to a index
%     getIndex   - Get the index of a key
%     existsKey  - Check if a key exists in the dictionary
%	  getKeys    - Get the entries of the dictionary
% 
    properties(Access=protected)
        map     % containers.Map object
		keys    % cell array with the keys
    end

	methods
        function obj = cDictionary(data)
		%cDictionary - Construct an instance of this class
		%   Syntax:
		%     obj = cDictionary(data)
		%   Input Arguments:
		%     data - cell array with the dictionary keys
		% 
			% Check data
			if iscell(data) && ~isempty(data)
                N=length(data);
            else
                obj.messageLog(cType.ERROR,cMessages.ListNotCell);
                return
			end
            if any(cellfun(@isempty,strtrim(data)))
                obj.messageLog(cType.ERROR,cMessages.ListEmpty);
                return
            end
			if length(unique(data))~=N
                obj.messageLog(cType.ERROR,cMessages.ListNotUnique);
                return
			end
			% Create map container
			index=uint16(1:N);
			obj.map=containers.Map(data,index);
			obj.keys=data;
		end

		function res = existsKey(obj,key)
		%existsKey - Check if key exists
		%   Syntax:
		%     res = obj.existsKey(key)
		%   Input Arguments:
		%     key - key name
		%   Output Arguments:
		%     res - true | false
			res=obj.map.isKey(key);
		end
		
        function res = getIndex(obj,key)
		%getIndex - Get the corresponding index of a key
		%   Syntax:
		%     res = obj.getIndex(key)
		%   Input Arguments:
		%     key - key name
		%   Output Arguments
		%     res - Index of the key.
		%
			res=0;
			if obj.map.isKey(key)
				res=obj.map(key);
			end
		end

        function res = getKey(obj,id)
		%getKey - Get the corresponding key(s) of a set of indexes
		%   Syntax:
		%     res = obj.getKey(id)
		%   Input Arguments:
		%     id - index(es) 
		%   Output Arguments:
		%     res - key(s) 
		%
			res=cType.EMPTY;
            % Check index
            if ~obj.isIndex(id)
                return
            end
            % Return values or cells depending on index
            if isscalar(id)
                res=obj.Entries{id};
            else
                res=obj.Entries(id);
            end
        end

		function res = getKeys(obj)
		% getKeys - Get the keys of the dictionary
		%   Syntax:
		%     res = obj.getKeys;
			res=obj.keys;
		end

		function res=isIndex(obj,idx)
		%isIndex - Check if the index is valid
		%   Syntax:
		%     res = obj.isIndex(idx)
		%   Input Arguments:
		%     idx - Index to check
		%   Output Argument:
		%     res - true | false
			  res=isIndex(idx,1:length(obj));
		end

        function res=size(obj)
        % Overload size function
           res=size(obj.map);
        end
        
        function res=length(obj)
		% Overload length function
			res=obj.map.Count;
		end

		function res=numel(obj)
		% Overload numel function
			res=obj.map.Count;
		end
	end
end
