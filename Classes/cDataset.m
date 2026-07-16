classdef(Sealed) cDataset < cDictionary
%cDataset - Keyed container for storing and retrieving TaesLab data objects.
%   cDataset extends cDictionary to associate a stored object (value) with
%   each key in the dictionary.  Keys are non-empty, unique strings; values
%   can be any MATLAB object.
%
%   Within TaesLab, cDataset is used to hold per-state or per-sample data
%   objects (e.g. cExergyData, cExergyCost, cResourceData), allowing lookup
%   by the state name or sample name string as well as by numeric index.
%
%   Individual entries can be read (getValues), replaced (setValues), or
%   appended (addValues) after construction.  All methods that fail due to
%   an invalid argument log an error through the cMessageLogger mechanism
%   and return an object whose status is false.
%
%   cDataset Methods:
%     cDataset  - Construct a dataset from a list of key names
%     getValues - Retrieve the object stored at a given key or index
%     setValues - Replace the object stored at a given key or index
%     addValues - Append a new key-value pair to the dataset
%
%   cDataset Methods (inherited from cDictionary):
%     existsKey - Check whether a key string exists in the dictionary
%     getIndex  - Return the numeric index associated with a key string
%     getKey    - Return the key string associated with a numeric index
%     getKeys   - Return all key strings as a cell array
%     addKey    - Append a new key to the dictionary
%     isIndex   - Check whether a numeric index is within the valid range
%
%   See also cDictionary, cMessageLogger
%
    properties (Access=private)
        Values       % Cell array with the objects
    end
  
    methods
        function obj=cDataset(list)
        %cDataset - Construct a dataset from a list of key names
        %   Delegates key validation and storage to the cDictionary
        %   constructor, then pre-allocates the internal cell array that
        %   holds the associated value objects.  The object status is set
        %   to false (invalid) when cDictionary construction fails, i.e.
        %   when list is not a non-empty cell array of unique, non-empty
        %   strings.
        %
        %   Syntax:
        %     obj = cDataset(list)
        %
        %   Input Arguments:
        %     list - Cell array of unique, non-empty key strings.
        %            Each element becomes the key for one dataset entry.
        %
        %   Output Arguments:
        %     obj  - cDataset object.  Use isValid(obj) to confirm
        %            successful construction before operating on it.
        %
            obj=obj@cDictionary(list);
            % Validate object and initialize values
            if obj.status
                obj.Values=cell(1,length(obj));
            end
        end
 
        function res=getValues(obj,arg)
        %getValues - Retrieve the object stored at a given key or index
        %   Returns the value object associated with the specified entry.
        %   The argument can be supplied either as a string key or as a
        %   positive integer index; both forms are resolved internally.
        %   If the argument is invalid (unknown key, out-of-range index,
        %   or wrong type), an error is logged and a cMessageLogger with
        %   status false is returned.
        %
        %   Syntax:
        %     res = obj.getValues(arg)
        %
        %   Input Arguments:
        %     arg - Key string (char) or numeric index (positive integer)
        %           identifying the entry to retrieve.
        %
        %   Output Arguments:
        %     res - The stored object for the requested entry, or a
        %           cMessageLogger with status false if arg is invalid.
        %
            res=cMessageLogger();
            idx=obj.validateArguments(arg);
            if idx
                res=obj.Values{idx};
            else
                res.messageLog(cType.ERROR,cMessages.InvalidDataSetKey);
            end
        end

        function log=setValues(obj,arg,val)
        %setValues - Replace the object stored at a given key or index
        %   Overwrites the value currently stored at the entry identified
        %   by arg with the new object val.  Because cDataset is a handle
        %   class, the update is visible through all references to the
        %   same object without reassignment.
        %   If arg is invalid (unknown key, out-of-range index, or wrong
        %   type), an error is logged on the returned cMessageLogger and
        %   the dataset is left unchanged.
        %
        %   Syntax:
        %     log = obj.setValues(arg, val)
        %
        %   Input Arguments:
        %     arg - Key string (char) or numeric index (positive integer)
        %           identifying the entry to overwrite.
        %     val - New object to store at the specified entry.
        %
        %   Output Arguments:
        %     log - cMessageLogger with the operation status.  Check
        %           log.status to verify whether the assignment succeeded.
        %
            log=cMessageLogger();
            idx=obj.validateArguments(arg);
            if idx
                obj.Values{idx}=val;
            else
                log.messageLog(cType.ERROR,cMessages.InvalidDataSetKey);
            end
        end

        function log=addValues(obj,key,val)
        %addValues - Append a new key-value pair to the dataset
        %   Registers key as a new dictionary entry (via cDictionary.addKey)
        %   and appends val to the internal value array.  The new entry
        %   receives the next available numeric index.
        %   The operation fails, and an error is logged, when key already
        %   exists in the dictionary or is not a valid non-empty string.
        %
        %   Syntax:
        %     log = obj.addValues(key, val)
        %
        %   Input Arguments:
        %     key - Non-empty string key that does not yet exist in the
        %           dataset.  Duplicate keys are rejected.
        %     val - Object to associate with the new key.
        %
        %   Output Arguments:
        %     log - cMessageLogger with the operation status.  Check
        %           log.status to verify whether the entry was added.
        %
            log=cMessageLogger();
            idx=obj.addKey(key);
            if idx
                obj.Values{end+1}=val;
            else
                log.messageLog(cType.ERROR,cMessages.InvalidDataSetKey);
            end
        end
    end

    methods(Access=private)
        function idx=validateArguments(obj,arg)
        %validateArguments - Resolve a key or index argument to a numeric index
        %   Accepts either a string key or a positive integer index and
        %   returns the corresponding numeric index within the dataset.
        %   String arguments are looked up through cDictionary.getIndex;
        %   numeric arguments are validated through cDictionary.isIndex.
        %   Returns 0 when arg is neither a known key nor a valid index,
        %   signalling the caller to report an error.
        %
        %   Syntax:
        %     idx = obj.validateArguments(arg)
        %
        %   Input Arguments:
        %     arg - Key string (char) or numeric index to validate.
        %
        %   Output Arguments:
        %     idx - Positive integer index into the Values array, or 0 if
        %           arg is an unknown key, an out-of-range index, or has
        %           an unsupported type.
        %
            idx=0;
            if ischar(arg)
                idx=getIndex(obj,arg);
            elseif isIndex(obj,arg)
                idx=arg;
            end
        end
    end
end