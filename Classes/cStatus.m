classdef cStatus < cTaesLab
% cStatus define the object status
%	It include methods to validate the status of the object,
% 	Methods:
%   	obj=cStatus(init_status)
%   	test=obj.isValid
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
		% Initialize class to manage errors
		%	Input:
		%		val - Initial state: true or false
            if nargin<1
    	        obj.status=true;
            else
                obj.status=logical(val);
            end
		end
				
		function test=isValid(obj)
		% Test if object is Valid
			test=(obj.status>cType.ERROR);
        end

		function test=isResultId(obj)
		% Test if object is a valid ResultId
			test=(isa(obj,'cResultId') || isa(obj,'cDataModel') || isa(obj,'cThermoeconomicModel'));
			test=test && isValid(obj);
		end

		function test=isDataModel(obj)
		% Test if object is a valid cDataModel
			test=isa(obj,'cDataModel') && isValid(obj);
		end

		function test=isResultSet(obj)
		% Test if object is a valid cResultSet
			test=isa(obj,'cResultSet') && isValid(obj);
		end

		function test=isValidTable(obj)
		% Test if object is a valid cResultSet
			test=isa(obj,'cTable') && isValid(obj);
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
			obj.status=logical(error);
			disp(message);
		end
	end
end
