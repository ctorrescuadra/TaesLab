function res=ListResultTables(varargin)
%ListResultTables - Displays the list of the TaesLab result tables and their properties.
%   If a cResultSet is provided, the active tables of the results set are listed.
%    
%   Syntax
%     res=ListResultTables(Name,Values)
%     res=ListResultTables(res,Name,Values)
%
%   Input Arguments
%     res - cResultSet object (optional)
%
%   Name-Values Arguments
%     Columns: Array of cells with the names of the columns to be displayed.
%       'DESCRIPTION' Description of the table
%       'RESULT_NAME' cResultInfo name of the table
%       'GRAPH' - Indicates if it has graphical representation
%       'TYPE' - Type of cTable
%       'CODE' - Text of the code for cType.Tables
%       'RESULT_CODE' - Text of the code for cType.ResultId
%       If it is not selected, the default list of columns cType.DIR_COLS_DEFAULT is shown
%     View: Selects how to show the table
%       'CONSOLE' - display in the console (default)
%       'GUI' - use a GUI table
%       'HTML' - use a web browser
%     ExportAs: Select the VarMode to get the table
%       'NONE' - return the cTable object (default)
%       'CELL' - return the table as array of cells
%       'STRUCT' - returns the table as a structured array
%       'TABLE' - returns a matlab table
%     SaveAs: Name of the file where the table will be saved.
%       array char | string
%
%   Output Arguments
%     res - Table object in the format specified in ExportAs, with the selected columns
%
%   Example
%     <a href="matlab:open TableInfoDemo.mlx">Tables Info Demo</a>
%
%   See also cTablesDefinition, cThermoeconomicModel
%
    res=cMessageLogger();
    % Check the variable arguments
    isResultSet=false;
    if nargin>0 && isObject(varargin{1},'cResultSet')
        isResultSet=true;
        arg=varargin{1};
        varargin=varargin(2:end);
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
        res.printError(cMessages.ShowHelp);
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
        ctd=cTablesDefinition;
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