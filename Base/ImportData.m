function res = ImportData(filename, varargin)
%ImportData - Import external tabular data from CSV or Excel files.
%   Reads data from CSV or Excel (XLSX) files and creates a cTableData object
%   for use in TaesLab workflows. This function is useful for importing
%   experimental measurements, external datasets, or results from
%   other analysis tools that need to be integrated with thermoeconomic models.
%
%   The function automatically detects the file format based on extension and
%   handles platform differences between MATLAB and Octave transparently. For
%   Excel files, you can specify which sheet to import; for CSV files, the
%   first row is always treated as column headers.
%
%   Syntax:
%     res = ImportData(filename)
%     res = ImportData(filename, Name, Value)
%  
%   Input Arguments:
%     filename - Path to the CSV or Excel file
%       char array | string
%       Supported formats: .csv (comma-separated values) or .xlsx (Excel workbook)
%
%   Name-Value Arguments:
%     Name - Identifier name for the imported table
%       char array (default: filename without extension for CSV, sheet name for XLSX)
%       Used to identify the table in subsequent operations and displays.
%
%     Description - Descriptive text about the table contents
%       char array (default: same as Name)
%       Provides context about the data source, measurement conditions, or purpose.
%
%     Sheet - Excel sheet name to import (XLSX files only)
%       char array (default: first sheet in workbook)
%       Specifies which worksheet to read from multi-sheet Excel files.
%       Ignored for CSV files. Returns error if sheet does not exist.
%
%   Output Arguments:
%     res - cTableData object containing the imported data
%       Includes column headers (from first row) and data values.
%       Check res.status or use isValid(res) to verify successful import.
%
%   Data Processing Details:
%     CSV Files:
%       - First row becomes column headers
%       - Remaining rows are data values
%       - All data imported as-is (no empty cell removal)
%       - Default Name: filename without extension
%
%     Excel Files (XLSX):
%       - First row becomes column headers
%       - Empty rows and columns are automatically removed
%       - Can select specific sheet from multi-sheet workbook
%       - Default Name: sheet name
%
%   Platform Compatibility:
%     MATLAB: Uses readcell() and sheetnames() - full support
%     Octave: Uses csv2cell() and xlsopen() - full support
%
%   Examples:
%     % Example 1: Import CSV file with automatic naming
%     data = ImportData('temperature_log.csv');
%     if isValid(data)
%         fprintf('Imported %d rows, %d columns\n', size(data.Data));
%     end
%
%     % Example 2: Import CSV with custom metadata
%     data = ImportData('sensors.csv', ...
%                       'Name', 'TempSensors', ...
%                       'Description', 'Hourly temperature measurements - Building A');
%
%     % Example 3: Import specific Excel sheet
%     data = ImportData('experiments.xlsx', 'Sheet', 'Trial_5');
%
%     % Example 4: Import Excel sheet with full metadata
%     data = ImportData('thermal_data.xlsx', ...
%                       'Sheet', 'HeatTransfer', ...
%                       'Name', 'HT_Coefficients', ...
%                       'Description', 'Heat transfer coefficients at 25C');
%
%     % Example 5: Import first Excel sheet (default)
%     data = ImportData('workbook.xlsx');
%     % Automatically reads first sheet with sheet name as identifier
%
%     % Example 6: Import with error handling
%     table = ImportData('measurements.csv');
%     if isValid(table)
%         disp(table.Data);
%     else
%         printLogger(table);  % Display detailed error messages
%     end
%
%   Live Script Demo:
%     <a href="matlab:open ImportDataDemo.mlx">Import Data Demo</a>
%
%   Common Use Cases:
%     • Importing experimental or measurement data
%     • Reading results from external analysis software
%     • Integrating third-party data with TaesLab models
%
%   Error Handling:
%     Returns invalid cTableData object if:
%       • File not found or path is invalid
%       • File format not supported (must be .csv or .xlsx)
%       • Specified Excel sheet does not exist
%       • File cannot be read (corrupted, locked, or permissions issue)
%       • File contains invalid or malformed data
%     Always check res.status or use isValid(res) before using imported data.
% 
%   See also:
%     cTableData, ExportResults, importCSV, importJSON, readcell, csv2cell
%
    res = cTaesLab();
    
    % Validate required input argument
    if nargin < 1 
        res.printError(cMessages.NarginError, cMessages.ShowHelp);
        return
    end    
    % Validate filename format
    if ~isFilename(filename)
        res.printError(cMessages.InvalidInputFile, filename);
        return
    end   
    % Check file existence
    if ~exist(filename, 'file')
        res.printError(cMessages.FileNotFound, filename);
        return
    end   
    % Parse optional name-value arguments
    p = inputParser;
    p.addParameter('Sheet', cType.EMPTY_CHAR, @ischar);
    p.addParameter('Name', cType.EMPTY_CHAR, @ischar);
    p.addParameter('Description', cType.EMPTY_CHAR, @ischar);
    try
        p.parse(varargin{:});
    catch err
        res.printError(err.message);
        return
    end
    props = p.Results;   
    % Import file based on extension (CSV or XLSX)
    [fileType, fileExt] = cType.getFileType(filename);
    switch fileType  
        case cType.FileType.CSV
            res = importCSV(filename, props);
        case cType.FileType.XLSX
            res = importXLSX(filename, props);
        otherwise
            res.printError(cMessages.InvalidFileExt, upper(fileExt));
            return
    end
end

function tbl = importCSV(filename, props)
%importCSV - Import CSV file to cTableData object
%   Internal helper function for CSV file processing
    tbl = cTaesLab();   
    % Read CSV file using platform-specific function
    if isOctave
        try
            values = csv2cell(filename);
        catch err
            tbl.printError(err.message);
            return
        end
    else % MATLAB
        try
            values = readcell(filename);
        catch err
            tbl.printError(err.message);
            return
        end
    end    
    % Extract filename for default Name and Description
    [~, name] = fileparts(filename);
    if isempty(props.Name)
        props.Name = name;
    end
    if isempty(props.Description)
        props.Description = name;
    end    
    % Create cTableData object from imported values
    tbl = cTableData.create(values, props);
end

function tbl = importXLSX(filename, props)
%importXLSX - Import Excel (XLSX) file to cTableData object
%   Internal helper function for Excel file processing
    tbl = cTaesLab();   
    % Open Excel file and get sheet names using platform-specific function
    if isOctave
        try
            xls = xlsopen(filename);
            shts = xls.sheets.sh_names;
        catch err
            tbl.printError(err.message);
            tbl.printError(cMessages.FileNotRead, filename);
            return
        end
    else % MATLAB
        try
            shts = sheetnames(filename);
            xls = filename;
        catch err
            tbl.printError(err.message);
            tbl.printError(cMessages.FileNotRead, filename);
            return
        end
    end    
    % Determine which sheet to import
    wsht = props.Sheet;
    if isempty(wsht)
        wsht = shts{1};  % Use first sheet if not specified
    end   
    % Validate that the specified sheet exists
    if ~ismember(wsht, shts)
        tbl.printError(cMessages.SheetNotExist, wsht);
        return
    end   
    % Read sheet data using platform-specific function
    if isOctave
        try
            values = xls2oct(xls, wsht);
        catch err
            tbl.printError(err.message);
            return
        end
    else % MATLAB
        try
            values = readcell(xls, 'Sheet', wsht);
        catch err
            tbl.printError(err.message);
            return
        end
    end   
    % Set default Name and Description to sheet name if not provided
    if isempty(props.Name)
        props.Name = wsht;
    end
    if isempty(props.Description)
        props.Description = wsht;
    end   
    % Create cTableData object from imported values
    tbl = cTableData.create(values, props);
end