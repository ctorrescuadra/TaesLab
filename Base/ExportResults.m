function res = ExportResults(arg,varargin)
%ExportResults - Exports the results tables in different formats.
%   If the option 'Table' is not used, the function returns a structure with all tables converted to the desired format. 
%
%   Syntax:
%     res=ExportResults(arg,Name,Value)
%  
%   Input Arguments:
%     arg - cResultSet object
%
%   Name-Value Arguments:
%     Table: Name of the table to export. If it is not selected, a structure with all result tables is created
%       char array
%     ExportAs: Select the output VarMode of the table/s.
%       'NONE' - returns the cTable object (default).
%       'CELL' - returns the table as an array of cells.
%       'STRUCT' - returns the table as a structured array.
%       'TABLE' - returns a MATLAB table object.
%     Format: Use the Format definition to output the (numeric values) tables
%       true | false (default)
%
%   Output Arguments:
%     res - The Table/s in the format specified by 'ExportAs' parameter
%
%   Example:
%     <a href="matlab:open TableInfoDemo.mlx">Tables Info Demo</a>
%  
%   See also cResultSet, cTable.
%
    res=cMessageLogger();
    if nargin<1 || ~isObject(arg,'cResultSet')
		res.printError(cMessages.InvalidObject,class(arg));
		res.printError(cMessages.ShowHelp);
		return
    end
    % Check input
    p = inputParser;
    p.addParameter('Table',cType.EMPTY_CHAR,@ischar);
	p.addParameter('ExportAs',cType.DEFAULT_VARMODE,@cType.checkVarMode);
	p.addParameter('Format',false,@islogical);
    try
		p.parse(varargin{:});
    catch err
        res.printError(err.message);
        res.printError(cMessages.ShowHelp);
        return
    end
    param=p.Results;
    varmode=cType.getVarMode(param.ExportAs);
    % Export tables
    if isempty(param.Table)
        res=exportResults(arg,varmode,param.Format);
    else
        res=exportTable(arg,param.Table,varmode,param.Format);
    end
end