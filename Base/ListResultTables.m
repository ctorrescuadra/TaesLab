function res=ListResultTables(varargin)
%ListResultTables - Shows the list of existing result tables in TaesLab and their properties.
%   This function lets to select where to display this table using the option 'Show',
%   export the table in diferent formats selecting the option 'ExportAs' or 'SaveAs' external file
%   and to select the columns with the table properties with option 'Columns'
%   
%   Syntax
%     res=ListResultTables(Name,Values)
%
%   Name-Values Arguments
%     Show: Selects how to show the table
%       CONSOLE - display in the console (default)
%       GUI - use a GUI table
%       HTML - use a web browser
%     ExportAs: Select the VarMode to get the table
%       NONE - return the cTable object (default)
%       CELL - return the table as array of cells
%       STRUCT - returns the table as a structured array
%       TABLE - returns a matlab table
%     Columns: Array of cells with the names of the columns to be displayed.
%                If it is not selected, the default list of columns cType.DirColsDefault is shown
%        DESCRIPTION - Description of the table
%        RESULT_NAME - cResultInfo name of the table
%        GRAPH - Indicates if it has graphical representation % TYPE - Type of cTable
%        TYPE - Type of cTable
%        CODE - Text of the code for cType.Tables
%        RESULT_CODE - Text of the code for cType.ResultId
%     SaveAs: indicates the name of the file where the table will be saved.
%
%   Output Arguments
%     res - table object in the format specified in ExportAs, with the selected columns
%
% See also cTablesDefinition
%
    res=cStatus();
    % Check input parameters
    p = inputParser;
    p.addParameter('Show',cType.DEFAULT_TABLEVIEW,@cType.checkTableView);
	p.addParameter('ExportAs',cType.DEFAULT_VARMODE,@cType.checkVarMode);
	p.addParameter('SaveAs','',@isFilename);
    p.addParameter('Columns',cType.DirColsDefault,@iscell)
    try
		p.parse(varargin{:});
    catch err
        res.printError(err.message);
        res.printError('Usage: res=ListResultTables(options)');
        return
    end
    param=p.Results;
    obj=cTablesDefinition;
    tbl=obj.getTablesDirectory(param.Columns);
    if ~isValid(tbl)
        printLogger(tbl);
        return
    end
    % Export the table
    option=cType.getVarMode(param.ExportAs);
    if nargout>0
        res=exportTable(tbl,option);
    end
    % View the table
    option=cType.getTableView(param.Show);
    showTable(tbl,option);
    % Save table 
    if ~isempty(param.SaveAs)
        SaveTable(tbl,param.SaveAs);
    end
end