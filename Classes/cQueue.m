classdef cQueue < cTaesLab
%cQueue - simple FIFO queue based on a dinamic cell array
%   Internal use only
%
%   cQueue properties:
%     Count - Number of elements of the queue
%
%   cQueue methods:
%     cQueue - Initialize the logger
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
        function obj = cQueue()
        %cQueue - Create a cQueue object. Initialize as a empty cell array 
            obj.clear;
        end
        
        function res=get.Count(obj)
        % Count the logger size
            res=numel(obj.buffer);
        end

        function add(obj, element)
        %add - Add an element at the end of the queue
        %   Syntax:
        %     obj.add(element)
        %   Input Argument:
        %     element - element to add to the queue 
            obj.buffer{end+1} = element;
        end
        
        function obj = clear(obj)
        %clear - Clear the queue
        %   Syntax: 
        %     obj.clear
        %   Output Argument
        %     obj - Current obj
            obj.buffer = cType.EMPTY_CELL;
        end

        function obj = addQueue(obj, queue)
        %addQueue - Add another queue at the end of this queue
        %   Syntax:
        %     obj.addQueue(queue)
        %   Output Argument
        %     obj - Current obj   
            if ~isempty(queue.buffer)
                obj.buffer = [obj.buffer, queue.buffer];
            end
        end
              
        function res=getContent(obj,idx)
        %getContent - get the content of the queue
        %   Syntax:
        %     res=obj.getContent(idx)
        %   Input Argument:
        %     idx - Index of the cell array to obtain (optional)
        %   Output Argument:
        %     res - If index if provided the value of the specific position of the queue
        %           if not provided return a cell array with all values of the queue
            if nargin==1
                res=obj.buffer;
            else
                res=obj.buffer{idx};
            end
        end

        function printContent(obj)
        %printContent - Print the content of the buffer
        %   Syntax:
        %     obj.printContent
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