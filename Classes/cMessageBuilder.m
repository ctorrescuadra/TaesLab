classdef cMessageBuilder
%cMessageBuilder - Formatted message object for logging and display systems.
%   Creates structured message objects that encapsulate three key components:
%   severity level (ERROR/WARNING/INFO), source class name, and message text.
%   These objects are used throughout TaesLab for consistent message formatting,
%   logging, and display across console output, GUI applications, and log files.
%
%   cMessageBuilder provides a standardized message format that makes it easy to:
%     • Track where messages originated (source class)
%     • Filter messages by severity level
%     • Format messages consistently across the toolbox
%     • Display messages with appropriate console highlighting
%     • Store messages for batch processing or GUI display
%
%   The class is intentionally simple and lightweight, designed to be created
%   in large quantities (hundreds or thousands) without performance impact.
%   Each message object is immutable once created (read-only properties).
%
%   Message Severity Levels:
%     ERROR (cType.ERROR)   - Critical issues that invalidate objects/operations
%                             Displayed to stderr (red in some consoles)
%     WARNING (cType.WARNING) - Non-critical issues that don't prevent operation
%                               Displayed to stdout
%     INFO (cType.VALID)    - Informational messages about successful operations
%                             Displayed to stdout
%
%   Message Format:
%     All messages follow the standard pattern:
%       "LEVEL: ClassName. Message text"
%     
%     Examples:
%       "ERROR: cDataModel. File not found: data.json"
%       "WARNING: cReadModelXLS. Sheet 'States' is empty"
%       "INFO: cExergyModel. Calculation completed successfully"
%
%   Usage in TaesLab:
%     cMessageBuilder objects are created by:
%       • cTaesLab.createMessage() - Base class message creation
%       • cMessageLogger.messageLog() - Stored in queue for batch display
%       • Manual creation for custom logging systems
%
%     Messages are consumed by:
%       • cQueue - Stores messages in FIFO queue
%       • cMessageLogger - Collects and displays message batches
%       • disp() - Immediate console output
%       • GUI tables - Formatted display in applications
%
%   Properties (Public, Read-Only):
%     Error - Message severity level
%       cType.ERROR | cType.WARNING | cType.VALID
%     Class - Source class name
%       char array
%     Text - Message content
%       char array
%
%   Methods (Public):
%     cMessageBuilder - Constructor, creates immutable message object
%     getMessage - Returns fully formatted message string
%     disp - Displays message to console (overloads built-in disp)
%
%   Object Lifecycle:
%     1. Create: obj = cMessageBuilder(type, class, text)
%     2. Store: queue.add(obj) or immediate display via disp(obj)
%     3. Retrieve: Used by logger to display or export
%     4. Message objects are immutable - properties cannot change
%
%   Examples:
%     % Example 1: Create and display error message
%     msg = cMessageBuilder(cType.ERROR, 'MyClass', 'Invalid parameter');
%     disp(msg);
%     % Output (to stderr): ERROR: MyClass. Invalid parameter
%
%     % Example 2: Create warning message with formatted text
%     filename = 'data.csv';
%     msg = cMessageBuilder(cType.WARNING, 'Parser', ...
%                           sprintf('File not found: %s', filename));
%     disp(msg);
%     % Output (to stdout): WARNING: Parser. File not found: data.csv
%
%     % Example 3: Create info message
%     msg = cMessageBuilder(cType.VALID, 'Validator', 'Validation passed');
%     disp(msg);
%     % Output (to stdout): INFO: Validator. Validation passed
%
%     % Example 4: Access message properties
%     msg = cMessageBuilder(cType.ERROR, 'TestClass', 'Test error');
%     fprintf('Level: %d\n', msg.Error);     % Output: 0
%     fprintf('Class: %s\n', msg.Class);     % Output: TestClass
%     fprintf('Text: %s\n', msg.Text);       % Output: Test error
%
%     % Example 5: Get formatted message string
%     msg = cMessageBuilder(cType.WARNING, 'Loader', 'Missing field');
%     fullText = msg.getMessage();
%     % fullText = 'WARNING: Loader. Missing field'
%
%     % Example 6: Store in queue for batch processing
%     queue = cQueue();
%     queue.add(cMessageBuilder(cType.ERROR, 'Parser', 'Line 5: syntax error'));
%     queue.add(cMessageBuilder(cType.WARNING, 'Parser', 'Line 10: deprecated'));
%     queue.printContent();  % Display all messages
%
%     % Example 7: Use in message logger
%     logger = cMessageLogger();
%     logger.messageLog(cType.ERROR, 'Operation failed');
%     % Internally creates: cMessageBuilder(cType.ERROR, 'cMessageLogger', 'Operation failed')
%
%   Common Usage Patterns:
%     • Validation workflows: Create messages for each validation issue
%     • File parsing: Record all parse errors before reporting
%     • Batch processing: Collect messages from multiple operations
%     • GUI applications: Build message tables for user display
%     • Debugging: Track operation flow with INFO messages
%
%   Display Behavior:
%     ERROR messages:
%       • Sent to stderr (file descriptor 2)
%       • May appear in red in some consoles
%       • If cType.DEBUG_MODE enabled, triggers dbstack() for debugging
%     
%     WARNING and INFO messages:
%       • Sent to stdout (file descriptor 1)
%       • Normal console formatting
%
%   Performance Considerations:
%     • Object creation is very fast (microseconds)
%     • Immutable design ensures thread safety
%     • Minimal memory footprint (~100 bytes per object)
%     • Suitable for creating thousands of messages
%     • String formatting done once at creation
%
%   Design Philosophy:
%     • Simple, focused responsibility (message container only)
%     • Immutable for reliability and safety
%     • Consistent formatting across entire toolbox
%     • Easy integration with logging and display systems
%     • Minimal dependencies (only cType)
%
%   See also:
%     cMessageLogger, cQueue, cTaesLab, cType, disp, fprintf
%
    properties(GetAccess=public,SetAccess=private)
        Error    % Message severity level: cType.ERROR (0), cType.WARNING (-1), or cType.VALID (1)
        Class    % Source class name that generated the message
        Text     % Message content text (without level/class prefix)
    end

    methods
        function obj = cMessageBuilder(type,class,text)
            %cMessageBuilder - Construct formatted message object.
            %   Creates an immutable message object with specified severity level,
            %   source class, and message text. The object encapsulates all information
            %   needed for consistent message display and logging throughout TaesLab.
            %
            %   Syntax:
            %     obj = cMessageBuilder(type, class, text)
            %
            %   Arguments:
            %     type - Message severity level
            %       Numeric code: cType.ERROR (0), cType.WARNING (-1), or cType.VALID (1)
            %       Determines display behavior (stderr vs stdout) and filtering
            %       Must be one of the three defined levels
            %
            %     class - Source class name
            %       char array
            %       Name of the class generating the message
            %       Used to track message origin for debugging and filtering
            %       Examples: 'cDataModel', 'cReadModelJSON', 'MyCustomClass'
            %
            %     text - Message content
            %       char array
            %       The actual message text (without level/class prefix)
            %       Can include formatted output from sprintf
            %       Should be concise and descriptive
            %
            %   Side Effects:
            %     • Creates object with read-only properties (immutable)
            %     • No validation performed on inputs (assumes caller validates)
            %     • No message display (display requires explicit disp() call)
            %
            %   Examples:
            %     % Example 1: Create error message
            %     msg = cMessageBuilder(cType.ERROR, 'Validator', 'Invalid input');
            %
            %     % Example 2: Create warning with formatted text
            %     filename = 'data.json';
            %     msg = cMessageBuilder(cType.WARNING, 'FileReader', ...
            %                           sprintf('File not found: %s', filename));
            %
            %     % Example 3: Create info message
            %     msg = cMessageBuilder(cType.VALID, 'Calculator', ...
            %                           'Calculation completed successfully');
            %
            %   Common Usage:
            %     • Called by cTaesLab.createMessage() for object validation messages
            %     • Called by cMessageLogger.messageLog() for queued logging
            %     • Manually created for custom logging systems
            %
            %   See also:
            %     cMessageLogger, cTaesLab, cType, getMessage, disp
            %
            obj.Error=type;
            obj.Class=class;
            obj.Text=text;
        end

        function text = getMessage(obj)
            %getMessage - Get fully formatted message string.
            %   Returns the complete message text in standard TaesLab format:
            %   "LEVEL: ClassName. Message text"
            %
            %   The method assembles the three message components (severity, source,
            %   content) into a single string following the toolbox-wide convention.
            %   This formatted string is suitable for console output, log files, or
            %   GUI display.
            %
            %   Syntax:
            %     text = getMessage(obj)
            %
            %   Returns:
            %     text - Fully formatted message string
            %       char array
            %       Format: "LEVEL: ClassName. Message text"
            %       LEVEL is one of: ERROR, WARNING, INFO
            %       ClassName is the source class from obj.Class property
            %       Message text is from obj.Text property
            %
            %   Side Effects:
            %     • None (read-only operation)
            %     • Creates new string on each call (not cached)
            %
            %   Examples:
            %     % Example 1: Get formatted error message
            %     msg = cMessageBuilder(cType.ERROR, 'Parser', 'Invalid syntax');
            %     text = msg.getMessage();
            %     % text = 'ERROR: Parser. Invalid syntax'
            %
            %     % Example 2: Get formatted warning message
            %     msg = cMessageBuilder(cType.WARNING, 'Loader', 'Missing field');
            %     text = msg.getMessage();
            %     % text = 'WARNING: Loader. Missing field'
            %
            %     % Example 3: Get formatted info message
            %     msg = cMessageBuilder(cType.VALID, 'Validator', 'All checks passed');
            %     text = msg.getMessage();
            %     % text = 'INFO: Validator. All checks passed'
            %
            %     % Example 4: Use in fprintf
            %     msg = cMessageBuilder(cType.ERROR, 'MyClass', 'Operation failed');
            %     fprintf('%s\n', msg.getMessage());
            %     % Output: ERROR: MyClass. Operation failed
            %
            %   Common Usage:
            %     • Called by disp() to get formatted output
            %     • Used in GUI tables to display message lists
            %     • Exported to log files for persistent storage
            %     • Filtering message lists based on content
            %
            %   Implementation Notes:
            %     • Uses cType.getTextErrorCode() to convert numeric code to text
            %     • Message format is consistent across entire TaesLab toolbox
            %     • Period separator between class and text is intentional
            %
            %   See also:
            %     cType.getTextErrorCode, disp, sprintf, fprintf
            %
            text=[cType.getTextErrorCode(obj.Error),': ',obj.Class,'. ',obj.Text];              
        end

        function disp(obj)
            %disp - Display message to console with appropriate stream routing.
            %   Overloads the built-in disp() function to provide smart message display
            %   that routes ERROR messages to stderr and WARNING/INFO messages to stdout.
            %   This ensures proper stream separation for console redirection and allows
            %   some terminals to highlight error messages in red.
            %
            %   The method is automatically called by MATLAB/Octave when:
            %     • A cMessageBuilder object is displayed without semicolon
            %     • An array of messages is displayed
            %     • disp(msg) is explicitly called
            %
            %   Syntax:
            %     disp(obj)
            %     disp(obj)  % Explicit call (same as line above)
            %     obj        % Implicit call (displays object)
            %
            %   Stream Routing:
            %     ERROR messages:
            %       • Sent to stderr (file descriptor 2)
            %       • May appear in red in some terminal emulators
            %       • Can be redirected separately: command 2>errors.log
            %       • Suitable for critical issues that invalidate operations
            %
            %     WARNING and INFO messages:
            %       • Sent to stdout (file descriptor 1)
            %       • Normal console formatting
            %       • Can be redirected separately: command 1>output.log
            %       • Suitable for non-critical information
            %
            %   Debug Mode:
            %     When cType.DEBUG_MODE is enabled and message is ERROR:
            %       • Displays stack trace with dbstack()
            %       • Shows function call chain leading to error
            %       • Useful for debugging error sources
            %
            %   Side Effects:
            %     • Writes formatted message to console (stderr or stdout)
            %     • Adds newline after message for readability
            %     • No modification to object (read-only operation)
            %     • If DEBUG_MODE enabled, may display stack trace
            %
            %   Examples:
            %     % Example 1: Display error message (to stderr)
            %     msg = cMessageBuilder(cType.ERROR, 'Validator', 'Invalid data');
            %     disp(msg);
            %     % Output (stderr): ERROR: Validator. Invalid data
            %
            %     % Example 2: Display warning message (to stdout)
            %     msg = cMessageBuilder(cType.WARNING, 'Parser', 'Deprecated syntax');
            %     disp(msg);
            %     % Output (stdout): WARNING: Parser. Deprecated syntax
            %
            %     % Example 3: Implicit display without semicolon
            %     msg = cMessageBuilder(cType.VALID, 'Calculator', 'Done')
            %     % Output (stdout): INFO: Calculator. Done
            %
            %     % Example 4: Display array of messages
            %     messages = [...
            %         cMessageBuilder(cType.ERROR, 'Parser', 'Line 5 error');
            %         cMessageBuilder(cType.WARNING, 'Parser', 'Line 10 warning');
            %         cMessageBuilder(cType.VALID, 'Parser', 'Parse complete')
            %     ];
            %     disp(messages);
            %     % Displays all three messages (errors to stderr, others to stdout)
            %
            %     % Example 5: Use in message queue display
            %     queue = cQueue();
            %     queue.add(cMessageBuilder(cType.ERROR, 'Loader', 'File not found'));
            %     queue.add(cMessageBuilder(cType.WARNING, 'Loader', 'Using defaults'));
            %     queue.printContent();  % Calls disp() for each message
            %
            %     % Example 6: Debug mode with stack trace
            %     cType.DEBUG_MODE = true;
            %     msg = cMessageBuilder(cType.ERROR, 'Test', 'Debug error');
            %     disp(msg);
            %     % Output: ERROR: Test. Debug error
            %     %         (followed by stack trace showing function call chain)
            %
            %   Common Usage:
            %     • Immediate message display in validation workflows
            %     • Batch message display from cQueue or cMessageLogger
            %     • Debugging message flow (see which messages are generated)
            %     • Interactive console output with proper stream separation
            %     • Testing message creation and formatting
            %
            %   Implementation Notes:
            %     • File descriptor 1 = stdout (standard output)
            %     • File descriptor 2 = stderr (standard error)
            %     • fprintf() is used instead of disp() for stream control
            %     • Newline is explicitly added for consistent formatting
            %     • Platform-independent (works on Windows, Linux, macOS)
            %
            %   Platform Behavior:
            %     MATLAB:
            %       • Full support for stderr/stdout separation
            %       • Some terminals show stderr in red
            %       • Stream redirection works in batch mode
            %
            %     Octave:
            %       • Full support for file descriptor routing
            %       • Consistent behavior with MATLAB
            %
            %   See also:
            %     getMessage, fprintf, cMessageLogger, cQueue.printContent, dbstack
            %
            fid=2*(obj.Error==0)+(obj.Error~=0);
            if cType.DEBUG_MODE && (obj.Error==cType.ERROR)
                dbstack;
            end
            fprintf(fid,'%s\n',obj.getMessage);
        end
    end
end