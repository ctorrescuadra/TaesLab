classdef  cTaesLab < handle
    %TaesLab - Base class of the TaesLab toolbox.
    %   Asign a unique objectId to each object and permit to set
    %   the status of the class derived from it. It also provides equality
    %   (eq) and inequality (ne) operators to compare two objects of the same class.
    %
    %   cTaesLab properties
    %     objectId - Unique object identifier 
    %       int64
    %     status - status of the object 
    %       true | false
    %       Default value is true
    %
    %   cTaesLab methods:
    %     cTaesLab     - Initialize a cTaesLab object
    %     getObjectId  - Get the object id
    % 
    properties(Access=protected)
        objectId % Unique object Id
    end

    properties(GetAccess=public,SetAccess=protected)
        status=true  % Object status (default true)
    end

    methods
        function obj = cTaesLab(val)
        %cTaesLab - Initialize a cTaesLab object
        %   Syntax:
        %     obj = cTaesLab()
        %   Output Arguments:
        %     obj - cTaesLab object
        %     obj = cTaesLab(status)
        %   Input Arguments:
        %     val - Initial status of the object [optional]
        %       cType.VALID | cType.INVALID
        %       Default value is cType.VALID
        %
            if nargin==1 && isscalar(val) && islogical(val)
                obj.status=val;
            end
            obj.objectId=cTaesLab.sequence;
        end

        function res = getObjectId(obj)
        %getObjectId - Get the object identifier
        %   Syntax:
        %     res = obj.getObjectId
            res=obj.objectId;
        end

        function res=eq(obj1,obj2)
        %eq - Overload eq operator. Check if two class object are equal.
        %   Syntax:
        %     res = (obj1 == obj2)
        %   Input Arguments:
        %     obj1 - cTaesLab object
        %     obj2 - cTaesLab object
        %   Output Arguments:
        %     res - true | false
        %
            res=(obj1.objectId==obj2.objectId);
        end
        
        function res=ne(obj1,obj2)
        %ne - Overload ne operator. Check if two class objects are different.
        %   Syntax:
        %     res = (obj1 ~= obj2)
        %   Input Arguments:
        %     obj1 - cTaesLab object
        %     obj2 - cTaesLab object
        %   Output Arguments:
        %     res - true | false
        %
            res=(obj1.objectId~=obj2.objectId);
		end
    end

    methods(Static,Access=private)
        function res=sequence()
		%sequence - Generate a unique object identifier.
        %   Use a persistent variable to count the number of objects created.
        %   Syntax:
        %     res = cTaesLab.sequence
        %   Output Arguments:
        %     res - Unique object identifier
        %
			persistent counter;
			if isempty(counter)
				counter=uint64(1);
			else
				counter=counter+1;
			end
			res=counter;
        end
    end
end