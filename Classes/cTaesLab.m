classdef cTaesLab < handle
    %cTaesLab Base class of the TaesLab toolbox
    properties(GetAccess=protected,SetAccess=private)
        objectId
        classId=0
    end

    methods
        function obj = cTaesLab()
        %cTaesLab Construct an instance of this class
            obj.objectId=randi(intmax,"int32");
        end

        function res = getObjectId(obj)
        % getObjectId - get the object identifier
            res=obj.objectId;
        end

        function setClassId(obj,value)
        % Set Class Id value
            obj.classId=value;
        end

        function res=getClassId(obj)
        % Get Class Id object
            res=obj.classId;
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