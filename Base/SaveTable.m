function SaveTable(tbl,filename)
%SaveTable - Save a result table in different formats
%   The available formats are XLSX, CSV, TXT, HTML, LaTeX, JSON, XML and MAT.
%   Show a message about the status of the operation
%   Used as interface of cTable/saveTable
%
% Syntax:
%   SaveTable(tbl,filename)
%
% Input arguments
%   tbl - cTable object
%   filename - Name of the file (with extension) to save the table data
%
% Example
%   <a href="matlab:open TableInfoDemo.mlx">Tables Info Demo</a>
%
% See also cTable
%
    log=cMessageLogger();
    % Check Input parameters
    if (nargin~=2) 
        log.printError('Usage: SaveTable(table,filename)');
        return
    end
    if ~isValidTable(tbl)
        log.printError('Invalid table object.');
        return
    end
    if ~isFilename(filename)
        log.printError('Invalid filename.');
        return
    end
    % Save table
    log=tbl.saveTable(filename);
    printLogger(log);
end