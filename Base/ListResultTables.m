function res = ListResultTables(varargin)
%ListResultTables - Display catalog of available result tables and their properties.
%   Lists all available result tables in the TaesLab system or shows the active
%   tables for a specific result set object. This is useful for discovering what
%   tables are available, understanding their purpose, and determining which tables
%   support graphical representations. The function can display a comprehensive
%   catalog of all defined tables or filter to show only tables present in a
%   specific analysis result.
%
%   When called without a cResultSet object, displays the complete table catalog
%   from cTablesDefinition. When called with a result object, shows only the
%   tables that are actually present in that result set.
%    
%   Syntax:
%     ListResultTables()
%     ListResultTables(Name, Value)
%     ListResultTables(resultObject)
%     ListResultTables(resultObject, Name, Value)
%     res = ListResultTables(...)
%
%   Input Arguments:
%     resultObject - cResultSet object (optional)
%       Any object derived from cResultSet including cModelResults, cResultInfo,
%       cDataModel, or cThermoeconomicModel. When provided, the listing shows only
%       the tables that exist in this specific result object. Without this argument,
%       the function shows the complete catalog of all available table types.
%
%   Name-Value Arguments:
%     Columns - Properties to display for each table
%       cell array of char (default: cType.DIR_COLS_DEFAULT)
%       Specifies which information columns to show for each table. Available columns:
%         'DESCRIPTION' - Full description of table content and purpose
%         'RESULT_NAME' - Name of the cResultInfo category containing the table
%         'GRAPH'       - Indicates if table has graphical representation available
%         'TYPE'        - Type of cTable (cTableCell, cTableMatrix, cTableData)
%         'CODE'        - Internal code identifier from cType.Tables enumeration
%         'RESULT_CODE' - Analysis type code from cType.ResultId enumeration
%       If not specified, uses the default column set defined in cType.DIR_COLS_DEFAULT.
%
%     View - Display method for the table listing
%       'CONSOLE' (default) | 'GUI' | 'HTML'
%       Controls how the table catalog is presented:
%         'CONSOLE' - Formatted text output in command window
%         'GUI'     - Interactive table viewer window
%         'HTML'    - Web browser display with styled formatting
%       Default is 'CONSOLE' unless output is captured (nargout > 0).
%
%     ExportAs - Format for returned data when capturing output
%       'NONE' (default) | 'CELL' | 'STRUCT' | 'TABLE'
%       When the function output is assigned to a variable, controls the format:
%         'NONE'   - Returns cTable object with full functionality
%         'CELL'   - Cell array with headers and data
%         'STRUCT' - Structured array with named fields
%         'TABLE'  - MATLAB table object (requires R2013b+)
%
%     SaveAs - Save the table catalog to a file
%       char array | string (default: empty - no save)
%       File path for saving the table listing. Format is determined by extension:
%       .xlsx, .csv, .json, .html, .tex, .md supported. Useful for documentation
%       or external reference.
%
%   Output Arguments:
%     res - Table catalog data (only when output is captured)
%       cTable object containing the table directory with selected columns.
%       Format depends on 'ExportAs' parameter. If no output is requested,
%       the table is displayed according to 'View' parameter instead.
%
%   Examples:
%     % Show complete catalog of all available tables in console
%     ListResultTables()
%
%     % Show tables available in a specific result object
%     results = model.thermoeconomicAnalysis();
%     ListResultTables(results)
%
%     % Display with custom columns in HTML viewer
%     ListResultTables('Columns', {'DESCRIPTION', 'GRAPH', 'TYPE'}, 'View', 'HTML')
%
%     % Capture table catalog as MATLAB table for processing
%     tableCatalog = ListResultTables('ExportAs', 'TABLE');
%
%     % Export catalog to Excel file
%     ListResultTables('SaveAs', 'table_catalog.xlsx')
%
%   Live Script Demo:
%     <a href="matlab:open TableInfoDemo.mlx">Tables Info Demo</a>
%
%   See also cTablesDefinition, cResultSet, cThermoeconomicModel, ExportResults, ShowResults.
%
    res=cTaesLab();
    % Check the variable arguments
    if nargin==0
        isResultSet=false;
    elseif isObject(varargin{1},'cResultSet')
        isResultSet=true;
        arg=varargin{1};
        varargin=varargin(2:end);
    else
        res.printError(cMessages.ResultSetRequired,cMessages.ShowHelp);
        return
    end
    % Select View depending of nargout
    if nargout 
        defaultView='NONE';
    else
        defaultView='CONSOLE';
    end
    % Check input parameters
    p = inputParser;
    p.addParameter('View',defaultView,@cType.checkTableView);
	p.addParameter('ExportAs',cType.DEFAULT_VARMODE,@cType.checkVarMode);
	p.addParameter('SaveAs',cType.EMPTY_CHAR,@isFilename);
    p.addParameter('Columns',cType.DIR_COLS_DEFAULT,@iscell)
    try
		p.parse(varargin{:});
    catch err
        res.printError(err.message);
        return
    end
    param=p.Results;
    % Get the table index or table directory
    if isResultSet
        switch arg.ClassId
            case cType.ClassId.RESULT_MODEL
                arg.setDebug(false);
                tbl=arg.getTablesDirectory(param.Columns);
            case cType.ClassId.DATA_MODEL
                tbl=arg.getTableIndex;
            case cType.ClassId.RESULT_INFO
                tbl=arg.getTableIndex;
        end
    else
        ctd=cTablesDefinition; % Get the complete tables definition
        if ctd.status
            tbl=ctd.getTablesDirectory(param.Columns);
            if ~tbl.status
                printLogger(tbl);
                res.printError(cMessages.InvalidTableDefinition)
                return
            end
        else
            printLogger(ctd);
            res.printError(cMessages.InvalidTableDefinition)
            return
        end
    end
    if ~tbl.status
        printLogger(tbl);
        return
    end
    % Export the table
    option=cType.getVarMode(param.ExportAs);
    if nargout>0
        res=exportTable(tbl,option);
        return
    end
    % View the table
    option=cType.getTableView(param.View);
    showTable(tbl,option);
    % Save table 
    if ~isempty(param.SaveAs)
        SaveTable(tbl,param.SaveAs);
    end
end