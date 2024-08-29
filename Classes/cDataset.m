classdef cDataset < cMessageLogger
% cDataset creates a container to store data and to access it by key or index
%   This class is used to store cExergyData, cExergyCost, and cResourceData objects
%   and access by state name or sample name. It use a cell array to keep the access keys
%   and a cell array of the same length to keep the objects.
%
% cDataset Properties:
%   Entries     - Entries of the data set - cell array of chars
%   Values      - Cell array with the object entries
%   NrOfEntries - Number of Entries
%
% cDataset Methods:
%   getValues - get the object associated to an entry
%   setValues - set an object to an entry
%   existKey  - Check if the key entry exists
%   getIndex  - Get the index of a key
%   getEntries - Get the key/s of a given index(es)
%
    properties (GetAccess=public,SetAccess=private)
        Entries      % Entries of the list - cell array of chars
        Values       % Cell array with the object
        NrOfEntries  % Number of Entries
    end
  
    methods
        function obj=cDataset(list)
        % Construct an object 
        %   list - cell array containig the values
            % Validate list
            if iscell(list) && ~isempty(list)
                N=length(list);
            else
                obj.messageLog(cType.ERROR,'List must be a cell array');
                return
            end
            if any(cellfun(@isempty,strtrim(list)))
                obj.messageLog(cType.ERROR,'List values cannot be empty');
                return
            end
            if length(unique(list))~=N
                obj.messageLog(cType.ERROR,'List values must be unique');
                return
            end
            if any(cellfun(@isempty,regexp(list,cType.NAME_PATTERN)))
                obj.messageLog(cType.ERROR,'List values are no valid');
                return
            end
            obj.Entries=list;
            obj.NrOfEntries=length(list);
            obj.Values=cell(1,obj.NrOfEntries);
        end

        function res=existKey(obj,key)
        % Check if a value belong to the collection
        %   key - char array
            res=false;
            if ischar(key)
                res=ismember(key,obj.Entries);
            end
        end

        function res=getIndex(obj,key)
        % Get the index location of the key
        %   key - char array
            [~,res]=ismember(key,obj.Entries);
        end

        function res=getEntries(obj,id)
        % Get the keys in the position id
        %   Input:
        %     id - position of the keys
            res=cType.EMPTY;
            % If no index is supplied resturn all values
            if nargin==1
                res=obj.Entries;
                return
            end
            % Check index
            if ~obj.isIndex(id)
                return
            end
            % Return values or cells depending on index
            if length(id)==1
                res=obj.Entries{id};
            else
                res=obj.Entries(id);
            end
        end

        function res=getValues(obj,arg)
        % Get the element in the position id
        %   Input:
        %     arg - key or index of the values to retrive
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
        %   Input:
        %     arg - key or index where value is assigned
        %     val - values to assing
            log=cMessageLogger();
            idx=obj.validateArguments(arg);
            if idx
                obj.Values{idx}=val;
            else
                log.messageLog(cType.ERROR,'cDataset.setValues invalid key');
            end
        end

        function res=length(obj)
        % Overload function length
            res=length(obj.Entries);
        end

        function res=numel(obj)
        % Overload function numel
            res=numel(obj.Entries);
        end

        function res=size(obj)
        % Overload function size
            res=size(obj.Entries);
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

        function res=isIndex(obj,idx)
        % Check if idx is a valid index
            res=cType.isInteger(idx,1:obj.NrOfEntries);
        end
        
    end
end