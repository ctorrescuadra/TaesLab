function res = ExportResults(arg,varargin)
%ExportResults - Export the results tables to a different format.
%   This function gets the result tables in different formats:
%     CELL - Table is converted in a cell array
%     STRUCT - Table is converted in a structred array
%     TABLE - Table is converted in a Matlab table object
%   In none is selected a cTable object is obtained
%   If 'Table' option is not used it returns a structure with 
%   all the tables converted to the desired format. 
%   If a 'Table' is selected, it return the table in the desired format.
%
%   Syntax
%     res=ExportResults(arg,Name,Value)
%  
%   Input Arguments
%     arg - cResultSet object
%
%   Name-Value Arguments
%     Table: Name of the table to export. 
%       If it is not selected a structure with all result tables is created
%       char array
%     ExportAs: Selects the output VarMode of the table/s.
%       'NONE' - returns the cTable object (default).
%       'CELL' - returns the table as an array of cells.
%       'STRUCT' - returns the table as a structured array.
%       'TABLE' - returns a matlab table object.
%     Format: Use the Format definition to output the (numeric values) tables
%       true | false (default)
%
%   Output Arguments
%     res - Table/s in the format specified by ExportAs.
%
%   Example
%     <a href="matlab:open ExergyAnalysisDemo.mlx">Exergy Analysis Demo</a>
%  
%  See also cResultSet, cTable.
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
            res.printError('Table %s is not available',name);
        end
    end
end