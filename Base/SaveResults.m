function SaveResults(arg,filename)
%SaveResults - Saves the result tables into a file
%   The available formats are: XLSX, CSV, TXT, HTML, LaTeX and MAT.
%   Show a message about the status of the operation
%   Used as the interface of cResultsSet/saveResults
%   
% Syntax
%   SaveResults(arg,filename)
%
% Input Arguments:
%   arg - cResultSet object
%   filename - name of the output file (with extension)
%     char array | string
%
% Example
%   <a href="matlab:open SaveResultsDemo.mlx">Save Results Demo</a>
%
% See also cResultSet
%
    log=cMessageLogger();
    % Check Input parameters
    if (nargin~=2)
        log.printError('Usage: SaveResults(res,filename)');
        return
    end
    if ~isResultSet(arg)
        log.printError('File NOT saved. Invalid Result Set.');
        return
    end
    if ~isFilename(filename)
        log.printError('File NOT saved. Invalid filename.');
        return
    end
    log=saveResults(arg,filename);
    printLogger(log);
end