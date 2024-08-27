classdef cStack < cTaesLab
% cStack - Define a LIFO stack data structure based on cell array
% 
% cStack Methods:
%   cStack  - Initialize the stack
%   clear   - Clear the stack
%   isempty - Check is the stack is empty
%   push    - add an element to the stack
%   pop     - Remove an element form the stack
%   top     - Get the top of the stack
%   
% See also cLogger
    properties (GetAccess=protected,SetAccess=private)
		Count   	% Number of elementes of the queue
		Content     % Cell array containing the queue data
	end
    properties (Access = private)
        buffer;      % storage
        capacity;    % Maximun capacity of the stack
    end
    
    methods
        function obj = cStack(N)
        % Create an instance of the class
        % Syntax:
        %   obj = cStack(N)
        % Input Arguments:
        %   N - initial capacity
            if (nargin == 1) && isscalar(N) && isnumeric(N) && (N > 1)
			    obj.capacity = N;
            else
                obj.capacity = cType.CAPACITY;
            end
			obj.buffer = cell(obj.capacity,1);
            obj.Count=0;
        end

        function res = get.Content(obj)
        % Get the content of the stack as cell array
            if isValid(obj)
                res={};
            else
                res = obj.buffer(obj.Count:-1:1);
            end
        end
        
        function clear(obj)
        % Clear stack
            obj.Count = 0;
        end
               
        function b = isempty(obj)
        % Check if the stack is empty            
            b = ~logical(obj.Count);
        end

        function push(obj, val)
        % push - add a new element into the stack
            if obj.Count >= obj.capacity
                obj.buffer(obj.capacity+1:2*obj.capacity) = cell(obj.capacity, 1);
                obj.capacity = 2*obj.capacity;
            end
            obj.Count = obj.Count + 1;
            obj.buffer{obj.Count} = val;
        end
        
        function res = top(obj)
        % top - get the top of the stack
            if obj.Count == 0
                res = [];
            else
                res = obj.buffer{obj.Count};
            end        
        end
               
        function res = pop(obj)
        % pop - get the top of the stack and remove it
            if obj.Count == 0
                res = [];
            else
                res = obj.buffer{obj.Count};
                obj.Count = obj.Count - 1;
            end
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
