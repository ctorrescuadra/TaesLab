classdef cMessageLogger < cTaesLab
%cMessageLogger - Create and manage a messages logger for cTaesLab objects.
%   The logger register messages created during the execution of TaesLab
%   functions. The messages can be printed in the console.
%	
%   cMessageLogger methods:
%     cMessageLogger  - Create a messages logger
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
	
	methods(Access=public)
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
end