classdef cStack < cTaesLab
% cStack define a LIFO stack data structure
%   Methods:
%       s = cStack(initial_capacity)
%       s.clear() 
%       s.isempty()
%       s.push(el)
%       s.pop() 
%   
% See also cQueue
    properties (GetAccess=public,SetAccess=private)
		Count   	% Number of elementes of the queue
		Content     % Cell array containing the queue data
	end
    properties (Access = private)
        buffer;      % storage
        capacity;    % Maximun capacity of the stack
    end
    
    methods
        function obj = cStack(arg)
        % Create an instance of the class
        % Input:
        %   arg - indicates the initial capacity
            if (nargin == 1) && isscalar(arg) && isnumeric(arg) && (arg > 1)
			    obj.capacity = arg;
            else
                obj.capacity = cType.CAPACITY*2;
            end
			obj.buffer = cell(obj.capacity,1);
            obj.Count=0;
        end

        function res = get.Content(obj)
        % content - show the content of the stack as cell array
            if isempty(obj)
                res=[];
            else
                res = obj.buffer(obj.Count:-1:1);
            end
        end
        
        function clear(obj)
        % clear - clear stack
            obj.Count = 0;
        end
               
        function b = isempty(obj)
        % isempty - check if the stack is empty            
            b = ~logical(obj.Count);
        end

        function push(obj, el)
        % push - add a new element into the stack
            if obj.Count >= obj.capacity
                obj.buffer(obj.capacity+1:2*obj.capacity) = cell(obj.capacity, 1);
                obj.capacity = 2*obj.capacity;
            end
            obj.Count = obj.Count + 1;
            obj.buffer{obj.Count} = el;
        end
        
        function el = top(obj)
        % top - get the top of the stack
            if obj.Count == 0
                el = [];
            else
                el = obj.buffer{obj.Count};
            end        
        end
               
        function el = pop(obj)
        % pop - get the top of the stack and remove it
            if obj.Count == 0
                el = [];
            else
                el = obj.buffer{obj.Count};
                obj.Count = obj.Count - 1;
            end
        end

		function res=length(obj)
		% length - get stack length. Overload length function
			res=obj.Count;
		end
    end
end
