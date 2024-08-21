classdef cStatusLogger < cStatus
% cStatusLogger - message logger class used by TaesLab
%	
% 	Methods:
%   	obj=cStatusLogger(init_state)
%   	obj.MessageLog(error,text)
%   	obj.printLogger()
%		obj.printLoggerType(type)
%   	[res,info]=obj.tableLogger() 
%   	obj.addLogger(newlogger)
%   	obj.clearLogger()
% See also cQueue, cType
%
	properties(Access=protected)
		logger      % cQueue containinig object messages
	end
	
	methods
		function obj=cStatusLogger(varargin)
		% Class Constructor. 
        % Initialize class to manage errors, logger and objectId
		%	Input:
		%		val - Initial state: cType.VALID or cType.ERROR
			obj=obj@cStatus(varargin{:});
			obj.logger=cQueue();
		end
		
		function messageLog(obj,error,varargin)
		% Add a message to the logger
		%  Input:
		%   error - error code
		%   text - message text
			obj.status=logical(error);
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
		
    end
end
