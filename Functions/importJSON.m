function res = importJSON(log, filename)
%importJSON - Import JSON file and parse into MATLAB structure.
%   Reads a JSON (JavaScript Object Notation) file and parses its contents
%   into a MATLAB structure using jsondecode(). This function is essential
%   for loading TaesLab data models and configuration files.
%   The function reads the entire file content as text using fileread(),
%   parses JSON text into MATLAB structure using jsondecode() and
%   logs errors to the provided cMessageLogger object if failures occur
%
%   Syntax:
%     res = importJSON(log, filename)
%
%   Input Arguments:
%     log      - cMessageLogger object for error logging
%     filename - JSON file path to read
%                char array | string scalar
%                File must exist and have .json extension
%
%   Output Arguments:
%     res - MATLAB structure containing parsed JSON data
%           Empty array [] if file cannot be read or parsed
%           Nested structures preserved from JSON hierarchy
%
%   Note:
%     JSON data types are automatically mapped to MATLAB types:
%     - Objects → struct
%     - Arrays → cell arrays or numeric arrays
%     - Strings → char arrays
%     - Numbers → double
%     - Booleans → logical
%     - null → []
%
%   Examples:
%     % Example 1: Import data model
%     log = cMessageLogger();
%     data = importJSON(log, 'plant_model.json');
%     if log.status
%         disp('Model loaded successfully');
%     end
%
%     % Example 2: Access nested structure
%     log = cMessageLogger();
%     model = importJSON(log, 'rankine_model.json');
%     flows = model.ProductiveStructure.flows;
%     processes = model.ProductiveStructure.processes;
%
%     % Example 3: Error handling
%     log = cMessageLogger();
%     data = importJSON(log, 'config.json');
%     if ~log.status
%         printLogger(log);  % Display error messages
%     end
%
%     % Example 4: Import configuration
%     log = cMessageLogger();
%     config = importJSON(log, 'printformat.json');
%     tables = config.datamodel;
%
%     % Example 5: Check if file was read
%     log = cMessageLogger();
%     result = importJSON(log, 'data.json');
%     if isempty(result)
%         fprintf('Failed to read JSON file\n');
%     else
%         fprintf('Loaded %d fields\n', length(fieldnames(result)));
%     end
%
%     % Example 6: String filename
%     log = cMessageLogger();
%     res = importJSON(log, string('Examples/rankine/rankine_model.json'));
%
%   Error Handling:
%     Errors are logged to the cMessageLogger object for:
%     - File does not exist
%     - File cannot be read (permissions, corruption)
%     - Invalid JSON syntax
%     - Encoding issues
%
%     The function does not throw exceptions; instead it logs errors and
%     returns an empty array, allowing the caller to check log.status.
%
%   See also: jsondecode, fileread, exportJSON, cMessageLogger, ReadDataModel
%
%   Copyright (c) 2025 TaesLab
%
%
    % Initialize with empty result
    res = cType.EMPTY;
    
    % Read and parse JSON file
    try
        % Read entire file content as text
        text = fileread(filename);        
        % Parse JSON text into MATLAB structure
        res = jsondecode(text);
    catch err
        % Log error details and file read failure
        log.messageLog(cType.ERROR, err.message);
        log.messageLog(cType.ERROR, cMessages.FileNotRead, filename);
    end
    
end