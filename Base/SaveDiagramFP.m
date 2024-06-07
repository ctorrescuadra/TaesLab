function SaveDiagramFP(model,filename)
% SaveDiagramFP saves adjacency tables of the Diagram FP into a file
%   The type of file depends on the file extension
%   *.csv, *.xlsx and *.mat are allowed
% USAGE:
%   SaveDiagramFP(model,filename)
% INPUT:
%   model - cThermoeconomicModel object
%   filename - name of the output file (with extension)
%
% See also cThermoeconomicModel, cDiagramFP
%
    % Check Input parameters
    log=cStatus(cType.VALID);
    % Check Input parameters
    if (nargin<2) || ~isText(filename) 
        log.printError('Usage: SaveDiagramFP(model,filename)');
        return
    end
    if ~isa(model,'cThermoeconomicModel') || ~isValid(model)
        log.printError('Invalid model object');
        return
    end
    if isstring(filename)
        filename=convertStringsToChars(filename);
    end
    % Save the Results
    log=saveDiagramFP(model,filename);
    log.printLogger;
end