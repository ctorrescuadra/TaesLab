function SaveTable(table,filename)
% SaveDiagramFP saves the Diagram FP adjacency tables into a file
%   The type of file depends on the file extension
%   *.csv, *.xlsx, *.xml, *.json, *.txt and *.mat are allowed
%   USAGE:
%       SaveTable(table,filename)
%   INPUT:
%       table - cTable object
%       filename - name of the output file (with extension)
% See also cTable
%
    % Check Input parameters
    log=cStatus(cType.VALID);
    % Check Input parameters
    if (nargin<2) || ~isText(filename) 
        log.printError('Usage: SaveDiagramFP(model,filename)');
        return
    end
    if ~isa(table,'cTable') || ~isValid(table)
        log.printError('Invalid model object');
        return
    end
    if isstring(filename)
        filename=convertStringsToChars(filename);
    end
    % Save the Results
    log=saveTable(table,filename);
    log.printLogger;
end