function SaveTable(tbl,filename)
%SaveTable - Save a result table in diferent format
%   The available format are: XLSX, CSV, TXT, HTML, LaTeX, JSON, XML and MAT.
%   Show a message about the status of the operation
%   Used as interface of cTable/saveTable
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
    log=cStatusLogger(cType.VALID);
    % Check Input parameters
    if (nargin~=2) || ~isFilename(filename)
        log.printError('Usage: SaveTable(table,filename)');
        return
    end
    if ~isa(tbl,'cTable') || ~isValid(tbl)
        log.printError('Invalid table object. File %s NOT Saved', filename);
        return
    end
    % Save table
    log=tbl.saveTable(filename);
    printLogger(log);
end