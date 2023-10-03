function SaveDiagramFP(model,filename)
% SaveDiagramFP saves the Diagram FP adjacency tables into a file
%   The type of file depends on the file extension
%   *.csv, *.xlsx and *.mat are allowed
%   USAGE:
%       SaveDiagramFP(model,filename)
%   INPUT:
%       model - cThermoeconomicModel
%       filename - name of the output file (with extension)
% See also cThermoeconomicModel
%
    % Check Input parameters
    log=cStatus(cType.VALID);
    % Check Input parameters
    if (nargin<2) || ~ischar(filename) || ~isa(model,'cThermoeconomicModel') 
        log.printError('Usage: SaveDiagramFP(model,filename)');
        return
    end
    log=saveDiagramFP(model,filename);
    log.printLogger;
end