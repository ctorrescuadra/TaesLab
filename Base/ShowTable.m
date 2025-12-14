function res=ShowTable(tbl,varargin)
%ShowTable - Display, export, and save individual result tables.
%   ShowTable provides flexible table presentation and data export capabilities
%   for cTable objects. Tables can be displayed in multiple formats (console,
%   web browser, GUI), exported to MATLAB variables in various structures, and
%   saved to external files in different formats.
%
%   This function operates in three modes simultaneously:
%   1. Display Mode: Shows the table using specified View option (CONSOLE/HTML/GUI)
%   2. Export Mode: Returns table data in specified format when output is requested
%   3. Persistence Mode: Saves table to file when SaveAs is specified
%
%   The function automatically adjusts default behavior based on output arguments:
%   - With output argument: Suppresses display by default (View='NONE')
%   - Without output argument: Displays in console by default (View='CONSOLE')
%
%   Syntax:
%     ShowTable(tableObj)
%     ShowTable(tableObj, 'View', viewType)
%     ShowTable(tableObj, 'SaveAs', filename)
%     result = ShowTable(tableObj, 'ExportAs', format)
%     result = ShowTable(tableObj, 'View', viewType, 'ExportAs', format, 'SaveAs', filename)
%
%   Input Arguments:
%     tableObj - Table object to display/export (cTable)
%                Can be any cTable subclass: cTableCell, cTableMatrix, cTableData
%                Typically obtained from result sets using getTable(resultSet, tableName)
%
%   Name-Value Arguments:
%     'View' - Display format for table visualization (char array)
%              'CONSOLE' - Formatted text output in command window (default when no output)
%              'HTML'    - Opens table in web browser with CSS styling
%              'GUI'     - Interactive uitable viewer (MATLAB only, not Octave)
%              'NONE'    - No display output (default when output argument present)
%              View option is automatically set to 'NONE' when function is called
%              with an output argument to avoid redundant console display
%
%     'ExportAs' - Format for returned table data (char array, default: 'CELL')
%                  Only applies when function is called with output argument
%                  'CELL'   - Returns table as cell array (default)
%                             Preserves mixed data types, most flexible format
%                  'STRUCT' - Returns table as MATLAB structure array
%                             Field names from column headers, one struct per row
%                  'TABLE'  - Returns MATLAB table object
%                             Native table format, supports column operations
%
%     'SaveAs' - Export table to external file (char/string, default: empty)
%                File format determined by extension:
%                  .xlsx - Excel workbook (single sheet)
%                  .csv  - Comma-separated values file
%                  .json - JSON structured data
%                  .mat  - MATLAB binary format
%                  .html - HTML document with embedded CSS
%                  .tex  - LaTeX document
%                  .md   - Markdown document
%   
%   Output Arguments:
%     result - Table data in format specified by ExportAs parameter
%              Only returned when function is called with output argument
%              Format depends on ExportAs option (cell/struct/table)
%
%   Examples:
%     % Display table in console (default behavior)
%     model = ThermoeconomicModel('rankine_model.json');
%     results = model.exergyAnalysis();
%     tbl = getTable(results, 'dcost');
%     ShowTable(tbl);
%
%     % Display table in web browser with HTML formatting
%     ShowTable(tbl, 'View', 'HTML');
%
%     % Export table to MATLAB table object without display
%     T = ShowTable(tbl, 'ExportAs', 'TABLE');
%
%     % Display in console and save to Excel file
%     ShowTable(tbl, 'SaveAs', 'cost_table.xlsx');
%
%     % Export to cell array with display and file save
%     cellData = ShowTable(tbl, 'View', 'CONSOLE', 'ExportAs', 'CELL', 'SaveAs', 'data.csv');
%
%     % Interactive GUI viewer (MATLAB only)
%     ShowTable(tbl, 'View', 'GUI');
%
%   Live Script Demo:
%     <a href="matlab:open TableInfoDemo.mlx">Tables Info Demo</a>
% 
%   See also ShowResults, , cTable, cTableCell, cTableMatrix,
%   SaveTable, ExportResults, cResultSet/getTable
%
%
    % Initialize message logger for error reporting
    log = cTaesLab();
    
    % Validate input: ensure table argument exists and is a valid cTable object
    if nargin < 1 || ~isObject(tbl, 'cTable')
        log.printError(cMessages.TableRequired, cMessages.ShowHelp);
        return
    end
    
    % Set default View behavior based on whether output is requested
    % When output is requested, suppress display to avoid redundancy
    if nargout 
        defaultView = 'NONE';      % No display when exporting to variable
    else
        defaultView = 'CONSOLE';   % Show in console when not exporting
    end
    % Configure input parser with display, export, and save parameters
    p = inputParser;
    p.addParameter('View', defaultView, @cType.checkTableView);         % Display mode
	p.addParameter('ExportAs', cType.DEFAULT_VARMODE, @cType.checkVarMode); % Export format
	p.addParameter('SaveAs', cType.EMPTY_CHAR, @isFilename);            % File path
    % Parse name-value pairs and handle validation errors
    try
		p.parse(varargin{:});
    catch err
        log.printError(err.message);
        return
    end 
    % Extract parsed parameters
    param = p.Results;
    % === EXPORT MODE: Return table data in requested format ===
    % Only executes when function is called with output argument
    if nargout > 0
        % Convert ExportAs string to numeric format code
        option = cType.getVarMode(param.ExportAs);       
        % Export table to specified format (cell array, struct, or MATLAB table)
        res = exportTable(tbl, option);
    end    
    % === DISPLAY MODE: Render table using specified view option ===
    % Convert View string to numeric option code
    option = cType.getTableView(param.View);    
    % Display table using appropriate renderer (console/HTML/GUI/none)
    tbl.showTable(option);  
    % === PERSISTENCE MODE: Save table to external file ===
    % Only executes when SaveAs parameter is specified
    if ~isempty(param.SaveAs)
        % Save table to file and capture operation log
        log = saveTable(tbl, param.SaveAs);       
        % Print any messages (success/warning/error) from save operation
        printLogger(log)
    end
end
