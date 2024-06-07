function res = ExportResults(arg,varargin)
% ExportResults exports the results tables to different formats.
%  USAGE:
%   res=ExportResults(arg,options)
%  INPUT:
%   arg - cResultSet object
%   options - a structure containing additional parameters (optional)
%       Table: Name of the table to export. If it is not selected a structure with all
%              results tables is created
%       ExportAs: Selects the output VarMode of the table/s.
%        NONE - returns the cTable object (default).
%        CELL - returns the table as an array of cells.
%        STRUCT - returns the table as a structured array.
%        TABLE - returns a matlab table object.
%       Format: true/false. Use table format
%  OUTPUT:
%   res - Table/s in the format specified by ExportAs.
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