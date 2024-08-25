classdef cLogger < handle
% cLogger - simple FIFO queue based on a dinamic cell array
% 
% cLogger Properties
%   Count - Number of elements of the queue
%
% cLogger Methods
%   cLogger - Initialize the logger
%   add     - Add a new element at the end of the queue
%   clear   - Clear (initialize) the logger
%   addLogger - Add another queue at the end of this queue
%   initIterator - Initialize the queue iterator
%   hasNext - Indicate if trasverse queue is finish
%   next - Get Next element of the queue
%   getContent - Get the content of the queue
%
    properties (GetAccess = public, SetAccess=private)
        Count  % logger size
    end

    properties(Access=private)
        pos    % iterator position
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
            obj.buffer = {};
			obj.pos = 1;
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
        
        % Obtener el tamaño de la cola
        function n = size(obj)
            n = size(obj.buffer); % Devolver el número de elementos en la cola
        end
        
    end
end