function ViewTable(table,varargin)
% ViewTable shows a cTable object as a GUI table or in a web browser
%   USAGE:
%       SaveTable(table,option)
%   INPUT:
%       table - cTable object
%       option - select the way to present the table
%           cType.TableView.CONSOLE (show in console)
%           cType.TableView.GUI (use uitable)
%           cType.TableView.HTML (use web browser)
% See also cTable
%
    log=cStatus(cType.VALID);
    % Check Input parameters
    if ~isa(table,'cTable') || ~isValid(table)
        log.printError('Invalid table');
        return
    end
    % View the table
    viewTable(table,varargin{:});
end