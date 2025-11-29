classdef(Sealed) cDataset < cDictionary
%cDataset - Class container to store objects and access them by key.
%   This class implements a dataset for TaesLab.
%   The keys are strings and the objects can be of any class.
%   This class is used to store cExergyData, cExergyCost, and cResourceData objects
%   and access by state name or sample name.
%
%   cDataset methods:
%     cDataset  - Build an instance of the object
%     getValues - Get the object associated to an entry
%     setValues - Set an object to an entry
%     addValues - Add a new entry
%
%   cDataset methods (inherited from cDictionary):
%     existsKey   - Check if a key exists in the dictionary
%     getIndex    - Get the index of a key
%     getKey      - Get the key associated to a index
%     getKeys     - Get all the keys of the dictionary
%     addKey      - Add a new key to the dictionary
%     isIndex     - Check if an index is valid
%
%   See also cDictionary
%
    properties (Access=private)
        Values       % Cell array with the objects
    end
  
    methods
        function obj=cDataset(list)
        %cDataset - Build an instance of the object
        %   Syntax:
        %     obj = cDataset(list)
        %   Input Arguments:
        %     list - cell array containig the key values
        %   Output Arguments:
        %     obj - cDataset object
        %
            obj=obj@cDictionary(list);
            % Validate object and initialize values
            if obj.status
                obj.Values=cell(1,length(obj));
            end
        end
 
        function res=getValues(obj,arg)
        %getValues - Get an element of the dataset
        %   Syntax: 
        %     res = obj.getValues(arg)
        %   Input Arguments:
        %     arg - key or index of the values to retrive
        %   Output Arguments:
        %     res - object with the required values
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
        %setValues - Set the values in position indicates by arg
        %   Syntax: 
        %     res = obj.setValues(arg,val)
        %   Input Arguments:
        %     arg - key or index of the values
        %     val - object with the values to store
        %   Output Arguments:
        %     log - cMessagesLog with status and messages
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
        %addValues - Add a new value at the end of the dataset
        %   Syntax: 
        %     res = obj.addValues(key,val)
        %   Input Arguments:
        %     key - key name
        %     val - object with the values to store
        %   Output Arguments:
        %     log - cMessagesLogger with status and messages
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
        %validateArguments - Check if the arguments are valid
        %   Syntax: 
        %     idx = obj.validateArguments(arg)
        %   Input Arguments:
        %     arg - key or index of the values
        %   Output Arguments:
        %     idx - index of the values or zero if its not valid
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