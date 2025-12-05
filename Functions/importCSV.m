function res = importCSV(filename)
%importCSV - Import CSV file contents as cell array.
%   Reads a CSV (Comma-Separated Values) file and returns its contents as
%   a cell array with cross-platform compatibility for MATLAB and GNU Octave.
%   Platform-specific implementations:
%    - MATLAB: Uses built-in readcell() function
%    - Octave: Uses csv2cell() function
%   The function verifies filename is valid and has .csv extension,
%   checks that file exists before attempting to read and
%   provides detailed error messages for troubleshooting.
%   Data types are automatically detected and preserved during import.
%
%   Syntax:
%     res = importCSV(filename)
%
%   Input Arguments:
%     filename - CSV file path to read
%                char array | string scalar
%                File must exist and have .csv extension
%
%   Output Arguments:
%     res - Cell array containing file contents
%           Empty cell array {} if file cannot be read
%           Mixed data types preserved (strings, numbers, logicals, etc.)
%
%   Examples:
%     % Example 1: Import simple data table
%     res = importCSV('data.csv');
%     % Returns: {'Name', 'Age'; 'Alice', 30; 'Bob', 25}
%
%     % Example 2: Import and display
%     data = importCSV('results.csv');
%     fprintf('Loaded %d rows and %d columns\n', size(data, 1), size(data, 2));
%
%     % Example 3: Import with error handling
%     try
%         data = importCSV('measurements.csv');
%         disp('File loaded successfully');
%     catch err
%         fprintf('Error: %s\n', err.message);
%     end
%
%     % Example 4: Extract headers and data
%     contents = importCSV('experiment.csv');
%     headers = contents(1, :);        % First row
%     data = contents(2:end, :);       % Remaining rows
%
%     % Example 5: Process numeric columns
%     raw = importCSV('values.csv');
%     % Skip header row, convert to numeric matrix
%     numData = cell2mat(raw(2:end, :));
%
%     % Example 6: String filename
%     res = importCSV(string('C:\data\output.csv'));
%
%   Error Handling:
%     Throws errors for:
%     - Wrong number of arguments (1 required)
%     - Invalid filename or wrong extension
%     - File does not exist
%     - File read operation fails
%
%   See also: readcell, csv2cell, exportCSV, isOctave, isFilename
%
    % Initialize with empty cell array
    res = cType.EMPTY_CELL;    
    % Validate input argument count
    if nargin ~= 1
        error(buildMessage(mfilename, cMessages.NarginError, cMessages.ShowHelp));
    end   
    % Validate filename and extension
    if ~isFilename(filename) || cType.getFileType(filename) ~= cType.FileType.CSV
        error(buildMessage(mfilename, cMessages.InvalidInputFile, cMessages.ShowHelp));
    end    
    % Check file exists before attempting to read
    if ~exist(filename, 'file')
        error(buildMessage(mfilename, cMessages.FileNotFound, filename));
    end    
    % Read CSV file using platform-specific function
    if isOctave()
        try
            res = csv2cell(filename);  % Octave: Use csv2cell function
        catch err
            error(buildMessage(mfilename, err.message));
        end
    else
        try
            res = readcell(filename); % MATLAB: Use built-in readcell function
        catch err
            error(buildMessage(mfilename, err.message));
        end
    end
    
end