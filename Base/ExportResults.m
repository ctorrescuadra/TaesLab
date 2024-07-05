function res = ExportResults(arg,varargin)
%ExportResults - Exports the results tables in the selected format.
%   If the 'Table' option is not used, the function returns a structure with all tables converted to the desired format. 
%   If the 'Table' option is selected, it returns the table in the desired format.
%
%   Syntax
%     res=ExportResults(arg,Name,Value)
%  
%   Input Arguments
%     arg - cResultSet object
%
%   Name-Value Arguments
%     Table: Name of the table to export.
%       If it is not selected, a structure with all result tables is created
%       char array
%     ExportAs: Select the output VarMode of the table/s.
%       'NONE' - returns the cTable object (default).
%       'CELL' - returns the table as an array of cells.
%       'STRUCT' - returns the table as a structured array.
%       'TABLE' - returns a matlab table object.
%     Format: Use the Format definition to output the (numeric values) tables
%       true | false (default)
%
%   Output Arguments
%     res - The Table/s in the format specified by ExportAs parameter
%
%   Example
%     <a href="matlab:open TableInfoDemo.mlx">Tables Info Demo</a>
%  
%   See also cResultSet, cTable.
%
    res=cStatus();
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
        res.printError(err.message);
        res.printError('Usage: ExportResults(arg,options)');
        return
    end
    param=p.Results;
    varmode=cType.getVarMode(param.ExportAs);
    % Export tables
    if isempty(param.Table)
        res=exportResults(arg,varmode,param.Format);
    else
        name=param.Table;
        tbl=arg.getTable(name);
        if isValid(tbl)
            res=exportTable(tbl,varmode,param.Format);
        else
            res.printError('Table %s is not available',name);
        end
    end
end