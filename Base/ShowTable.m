function res=ShowTable(tbl,varargin)
%ShowTable - Show, export or save a table object in diferent ways 
%   A table could be shown in the console, web browser or GUI table depending the 'View' option.
%   Tables could be also exported or save into file with options 'ExportAs', 'SaveAs'
%
%   Syntax
%     ShowTable(tbl,Name,Value)
%
%   Input Argument
%     tbl - cTable object
%
%   Name-Value Arguments
%     View: Select the way to show the table
%       CONSOLE - show in console (default)
%       GUI - use uitable
%       HTML- use web browser
%     ExportAs: Select the VarMode to output the ResultSet/Table
%       NONE - return the cTable object (default)
%       CELL - return the table as cell array
%       STRUCT - return the table as structured array
%       TABLE - return a matlab table
%     SaveAs: Save the table in an external file. 
%   
%   Output Arguments
%     res - table object in the format specified in ExportAs
%  
% See also cTable
%
    log=cStatus();
    % Check input
    checkTable=@(x) isa(x,'cTable');
    p = inputParser;
    p.addRequired('tbl',checkTable);
    p.addParameter('View',cType.DEFAULT_TABLEVIEW,@cType.checkTableView);
	p.addParameter('ExportAs',cType.DEFAULT_VARMODE,@cType.checkVarMode);
	p.addParameter('SaveAs','',@isFilename);
    try
		p.parse(tbl,varargin{:});
    catch err
        log.printError(err.message);
        log.printError('Usage: ShowTable(tbl,options)');
        return
    end
    param=p.Results;
    if ~isValid(tbl)
        tbl.printLogger;
        return
    end
    % Export the table
    if nargout>0
        option=cType.getVarMode(param.ExportAs);
        res=exportTable(tbl,option);
    end
    % Save table 
    if ~isempty(param.SaveAs)
        SaveTable(tbl,param.SaveAs);
    end
    % View the table
    option=cType.getTableView(param.View);
    tbl.showTable(option);
end