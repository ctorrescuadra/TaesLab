classdef cLogger < cTaesLab
%cLogger - simple FIFO queue based on a dinamic cell array
%   Internal use only
%
%   cLogger properties:
%     Count - Number of elements of the queue
%
%   cLogger methods:
%     cLogger - Initialize the logger
%     add     - Add a new element at the end of the queue
%     clear   - Clear (initialize) the logger
%     addLogger - Add another queue at the end of this queue
%     getContent - Get the content of the queue
%     printContent - Print the content of the queue in console
%
    properties (GetAccess = public, SetAccess=private)
        Count  % logger size
    end
    properties(Access=private)
        buffer % data cell array
    end
    
    methods
        function obj = cLogger()
        % Create a cLogger object. Initialize the logger as a empty cell array 
            obj.clear;
        end
        
        function res=get.Count(obj)
        % Count the logger size
            res=numel(obj.buffer);
        end

        function obj = add(obj, element)
        % Add an element at the end of the queue
            obj.buffer{end+1} = element;
        end
        
        function obj = clear(obj)
        % Clear the queue
            obj.buffer = cType.EMPTY_CELL;
        end

        function obj = addLogger(obj, logger)
        % Add another queue at the end of this queue
            if ~isempty(logger.buffer)
                obj.buffer = [obj.buffer, logger.buffer];
            end
        end
              
        function res=getContent(obj,idx)
            if nargin==1
                res=obj.buffer;
            else
                res=obj.buffer{idx};
            end
        end

        function printContent(obj)
        % Print the content of the buffer
            arrayfun(@(i) disp(obj.buffer{i}), 1:obj.Count);
        end
        
        function res=size(obj,dim)
        % overload size function
            tmp=[obj.Count 1];
            if nargin==1
                res=tmp;
            else
                res=tmp(dim);
            end
        end
    
        function res=length(obj)
        % overload length function
            res=size(obj,1);
        end
    
        function res=numel(obj)
        % overload numel function
            res=size(obj,1);
        end
        
    end
end