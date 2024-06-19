function SaveTable(tbl,filename)
%SaveTable - Save a result table in diferent format
%   The available format are: XLSX, CSV, TXT, HTML, LaTeX, JSON, XML and MAT.
%   Show a message about the status of the operation
%   Used as interface of cTable/SaveTable
%
%   Syntax:
%     SaveTable(tbl,filename)
%
%   Input arguments
%     tbl - cTable object
%     filename - Name of the file (with extension) to dsave the table data
%
%   See also cTable
%
    log=cStatus(cType.VALID);
    % Check Input parameters
    if (nargin<2) || ~isText(filename)
        log.printError('Usage: SaveSummary(tbl,filename)');
        return
    end
    if ~isa(tbl,'cTable') || ~isValid(tbl)
        log.printError('File NOT saved. Invalid model object');
        return
    end
    if isstring(filename)
        filename=convertStringsToChars(filename);
    end
    % Save table
    log=saveTable(tbl,filename);
    log.printLogger;
end