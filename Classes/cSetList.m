classdef cSetList < cStatusLogger
% cSetList creates a list whose elements are unique
%   The class provide methods to check if an element is member of the set
%   and determine its position in the set
%   
%   Methods
%     obj=cSetList(list)
%     res=existValue(val)
%     id=getIndex(val)
%     val=getValue(id)
%
    properties (GetAccess=public,SetAccess=private)
        Entries={}    % Entries of the list - cell array
    end
    properties (Access=private)
        index      % Internal structure
    end
    methods
        function obj=cSetList(list)
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
            % Create the internal structure
            obj.index=struct();
            for i=1:N
                obj.index.(list{i})=i;
            end
            obj.Entries=list;
        end

        function res=existValue(obj,val)
        % Check if a value belong to the set
        %   val - char array 
            res=isfield(obj.index,val);
        end

        function res=getIndex(obj,val)
        % Get the position of the val in the list
            res=[];
            if obj.existValue(val)
                res=obj.index.(val);
            end
        end

        function res=Values(obj,id)
        % Get the element in the position id 
            res=[];
            % If no index is supplied resturn all values
            if nargin==1
                res=obj.Entries;
                return
            end
            % Check index
            aux=1:length(obj.Entries);
            if ~all(ismember(id,aux))
                return
            end
            % Return values or cells depending on index
            if length(id)==1
                res=obj.Entries{id};
            else
                res=obj.Entries(id);
            end
        end

        function setValue(obj,id,val)
            if id>0 && id <= length(obj)
                obj.Entries{id}=val;
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
end