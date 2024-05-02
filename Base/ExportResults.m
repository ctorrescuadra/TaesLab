function res = ExportResults(arg,varargin)
% ShowResults shows the tables results, export and save them in diferent format
%   USAGE:
%       res=ShowResults(arg,options)
%   INPUT:
%       arg - cResultSet object
%       options - an structure contains additional parameters
%           Table: Name of the table to show. 
%           ExportAs: Select the VarMode to output the table
%               NONE - return the cTable object (default)
%               CELL - return the table as cell array
%               STRUCT - return the table as structured array
%               TABLE - return a matlab table
%           Format: true/false. Use table formatted
%   OUTPUT:
%       res - table object in the format specified in ExportAs
%  
% See also cResultSet
%
    log=cStatusLogger(cType.ERROR);
    % Check input
    checkModel=@(x) isa(x,'cResultSet');
    p = inputParser;
    p.addRequired('arg',checkModel);
    p.addParameter('Table','',@ischar);
	p.addParameter('ExportAs',cType.DEFAULT_VARMODE,@cType.checkVarMode);
	p.addParameter('Format',false,@islogical);
    try
		p.parse(arg,varargin{:});
    catch err
        log.printError(err.message);
        log.printError('Usage: ViewTable(arg,options)');
        return
    end
    param=p.Results;
    varmode=cType.getVarMode(param.ExportAs);
    % Export tables
    if isempty(param.Table)
        names=arg.getListOfTables;
        tables=cellfun(@(x) exportTable(arg,x,varmode,param.Format),names,'UniformOutput',false);
        res=cell2struct(tables,names,1);
        return
    else
        name=param.Table;
        tbl=arg.getTable(name);
        if isValid(tbl)
            res=tbl.exportTable(varmode,param.Format);
        else
            log.printError('Table %s is not available',name);
        end
    end
end