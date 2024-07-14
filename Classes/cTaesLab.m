classdef cTaesLab < handle
    %cTaesLab Base class of the TaesLab toolbox
    properties(GetAccess=protected,SetAccess=private)
        objectId    % Unique object Id
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