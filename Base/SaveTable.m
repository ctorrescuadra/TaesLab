function SaveTable(tbl,filename)
%SaveTable - Saves a table of results in different formats.
%   The available formats are XLSX, CSV, TXT, HTML, LaTeX, JSON, XML, and MAT.
%   Displays a message about the status of the operation.
%   Used as an interface for cTable/saveTable.
%
%   Syntax:
%     SaveTable(tbl,filename)
%
%   Input arguments
%     tbl - cTable object
%     filename - Name of the file (with extension) to save the table data
%
%   Example
%     <a href="matlab:open TableInfoDemo.mlx">Tables Info Demo</a>
%
%   See also cTable
%
    log=cMessageLogger();
    % Check Input parameters
    if (nargin~=2) || ~isObject(tbl,'cTable')
        log.printError(cMessages.TableRequired);
        log.printError(cMessages.ShowHelp);
        return
    end
    if ~isFilename(filename)
        log.printError(cMessages.InvalidOutputFilename,filename);
        log.printError(cMessages.ShowHelp);
        return
    end
    % Save table
    log=tbl.saveTable(filename);
    printLogger(log);
end