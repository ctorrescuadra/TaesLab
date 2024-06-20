function SaveResults(arg,filename)
%SaveResult - Saves the result tables into a file
%   The available format are: XLSX, CSV, TXT, HTML, LaTeX and MAT.
%   Show a message about the status of the operation
%   Used as interface of cResultsSet/saveResults
%   
%   Syntax
%     SaveResults(arg,filename)
%
%   Input Arguments:
%     arg - cResultSet object
%     filename - name of the output file (with extension)
%       char array | string
%
%   Example
%     <a href="matlab:open SaveResultsDemo.mlx">Save Results Demo</a>
%
% See also cResultSet
%
    log=cStatusLogger(cType.VALID);
    % Check Input parameters
    if (nargin~=2) || ~isFilename(filename)
        log.printError('Usage: SaveResults(res,filename)');
        return
    end
    if ~isa(arg,'cResultSet') || ~isValid(arg)     
        log.printError('Invalid Result Set. File %s NOT saved',filename);
        return
    end
    log=saveResults(arg,filename);
    printLogger(log);
end