classdef cMessageLogger < cTaesLab
%cMessageLogger - Message logging and management system for TaesLab objects.
%   Extends cTaesLab to provide comprehensive message collection, storage, and
%   retrieval capabilities. While cTaesLab prints messages immediately to the
%   console, cMessageLogger stores them in a queue for later inspection, filtering,
%   batch display, or export to applications and user interfaces.
%
%   This class is essential for objects that perform complex operations requiring
%   detailed validation logging, batch processing with multiple warnings, or
%   integration with GUI applications that need to display collected messages.
%
%   Key Features:
%     • Message collection in a persistent queue (cQueue container)
%     • Stores ERROR, WARNING, and INFO messages with full context
%     • Filter and display messages by type (errors only, warnings only, etc.)
%     • Export messages as formatted tables for UI display
%     • Combine loggers from multiple objects
%     • Clear logger to reuse object
%     • Inherits immediate message printing from cTaesLab
%
%   Dual Message Handling:
%     Inherited from cTaesLab (immediate display):
%       • printError() - Displays error and sets status to false
%       • printWarning() - Displays warning (status unchanged)
%       • printInfo() - Displays info message (status unchanged)
%     
%     Added by cMessageLogger (stored for later):
%       • messageLog() - Stores message in queue without displaying
%       • printLogger() - Displays all stored messages
%       • printLoggerType() - Displays only specific message types
%
%   Typical Usage Pattern:
%     During complex operations (file reading, validation, parsing):
%       1. Use messageLog() to collect all issues without interrupting flow
%       2. Continue processing to identify all problems (not just first error)
%       3. After completion, use printLogger() to display all collected messages
%       4. Check status to determine if any errors occurred
%
%   cMessageLogger Properties (Inherited from cTaesLab):
%     objectId - Unique object identifier
%     status - Object validity flag
%
%   cMessageLogger Methods:
%     cMessageLogger - Constructor, initializes logger with empty queue
%     messageLog - Adds message to queue without displaying
%     printLogger - Displays all collected messages in order
%     printLoggerType - Displays only messages of specified type
%     tableLogger - Exports messages as table for UI display
%     addLogger - Merges messages from another logger
%     clearLogger - Removes all messages from queue
%
%   cMessageLogger Methods (Inherited from cTaesLab):
%     printError - Displays error immediately and sets status to false
%     printWarning - Displays warning immediately (status unchanged)
%     printInfo - Displays info message immediately (status unchanged)
%     getObjectId - Returns unique object identifier
%     eq, ne - Equality/inequality operators
%
%   Message Storage vs. Immediate Display:
%     Use messageLog() when:
%       • Collecting multiple validation errors to show all at once
%       • Building error reports for batch processing
%       • Integrating with GUI applications that need message lists
%       • Want to continue processing after errors to find all issues
%     
%     Use printError/Warning/Info() when:
%       • Need immediate feedback to console
%       • Single critical error that should stop execution
%       • Interactive debugging or quick status updates
%       • Don't need to store messages for later
%
%   Examples:
%     % Example 1: Create logger and collect messages
%     obj = cMessageLogger();
%     obj.messageLog(cType.ERROR, 'Invalid parameter: %s', 'newstate');
%     obj.messageLog(cType.WARNING, 'Using default value: %d', 100);
%     obj.messageLog(cType.INFO, 'Validation complete');
%     obj.printLogger();  % Display all three messages
%     fprintf('Status: %d\n', obj.status);  % 0 (false, due to error)
%
%     % Example 2: Create invalid logger from start
%     obj = cMessageLogger(false);
%     fprintf('Created with status: %d\n', obj.status);  % 0
%
%     % Example 3: Filter messages by type
%     obj = cMessageLogger();
%     obj.messageLog(cType.ERROR, 'Error 1');
%     obj.messageLog(cType.WARNING, 'Warning 1');
%     obj.messageLog(cType.ERROR, 'Error 2');
%     obj.printLoggerType(cType.ERROR);  % Shows only Error 1 and Error 2
%
%     % Example 4: Export messages to table for GUI
%     obj = cMessageLogger();
%     obj.messageLog(cType.ERROR, 'File not found: %s', 'data.json');
%     obj.messageLog(cType.WARNING, 'Missing optional field');
%     [msgTable, errorIndex] = obj.tableLogger();
%     % msgTable: {'ERROR', 'cMessageLogger', 'File not found...'; ...}
%     % errorIndex: [1, 0] - indexes for color coding in UI
%
%     % Example 5: Combine loggers from multiple objects
%     obj1 = cMessageLogger();
%     obj1.messageLog(cType.ERROR, 'Error in object 1');
%     obj2 = cMessageLogger();
%     obj2.messageLog(cType.WARNING, 'Warning in object 2');
%     obj1.addLogger(obj2);  % obj1 now has both messages
%     obj1.printLogger();
%
%     % Example 6: Use in validation workflow
%	  S = struct(...);
%     log = exportJSON(S,'data.json')
%	  if ~isValid(data)
%		log.printLogger();
%	  end	  
%
%     % Example 7: Clear and reuse logger
%     obj = cMessageLogger();
%     obj.messageLog(cType.INFO, 'First batch');
%     obj.printLogger();
%     obj.clearLogger();  % Remove all messages
%     obj.messageLog(cType.INFO, 'Second batch');
%     obj.printLogger();  % Shows only "Second batch"
%
%   Common Usage Patterns:
%     • File validation: Collect all parsing errors before reporting
%     • Data model validation: Gather all field errors to show complete picture
%     • Batch processing: Log issues from multiple items, display summary
%     • GUI integration: Export messages to tables for user-friendly display
%     • Debugging: Store detailed operation logs for troubleshooting
%     • Multi-stage processing: Combine logs from different processing steps
%
%   Status Management:
%     Status is set to false when:
%       • messageLog() is called with cType.ERROR
%       • printError() is called (inherited from cTaesLab)
%       • addLogger() merges a logger with status=false
%     
%     Status remains true when:
%       • Only WARNING or INFO messages logged
%       • Logger is cleared (clearLogger does not reset status)
%
%   See also:
%     cTaesLab, cQueue, cMessageBuilder, cType, cMessages, isValid,
%
    properties(Access=protected)
        logger  % Message queue container (cQueue of cMessageBuilder objects)
    end
	
	methods(Access=public)
        function obj = cMessageLogger(val)
        %cMessageLogger - Constructor, initializes logger with empty message queue.
        %   Creates a new cMessageLogger object with an empty message queue (cQueue)
        %   and optional initial status. Inherits unique object ID from cTaesLab.
        %   The queue is ready to collect messages via messageLog() method.
        %
        %   Syntax:
        %     obj = cMessageLogger()
        %     obj = cMessageLogger(status)
        %
        %   Input Arguments (Optional):
        %     status - Initial validity state of the object
        %       logical (default: true)
        %       Use false to create an invalid logger from the start.
        %
        %   Output Arguments:
        %     obj - Initialized cMessageLogger object
        %       Properties: objectId, status, logger (empty queue)
        %
        %   Examples:
        %     obj = cMessageLogger();       % Create valid logger
        %     obj = cMessageLogger(false);  % Create invalid logger
        %
        %   See also: messageLog, printLogger, cQueue, cTaesLab
        %
            if nargin == 1
                obj.status = val;
            end
            obj.logger = cQueue();
        end
		
        function messageLog(obj, error, varargin)
        %messageLog - Adds message to queue without displaying to console.
        %   Creates a formatted message and stores it in the internal queue for
        %   later retrieval. Unlike printError/Warning/Info, this method does NOT
        %   display the message immediately. Messages accumulate until printLogger()
        %   is called. Sets status to false if message type is ERROR.
        %
        %   Syntax:
        %     obj.messageLog(type, format, arg1, arg2, ...)
        %
        %   Input Arguments:
        %     type - Message severity level
        %       cType.ERROR | cType.WARNING | cType.VALID (INFO)
        %       ERROR sets obj.status to false
        %     
        %     format - Message format string (printf-style)
        %       char array
        %     
        %     arg1, arg2, ... - Values to substitute in format string
        %       any type
        %
        %   Side Effects:
        %     • Adds message to internal queue
        %     • Sets obj.status to false if type == cType.ERROR
        %     • Does NOT display message (use printLogger to display)
        %
        %   Examples:
        %     obj.messageLog(cType.ERROR, 'File not found: %s', filename);
        %     obj.messageLog(cType.WARNING, 'Using default: %d', value);
        %     obj.messageLog(cType.VALID, 'Processing complete');
        %
        %   See also: printLogger, printLoggerType, cType, cMessages
        %
            message = obj.createMessage(error, varargin{:});
            obj.logger.add(message);
        end
		
        function printLogger(obj)
        %printLogger - Displays all collected messages to console in order.
        %   Prints all messages stored in the queue, preserving the order they
        %   were added. Each message shows its type (ERROR/WARNING/INFO), source
        %   class, and text. Does not clear the queue after printing.
        %
        %   Syntax:
        %     obj.printLogger()
        %     printLogger(obj)  % Alternative calling style
        %
        %   Output Format:
        %     Each message prints as: "TYPE: ClassName. Message text"
        %
        %   Examples:
        %     obj = cMessageLogger();
        %     obj.messageLog(cType.ERROR, 'Error 1');
        %     obj.messageLog(cType.WARNING, 'Warning 1');
        %     obj.printLogger();
        %     % Output:
        %     %   ERROR: cMessageLogger. Error 1
        %     %   WARNING: cMessageLogger. Warning 1
        %
        %   Common Usage:
        %     if ~isValid(obj)
        %         printLogger(obj);  % Show why validation failed
        %     end
        %
        %   See also: messageLog, printLoggerType, clearLogger
        %
            printContent(obj.logger);
        end

        function printLoggerType(obj, type)
        %printLoggerType - Displays only messages of specified type to console.
        %   Filters the message queue and displays only messages matching the
        %   specified severity level. Useful for showing only errors, only warnings,
        %   or only info messages. Does not modify the queue.
        %
        %   Syntax:
        %     obj.printLoggerType(type)
        %
        %   Input Arguments:
        %     type - Message severity level to display
        %       cType.ERROR | cType.WARNING | cType.VALID (INFO)
        %       Only messages matching this type will be shown
        %
        %   Examples:
        %     % Show only errors
        %     obj.printLoggerType(cType.ERROR);
        %     
        %     % Show only warnings
        %     obj.printLoggerType(cType.WARNING);
        %     
        %     % Show only info messages
        %     obj.printLoggerType(cType.VALID);
        %
        %   Common Usage:
        %     % Display errors only after validation
        %     if ~validator.status
        %         validator.printLoggerType(cType.ERROR);
        %     end
        %
        %   See also: printLogger, messageLog, cType
        %
            q = obj.logger;
            for i = 1:q.Count
                message = q.getContent(i);
                if message.Error == type
                    disp(message)
                end
            end
        end

        function [res, index] = tableLogger(obj)
        %tableLogger - Exports messages as cell array table for GUI display.
        %   Converts all messages in the queue to a structured cell array suitable
        %   for display in MATLAB App Designer tables, uitable components, or other
        %   UI frameworks. Also provides numeric indices for color-coding rows by
        %   message severity.
        %
        %   Syntax:
        %     [res, index] = obj.tableLogger()
        %
        %   Output Arguments:
        %     res - Cell array table with message data
        %       cell array (n × 3) where n = number of messages
        %       Columns: {Type, Class, Message}
        %       Type: 'ERROR', 'WARNING', or 'INFO'
        %       Class: Source class name
        %       Message: Formatted message text
        %     
        %     index - Numeric severity codes for each message
        %       uint8 array (1 × n)
        %       Values: 1 (ERROR), 0 (WARNING), 2 (INFO)
        %       Useful for color-coding rows in UI tables
        %
        %   Examples:
        %     % Export to table for display
        %     obj = cMessageLogger();
        %     obj.messageLog(cType.ERROR, 'Error message');
        %     obj.messageLog(cType.WARNING, 'Warning message');
        %     [msgTable, errorIdx] = obj.tableLogger();
        %     % msgTable = {'ERROR', 'cMessageLogger', 'Error message'; ...
        %     %             'WARNING', 'cMessageLogger', 'Warning message'}
        %     % errorIdx = [1, 0]
        %     
        %     % Use in App Designer
        %     app.MessageTable.Data = obj.tableLogger();
        %
        %   Common Usage:
        %     % Color-code table rows by severity
        %     [data, idx] = logger.tableLogger();
        %     colors = [1 0 0; 1 1 0; 0 0 0];  % Red, Yellow, Black
        %     for i = 1:length(idx)
        %         table.RowColor(i) = colors(idx(i)+1, :);
        %     end
        %
        %   See also: messageLog, printLogger, cType.getTextErrorCode
        %
            q = obj.logger;
            res = cell(q.Count, 3);
            index = zeros(1, q.Count,'uin8');
            for i = 1:q.Count
                message = q.getContent(i);
                res{i, 1} = cType.getTextErrorCode(message.Error);
                res{i, 2} = message.Class;
                res{i, 3} = message.Text;
                index(i) = message.Error + 2;
            end
        end
	
        function addLogger(obj1, obj2)
        %addLogger - Merges messages from another logger into this one.
        %   Concatenates all messages from obj2's queue to the end of obj1's queue,
        %   preserving message order. The combined status is the logical AND of both
        %   loggers (false if either logger has errors). obj2 is not modified.
        %
        %   Syntax:
        %     obj1.addLogger(obj2)
        %
        %   Input Arguments:
        %     obj1 - Target logger (this object, will receive messages)
        %       cMessageLogger
        %     
        %     obj2 - Source logger (messages to copy from)
        %       cMessageLogger
        %       Not modified by this operation
        %
        %   Side Effects:
        %     • Appends all messages from obj2 to obj1
        %     • Sets obj1.status = obj1.status AND obj2.status
        %     • obj2 remains unchanged
        %
        %   Examples:
        %     % Combine validation results from multiple objects
        %     validator1 = cMessageLogger();
        %     validator1.messageLog(cType.ERROR, 'Error in section A');
        %     
        %     validator2 = cMessageLogger();
        %     validator2.messageLog(cType.WARNING, 'Warning in section B');
        %     
        %     validator1.addLogger(validator2);
        %     validator1.printLogger();
        %     % Shows: Error in section A, then Warning in section B
        %
        %   Common Usage:
        %     % Collect validation messages from multiple sources
        %     masterLog = cMessageLogger();
        %     for i = 1:length(validators)
        %         masterLog.addLogger(validators{i});
        %     end
        %     if ~masterLog.status
        %         masterLog.printLogger();
        %     end
        %
        %   See also: messageLog, printLogger, clearLogger
        %
            obj1.logger.addQueue(obj2.logger);
            obj1.status = isValid(obj1) && isValid(obj2);
        end

        function clearLogger(obj)
        %clearLogger - Removes all messages from the queue.
        %   Clears the internal message queue, effectively resetting the logger
        %   to empty state. The object can then be reused to collect new messages.
        %   Note: Does NOT reset the status property - if status was false due to
        %   previous errors, it remains false after clearing.
        %
        %   Syntax:
        %     obj.clearLogger()
        %
        %   Side Effects:
        %     • Removes all messages from queue
        %     • Queue becomes empty (Count = 0)
        %     • Status property is NOT changed
        %
        %   Examples:
        %     % Reuse logger for multiple operations
        %     logger = cMessageLogger();
        %     
        %     % First operation
        %     logger.messageLog(cType.INFO, 'Processing batch 1');
        %     logger.printLogger();
        %     
        %     % Clear and reuse for second operation
        %     logger.clearLogger();
        %     logger.messageLog(cType.INFO, 'Processing batch 2');
        %     logger.printLogger();  % Shows only batch 2 message
        %
        %   Common Usage:
        %     % Clear between iterations
        %     for i = 1:nFiles
        %         logger.clearLogger();
        %         validateFile(files{i}, logger);
        %         if ~logger.status
        %             fprintf('File %d failed:\n', i);
        %             logger.printLogger();
        %         end
        %     end
        %
        %   Note:
        %     To fully reset the logger including status, create a new object:
        %       logger = cMessageLogger();  % Fresh logger with status=true
        %
        %   See also: messageLog, printLogger, addLogger
        %
            obj.logger.clear;
        end
    end
end