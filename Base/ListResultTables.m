function res=ListResultTables(varargin)
% ListResultTables shows the list of the result tables of TaesLab
%   USAGE:
%       res=ListResultTables(options)
%   INPUT:
%       options - an structure contains additional parameters
%           View: Select the way to show the table
%               CONSOLE - show in console (default)
%               GUI - use uitable
%               HTML- use web browser
%           ExportAs: Select the VarMode to output the table
%               NONE - return the cTable object (default)
%               CELL - return the table as cell array
%               STRUCT - return the table as structured array
%               TABLE - return a matlab table
%           SaveAs: Save the table in an external file. 
%               If it is empty the table is not save
%           Columns: Cell Array with column names to show.
%               If it is empty the default list of columns
%               cType.DirColsDefault is shown
%               DESCRIPTION - Table description
%               RESULT_NAME - cResultInfo name of the table
%               GRAPH - Indicate if have graph representation
%               TYPE - Type of cTable
%               CODE - Code text for cType.Tables
%               RESULT_CODE - Code Text for cType.ResultId
%   OUTPUT:
%       res - table object in the format specified in ExportAs
%               and the selected columns
%
    log=cStatusLogger(cType.ERROR);
    % Check input parameters
    p = inputParser;
    p.addParameter('View',cType.DEFAULT_TABLEVIEW,@cType.checkTableView);
	p.addParameter('ExportAs',cType.DEFAULT_VARMODE,@cType.checkVarMode);
	p.addParameter('SaveAs','',@ischar);
    p.addParameter('Columns',cType.DirColsDefault,@iscell)
    try
		p.parse(varargin{:});
    catch err
        log.printError(err.message);
        log.printError('Usage: ViewTable(arg,options)');
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
    option=cType.getTableView(param.View);
    viewTable(tbl,option);
    % Save table 
    if ~isempty(param.SaveAs)
        log=saveTable(tbl,param.SaveAs);
        log.printLogger;
    end
end