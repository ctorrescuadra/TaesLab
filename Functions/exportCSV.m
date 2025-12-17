function log = exportCSV(values, filename)
%exportCSV - Export cell array to CSV file.
%   Exports a cell array to a CSV (Comma-Separated Values) file with
%   cross-platform compatibility for both MATLAB and GNU Octave.
%   Platform-specific implementations:
%    - MATLAB: Uses built-in writecell() function
%    - Octave: Uses cell2csv() function
%   The function validates inputs, checks file extension, and provides
%   detailed error logging through the cMessageLogger system.
%
%   Syntax:
%     log = exportCSV(values, filename)
%
%   Input Arguments:
%     values   - Cell array containing data to export
%                Can contain mixed types (strings, numbers, logicals)
%     filename - CSV output filename (must have .csv extension)
%                char array | string scalar
%
%   Output Arguments:
%     log - cMessageLogger object containing operation status
%           log.status = true  : File saved successfully
%           log.status = false : Error occurred during save
%
%   Examples:
%     % Example 1: Export simple data table
%     values = {'Name', 'Age'; 'Alice', 30; 'Bob', 25};
%     log = exportCSV(values, 'data.csv');
%     if log.status
%         fprintf('File saved successfully\n');
%     end
%
%     % Example 2: Export numeric matrix with headers
%     headers = {'X', 'Y', 'Z'};
%     data = num2cell([1 2 3; 4 5 6; 7 8 9]);
%     values = [headers; data];
%     log = exportCSV(values, 'results.csv');
%
%     % Example 3: Export mixed data types
%     values = {'Product', 'Price', 'InStock'; ...
%               'Apple', 1.50, true; ...
%               'Orange', 2.00, false};
%     log = exportCSV(values, 'inventory.csv');
%
%     % Example 4: Handle errors
%     log = exportCSV({'A', 'B'}, 'invalid.txt');  % Wrong extension
%     if ~log.status
%         printLogger(log);  % Display error messages
%     end
%
%     % Example 5: String filename
%     values = {'Col1', 'Col2'; 1, 2; 3, 4};
%     log = exportCSV(values, string('output.csv'));
%
%   Error Handling:
%     The function validates:
%     - Correct number of input arguments (2 required)
%     - values is a cell array
%     - filename is valid and has .csv extension
%     - Write operation succeeds
%
%   See also: writecell, cell2csv, importCSV, isOctave, isFilename
%
    log = cMessageLogger();
    % Validate input argument count
    if nargin ~= 2
        log.messageLog(cType.ERROR, cMessages.NarginError, cMessages.ShowHelp);
        return;
    end   
    % Validate values is a cell array
    if ~iscell(values)
        log.messageLog(cType.ERROR, cMessages.InvalidArgument, cMessages.ShowHelp);
        return;
    end    
    % Validate filename and extension
    if ~isFilename(filename) || ~cType.checkFileExt(filename, cType.FileExt.CSV)
        log.messageLog(cType.ERROR, cMessages.InvalidInputFile, filename);
        log.messageLog(cType.ERROR, cMessages.ShowHelp);
        return;
    end    
    % Export cell array to CSV file (platform-specific implementation)
    try
        if isOctave()
            cell2csv(filename, values);  % Octave: Use cell2csv function
        else
            writecell(values, filename); % MATLAB: Use built-in writecell function
        end
    catch err
        % Log error details and file save failure
        log.messageLog(cType.ERROR, err.message);
        log.messageLog(cType.ERROR, cMessages.FileNotSaved, filename);
    end    
end