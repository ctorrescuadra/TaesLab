classdef  cTaesLab < handle
    %TaesLab - Base class of the TaesLab toolbox
    %   Asign a unique objectId to each object
    %   and permit to set the status of the class
    %   to each class derived from it.
    %
    %   cTaesLab constructor
    %     obj = cTaesLab() 
    %
    %   cTaesLab properties
    %     objectId - Unique object identifier 
    %       int64
    %     status - status of the object
    %       true | false
    %
    %   cTaesLab methods:
    %     getObjectId  - Get the object id
    % 
    properties(Access=protected)
        objectId % Unique object Id
    end

    properties(GetAccess=public,SetAccess=protected)
        status  % Object status
    end

    methods
        function obj = cTaesLab()
        %cTaesLab - Initialize a cTaesLab object
            obj.status=cType.VALID;   
            obj.objectId=cTaesLab.sequence;
        end

        function set.status(obj,val)
        % Set status of the class
            if isscalar(val) && islogical(val)
                obj.status=val;
            end
        end

        function res = getObjectId(obj)
        %getObjectId Get the object identifier
        %   Syntax:
        %     res = obj.getObjectId
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

    methods(Static,Access=private)
        function res=sequence()
		% Generate a sequence of numbers. Internal function,
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