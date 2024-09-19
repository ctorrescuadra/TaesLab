function res=ShowTable(tbl,varargin)
%ShowTable - Allows to display, export or save a table object.
%   Depending on the ' View ' option, a table can be displayed in different ways: 
%   in the console, in a web browser or in a GUI table.
%   Tables can be exported or saved to a file with the 'ExportAs' and 'SaveAs' options.
%
% Syntax
%   res=ShowTable(tbl,Name,Value)
%
% Input Argument
%   tbl - cTable object
%
% Name-Value Arguments
%   View: Select the way to show the table
%     'CONSOLE' - show in console (default)
%     'GUI' - use uitable
%     'HTML' - use web browser
%   ExportAs: Select the VarMode to output the ResultSet/Table
%     'NONE' - return the cTable object (default)
%     'CELL' - return the table as cell array
%     'STRUCT' - return the table as structured array
%     'TABLE' - return a matlab table
%   SaveAs: Save the table in an external file. 
%   
% Output Arguments
%   res - table object in the format specified in ExportAs
%
% Example
%   <a href="matlab:open TableInfoDemo.mlx">Tables Info Demo</a>
% 
% See also cTable
%
    log=cMessageLogger();
    if nargin<1 || ~isObject(tbl,'cTable')
        log.printError('First Argument must be a Table')
        log.printError('Usage: ShowTable(arg,options)');
        return
    end
    if nargout 
        defaultView='NONE';
    else
        defaultView='CONSOLE';
    end
    % Check input
    p = inputParser;
    p.addParameter('View',defaultView,@cType.checkTableView);
	p.addParameter('ExportAs',cType.DEFAULT_VARMODE,@cType.checkVarMode);
	p.addParameter('SaveAs',cType.EMPTY_CHAR,@isFilename);
    try
		p.parse(varargin{:});
    catch err
        log.printError(err.message);
        log.printError('Usage: ShowTable(tbl,options)');
        return
    end
    param=p.Results;
    % Export the table
    if nargout>0
        option=cType.getVarMode(param.ExportAs);
        res=exportTable(tbl,option);
    end
    % View the table
    option=cType.getTableView(param.View);
    tbl.showTable(option);
    % Save table 
    if ~isempty(param.SaveAs)
        log=saveTable(tbl,param.SaveAs);
        printLogger(log)
    end
end