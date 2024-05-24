function res=ShowResults(arg,varargin)
% ShowResults shows the tables results, export and save them in diferent format
%   USAGE:
%       res=ShowResults(arg,options)
%   INPUT:
%       arg - cResultSet object
%       options - an structure contains additional parameters
%           Table: Name of the table to show. 
%               If empty print on console all the results tables
%           View: Select the way to show the table
%               CONSOLE - show in console (default)
%               GUI - use uitable
%               HTML- use web browser
%           Index: (false/true) Use the Table Index panel to select the tables
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
    % Check input
    checkModel=@(x) isa(x,'cResultSet');
    p = inputParser;
    p.addRequired('arg',checkModel);
    p.addParameter('Table','',@ischar);
    p.addParameter('View',cType.DEFAULT_TABLEVIEW,@cType.checkTableView);
    p.addParameter('Index',false,@islogical);
	p.addParameter('ExportAs',cType.DEFAULT_VARMODE,@cType.checkVarMode);
	p.addParameter('SaveAs','',@ischar);
    try
		p.parse(arg,varargin{:});
    catch err
        log.printError(err.message);
        log.printError('Usage: ViewTable(arg,options)');
        return
    end
    param=p.Results;
    % If table is empty printResults or use TablesPanel
    if isempty(param.Table)
        if param.Index
            tp=cTablesPanel(param.View);
            tp.setIndexTable(arg);
        else
            printResults(arg);
        end   
    else
    % Select the table to show
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
        showTable(tbl,option);
        % Save table 
        if ~isempty(param.SaveAs)
            log=saveTable(tbl,param.SaveAs);
            log.printLogger;
        end
    end
end