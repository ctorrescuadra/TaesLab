classdef cQueue < cTaesLab
%cQueue - Simple FIFO queue based on a dinamic cell array
%   This class implements a simple FIFO queue based on a dinamic cell array.
%   It is used in cParseStream to store the flows while parsing a stream text,
%   and in cMessageLogger to store the messages.
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
        %   Syntax:
        %     obj = cQueue()
        %   Output Arguments:
        %     obj - cQueue object
        %
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
        %   Input Arguments:
        %     element - Element to add at the end of the queue
        %              
            obj.buffer{end+1} = element;
        end
        
        function clear(obj)
        %clear - Clear the queue
        %   Syntax: 
        %     obj.clear()
        %
            obj.buffer = cType.EMPTY_CELL;
        end

        function addQueue(obj, queue)
        %addQueue - Add another queue at the end of this queue
        %   Syntax:
        %     obj.addQueue(queue)
        %   Input Arguments:
        %     queue - cQueue object to add at the end of this queue
        %
            if ~isempty(queue.buffer)
                obj.buffer = [obj.buffer, queue.buffer];
            end
        end
              
        function res=getContent(obj,idx)
        %getContent - get the content of the queue
        %   Syntax:
        %     res=obj.getContent(idx)
        %   Input Arguments:
        %     idx - Index of the cell array to obtain (optional)
        %   Output Arguments:
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
        %
            arrayfun(@(i) disp(obj.buffer{i}), 1:obj.Count);
        end
        
        function res=size(obj)
        %size - Size of the queue. Overload size function
            res=size(obj.buffer);
        end
    
        function res=length(obj)
        %length - Leght of the queue. Overload length function
            res=lenght(obj.buffer);
        end
    
        function res=numel(obj)
        %numel - Number of elements of the queue. Overload numel function
            res=numel(obj.buffer);
        end
        
    end
end