function log = exportJSON(S, filename)
%exportJSON - Export MATLAB structure to JSON file.
%   Exports a MATLAB structure to a JSON (JavaScript Object Notation) file
%   with human-readable formatting (pretty-print). This function is used
%   to save TaesLab data models and configuration files.
%   This function validates input structure, encodes structure to JSON text with
%   identation (PrettyPrint) and writes formatted JSON text to file.
%   Provides detailes error logging through the cMessageLogger system.
%
%   Syntax:
%     log = exportJSON(S, filename)
%
%   Input Arguments:
%     S        - MATLAB structure to export
%                Can contain nested structures, arrays, and mixed data types
%     filename - JSON output filename (must have .json extension)
%                char array | string scalar
%
%   Output Arguments:
%     log - cMessageLogger object containing operation status
%           log.status = true  : File saved successfully
%           log.status = false : Error occurred during save
%
%   Notes:
%     MATLAB data types are automatically mapped to JSON:
%     - struct → JSON objects
%     - cell arrays → JSON arrays
%     - numeric arrays → JSON arrays of numbers
%     - char arrays → JSON strings
%     - logical → JSON booleans
%     - [] (empty) → JSON null
%
%   Examples:
%     % Example 1: Export simple structure
%     data.name = 'Plant A';
%     data.power = 1000;
%     data.efficiency = 0.85;
%     log = exportJSON(data, 'plant_data.json');
%
%     % Example 2: Export nested structure (data model)
%     model.ProductiveStructure.flows = {struct('key', 'F1', 'type', 'RESOURCE')};
%     model.ProductiveStructure.processes = {struct('key', 'P1', 'fuel', 'F1')};
%     log = exportJSON(model, 'model.json');
%     if log.status
%         fprintf('Model saved successfully\n');
%     end
%
%     % Example 3: Export with error handling
%     config.version = '1.0';
%     config.settings = struct('debug', true);
%     log = exportJSON(config, 'config.json');
%     if ~log.status
%         printLogger(log);
%     end
%
%     % Example 4: Export array of structures
%     flows(1) = struct('key', 'CMB', 'type', 'RESOURCE');
%     flows(2) = struct('key', 'WN', 'type', 'OUTPUT');
%     data.flows = flows;
%     log = exportJSON(data, 'flows.json');
%
%     % Example 5: Export configuration
%     format.datamodel = {'Flows', 'Processes'};
%     format.options = struct('validate', true);
%     log = exportJSON(format, 'printformat.json');
%
%     % Example 6: String filename
%     log = exportJSON(data, string('C:\output\results.json'));
%
%   Error Handling:
%     The function validates:
%     - Correct number of input arguments (2 required)
%     - S is a structure
%     - filename is valid and has .json extension
%     - File write operation succeeds
%     Errors are logged in the cMessageLogger object for troubleshooting.
%
%   See also: jsonencode, fwrite, importJSON, exportCSV, isFilename
%
    log = cMessageLogger();   
    % Validate input argument count
    if nargin ~= 2
        log.messageLog(cType.ERROR, cMessages.NarginError, cMessages.ShowHelp);
        return;
    end   
    % Validate S is a structure
    if ~isstruct(S)
        log.messageLog(cType.ERROR, cMessages.InvalidArgument, cMessages.ShowHelp);
        return;
    end   
    % Validate filename and extension
    if ~isFilename(filename) || ~cType.checkFileExt(filename, cType.FileExt.JSON)
        log.messageLog(cType.ERROR, cMessages.InvalidInputFile, filename);
        log.messageLog(cType.ERROR, cMessages.ShowHelp);
        return;
    end  
    % Encode struct to JSON text with pretty-printing and write to file
    try
        text = jsonencode(S, 'PrettyPrint', true);
        fid = fopen(filename, 'wt');
        if fid == -1
            error('Cannot open file for writing: %s', filename);
        end       
        fwrite(fid, text);  % Write JSON text to file      
        fclose(fid);        % Close file
    catch err
        % Log error details and file save failure
        log.messageLog(cType.ERROR, err.message);
        log.messageLog(cType.ERROR, cMessages.FileNotSaved, filename);
    end    
end