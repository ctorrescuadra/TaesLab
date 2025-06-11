function SaveResults(arg,filename)
%SaveResults - Save the result tables into a file
%   The available formats are: XLSX, CSV, JSON, XML, and MAT.
%   Displays a message about the status of the operation.
%   Used as an interface for cResultSet/saveResults.
%   
%   Syntax
%     SaveResults(arg, filename)
%
%   Input Arguments
%     arg - cResultSet object
%     filename - name of the output file (with extension)
%       char array | string
%
%   Example
%     <a href="matlab:open SaveResultsDemo.mlx">Save Results Demo</a>
%
%   See also cResultSet
%
    log=cMessageLogger();
    % Check Input parameters
    if (nargin~=2) || ~isObject(arg,'cResultSet')
        log.printError(cMessages.ResultSetRequired);
        log.printError(cMessages.ShowHelp);
        return
    end
    if ~isFilename(filename)
        log.printError(cMessages.InvalidOutputFile,filename);
        log.printError(cMessages.ShowHelp);
        return
    end
    log=saveResults(arg,filename);
    printLogger(log);
end