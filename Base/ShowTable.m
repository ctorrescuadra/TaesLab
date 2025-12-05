function res=ShowTable(tbl,varargin)
%ShowTable - Show, export, or save a table.
%  Depending on the “View” option, a table can be displayed in different ways: 
%  in the console, in a web browser, or in a GUI table.
%  Tables can be exported or saved into a file using the 'ExportAs' and 'SaveAs' options.
%
%   Syntax:
%     res=ShowTable(tbl,Name,Value)
%
%   Input Arguments:
%     tbl - cTable object
%
%   Name-Value Arguments:
%     View: Select the way to show the table
%      'CONSOLE' - show in console (default)
%      'GUI'     - use uitable
%      'HTML'    - use web browser
%     ExportAs: Select the VarMode to output the ResultSet/Table
%      'CELL'   - return the table as cell array
%      'STRUCT' - return the table as structured array
%      'TABLE'  - return a matlab table
%     SaveAs: Name of the file wheSave the table in an external file. 
%   
%   Output Arguments:
%     res - table object in the format specified in ExportAs
%
%   Example:
%     <a href="matlab:open TableInfoDemo.mlx">Tables Info Demo</a>
% 
%   See also cTable
%
    log=cTaesLab();
    if nargin<1 || ~isObject(tbl,'cTable')
        log.printError(cMessages.TableRequired,cMessages.ShowHelp);
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