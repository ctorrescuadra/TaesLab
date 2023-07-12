classdef cStatus < handle
% cStatus Base class used by ExIOLab classes.
%	It include methods to validate the status of the object,
% 	Methods:
%   	obj=cStatus(init_status)
%   	test=obj.isValid()
%   	test=obj.isError()
%   	test=obj.isWarning()
%   	obj.printMessage(error,text)
%   	obj.printError(text)
%   	obj.printWarning(text)
%   	obj.printInfo(text)
% See also cType
%
	properties(GetAccess=public,SetAccess=protected)
		status	% Status of the object
	end
	
	methods
		function obj=cStatus(val)
		% Class Constructor. 
        % Initialize class to manage errors, logger and objectId
            if nargin<1
    	        obj.status=cType.ERROR;
            else
                obj.status=val;
            end
		end
				
		function test=isValid(obj)
		% Test is class status is Valid
			test=(obj.status>cType.ERROR);
        end

		function test=isWarning(obj)
		% Test is class status is Warning
			test=(obj.status==cType.WARNING);
        end
        
		function test=isError(obj)
		% Test is class status is Error
			test=(obj.status==cType.ERROR);
		end
		
		function printError(obj,varargin)
		% Print error message
		%  Input:
		%   text - text message		
			printMessage(obj,cType.ERROR,varargin{:});
		end
		
		function printWarning(obj,varargin)
		% Print warning message
		%  Input:
		%   text - text message		
			printMessage(obj,cType.WARNING,varargin{:});
		end
		
		function printInfo(obj,varargin)
		% Print info message
		%  Input:
		%   text - text message			
			printMessage(obj,cType.VALID,varargin{:});
        end
    end
	
	methods(Access=protected)
		function message=createMessage(obj,error,varargin)
		% Get the text message depending of error code
		% Input:
		%  error - Error code 
		%  text - message text
			if error>cType.INFO || error<cType.WARNING
				text='Unknown Error Code';
			else
				text=sprintf(varargin{:});
			end
			message=cMessageLog(error,class(obj),text);
		end

		function printMessage(obj,error,varargin)
		% Print messages depending of type error
		%  Input:
		%   error - error code
		%   text - text message
			message=obj.createMessage(error,varargin{:});
			obj.status=error;
			disp(message);
		end
	end
end
