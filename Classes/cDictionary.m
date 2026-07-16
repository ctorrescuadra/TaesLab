classdef cDictionary < cMessageLogger
%cDictionary - Bidirectional string-to-index dictionary for TaesLab.
%   cDictionary maintains an ordered, one-to-one mapping between unique
%   string keys and consecutive uint16 indices starting at 1.  Lookup is
%   O(1) in both directions: by key string via an internal containers.Map
%   and by index via the public Keys cell array.
%
%   The class inherits from cMessageLogger, so construction failures
%   (empty input, non-cell input, duplicate or blank keys) are recorded
%   as errors and leave the object with status false rather than throwing.
%
%   New entries can be appended at runtime with addKey; the mapping is
%   otherwise immutable after construction.
%
%   cDictionary Properties:
%     Keys - Cell array of key strings in insertion order (read-only).
%
%   cDictionary Methods:
%     cDictionary - Construct a dictionary from a cell array of key strings
%     existsKey   - Check whether a key string is registered
%     getIndex    - Return the numeric index for a key string
%     getKey      - Return the key string(s) for one or more numeric indices
%     getKeys     - Return all key strings as a cell array
%     addKey      - Append a new key string to the dictionary
%     isIndex     - Check whether a numeric index is within the valid range
%     size        - Return the size of the dictionary (overloads built-in)
%     length      - Return the number of entries (overloads built-in)
%     numel       - Return the number of entries (overloads built-in)
%
%   See also cMessageLogger, containers.Map
% 
    properties(Access=protected)
        map     % containers.Map object
	end

	properties(GetAccess=public,SetAccess=protected)
		Keys    % cell array with the keys
    end

	methods
        function obj = cDictionary(data)
		%cDictionary - Construct a dictionary from a cell array of key strings
		%   Validates data and builds the internal containers.Map and Keys
		%   array.  Construction fails (status set to false) under any of the
		%   following conditions:
		%     - data is not a cell array, or is empty
		%     - any element of data is a blank or empty string
		%     - data contains duplicate key strings
		%
		%   Syntax:
		%     obj = cDictionary(data)
		%
		%   Input Arguments:
		%     data - Cell array of unique, non-empty string keys.
		%            Insertion order is preserved and determines the
		%            numeric indices (first key → 1, second → 2, ...).
		%
		%   Output Arguments:
		%     obj  - cDictionary object.  Use isValid(obj) to confirm
		%            successful construction before operating on it.
		% 
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
		%existsKey - Check whether a key string is registered in the dictionary
		%
		%   Syntax:
		%     res = obj.existsKey(key)
		%
		%   Input Arguments:
		%     key - String to look up.
		%
		%   Output Arguments:
		%     res - Logical scalar: true if key is present, false otherwise.
		%
			res=obj.map.isKey(key);
		end
		
        function res = getIndex(obj,key)
		%getIndex - Return the numeric index associated with a key string
		%   Returns 0 when key is not a string or is not registered,
		%   providing a safe sentinel the caller can test without error.
		%
		%   Syntax:
		%     res = obj.getIndex(key)
		%
		%   Input Arguments:
		%     key - String key to look up.
		%
		%   Output Arguments:
		%     res - Positive uint16 index if key exists; 0 otherwise.
		%
			res=0;
			if ~ischar(key), return; end
			if obj.map.isKey(key)
				res=obj.map(key);
			end
		end

        function res = getKey(obj,id)
		%getKey - Return the key string(s) corresponding to one or more indices
		%   The return type depends on whether id is scalar or a vector:
		%     - Scalar id  → returns a single char string.
		%     - Vector id  → returns a cell array of char strings.
		%   Returns cType.EMPTY when any element of id is out of range.
		%
		%   Syntax:
		%     res = obj.getKey(id)
		%
		%   Input Arguments:
		%     id  - Positive integer scalar or vector of indices to look up.
		%           All elements must be within [1, length(obj)].
		%
		%   Output Arguments:
		%     res - Char string (scalar id) or cell array of strings (vector
		%           id), or cType.EMPTY if id is invalid.
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
		%getKeys - Return all key strings in insertion order
		%   Returns the same cell array as the public Keys property.
		%   Keys are ordered by their assigned index (Keys{i} has index i).
		%
		%   Syntax:
		%     res = obj.getKeys()
		%
		%   Output Arguments:
		%     res - 1×N cell array of char strings, where N = length(obj).
		%
			res=obj.Keys;
		end

		function idx=addKey(obj,key)
		%addKey - Append a new key to the dictionary if it does not yet exist
		%   Assigns the next available index to key and registers it in the
		%   internal map and Keys array.  If key is already registered the
		%   dictionary is left unchanged and 0 is returned, allowing the
		%   caller to detect the duplicate without an error being thrown.
		%
		%   Syntax:
		%     idx = obj.addKey(key)
		%
		%   Input Arguments:
		%     key - Non-empty string key to add.  Must not already exist.
		%
		%   Output Arguments:
		%     idx - Positive integer index assigned to the new key, or 0 if
		%           key already exists or is otherwise invalid.
		%
			idx=0;
			if ~obj.existsKey(key)
				idx=obj.map.Count+1;
				obj.map(key)=idx;
				obj.Keys{idx}=key;
			end
		end

		function res=isIndex(obj,idx)
		%isIndex - Check whether a numeric index is within the valid range
		%   Overloads the standalone isIndex function, binding the valid
		%   range to [1, length(obj)] automatically.  Accepts scalar or
		%   vector idx; all elements must be in range for the result to be
		%   true.
		%
		%   Syntax:
		%     res = obj.isIndex(idx)
		%
		%   Input Arguments:
		%     idx - Numeric scalar or vector of indices to validate.
		%
		%   Output Arguments:
		%     res - Logical scalar: true if all elements of idx are integers
		%           in [1, length(obj)], false otherwise.
		%
			res=isIndex(idx,1,length(obj));
		end

        function res=size(obj)
        %size - Return the size of the dictionary (overloads built-in size)
		%   Delegates to size(containers.Map), which returns [1, N] where
		%   N is the number of registered entries.
		%
		%   Syntax:
		%     res = obj.size()
		%
		%   Output Arguments:
		%     res - 1×2 array [1, N], where N = number of dictionary entries.
		%
           res=size(obj.map);
        end
        
        function res=length(obj)
		%length - Return the number of entries in the dictionary (overloads built-in)
		%   Returns the same value as numel(obj).  Provided so that
		%   length(obj) gives the entry count rather than the default
		%   handle-object behaviour.
		%
		%   Syntax:
		%     res = obj.length()
		%
		%   Output Arguments:
		%     res - Scalar integer equal to the number of registered keys.
			res=obj.map.Count;
		end

		function res=numel(obj)
		%numel - Return the number of entries in the dictionary (overloads built-in)
		%   Overrides the default handle-object numel so that expressions
		%   such as numel(obj) report the dictionary entry count instead of 1.
		%
		%   Syntax:
		%     res = obj.numel()
		%
		%   Output Arguments:
		%     res - Scalar integer equal to the number of registered keys.
		%
			res=obj.map.Count;
		end
	end
end
