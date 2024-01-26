function res=ShowResults(arg,varargin)
% ShowResults shows the tables results, export and save them in diferent format
%   USAGE:
%       res=ShowResults(arg,options)
%   INPUT:
%       arg - cResultInfo or cThermoeconomicModel
%       options - an structure contains additional parameters
%           Table: Name of the table to show. 
%               If empty print on console all the results tables
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
%   OUTPUT:
%       res - table object in the format specified in ExportAs
%  
% See also cResultInfo, cThermoeconomicModel
%
    log=cStatusLogger(cType.ERROR);
    if nargin<1
        log.printError('Usage: ShowResults(res)');
		return
    end
    % Check Input parameters
	if ~(isa(arg,'cThermoeconomicModel') || isa(arg,'cResultInfo')) || ~isValid(arg)
		log.printError('Invalid result parameter');
		return
	end
    % Check input parameters
    p = inputParser;
    p.addParameter('Table','',@ischar);
    p.addParameter('View',cType.DEFAULT_TABLEVIEW,@cType.checkTableView);
	p.addParameter('ExportAs',cType.DEFAULT_VARMODE,@cType.checkVarMode);
	p.addParameter('SaveAs','',@ischar);
    try
		p.parse(varargin{:});
    catch err
        log.printError(err.message);
        log.printError('Usage: ViewTable(arg,options)');
        return
    end
    param=p.Results;
    % If table is empty printResults
    if isempty(param.Table)
        printResults(arg);
        return
    end
    % Get table
    tbl=getTable(arg,param.Table);
    if ~isValid(tbl)
        tbl.printLogger;
        return
    end
    % Export the table
    if nargout>0
        option=cType.getVarMode(param.ExportAs);
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