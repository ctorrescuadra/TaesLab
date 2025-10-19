function SaveResults(arg,filename)
%SaveResults - Save the result tables into a file.
%   The available formats are: XLSX, CSV, TXT, HTML, LaTeX and MAT.
%   Displays a message about the status of the operation.
%   Used as an interface for cResultSet/saveResults.
%   
%   Syntax:
%     SaveResults(arg, filename)
%
%   Input Arguments:
%     arg - cResultSet object
%     filename - Name of the output file (with extension)
%       char array | string
%
%   Example:
%     <a href="matlab:open SaveResultsDemo.mlx">Save Results Demo</a>
%
%   See also cResultSet
%
    log=cTaesLab();
    % Check Input parameters
    if (nargin~=2) 
        log.printError(cMessages.NarginError,cMessages.ShowHelp);
        return
    end
    if ~isObject(arg,'cResultSet')
        log.printError(cMessages.ResultSetRequired);
        return
    end
    if ~isFilename(filename)
        log.printError(cMessages.InvalidOutputFile,filename);
        return
    end
    % Save Results
    log=saveResults(arg,filename);
    printLogger(log);
end