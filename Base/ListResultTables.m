function res=ListResultTables(options)
% ListResultTables shows a list of the result tables of TaesLab
%   USAGE:
%       res=ListResultTables(options)
%   INPUT:
%       options - Determine the form to view the information
%           cType.TableView.CONSOLE
%           cType.TableView.HTML
%           cType.TableView.GUI
%        If option is not provided no values are shown
%   OUTPUT:
%       res - cTableData containing the result tables info
% See also cTableData, cTableDefinition
%
    cols={'DESCRIPTION','RESULT_NAME','GRAPH'};
    obj=cTablesDefinition;
    res=obj.getTablesDirectory(cols);
    if isValid(res) && (nargin>0)
        viewTable(res,options)
    end
end