function SaveSummary(model,filename)
%SaveSummary - Save the summary results into a file.
%   The available formats are: XLSX, CSV, HTML, TXT, TeX and MAT.
%   Displays a message about the status of the operation.
%   Used as an interface for cResultSet/saveSummary.
%
%   Syntax:
%     SaveSummary(model,filename)
%
%   Input Arguments:
%     model - cThermoeconomicModel object
%     filename - Name of the file (with extension) to save the table data
%       array char | string
%
%   Example:
%     <a href="matlab:open SummaryResultsDemo.mlx">Summary Results Demo</a>
%
%   See also cThermoeconomicModel, cSummaryResults
%
    log=cTaesLab();
    % Check Input parameters
    if (nargin~=2)
        log.printError(cMessages.NarginError,cMessages.ShowHelp);
        return
    end
    if ~isObject(model,'cThermoeconomicModel')
        log.printError(cMessages.ThermoModelRequired,cMessages.ShowHelp);
        return
    end
    if ~isFilename(filename)
        log.printError(cMessages.InvalidOutputFile,filename);
        return
    end
    % Save summary results
    log=saveSummary(model,filename);
    log.printLogger;
end