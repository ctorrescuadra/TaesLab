function ShowResults(arg,varargin)
%ShowResults - Display and save result tables from thermoeconomic analyses.
%   ShowResults is the primary console interface for displaying results from 
%   TaesLab analyses. It provides flexible output options including console display,
%   web browser HTML rendering, and GUI table viewers. Results can be shown either
%   as complete result sets or as individual tables, with optional persistence to 
%   various file formats.
%
%   This function operates in two modes:
%   1. Result Set Mode (default): When 'Table' is not specified, all tables in the
%      result set are processed. Use 'Panel' option for interactive table selection.
%   2. Single Table Mode: When 'Table' is specified, only that table is displayed
%      according to the 'View' option (CONSOLE/HTML/GUI).
%
%   The function supports simultaneous display and export operations through the
%   'SaveAs' parameter, enabling efficient result documentation workflows.
%
%   Syntax:
%     ShowResults(resultSet)
%     ShowResults(resultSet, 'Table', tableName)
%     ShowResults(resultSet, 'View', viewType)
%     ShowResults(resultSet, 'Table', tableName, 'View', viewType, 'SaveAs', filename)
%   
%   Input Arguments:
%     resultSet - Result container from analysis functions (cResultSet)
%                 Objects typically returned by ExergyAnalysis, ThermoeconomicAnalysis,
%                 ThermoeconomicDiagnosis, WasteAnalysis, or cThermoeconomicModel methods
%
%   Name-Value Arguments: 
%     'Table' - Specific table name to display (char array, default: empty)
%               When empty, displays all tables in the result set
%               Use 'tindex' to show the table of contents with all available table names
%               Table names are case-sensitive and defined in printformat.json
%
%     'View' - Display format for tables (char array, default: 'CONSOLE')
%              'CONSOLE' - Formatted text output in MATLAB command window
%              'HTML'    - Opens table in system web browser with CSS styling
%              'GUI'     - Interactive uitable viewer (MATLAB only, not Octave compatible)
%
%     'Panel' - Launch interactive Results Panel for table selection (logical, default: false)
%               When true, opens ResultsPanel GUI for browsing all tables
%               Ignored if 'Table' parameter is specified
%               Requires MATLAB with GUI support
%
%     'SaveAs' - Export results to file (char/string, default: empty)
%                File format determined by extension:
%                  .xlsx - Excel workbook with separate sheets per table
%                  .csv  - CSV file (single table) or directory of CSV files (result set)
%                  .json - JSON structured data
%                  .mat  - MATLAB binary format
%                  .html - HTML document with embedded CSS
%                  .tex  - LaTeX document
%                  .md   - Markdown document
%
%   Examples:
%     % Display all exergy analysis results in console
%     model = ThermoeconomicModel('rankine_model.json');
%     results = model.exergyAnalysis();
%     ShowResults(results);
%
%     % Show specific table in web browser
%     ShowResults(results, 'Table', 'dcost', 'View', 'HTML');
%
%     % Interactive panel with export to Excel
%     ShowResults(results, 'Panel', true, 'SaveAs', 'analysis.xlsx');
%
%     % Display table index to see available tables
%     ShowResults(results, 'Table', 'tindex');
%
%   Live Script Demo:
%     <a href="matlab:open ShowResultsDemo.mlx">Show Results Demo</a>
%
%   See also SaveResults, ShowTable, ResultsPanel, ViewResults, cResultSet, 
%   ExergyAnalysis, ThermoeconomicAnalysis, cResultInfo
%
    log = cTaesLab(); 
    % Validate required input argument
	if nargin < 1
		log.printError(cMessages.NarginError, cMessages.ShowHelp);
	end	    
    % Ensure input is a valid cResultSet object (from analysis functions)
	if ~isObject(arg, 'cResultSet')
		log.printError(cMessages.ResultSetRequired, cMessages.ShowHelp);
		return
	end  
    % Configure input parser with validation functions
    p = inputParser;
    p.addParameter('Table', cType.EMPTY_CHAR, @ischar);           % Table name or empty for all
    p.addParameter('View', cType.DEFAULT_TABLEVIEW, @cType.checkTableView);  % Display format
    p.addParameter('Panel', false, @islogical);                    % Interactive panel flag
	p.addParameter('SaveAs', cType.EMPTY_CHAR, @isFilename);      % Output file path   
    % Parse name-value pairs and handle validation errors
    try
		p.parse(varargin{:});
    catch err
        log.printError(err.message);
        return
    end
    % Extract parsed parameters
    param = p.Results;
    
    % Convert view type string to numeric option code
    option = cType.getTableView(param.View);   
    % Display results using appropriate interface
    if isempty(param.Table) %Process entire result set
        if param.Panel % Launch interactive Results Panel for table browsing
            ResultsPanel(arg);
        elseif option > 0
            % Print all tables to console with current view settings
            printResults(arg);
        end        
        % Persist entire result set to file if SaveAs specified
        if ~isempty(param.SaveAs)
            SaveResults(arg, param.SaveAs);
        end
    else %Retrieve requested table from result set
        tbl = getTable(arg, param.Table);       
        % Verify table exists and is valid
        if ~tbl.status
            % Print any error messages from table retrieval
            printLogger(tbl);
            return
        end        
        % Display table using specified view option
        showTable(tbl, option);        
        % Export individual table to file if requested
        if ~isempty(param.SaveAs)
            SaveTable(tbl, param.SaveAs);
        end
    end
end
