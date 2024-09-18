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
    %  isValid      - Check is the object is valid
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

        function test=isValid(obj)
        % Check if a cTaesLab object is Valid
        % Syntax:
        %	test = isValid(obj)
        %
            try
                test = isa(obj,'cTaesLab') && obj.status;
            catch
                test=false;
            end
        end

        function res = getObjectId(obj)
        % Get the object identifier
            res=obj.objectId;
        end

        function res=eq(obj1,obj2)
        % Check if two class object are equal. Overload eq operator
            res=(obj1.objectId==obj2.objectId);
        end
        
        function res=ne(obj1,obj2)
        % Check if two class objects are different. Overload ne operator
            res=(obj1.objectId~=obj2.objectId);
		end
    end
end