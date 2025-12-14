classdef cTaesLab < handle
%cTaesLab - Base class for all TaesLab objects providing common infrastructure.
%   Foundation class that all TaesLab classes inherit from, providing
%   functionality for object identification, status management, message logging,
%   and object comparison. This class ensures consistent behavior across the
%   entire toolbox through a unified interface for error handling and object tracking.
%
%   Key Features:
%     - Status flag for tracking object validity (valid/invalid state)
%     - Standardized message printing (errors, warnings, info)
%     - Handle semantics for reference-based object passing
%     - Unique object identification using auto-incrementing IDs
%     - Equality/inequality operators for object comparison
%     • Base infrastructure for logging and debugging
%
%   All TaesLab classes extend this base class to inherit:
%     - Automatic unique ID assignment upon object creation
%     - Status property for validation workflows
%     - Consistent error/warning/info message formatting
%     - Object comparison based on unique identifiers
%
%   cTaesLab Properties:
%     status - Indicates whether object is valid (true) or invalid (false).
%       logical (default: true)
%     objectId - Unique object identifier
%       uint64 (auto-generated)
%
%   cTaesLab Methods:
%     cTaesLab - Constructor, initializes object with unique ID and status
%     printError - Prints error message and sets status to false
%     printWarning - Prints warning message without changing status
%     printInfo - Prints informational message
%     eq - Equality operator (==) compares objects by objectId
%     ne - Inequality operator (~=) compares objects by objectId
%
%   Design Pattern:
%     Handle Class - Objects are passed by reference, not by value
%       - Multiple variables can reference the same object
%       - Changes to object properties affect all references
%       - Use copy() method if value semantics needed (implement in subclass)
%
%   Status Management:
%     The status property provides a simple validity flag:
%       true  - Object is valid and ready to use
%       false - Object is invalid (error occurred)
%     
%     Status is automatically set to false when:
%       • printError() method is called
%       • Error message is logged
%     
%     Check status using:
%       • obj.status property directly
%       • isValid(obj) function (recommended)
%
%   Message Formatting:
%     All messages follow the pattern:
%       [LEVEL]: ClassName. Message text
%     
%     Levels:
%       ERROR   - Critical issues, sets status to false
%       WARNING - Issues that don't prevent operation
%       INFO    - Informational messages about operations
%
%   Examples:
%     % Example 1: Create base object with default status (valid)
%     obj = cTaesLab();
%     fprintf('Object ID: %d, Status: %d\n', obj.ObjectId, obj.status);
%     % Output: Object ID: 12345, Status: 1
%
%     % Example 2: Create object with invalid status
%     obj = cTaesLab(false);
%     if ~obj.status
%         fprintf('Object created as invalid\n');
%     end
%
%     % Example 3: Print error message (sets status to false)
%     obj = cTaesLab();
%     obj.printError('File not found: %s', 'data.json');
%     % Output: ERROR: cTaesLab. File not found: data.json
%     fprintf('Status after error: %d\n', obj.status);
%     % Output: Status after error: 0
%
%     % Example 4: Print warning (status remains true)
%     obj = cTaesLab();
%     obj.printWarning('Using default value: %d', 100);
%     % Output: WARNING: cTaesLab. Using default value: 100
%     fprintf('Status after warning: %d\n', obj.status);
%     % Output: Status after warning: 1
%
%     % Example 5: Print informational message
%     obj = cTaesLab();
%     obj.printInfo('Processing completed successfully');
%     % Output: INFO: cTaesLab. Processing completed successfully
%
%     % Example 6: Compare objects using equality operators
%     obj1 = cTaesLab();
%     obj2 = cTaesLab();
%     obj3 = obj1;  % Reference to same object
%     fprintf('obj1 == obj2: %d\n', obj1 == obj2);  % false (different IDs)
%     fprintf('obj1 == obj3: %d\n', obj1 == obj3);  % true (same object)
%     fprintf('obj1 ~= obj2: %d\n', obj1 ~= obj2);  % true (different IDs)
%
%     % Example 7: Handle semantics demonstration
%     obj1 = cTaesLab();
%     obj2 = obj1;  % Both reference the same object
%     obj2.printError('Test error');
%     fprintf('obj1.status: %d\n', obj1.status);  % 0 (both affected)
%     fprintf('obj2.status: %d\n', obj2.status);  % 0 (both affected)
%
%   Common Usage Patterns:
%     • Inherit from cTaesLab for all custom TaesLab classes
%     • Use printError() for critical failures that invalidate objects
%     • Use printWarning() for non-critical issues or deprecation notices
%     • Use printInfo() for progress updates and confirmations
%     • Always check status or use isValid() before using objects
%     • Use objectId for debugging and object tracking
%
%   Inheritance Guidelines:
%     When creating a new TaesLab class:
%       1. Extend from cTaesLab: classdef cMyClass < cTaesLab
%       2. Call superclass constructor: obj@cTaesLab()
%       3. Use inherited message methods: obj.printError(), etc.
%       4. Let status be managed automatically by message methods
%       5. Consider extending cMessageLogger if message collection needed
%
%   See also:
%     cMessageLogger, cMessageBuilder, cType, cMessages, isValid, isObject, handle
% 

    properties(GetAccess=public, SetAccess=protected)
        status = true  % Object validity flag: true (valid) | false (invalid)
		objectId       % Object unique ID
    end

    methods
        function obj = cTaesLab(val)
        %cTaesLab - Constructor, initializes base object with unique ID and status.
        %   Creates a new cTaesLab object with automatically assigned unique
        %   identifier and optional initial status. The unique ID is generated
        %   from a persistent counter and is never reused. Status defaults to
        %   true (valid) unless explicitly set to false.
        %
        %   Syntax:
        %     obj = cTaesLab()
        %     obj = cTaesLab(status)
        %
        %   Input Arguments (Optional):
        %     status - Initial validity state of the object
        %       logical (default: true)
        %       Use false to create an invalid object from the start.
        %
        %   Output Arguments:
        %     obj - Initialized cTaesLab object
        %
        %   Examples:
        %     obj = cTaesLab();       % Create valid object
        %     obj = cTaesLab(false);  % Create invalid object
        %
        %   See also: isValid
        %
            if nargin == 1 && isscalar(val) && islogical(val)
                obj.status = val;
            end
            obj.objectId = cTaesLab.sequence;
        end

        function printError(obj, varargin)
        %printError - Prints error message and sets object status to invalid.
        %   Displays formatted error message and sets status to false.
        %
        %   Syntax:
        %     obj.printError(format, arg1, arg2, ...)
        %
        %   Input Arguments:
        %     format - Error message format string (printf-style)
        %     arg1, arg2, ... - Values to substitute
        %
        %   Side Effects:
        %     Sets obj.status to false
        %
        %   Examples:
        %     obj.printError('File not found: %s', filename);
        %     obj.printError(cMessages.FileNotFound, filename);
        %
        %   See also: printWarning, printInfo, cMessages
        %
            printMessage(obj, cType.ERROR, varargin{:});
        end
	
        function printWarning(obj, varargin)
        %printWarning - Prints warning message without changing object status.
        %   Displays formatted warning message. Does NOT set status to false.
        %
        %   Syntax:
        %     obj.printWarning(format, arg1, arg2, ...)
        %
        %   Input Arguments:
        %     format - Warning message format string (printf-style)
        %     arg1, arg2, ... - Values to substitute
        %
        %   Examples:
        %     obj.printWarning('Using default value: %d', defaultVal);
        %
        %   See also: printError, printInfo
        %
            printMessage(obj, cType.WARNING, varargin{:});
        end
	
        function printInfo(obj, varargin)
        %printInfo - Prints informational message without changing status.
        %   Displays formatted informational message.
        %
        %   Syntax:
        %     obj.printInfo(format, arg1, arg2, ...)
        %
        %   Input Arguments:
        %     format - Info message format string (printf-style)
        %     arg1, arg2, ... - Values to substitute
        %
        %   Examples:
        %     obj.printInfo('Operation completed successfully');
        %     obj.printInfo('Loaded %d records', count);
        %
        %   See also: printError, printWarning
        %
            printMessage(obj, cType.VALID, varargin{:});
        end

        function res = eq(obj1, obj2)
        %eq - Equality operator overload, compares objects by unique ID.
        %   Implements == operator. Objects are equal if same objectId.
        %
        %   Syntax:
        %     res = (obj1 == obj2)
        %
        %   Input Arguments:
        %     obj1, obj2 - cTaesLab objects
        %
        %   Output Arguments:
        %     res - true if same object, false otherwise
        %
        %   Examples:
        %     obj1 = cTaesLab();
        %     obj2 = obj1;
        %     obj1 == obj2  % true (same object)
        %
            res = (obj1.objectId == obj2.objectId);
        end

        function res = ne(obj1, obj2)
        %ne - Inequality operator overload, compares objects by unique ID.
        %   Implements ~= operator. Objects are different if different objectIds.
        %
        %   Syntax:
        %     res = (obj1 ~= obj2)
        %
        %   Input Arguments:
        %     obj1, obj2 - cTaesLab objects
        %
        %   Output Arguments:
        %     res - true if different objects, false if same
        %
        %   Examples:
        %     obj1 = cTaesLab();
        %     obj2 = cTaesLab();
        %     obj1 ~= obj2  % true (different objects)
        %
            res = (obj1.objectId ~= obj2.objectId);
        end
    end

    methods(Access=protected)
        function message = createMessage(obj, error, varargin)
        %createMessage - Creates formatted message with error level and class context.
        %   Internal method that constructs a cMessageBuilder object.
        %   Sets status to false if error level is ERROR.
        %
        %   Syntax:
        %     message = obj.createMessage(error, format, arg1, ...)
        %
        %   Input Arguments:
        %     error - Message severity level
        %       cType.ERROR | cType.WARNING | cType.VALID (INFO)
        %     format - Message format string (printf-style)
        %     arg1, ... - Values to substitute
        %
        %   Output Arguments:
        %     message - Formatted message object (cMessageBuilder)
        %
        %   See also: printMessage, cMessageBuilder, cType
        %
            if error > cType.INFO || error < cType.WARNING || isempty(varargin)
                text = 'Unknown Error Code';
            else
                text = sprintf(varargin{:});
            end
            if error == cType.ERROR
                obj.status = logical(error);
            end
            message = cMessageBuilder(error, class(obj), text);
        end

        function printMessage(obj, error, varargin)
        %printMessage - Creates and displays message, updates status if error.
        %   Internal method that creates formatted message and displays it.
        %   Status is set to false if message level is ERROR.
        %
        %   Syntax:
        %     obj.printMessage(error, format, arg1, ...)
        %
        %   Input Arguments:
        %     error - Message severity level
        %       cType.ERROR | cType.WARNING | cType.VALID (INFO)
        %     format - Message format string (printf-style)
        %     arg1, ... - Values to substitute
        %
        %   Example:
        %     obj.printMessage(cType.ERROR, 'File not found: %s', filename);
        %     % Output: ERROR: cTaesLab. File not found: filename
        %
        %   See also: createMessage, printError, printWarning, printInfo
        %
            msg = obj.createMessage(error, varargin{:});
            disp(msg);
        end
    end

    methods(Static, Access=private)
        function res = sequence()
        %sequence - Generates unique sequential object identifiers.
        %   Static method that maintains persistent counter for unique IDs.
        %   Counter is initialized with random value, then incremented.
        %   IDs are never reused within a MATLAB session.
        %
        %   Syntax:
        %     res = cTaesLab.sequence()  % Internal use only
        %
        %   Output Arguments:
        %     res - Unique identifier (uint64)
        %
        %   Implementation:
        %     Uses persistent variable, initialized with random value
        %
            persistent counter;
            if isempty(counter)
                counter = uint64(randi(intmax));
            else
                counter = counter + 1;
            end
            res = counter;
        end
    end
end