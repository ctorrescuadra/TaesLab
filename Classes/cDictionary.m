classdef cDictionary < cMessageLogger
%cDictionary - Class container to store and access data by key or index.
%   This class implements a (key, id) dictionary for TaesLab.
%   The keys are strings and the ids are integer numbers starting from 1.
%   The class uses a containers.Map object to store the (key, id) pairs.
%
%	cDictionary Properties:
%     - Keys - Cell array with the keys of the dictionary
%
%   cDictionary methods:
%     cDictionary - Construct an instance of this class
%     existsKey   - Check if a key exists in the dictionary
%     getIndex    - Get the index of a key
%     getKey      - Get the key associated to a index
%     getKeys     - Get all the keys of the dictionary
%     addKey      - Add a new key to the dictionary
%     isIndex     - Check if an index is valid
% 
    properties(Access=protected)
        map     % containers.Map object
	end

	properties(GetAccess=public,SetAccess=protected)
		Keys    % cell array with the keys
    end

	methods
        function obj = cDictionary(data)
		%cDictionary - Construct an instance of this class
		%   Syntax:
		%     obj = cDictionary(data)
		%   Input Arguments:
		%     data - cell array with the dictionary keys
		%   Output Arguments:
		%	 obj - cDictionary object
		 
			% Check input parameters
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
			obj.Keys=data;
		end

		function res = existsKey(obj,key)
		%existsKey - Check if key exists
		%   Syntax:
		%     res = obj.existsKey(key)
		%   Input Arguments:
		%     key - key name
		%   Output Arguments:
		%     res - true | false
		%
			res=obj.map.isKey(key);
		end
		
        function res = getIndex(obj,key)
		%getIndex - Get the corresponding index of a key
		%   Syntax:
		%     res = obj.getIndex(key)
		%   Input Arguments:
		%     key - key name
		%   Output Arguments:
		%     res - Index of the key.
		%
			res=0;
			if ~ischar(key), return; end
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
                res=obj.Keys{id};
            else
                res=obj.Keys(id);
            end
        end

		function res = getKeys(obj)
		% getKeys - Get the keys of the dictionary
		%   Syntax:
		%     res = obj.getKeys
		%   Output Arguments:
		%     res - cell array with the keys
		%
			res=obj.Keys;
		end

		function idx=addKey(obj,key)
		%addKey - Add a new key if doesn't exists
		%   Syntax:
		%     res = obj.addKey(idx)
		%   Input Arguments:
		%     key - key name
		%   Output Arguments:
		%     idx - true | false
		%
			idx=0;
			if ~obj.existsKey(key)
				idx=obj.map.Count+1;
				obj.map(key)=idx;
				obj.Keys{idx}=key;
			end
		end

		function res=isIndex(obj,idx)
		%isIndex - Check if the index is valid. 
		% 	Overload isIndex function
		%   Syntax:
		%     res = obj.isIndex(idx)
		%   Input Arguments:
		%     idx - Index to check
		%   Output Arguments:
		%     res - true | false
		%
			res=isIndex(idx,1,length(obj));
		end

        function res=size(obj)
        %size - Size of the dictionary
		%	Overload size function
		%   Syntax:
		%     res = obj.size
		%   Output Arguments:
		%     res - size of the dictionary
		%
           res=size(obj.map);
        end
        
        function res=length(obj)
		%length - Length of the dictionary
		% 	Overload length function
		%   Syntax:
		%     res = obj.length
		%   Output Arguments:
		%     res - length of the dictionary
		%
			res=obj.map.Count;
		end

		function res=numel(obj)
		%numel - Number of elements of the dictionary
		% 	Overload numel function
		%   Syntax:
		%     res = obj.numel
		%   Output Arguments:
		%     res - number of elements of the dictionary
		%
			res=obj.map.Count;
		end
	end
end
