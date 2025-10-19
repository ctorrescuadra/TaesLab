classdef  cTaesLab < handle
    %TaesLab - Base class of the TaesLab toolbox.
    %   Asign a unique objectId to each object and permit to set
    %   the status of the class derived from it.
    %   Provides methods to print error, warning and info messages,
    %   Also provides equality (eq) and inequality (ne) operators 
    %   to compare two objects of the same class.
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
    %     printError   - Print error message
    %     printWarning - Print warning message
    %     printInfo    - Print info message
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

        function printError(obj,varargin)
		%printError - Print error message. 
		%   Syntax:
		%	  obj.printError(varargin)
		%   Input Arguments:
		%     text - text message, use fprintf syntax
		%       varargin
		%   Example:
		%	  obj.printError(cMessages.FileNotFound,filename)
		%
			printMessage(obj,cType.ERROR,varargin{:});
		end
			
		function printWarning(obj,varargin)
		%printWarning - Print warning message. 
		%   Syntax:
		% 	  obj.printWarning(varargin)
		%   Input Arguments:
		%     text - text message, use fprintf syntax
		%       varargin
		% 
			printMessage(obj,cType.WARNING,varargin{:});
		end
			
		function printInfo(obj,varargin)
		%printInfo - Print info message. Use fprintf syntax
		%   Syntax:
		%     obj.printInfo(text)
		%   Input Arguments:
		%     text - text message, using fprintf syntax
		%       varargin
		%
			printMessage(obj,cType.VALID,varargin{:});
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

	methods(Access=protected)
		function message=createMessage(obj,error,varargin)
		%createMessage - Create the text message depending of error code
		%   Syntax:
		%     message = obj.createMessage(error,varargin)
		%   Input Arguments:
		%     error - type of error
		%       cType.ERROR | cType.WARNING | cType.INFO
		%     text - text message, use fprintf format
		%       varargin
		%   Output Arguments:
		%     message - cMessageBuilder object containing the message
		%	 Example:
		%	   message=obj.createMessage(cType.ERROR,cMessages.InvalidFileName,filename)
		%
			if error>cType.INFO || error<cType.WARNING || isempty(varargin)
				text='Unknown Error Code';
			else
				text=sprintf(varargin{:});
			end
			if error==cType.ERROR
				obj.status=logical(error);
			end
			message=cMessageBuilder(error,class(obj),text);
		end

		function printMessage(obj,error,varargin)
		% Print messages depending of type error and update state
		%   Syntax:
		%     obj.printMessage(error,varargin)
		%   Input Arguments:
		%     error - type of error
		%       cType.ERROR | cType.WARNING | cType.INFO
		%     text - text message, use fprintf format
		%       varargin
		%   Example:
		%     obj.printMessage(cType.ERROR,cMessages.InvalidFileName,filename)
        %     %returns ERROR: cTaesLab. Invalid file name 'filename'
		%
			msg=obj.createMessage(error,varargin{:});
			disp(msg);
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