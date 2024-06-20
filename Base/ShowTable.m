function res=ShowTable(tbl,varargin)
% ShowTable let the show, export or save a table object in diferent formats 
%  A table could be shown in the console, web browser or GUI table depending the 'View' option.
%  Tables could be also exported or save into file with options 'ExportAs', 'SaveAs'
%
% USAGE:
%   ShowTable(tbl,options)
% INPUT:
%   tbl - cTable object
%   options - an structure contains additional parameters
%    View: Select the way to show the table
%     CONSOLE - show in console (default)
%     GUI - use uitable
%     HTML- use web browser
%    ExportAs: Select the VarMode to output the ResultSet/Table
%     NONE - return the cTable object (default)
%     CELL - return the table as cell array
%     STRUCT - return the table as structured array
%     TABLE - return a matlab table
%    SaveAs: Save the table in an external file. 
%   
%   OUTPUT:
%       res - table object in the format specified in ExportAs
%  
% See also cResultInfo, cResultSet
%
    log=cStatus(cType.VALID);
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
        log.printError('Usage: ViewTable(arg,options)');
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