classdef  cTaesLab < handle
    % cTaesLab - Base Abstract class of the TaesLab toolbox
    %
    % cTaesLab properties
    %   objectId - Unique object identifier
    %     int64
    %   status - status of the object
    %     true | false
    %
    % cTaesLab methods:
    %  isValid - Check is the object is valid
    properties(Access=protected)
        objectId % Unique object Id
    end
    properties(GetAccess=public,SetAccess=protected)
        status  % Object status
    end
    methods
        function obj = cTaesLab()
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
        % Check if object is Valid
        % Syntax:
        %	test = isValid(obj)
        %
            test=isa(obj,'cTaesLab') && obj.status;
        end
    
        function test=isResultId(obj)
        % Check if object is a valid cResultId object
        % Syntax:
        %	test = isResultId(obj)
        %
            test=(isa(obj,'cResultId') || isa(obj,'cDataModel') || isa(obj,'cThermoeconomicModel'));
            test=test && isValid(obj);
        end
    
        function test=isDataModel(obj)
        % Check if object is a valid cDataModel
        % Syntax:
        %	test = isDataModel(obj)
        %
            test=isa(obj,'cDataModel') && isValid(obj);
        end
    
        function test=isResultSet(obj)
        % Check if object is a valid cResultSet
        % Syntax:
        %	test = isResultSet(obj)
        %
            test=isa(obj,'cResultSet') && isValid(obj);
        end

        function test=isResultInfo(obj)
        % Check if object is a valid cResultSet
        % Syntax:
        %	test = isResultInfo(obj)
        %
            test=isa(obj,'cResultInfo') && isValid(obj);
        end
    
        function test=isValidTable(obj)
        % Check if object is a valid cTable
        % Syntax:
        %	test = isValidTable(obj)
            test=isa(obj,'cTable') && isValid(obj);
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