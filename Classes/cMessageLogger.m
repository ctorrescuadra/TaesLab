classdef cMessageLogger < cTaesLab
% cStatusLogger - Create and manage a messages logger for cTaesLab objects
%	
% cMessageLogger Methods:
%   cMessageLogger - create a messages logger
%   printError - show a error message in the console
%   printWarning - show a warning message in the console
%   printInfo - show a print message in the console
%   messageLog - add a message to the the logger queue
%   printLogger - show the messages logger in console
%   printLoggerType - show a type of messages in the console 
%   tableLogger - create a table with the logger messages
%   addLogger - concatenate two loggers
%   clearLogger - clear the messages of the logger
%
% See also cLogger, cType
%
	properties(Access=protected)
		logger      % cLogger containinig object messages
	end
	
	methods
		function obj=cMessageLogger(val)
        % Creates an instance of the class
		% Syntax:
		%   obj = cMessageLogger(status)
		% Input Argument
		%	status - Initial status of the object [optional]
		%     cType.VALID | cType.INVALID
		%
			if nargin==1
				obj.status=val;
			end
			obj.logger=cLogger();
		end

		function printError(obj,varargin)
		% Print error message. 
		% Syntax:
		%	obj.printError(varargin)
		% Input Argument:
		%   text - text message, use fprintf syntax
		%     varargin
		% Example:
		%	obj.printError('File %s not found',filename)
		%
			printMessage(obj,cType.ERROR,varargin{:});
		end
			
		function printWarning(obj,varargin)
		% Print warning message. 
		% Syntax:
		% 	obj.printWarning(varargin)
		% Input Argument:
		%   text - text message, use fprintf syntax
		%     varargin
		% 
			printMessage(obj,cType.WARNING,varargin{:});
		end
			
		function printInfo(obj,varargin)
		% Print info message. Use fprintf syntax
		% Syntax:
		%  obj.printInfo(text)
		% Input Argument:
		%   text - text message, using fprintf syntax
		%     varargin
		%
			printMessage(obj,cType.VALID,varargin{:});
		end
		
		function messageLog(obj,error,varargin)
		% Add a message to the logger
        % Syntax:
		%    obj.messageLog(type,text)	
		%  Input:
		%   type - error type code
		%     cType.ERROR | cType.WARNING | cType.INFO
		%   text - message text, use fprintf format
		%     varargin
		% Example:
		%   obj.messageLog(cType.ERROR,'Invalid file name %s',filename)
		%
			message=obj.createMessage(error,varargin{:});
			obj.logger.add(message);
		end
		
		function printLogger(obj)
		% Print the logger
		% Syntax:
		%   obj.printLogger
		%
			printContent(obj.logger);
		end

		function printLoggerType(obj,type)
		% Print the messages of the logger of the specified type
		% Syntax:
		%   obj.printLoggerType(type)
		%  Input Arguments:
		%	type - type of error message
		%     cType.ERROR | cType.WARNING | cType.INFO
		%
			q=obj.logger;
			for i=1:q.Count
				message=q.getContent(i);
				if message.Error==type
					disp(message)
				end
			end
		end

		function [res,index]=tableLogger(obj)
		% Build a table logger to use in apps
		% Syntax:
		%   [res,index]=obj.tableLogger
		% Output Arguments:
		%  	res: cell array containing the table (Error, Class, Message)
		%  	index: array containing the error index of each message
		%
			q=obj.logger;
			res=cell(q.Count,3);
			index=zeros(1,q.Count);
			for i=1:q.Count
				message=q.getContent(i);
				res{i,1}=cType.getTextErrorCode(message.Error);
				res{i,2}=message.Class;
				res{i,3}=message.Text;
				index(i)=message.Error+2;
			end
		end
	
		function addLogger(obj1,obj2)
		% Concatenate two message loggers
		% Syntax:
		%   addLogger(obj1,obj2)
		% Input Arguments
		%	obj1 - current object
		%   obj2 - cMessagesLogger containing object messages
		%
            obj1.logger.addLogger(obj2.logger);
			obj1.status=isValid(obj1) && isValid(obj2);
        end

		function clearLogger(obj)
		% Clear the message logger
		% Syntax:
		%   obj.clearLogger
		%
			obj.logger.clear;
		end
    end

	methods(Access=private)
		function message=createMessage(obj,error,varargin)
		% Create the text message depending of error code
			if error>cType.INFO || error<cType.WARNING
				text='Unknown Error Code';
			else
				text=sprintf(varargin{:});
			end
			message=cMessage(error,class(obj),text);
			obj.status=logical(error);
		end

		function printMessage(obj,error,varargin)
		% Print messages depending of type error and update state
			msg=obj.createMessage(error,varargin{:});
			disp(msg);
		end
	end
end