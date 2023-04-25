classdef cStatusLogger < handle
% cStatusLogger Base class used by ExIOLab classes.
%	It include methods to validate the status of the object,
%   object comparison (eq, neq) and messages logger.
% 	Methods:
%   	obj=cStatusLogger()
%   	test=obj.isValid()
%   	test=obj.isError()
%   	test=obj.isWarning()
%   	obj.MessageLog(error,text)
%   	obj.printLogger()
%		obj.printLoggerType(type)
%   	[res,info]=obj.tableLogger() 
%   	obj.addLogger(newlogger)
%   	obj.clearLogger()
%   	obj.printMessage(error,text)
%   	obj.printError(text)
%   	obj.printWarning(text)
%   	obj.printInfo(text)
% See also cQueue, cType
%
	properties(Access=protected)
		logger      % cQueue containinig object messages
		objectId    % class object identifier
	end

	properties(GetAccess=public,SetAccess=protected)
		status
	end
	
	methods
		function obj=cStatusLogger(val)
		% Class Constructor. 
        % Initialize class to manage errors, logger and objectId
            if nargin<1
    	        obj.status=cType.ERROR;
            else
                obj.status=val;
            end
			obj.logger=cQueue();
			obj.objectId=randi(intmax,"int32");
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
		
		function messageLog(obj,error,varargin)
		% Add a message to the logger
		%  Input:
		%   error - error code
		%   text - message text
			obj.status=error;
			message=obj.createMessage(error,varargin{:});
			obj.logger.add(message);
		end
		
		function printLogger(obj)
		% Print the logger
			q=obj.logger;
			q.init;
			while q.hasNext
				disp(q.next);
			end
		end

		function printLoggerType(obj,type)
		% Print the messages of the logger of the specified type
		%  Input:
		%	type - type of message
			q=obj.logger;
			for i=1:q.Count
				message=q.Content{i};
				if message.Error==type
					disp(message)
				end
			end
		end

		function [res,index]=tableLogger(obj)
		% Build table logger to use in apps
		%  Output:
		%  	res: cell array containing the table (Error, Class, Message)
		%  	index: array containing the error index of each message
			q=obj.logger;
			res=cell(q.Count,3);
			index=zeros(1,q.Count);
			for i=1:q.Count
				message=q.Content{i};
				res{i,1}=cType.getTextErrorCode(message.Error);
				res{i,2}=message.Class;
				res{i,3}=message.Text;
				index(i)=message.Error+2;
			end
		end
	
		function addLogger(obj,newobj)
		% Add a list of messages to the actual logger
		%  Input:
		%   newloger - cLogger list containing object messages
            obj.logger.addQueue(newobj.logger);
			obj.status=isValid(obj) && isValid(newobj);
        end

		function clearLogger(obj)
		% Clear the object logger
			obj.logger.clear;
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
	    
        function res=eq(obj1,obj2)
        % Check if two class object are equal. Overload eq operator
            res=(obj1.objectId==obj2.objectId);
        end
        
        function res=ne(obj1,obj2)
        % Check if two class objects are different. Overload ne operator
            res=(obj1.objectId~=obj2.objectId);
		end
    end
	
	methods(Access=private)
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
