function res = isFilename(filename)
%isFilename - Validate if a filename is acceptable for read/write operations.
%   Validates whether a filename matches the acceptable pattern defined in
%   cType.FILE_PATTERN. The validation checks:
%   - Filename contains only word characters (letters, digits, underscores)
%   - Extension is one of the supported formats
%   - Filename is not a reserved system name (e.g., CON, PRN, AUX, NUL)
%   Supported file extensions:
%     - Data formats: .xlsx, .csv, .json, .xml, .mat, .txt
%     - Documentation: .html, .tex, .md, .mhlp
%     - Code: .m
%   The function extracts the filename and extension from the full path,
%   so it works with both simple filenames and full file paths.
%
%   Syntax:
%     res = isFilename(filename)
%
%   Input Arguments:
%     filename - Filename to validate (with or without path)
%                char array | string scalar
%
%   Output Arguments:
%     res - Logical result
%       true  - Filename is valid for file operations
%       false - Filename is invalid or contains illegal characters
%
%   Examples:
%     % Example 1: Valid filenames
%     res = isFilename('data.txt');           % Returns true
%     res = isFilename('model_results.xlsx'); % Returns true
%     res = isFilename('plant_data.json');    % Returns true
%     res = isFilename('C:\path\to\file.csv');% Returns true (path ignored)
%
%     % Example 2: Invalid characters
%     res = isFilename('invalid file.txt');   % Returns false (space)
%     res = isFilename('file:name.csv');      % Returns false (colon)
%     res = isFilename('data-file.json');     % Returns false (hyphen)
%
%     % Example 3: Invalid extensions
%     res = isFilename('document.docx');      % Returns false
%     res = isFilename('image.png');          % Returns false
%     res = isFilename('archive.zip');        % Returns false
%
%     % Example 4: Reserved names
%     res = isFilename('CON.txt');            % Returns false (Windows reserved)
%     res = isFilename('PRN.csv');            % Returns false (Windows reserved)
%     res = isFilename('NUL.json');           % Returns false (Windows reserved)
%
%     % Example 5: Edge cases
%     res = isFilename('');                   % Returns false (empty)
%     res = isFilename('file');               % Returns false (no extension)
%     res = isFilename('.txt');               % Returns false (no name)
%
%     % Example 6: String input
%     res = isFilename(string('results.mat'));% Returns true
%
%   See also: fileparts, ischar, isstring, cType.FILE_PATTERN
%
    res = false; 
    % Validate input argument
    if nargin ~= 1 || isempty(filename) || ~(ischar(filename) || isstring(filename))
        return;
    end   
    % Convert to char array if it is a string
    filename = char(filename);
    % Extract filename and extension from full path
    % This allows validation of both 'file.txt' and 'C:\path\to\file.txt'
    [~, name, ext] = fileparts(filename); 
    % Check if the filename matches the acceptable pattern
    % Pattern validates: word characters + supported extension + not reserved name
    if regexp(strcat(name, ext), cType.FILE_PATTERN, 'once')
        res = true;
    end   
end