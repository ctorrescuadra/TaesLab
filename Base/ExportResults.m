function res = ExportResults(arg, varargin)
%ExportResults - Export result tables to various MATLAB data formats.
%   Converts result tables from cResultSet objects into MATLAB-native formats
%   for further processing, analysis, or integration with other tools. This 
%   function provides flexible export options for individual tables or complete
%   result sets, with optional formatting control.
%
%   By default, returns all tables as cTable objects in a structure. Specify
%   'ExportAs' to convert tables to cell arrays, structs, or MATLAB table objects.
%   Use 'Table' to export a single specific table instead of all results.
%
%   Syntax:
%     res = ExportResults(arg)
%     res = ExportResults(arg, Name, Value)
%  
%   Input Arguments:
%     arg - cResultSet object containing result tables
%       Any object derived from cResultSet (cModelResults, cResultInfo, cDataModel,
%       cThermoeconomicModel). These objects contain collections of result tables
%       that can be accessed and exported.
%
%   Name-Value Arguments:
%     Table - Name of specific table to export
%       char array | string (default: empty - export all tables)
%       When specified, exports only the named table. If empty, exports all tables
%       in the result set as a structure. Use ListResultTables to see available
%       table names for a given result object.
%
%     ExportAs - Output format for table data
%       'NONE' (default) | 'CELL' | 'STRUCT' | 'TABLE'
%       Controls the MATLAB data type of exported tables:
%         'NONE'   - Returns cTable objects (no conversion)
%         'CELL'   - Cell array with headers and data
%         'STRUCT' - Structured array with field names
%         'TABLE'  - MATLAB table object (requires MATLAB R2013b+)
%
%     Format - Apply format definitions to numeric values
%       true | false (default)
%       When true, applies the format specification defined in the cTable object
%       to convert numeric values to formatted strings (e.g., "12.34" instead of
%       12.3456). Useful for presentation but loses numeric precision.
%
%   Output Arguments:
%     res - Exported table data
%       Single table: Exported in the format specified by 'ExportAs'
%       Multiple tables: Structure with field names matching table names
%       If 'Table' is specified, returns a single export of that table.
%       If 'Table' is not specified, returns a structure containing all tables.
%     
%   Examples:
%     % Export all tables as cell arrays
%     results = ExportResults(modelResults, 'ExportAs', 'CELL');
%
%     % Export specific table as MATLAB table object
%     costTable = ExportResults(costResults, 'Table', 'dcost', 'ExportAs', 'TABLE');
%
%     % Export all tables with formatting applied
%     formattedData = ExportResults(data, 'ExportAs', 'STRUCT', 'Format', true);
%
%     % Get all tables as cTable objects (default)
%     tableSets = ExportResults(model);
%
%     <a href="matlab:open TableInfoDemo.mlx">Tables Info Demo</a>
%  
%   See also cResultSet, cTable, ListResultTables, ShowResults, SaveResults.
%
    res=cTaesLab();
    if nargin<1
        res.printError(cMessages.NarginError,cMessages.ShowHelp);
        return
    end
    if ~isObject(arg,'cResultSet')
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