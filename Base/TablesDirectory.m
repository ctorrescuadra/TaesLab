function res = TablesDirectory(varargin)
% TablesDirectory get result tables information
%   USAGE:
%       TablesDirectory - prints tables info on console
%       res=TablesDirectory - get a cTableData containing tables info
%       res=TablesDirectory(options) - get diferent options to show tables info
%   INPUT:
%       param - Select the options to use
%           ViewTable - (true/false) view the tables info in a uitable
%           SaveAs - Save the tables info in a file
%                    Valid options: *.txt, *.csv, *.xlsx, *.json, *.xml, *.html, *.mat
%           VarMode - Select the kind of output for tables info
%               cType.VarMode.NONE - get a cTableData object
%               cType.VarMode.CELL - get a cell array
%               cType.VarMode.STRUCT - get a struct array
%               cType.Varmode.TABLE - get a Matlab table
%   OUTPUT:
%       res - Variable containing the tables info, depending VarMode
%   See also cTablesDefinition
%
    % Load the tables directory
    obj=cTablesDefinition;
    res=obj.getTablesDirectory;
    % Get parameters
    p = inputParser;
	p.addParameter('PrintTable',true,@islogical);
    p.addParameter('ViewTable',false,@islogical);
	p.addParameter('VarMode',cType.VarMode.NONE,@isnumeric);
	p.addParameter('SaveAs','',@ischar);
    try
		p.parse(varargin{:});
    catch err
        obj.printError(err.message);
        obj.printError('Usage: TablesDirectory(param)');
        return
    end
    param=p.Results;
    % Show info as uitable
    if param.ViewTable
        param.PrintTable=false;
        obj.viewTablesDirectory;
    end
    % Save info into a file
    if ~isempty(param.SaveAs)
        param.PrintTable=false;
        log=obj.saveTablesDirectory(param.SaveAs);
        printLogger(log)
    end
    % Get the info as a variable
    if (nargout > 0)
        param.PrintTable=false;
        res=obj.exportTablesDirectory(param.VarMode);
    end
    % Print the table on console
    if (param.PrintTable)
        obj.printTablesDirectory
    end
end