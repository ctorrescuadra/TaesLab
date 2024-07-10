function SaveSummary(model,filename)
%SaveSummary saves the summary model results into a file
%   The available format are: XLSX, CSV, TXT, HTML, LaTeX and MAT.
%   Show a message about the status of the operation
%   Used as interface of cThermoeconomicModel/saveSummary
%
%   Syntax:
%     SaveTable(tbl,filename)
%
%   Input arguments
%     model - cThermoeconomicModel object
%     filename - Name of the file (with extension) to save the table data
%
%   Example
%     <a href="matlab:open SummaryResultsDemo.mlx">Summary Results Demo</a>
%
%   See also cThermoeconomicModel, cModelSummary
%
    log=cStatusLogger(cType.VALID);
    % Check Input parameters
    if (nargin<2) || ~isFilename(filename)
        log.printError('Usage: SaveSummary(model,filename)');
        return
    end
    if ~isa(model,'cThermoeconomicModel') || ~isValid(model)
        log.printError('Invalid model object. File % NOT saved',filename);
        return
    end
    % Save summary results
    log=saveSummary(model,filename);
    log.printLogger;
end