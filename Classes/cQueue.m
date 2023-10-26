classdef cQueue < cTaesLab
% cQueue Creates a FIFO queue data structure. It uses a cell array to store the data
% 	Methods:
%   	obj = cQueue(initial_capacity)
%   	obj.add(data) 
%   	obj.addQueue(q)
%   	obj.clear() 
%   	obj.init() 
%   	test=obj.hasNext() 
%   	res=obj.next() 
% 
	properties (GetAccess=public,SetAccess=private)
		Count		% Number of elementes of the queue
		Content     % Cell array containing the queue data
	end
	properties (Access = private)
		capacity   % storage size
		buffer     % storage
		iterator   % traverse queue iterator
	end

	methods
		function obj = cQueue(arg)
		% cQueue - Construct an instance of this class
		%  Input:
		%   capacity - [optional] buffer size
			if (nargin == 1) && isscalar(arg) && isnumeric(arg) && (arg > 1)
				obj.capacity = arg;
			else
				obj.capacity = cType.CAPACITY;
			end
			obj.buffer = cell(obj.capacity, 1);
			obj.Count=0;
			obj.iterator=1;
		end
	
		function res = get.Content(obj)
			if obj.Count<1
				res={};
			else
				res = obj.buffer(1:obj.Count);
			end
		end

		function add(obj,data)
		% add - Add an element to the list
		%  Input:
		%   data - element to add
			if obj.Count >= obj.capacity
				obj.buffer(obj.capacity+1:2*obj.capacity) = cell(obj.capacity, 1);
				obj.capacity = 2*obj.capacity;
			end
			obj.Count = obj.Count + 1;
			obj.buffer{obj.Count} = data;
		end
	
		function addQueue(obj,q)
		% addQueue - Append a Queue to the actual
		%  Input:
		%	q - cQueue to append
			newsize=obj.Count+q.Count;
            if obj.capacity < newsize % Allocate more capacity
				newcapacity=obj.capacity+q.capacity;
				obj.buffer(obj.capacity+1:newcapacity)=cell(q.capacity, 1);
				obj.capacity=newcapacity;
            end
			obj.buffer(obj.Count+1:newsize)=q.buffer(1:q.Count);
			obj.Count=newsize;
		end

		function clear(obj)
		% clear queue
			obj.Count = 0;
			obj.iterator=1;
		end

		function init(obj)
		% init the queue iterator
			obj.iterator=1;
		end
	
		function test = hasNext(obj)
		% indicate if trasverse queue is finish
			test= (obj.iterator<=obj.Count);
		end
	
		function res = next(obj)
		% return next element on the queue
			res= obj.buffer{obj.iterator};
			obj.iterator=obj.iterator+1;
		end

		function res=length(obj)
		% get queue length. Overload length function
			res=obj.Count;
		end
	end
end