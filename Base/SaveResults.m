function SaveResults(arg,filename)
%SaveResults - Save the result tables into a file/s in diferent formats
%   The accepted extensions are xlsx, csv, html, txt, tex and mat
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
    log=cStatus(cType.VALID);
    if ~isa(arg,'cResultSet')       
        log.printError('Usage: SaveResults(res,filename)');
        return
    end
    % Check Input parameters
    if (nargin~=2) || ~isText(filename)
        log.printError('Usage: SaveResults(res,filename)');
        return
    end
    if isstring(filename)
        filename=convertStringsToChars(filename);
    end
    log=saveResults(arg,filename);
    printLogger(log);
end