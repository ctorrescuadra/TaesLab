classdef cDataset < cDictionary
% cDataset creates a container to store data and to access it by key or index
%   This class is used to store cExergyData, cExergyCost, and cResourceData objects
%   and access by state name or sample name.
%
% cDataset Methods:
%   getValues - Get the object associated to an entry
%   setValues - set an object to an entry
%
    properties (Access=private)
        Values       % Cell array with the object
    end
  
    methods
        function obj=cDataset(list)
        % Build an instance of the object
        % Syntax:
        %   obj = cDataset(list)
        % Input Arguments:
        %   list - cell array containig the key values
        %
            % Validate list
            obj=obj@cDictionary(list);
            obj.Values=cell(1,length(obj));
        end
 
        function res=getValues(obj,arg)
        % Get an element of the dataset
        % Syntax: 
        %   res = obj.getValues(arg)
        % Input Argument:
        %   arg - key or index of the values to retrive
        % Output Argument:
        %   res - object with the required values
        %
            % Validate arguments
            res=cMessageLogger();
            idx=obj.validateArguments(arg);
            if idx
                res=obj.Values{idx};
            else
                res.messageLog(cType.ERROR,'cDataset.getValues invalid key');
            end
        end

        function log=setValues(obj,arg,val)
        % Set the values in position indicates by arg
        % Syntax: 
        %   res = obj.getValues(arg)
        % Input Argument:
        %   arg - key or index of the values
        %   val - object with the values to store
        % Output Argument:
        %   log - cMessagesLog with status and messages
        %
            log=cMessageLogger();
            idx=obj.validateArguments(arg);
            if idx
                obj.Values{idx}=val;
            else
                log.messageLog(cType.ERROR,'cDataset.setValues invalid key');
            end
        end
    end

    methods(Access=private)
        function idx=validateArguments(obj,arg)
        % Check if the arguments are valid
        %   Return the index of the argument or zero if its not valid
            idx=0;
            if ischar(arg)
                idx=getIndex(obj,arg);
            elseif isIndex(obj,arg)
                idx=arg;
            end
        end
    end
end