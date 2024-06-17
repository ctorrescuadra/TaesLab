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
        st      % Internal structure
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
            obj.st=struct();
            for i=1:N
                obj.st.(list{i})=i;
            end
            obj.Entries=list;
        end

        function res=existValue(obj,val)
        % Check if a value belong to the set
        %   val - char array 
            res=isfield(obj.st,val);
        end

        function res=getIndex(obj,val)
        % Get the position of the val in the list
            res=0;
            if obj.existKey(val)
                res=obj.st.(val);
            end
        end

        function res=getKey(obj,id)
        % Get the element in the position id
            res=[];
            if id>0 && id <= length(obj)
                res=obj.Entries{id};
            end
        end

        function res=length(obj)
        % Overload function length
            res=length(obj.Entries);
        end

        function res=size(obj)
        % Overload function size
            res=size(obj.Entries);
        end
    end
end