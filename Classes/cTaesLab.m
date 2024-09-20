classdef  cTaesLab < handle
    % cTaesLab - Base class of the TaesLab toolbox
    %
    % cTaesLab properties
    %   objectId - Unique object identifier 
    %     int64
    %   status - status of the object
    %     true | false
    %
    % cTaesLab methods:
    %  getObjectId  - Get the object id
    % 
    properties(Access=protected)
        objectId % Unique object Id
    end
    properties(GetAccess=public,SetAccess=protected)
        status  % Object status
    end
    methods
        function obj = cTaesLab()
        % Initialize a cTaesLab object
            obj.status=cType.VALID;   
            obj.objectId=cType.sequence;
        end

        function set.status(obj,val)
        % Set state value
            if isscalar(val) && islogical(val)
                obj.status=val;
            end
        end

        function res = getObjectId(obj)
        % Get the object identifier
            res=obj.objectId;
        end

        function res=eq(obj1,obj2)
        % Overload eq operator. Check if two class object are equal. 
            res=(obj1.objectId==obj2.objectId);
        end
        
        function res=ne(obj1,obj2)
        % Overload ne operator. Check if two class objects are different. 
            res=(obj1.objectId~=obj2.objectId);
		end
    end
end