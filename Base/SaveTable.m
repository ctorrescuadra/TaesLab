function SaveTable(tbl,filename)
%SaveTable - Save the table content into a file.
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
%       array char | string
%
%   Example:
%     <a href="matlab:open TableInfoDemo.mlx">Tables Info Demo</a>
%
%   See also cTable
%
    log=cTaesLab();
    % Check Input parameters
    if (nargin~=2)
        log.printError(cMessages.NarginError,cMessages.ShowHelp);
        return
    end
    if  ~isObject(tbl,'cTable')
        log.printError(cMessages.TableRequired,cMessages.ShowHelp);
        return
    end
    if ~isFilename(filename)
        log.printError(cMessages.InvalidOutputFilename,filename);
        return
    end
    % Save table
    log=tbl.saveTable(filename);
    printLogger(log);
end