classdef cMessageLogger < cTaesLab
%cMessageLogger - Create and manage a messages logger for cTaesLab objects.
%   The logger register messages created during the execution of TaesLab
%   functions. The messages can be printed in the console.
%	
%   cMessageLogger methods:
%     cMessageLogger  - Create a messages logger
%     printError      - Show a error message in the console
%     printWarning    - Show a warning message in the console
%     printInfo       - Show a print message in the console
%     messageLog      - Add a message to the the logger queue
%     printLogger     - Show the messages logger in console
%     printLoggerType - Show a type of messages in the console 
%     tableLogger     - Create a table with the logger messages
%     addLogger       - Concatenate two loggers
%     clearLogger     - clear the messages of the logger
%
%   See also cQueue, cType, cMessages
%
	properties(Access=protected)
		logger      % cQueue containinig object messages
	end
	
	methods
		function obj=cMessageLogger(val)
        %cMessageLogger - Creates an instance of the class
		%   Syntax:
		%     obj = cMessageLogger(status)
		%   Input Arguments:
		%	  status - Initial status of the object [optional]
		%       cType.VALID | cType.INVALID
		%       Default value is cType.VALID
		%   Output Arguments:
		%     obj - cMessageLogger object
		%
			if nargin==1
				obj.status=val;
			end
			obj.logger=cQueue();
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
		
		function messageLog(obj,error,varargin)
		%messageLog - Add a message to the logger
        %   Syntax:
		%      obj.messageLog(type,text)	
		%   Input:
		%     error - error type code
		%       cType.ERROR | cType.WARNING | cType.INFO
		%     text - message text, use fprintf format
		%       varargin
		% Example:
		%   obj.messageLog(cType.ERROR,'Invalid file name %s',filename)
		%
			message=obj.createMessage(error,varargin{:});
            obj.logger.add(message);
			if cType.DEBUG_MODE && (error==cType.ERROR)
				disp(message,true);
			end
		end
		
		function printLogger(obj)
		%printLogger - Print the logger
		%   Syntax:
		%     obj.printLogger
		%
			printContent(obj.logger);
		end

		function printLoggerType(obj,type)
		%printLoggerType - Print the messages of the logger of the specified type
		%   Syntax:
		%     obj.printLoggerType(type)
		%   Input Arguments:
		%	  type - type of error message
		%       cType.ERROR | cType.WARNING | cType.INFO
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
		%tableLogger - Build a table logger to use in apps
		% 	Syntax:
		%     [res,index]=obj.tableLogger
		%   Output Arguments:
		%  	  res: cell array containing the table (Error, Class, Message)
		%  	  index: array containing the error index of each message
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
		%addLogger - Concatenate two message loggers
		%   Syntax:
		%     addLogger(obj1,obj2)
		%   Input Arguments:
		%	  obj1 - current object
		%     obj2 - cMessageLogger containing object messages
		%
            obj1.logger.addQueue(obj2.logger);
			obj1.status=isValid(obj1) && isValid(obj2);
        end

		function clearLogger(obj)
		%clearLogger - Clear the message logger
		%   Syntax:
		%     obj.clearLogger
		%
			obj.logger.clear;
		end
    end

	methods(Access=private)
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
		%	   message=obj.createMessage(cType.ERROR,'Invalid file name %s',filename)
		%
			if error>cType.INFO || error<cType.WARNING
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
		%     obj.printMessage(cType.ERROR,'Invalid file name %s',filename)
		%
			msg=obj.createMessage(error,varargin{:});
            debug=cType.DEBUG_MODE && (error==cType.ERROR);
			disp(msg,debug);
		end
	end
end