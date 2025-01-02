function res=ListResultTables(varargin)
%ListResultTables - Displays the list of existing TaesLab result tables and their properties.
%   The 'Show' option allows to select how the table will be displayed. 
%   The 'ExportAs' option allows you to export the table in different formats.
%   The 'SaveAs' option allows you to save the table as an external file.
%   The 'Columns' option allows you to select the columns of the table.
%   If a thermoeconomic model is provided, the active tables of the model are listed.
%    
% Syntax
%  res=ListResultTables(Name,Values)
%  res=ListResultTables(model,Name,Values)
%
% Input Arguments
%   model - cThermoeconomicModel object (optional)
%
% Name-Values Arguments
%   View: Selects how to show the table
%     CONSOLE - display in the console (default)
%     GUI - use a GUI table
%     HTML - use a web browser
%   ExportAs: Select the VarMode to get the table
%     NONE - return the cTable object (default)
%     CELL - return the table as array of cells
%     STRUCT - returns the table as a structured array
%     TABLE - returns a matlab table
%   Columns: Array of cells with the names of the columns to be displayed.
%     DESCRIPTION - Description of the table
%     RESULT_NAME - cResultInfo name of the table
%     GRAPH - Indicates if it has graphical representation
%     TYPE - Type of cTable
%     CODE - Text of the code for cType.Tables
%     RESULT_CODE - Text of the code for cType.ResultId
%    If it is not selected, the default list of columns cType.DIR_COLS_DEFAULT is shown
% SaveAs: Indicates the name of the file where the table will be saved.
%
% Output Arguments
%   res - table object in the format specified in ExportAs, with the selected columns
%
% Example
%   <a href="matlab:open TableInfoDemo.mlx">Tables Info Demo</a>
%
% See also cTablesDefinition, cThermoeconomicModel
%
    res=cMessageLogger();
    % Check if model is provided
    isModel=false;
    if nargin>0 && isObject(varargin{1},'cThermoeconomicModel')
        isModel=true;
        model=varargin{1};
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
    % Build the Tables directory 
    if isModel
        model.setDebug(false);
        tbl=model.getTablesDirectory(param.Columns);
    else
        ctd=cTablesDefinition;
        tbl=ctd.getTablesDirectory(param.Columns);
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