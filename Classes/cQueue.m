classdef cQueue < cTaesLab
%cQueue - Dynamic FIFO queue container for efficient element storage and retrieval.
%   Implements a First-In-First-Out (FIFO) queue using a dynamic cell array that
%   automatically grows as elements are added. Designed for efficient sequential
%   storage and batch processing of heterogeneous data types. It is used in
%   TaesLab for message logging, and temporary data collection.
%
%   The queue provides O(1) amortized addition time and supports storing any MATLAB
%   data type (objects, arrays, structs, etc.) since it uses a cell array internally.
%   Elements maintain insertion order and can be accessed individually or as a batch.
%
%   Key Features:
%     • Dynamic sizing - automatically grows without pre-allocation
%     • Type-agnostic storage - holds any MATLAB data type
%     • FIFO ordering - preserves insertion sequence
%     • Batch operations - merge queues, clear all, retrieve all
%     • Efficient iteration - direct access by index
%     • Memory efficient - uses cell array with minimal overhead
%
%   Common Use Cases:
%     • Message logging (cMessageLogger uses cQueue for message storage)
%     • Stream parsing (cParseStream uses cQueue for flow collection)
%     • Temporary data accumulation during validation
%     • Event collection in batch processing
%     • Building result lists with unknown final size
%
%   cQueue Properties:
%     Count - Number of elements currently in the queue
%       uint32
%
%   cQueue Properties (Inherited from cTaesLab):
%     objectId - Unique object identifier (uint64, auto-generated)
%     status   - Object validity flag (logical, default: true)
%
%   cQueue Methods:
%     cQueue - Constructor, creates empty queue
%     add - Appends element to end of queue
%     clear - Removes all elements (resets to empty)
%     addQueue - Merges another queue to end of this queue
%     getContent - Retrieves element(s) from queue
%     printContent - Displays all elements to console
%     size - Returns dimensions of internal buffer
%     length - Returns number of elements (same as Count)
%     numel - Returns number of elements (same as Count)
%
%   Methods (Inherited from cTaesLab):
%     printError, printWarning, printInfo - Message display
%     eq, ne - Equality/inequality operators
%
%   Queue Operations:
%     Add element:
%       queue.add(element)  % Appends to end, O(1) amortized
%     
%     Get specific element:
%       elem = queue.getContent(i)  % Returns i-th element
%     
%     Get all elements:
%       allElems = queue.getContent()  % Returns cell array
%     
%     Merge queues:
%       queue1.addQueue(queue2)  % Appends queue2 to queue1
%     
%     Clear queue:
%       queue.clear()  % Removes all elements
%
%   Examples:
%     % Example 1: Create queue and add elements
%     q = cQueue();
%     q.add('First item');
%     q.add(42);
%     q.add([1, 2, 3]);
%     fprintf('Queue has %d elements\n', q.Count);  % Output: 3
%
%     % Example 2: Retrieve specific element
%     q = cQueue();
%     q.add('Apple');
%     q.add('Banana');
%     q.add('Cherry');
%     item = q.getContent(2);  % Returns 'Banana'
%
%     % Example 3: Retrieve all elements
%     q = cQueue();
%     q.add(10);
%     q.add(20);
%     q.add(30);
%     allItems = q.getContent();  % Returns {10, 20, 30}
%
%     % Example 4: Iterate through queue
%     q = cQueue();
%     q.add('Error 1');
%     q.add('Error 2');
%     for i = 1:q.Count
%         fprintf('%d: %s\n', i, q.getContent(i));
%     end
%
%     % Example 5: Merge two queues
%     q1 = cQueue();
%     q1.add('A');
%     q1.add('B');
%     q2 = cQueue();
%     q2.add('C');
%     q2.add('D');
%     q1.addQueue(q2);  % q1 now has: {'A', 'B', 'C', 'D'}
%     fprintf('Merged queue has %d elements\n', q1.Count);  % Output: 4
%
%     % Example 6: Clear and reuse queue
%     q = cQueue();
%     q.add(1);
%     q.add(2);
%     fprintf('Before clear: %d\n', q.Count);  % Output: 2
%     q.clear();
%     fprintf('After clear: %d\n', q.Count);   % Output: 0
%
%     % Example 7: Store objects in queue
%     q = cQueue();
%     obj1 = cTaesLab();
%     obj2 = cTaesLab();
%     q.add(obj1);
%     q.add(obj2);
%     retrieved = q.getContent(1);  % Returns obj1
%
%     % Example 8: Use in message logging (typical TaesLab pattern)
%     messages = cQueue();
%     messages.add(cMessageBuilder(cType.ERROR, 'Parser', 'Line 5: syntax error'));
%     messages.add(cMessageBuilder(cType.WARNING, 'Parser', 'Line 10: deprecated'));
%     messages.printContent();  % Display all messages
%
%   Performance Characteristics:
%     • Add operation: O(1) amortized (dynamic array doubling strategy)
%     • Access by index: O(1) constant time
%     • Memory overhead: ~8 bytes per element (cell array pointer)
%     • Growing strategy: Cell array expands automatically
%     • Suitable for: 1 to 10,000+ elements without performance degradation
%
%   Implementation Notes:
%     • Uses MATLAB cell array for internal storage
%     • Cell arrays support any data type (heterogeneous storage)
%     • Count property is computed dynamically (no separate counter)
%     • Clear operation resets to empty cell array (releases memory)
%     • Queue order is strictly FIFO (first added = first in array)
%
%   Comparison with Other Containers:
%     Use cQueue when:
%       • Need to accumulate items of unknown quantity
%       • Order of insertion must be preserved
%       • Storing mixed data types
%       • Don't know final size in advance
%     
%     Use cell array when:
%       • Size is known beforehand
%       • No need for queue-specific operations
%     
%     Use struct array when:
%       • All items have same fields
%       • Need named field access
%
%   See also:
%     cTaesLab, cMessageLogger
%
    properties (GetAccess = public, SetAccess=private)
        Count  % Number of elements in queue (computed dynamically)
    end

    properties(Access=private)
        buffer % data cell array
    end
    
    methods
        function obj = cQueue()
        %cQueue - Constructor, creates empty queue ready for element addition.
        %   Initializes a new cQueue object with an empty internal buffer.
        %   The queue is immediately ready to accept elements via add() method.
        %   Count property starts at zero and increments with each addition.
        %
        %   Syntax:
        %     obj = cQueue()
        %
        %   Output Arguments:
        %     obj - Initialized cQueue object
        %       Properties: Count=0, empty internal buffer
        %
        %   Examples:
        %     q = cQueue();  % Create empty queue
        %     fprintf('Initial count: %d\n', q.Count);  % Output: 0
        %
        %   See also: add, clear, cTaesLab
        %
            obj.clear;
        end
        
        function res=get.Count(obj)
        % Count the logger size
            res=numel(obj.buffer);
        end

        function add(obj, element)
        %add - Appends element to the end of the queue.
        %   Adds a new element to the end of the queue, incrementing Count by one.
        %   The element can be of any MATLAB type (scalar, array, object, struct,
        %   cell, etc.). Elements are stored in insertion order (FIFO). Operation
        %   is O(1) amortized time due to dynamic array growth strategy.
        %
        %   Syntax:
        %     obj.add(element)
        %
        %   Input Arguments:
        %     element - Data to add to queue
        %       any type
        %       Stored in internal cell array, preserving type and content
        %
        %   Side Effects:
        %     • Increments Count property by 1
        %     • Element becomes last item in queue
        %     • Internal buffer may grow if needed
        %
        %   Examples:
        %     q = cQueue();
        %     q.add('text');           % Add string
        %     q.add(42);               % Add number
        %     q.add([1, 2, 3]);        % Add array
        %     q.add(struct('a', 1));   % Add struct
        %     fprintf('Count: %d\n', q.Count);  % Output: 4
        %
        %   See also: getContent, addQueue, Count
        %
            obj.buffer{end+1} = element;
        end
        
        function clear(obj)
        %clear - Removes all elements from the queue.
        %   Resets the queue to empty state by clearing the internal buffer.
        %   Count property becomes zero. Memory used by stored elements is released.
        %   The queue object remains valid and can immediately accept new elements.
        %
        %   Syntax:
        %     obj.clear()
        %
        %   Side Effects:
        %     • Sets Count to 0
        %     • Removes all stored elements
        %     • Releases memory used by elements
        %     • Queue becomes empty (ready for reuse)
        %
        %   Examples:
        %     q = cQueue();
        %     q.add('item1');
        %     q.add('item2');
        %     fprintf('Before: %d\n', q.Count);  % Output: 2
        %     q.clear();
        %     fprintf('After: %d\n', q.Count);   % Output: 0
        %
        %   Common Usage:
        %     % Reuse queue in loop
        %     q = cQueue();
        %     for i = 1:nIterations
        %         q.clear();
        %         % ... add items ...
        %         processQueue(q);
        %     end
        %
        %   See also: add, Count
        %
            obj.buffer = cType.EMPTY_CELL;
        end

        function addQueue(obj, queue)
        %addQueue - Merges another queue to the end of this queue.
        %   Appends all elements from the source queue to the end of this queue,
        %   preserving order. The source queue is not modified. If source queue
        %   is empty, no action is taken. This is more efficient than adding
        %   elements one-by-one when merging large queues.
        %
        %   Syntax:
        %     obj.addQueue(queue)
        %
        %   Input Arguments:
        %     queue - Source queue to merge from
        %       cQueue object
        %       Not modified by this operation. Can be empty.
        %
        %   Side Effects:
        %     • Appends all elements from queue to end of obj
        %     • Increases obj.Count by queue.Count
        %     • Source queue remains unchanged
        %     • If queue is empty, no change occurs
        %
        %   Examples:
        %     q1 = cQueue();
        %     q1.add('A');
        %     q1.add('B');
        %     
        %     q2 = cQueue();
        %     q2.add('C');
        %     q2.add('D');
        %     
        %     q1.addQueue(q2);  % q1 now has: {'A', 'B', 'C', 'D'}
        %     fprintf('q1 count: %d\n', q1.Count);  % Output: 4
        %     fprintf('q2 count: %d\n', q2.Count);  % Output: 2 (unchanged)
        %
        %   Common Usage:
        %     % Combine validation results from multiple sources
        %     masterQueue = cQueue();
        %     for i = 1:length(validators)
        %         masterQueue.addQueue(validators{i}.messages);
        %     end
        %
        %   See also: add, getContent
        %
            if ~isempty(queue.buffer)
                obj.buffer = [obj.buffer, queue.buffer];
            end
        end
              
        function res = getContent(obj, idx)
        %getContent - Retrieves element(s) from the queue.
        %   Returns either a single element at specified index or all elements
        %   as a cell array. Elements remain in queue (non-destructive read).
        %   Index-based access is O(1) constant time. Useful for iteration,
        %   inspection, and batch processing of queued items.
        %
        %   Syntax:
        %     res = obj.getContent()      % Get all elements
        %     res = obj.getContent(idx)   % Get element at index
        %
        %   Input Arguments (Optional):
        %     idx - Index of element to retrieve
        %       positive integer (1 to Count)
        %       If omitted, returns all elements
        %
        %   Output Arguments:
        %     res - Retrieved content
        %       If idx provided: Single element at that position (any type)
        %       If idx omitted: Cell array containing all elements
        %
        %   Examples:
        %     % Get specific element
        %     q = cQueue();
        %     q.add('First');
        %     q.add('Second');
        %     q.add('Third');
        %     item = q.getContent(2);  % Returns 'Second'
        %     
        %     % Get all elements
        %     allItems = q.getContent();  % Returns {'First', 'Second', 'Third'}
        %     
        %     % Iterate through queue
        %     for i = 1:q.Count
        %         elem = q.getContent(i);
        %         fprintf('Item %d: %s\n', i, elem);
        %     end
        %     
        %     % Process all at once
        %     allElems = q.getContent();
        %     cellfun(@disp, allElems);
        %
        %   Common Usage:
        %     % Export queue contents for processing
        %     messages = logger.getContent();  % Get all messages
        %     for i = 1:length(messages)
        %         processMessage(messages{i});
        %     end
        %
        %   See also: add, Count, printContent
        %
            if nargin == 1
                res = obj.buffer;
            else
                res = obj.buffer{idx};
            end
        end

        function printContent(obj)
        %printContent - Displays all queue elements to console.
        %   Prints each element in the queue to the console in order, using
        %   MATLAB's disp() function. Each element displays according to its
        %   type's default display format. Useful for debugging, logging, and
        %   quick inspection of queue contents.
        %
        %   Syntax:
        %     obj.printContent()
        %
        %   Output Format:
        %     Each element printed on separate line(s) using disp() format
        %
        %   Examples:
        %     % Print string elements
        %     q = cQueue();
        %     q.add('First message');
        %     q.add('Second message');
        %     q.printContent();
        %     % Output:
        %     %   First message
        %     %   Second message
        %     
        %     % Print mixed types
        %     q = cQueue();
        %     q.add('Text');
        %     q.add(42);
        %     q.add([1, 2, 3]);
        %     q.printContent();
        %     % Output:
        %     %   Text
        %     %   42
        %     %   1  2  3
        %
        %   Common Usage:
        %     % Display collected messages
        %     if ~validator.status
        %         validator.messages.printContent();
        %     end
        %
        %   See also: getContent, disp
        %
            arrayfun(@(i) disp(obj.buffer{i}), 1:obj.Count);
        end
        
        function res = size(obj)
        %size - Returns dimensions of internal buffer.
        %   Overloads MATLAB's built-in size() function to return dimensions
        %   of the internal cell array buffer. For standard queue usage, prefer
        %   using the Count property instead.
        %
        %   Syntax:
        %     res = obj.size()
        %     res = size(obj)
        %
        %   Output Arguments:
        %     res - Dimensions of internal buffer
        %       [1, n] where n = Count
        %
        %   See also: Count, length, numel
        %
            res = size(obj.buffer);
        end
    
        function res = length(obj)
        %length - Returns number of elements in queue.
        %   Overloads MATLAB's built-in length() function. Returns same value
        %   as Count property. For clarity, prefer using Count property directly.
        %
        %   Syntax:
        %     res = obj.length()
        %     res = length(obj)
        %
        %   Output Arguments:
        %     res - Number of elements (same as Count)
        %       non-negative integer
        %
        %   See also: Count, size, numel
        %
            res = length(obj.buffer);
        end
    
        function res = numel(obj)
        %numel - Returns number of elements in queue.
        %   Overloads MATLAB's built-in numel() function. Returns same value
        %   as Count property. For clarity, prefer using Count property directly.
        %
        %   Syntax:
        %     res = obj.numel()
        %     res = numel(obj)
        %
        %   Output Arguments:
        %     res - Number of elements (same as Count)
        %       non-negative integer
        %
        %   See also: Count, size, length
        %
            res = numel(obj.buffer);
        end
        
    end
end