function SaveSummary(model,filename)
%SaveSummary - Save the summary results into a file.
%   The available formats are: XLSX, CSV, HTML, TXT, TeX and MAT.
%   Displays a message about the status of the operation.
%   Used as an interface for cResultSet/saveSummary.
%
%   Syntax:
%     SaveTable(tbl,filename)
%
%   Input Arguments
%     model - cThermoeconomicModel object
%     filename - Name of the file (with extension) to save the table data
%       array char | string
%
%   Example
%     <a href="matlab:open SummaryResultsDemo.mlx">Summary Results Demo</a>
%
%   See also cThermoeconomicModel, cSummaryResults
%
    log=cMessageLogger();
    % Check Input parameters
    if (nargin~=2) || ~isObject(model,'cThermoeconomicModel')
        log.printError(cMessages.ResultSetRequired);
        log.printError(cMessages.ShowHelp);
        return
    end
    if ~isFilename(filename)
        log.printError(cMessages.InvalidOutputFile,filename);
        log.printError(cMessages.ShowHelp);
        return
    end
    % Save summary results
    log=saveSummary(model,filename);
    log.printLogger;
end