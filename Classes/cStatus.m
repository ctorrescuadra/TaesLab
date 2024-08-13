classdef cStatus < cTaesLab
    % cStatus - Define the object status for TaesLab objects
    %   Include functions to validate the status of the objects
    %   and print the error messgaes on the console
    %
    % cStatus Properties:
    %    status - Status of the object. boolean
    %
    % cStatus Methods
	%
	%  Check Methods:
    %   isValid - Check if a object is valid
    %   isResultId - Check if a object is a valid cResultId
    %   isDataModel - Check if a object is a valid cDataModel
    %   isResultSet - Check if a object is a valid cResultSet
    %   isValidTable - Check if a object is a valid cTable
	%
	%  Print Methods:
    %   printError - Print a error message on the console
    %   printWarning - Print a warning message on the console
    %   printInfo - Print a info message on the console
    %
	% See also cStatusLogger
	properties(GetAccess=public,SetAccess=protected)
		status	% Status of the object
	end
	
	methods
		function obj=cStatus(val)
		% Create an instace of the cStatus class 
		% Initialize cStatus object to manage errors
        % Syntax:
        %   obj = cStatus();
        %   obj = cStatus(value);
		% Input Arguments:
		%   val - Initial status [optional]
        %     false | true (default).
		%
            if nargin<1
    	        obj.status=true;
            else
                obj.status=logical(val);
            end
		end
				
		function test=isValid(obj)
		% Check if object is Valid
        % Syntax:
		%	test = isValid(obj)
        %
			test=(obj.status>cType.ERROR);
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

		function test=isValidTable(obj)
		% Check if object is a valid cTable
		% Syntax:
		%	test = isValidTable(obj)
			test=isa(obj,'cTable') && isValid(obj);
		end

		function printError(obj,varargin)
		% Print error message. Use fprintf syntax
		% Syntax:
		%	obj.printError(varargin)
        % Input Argument:
		%   text - text message
    	%     varargin
		% Example
		%	obj.printError('File %s not found',filename)
    	% See also fprintf
			printMessage(obj,cType.ERROR,varargin{:});
		end
		
		function printWarning(obj,varargin)
		% Print warning message. Use fprintf syntax
		% Syntax:
		% 	obj.printWarning()
		% Input Argument:
		%   text - text message
    	%     varargin
		% See also fprintf
			printMessage(obj,cType.WARNING,varargin{:});
		end
		
		function printInfo(obj,varargin)
		% Print info message. Use fprintf syntax
		% Input Argument:
		%   text - text message
        %     varargin
		% See also fprintf
			printMessage(obj,cType.VALID,varargin{:});
        end
    end
	
	methods(Access=protected)
		function message=createMessage(obj,error,varargin)
		% Create the text message depending of error code
		% Input Argument:
		%   error - Error code
        %     cType.ERROR (0)
        %     cType.VALID (1)
        %     cType.WARNING (-1)
		%   text - message text
        %     varargin
			if error>cType.INFO || error<cType.WARNING
				text='Unknown Error Code';
			else
				text=sprintf(varargin{:});
			end
			message=cMessageLog(error,class(obj),text);
		end

		function printMessage(obj,error,varargin)
		% Print messages depending of type error
		% Input Argument
		%   error - error code
		%   text - text message
        %     varargin 
			message=obj.createMessage(error,varargin{:});
			obj.status=logical(error);
			disp(message);
		end
	end
end
