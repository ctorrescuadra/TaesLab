function SaveSummary(model,filename)
%SaveSummary saves the summary model results into a file
%   The available formats are: XLSX, CSV, TXT, HTML, LaTeX and MAT.
%   Show a message about the status of the operation
%   Used as the interface of cThermoeconomicModel/saveSummary
%
% Syntax:
%   SaveTable(tbl,filename)
%
% Input Arguments
%   model - cThermoeconomicModel object
%   filename - Name of the file (with extension) to save the table data
%
% Example
%   <a href="matlab:open SummaryResultsDemo.mlx">Summary Results Demo</a>
%
% See also cThermoeconomicModel, cModelSummary
%
    log=cMessageLogger();
    % Check Input parameters
    if (nargin~=2) || ~isObject(model,'cThermoeconomicModel')
        log.printError(cMessages.ResultSetRequired);
        log.printError(cMessages.UseSaveSummary);
        return
    end
    if ~isFilename(filename)
        log.printError(cMessages.InvalidOutputFile,filename);
        log.printError(cMessages.UseSaveSummary);
        return
    end
    % Save summary results
    log=saveSummary(model,filename);
    log.printLogger;
end