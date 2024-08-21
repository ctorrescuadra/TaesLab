classdef cStatus < cTaesLab
    % cStatus - Create a status object
	%   Provide methods to print messages on console
    %
    % cStatus Methods
	%   printError   - Print a error message on the console
    %   printWarning - Print a warning message on the console
    %   printInfo    - Print a info message on the console
    %
	% See also cTaesLab, cStatusLogger
	
	methods
		function obj=cStatus(val)
		% Create an instace of the cStatus object 
		% Initialize cStatus object to manage errors
        % Syntax:
        %   obj = cStatus();
        %   obj = cStatus(value);
		% Input Arguments:
		%   val - Initial status [optional]
        %     false | true (default).
		%
            if nargin<1
    	        obj.status=cType.VALID;
            else
                obj.status=val;
            end
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
		% Print messages depending of type error and update state
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
