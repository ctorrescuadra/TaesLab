function SaveDiagramFP(res,filename)
% SaveDiagramFP saves the Diagram FP adjacency tables into a file
%   The type of file depends on the file extension
%   *.csv, *.xlsx and *.mat are allowed
%   INPUT:
%       model - cThermoeconomicModel object
%       filename - name of the output file (with extension)
% See also cResultInfo, cThermoeconomicModel
%
    log=cStatus(cType.VALID);
    % Check Input parameters
    if (nargin~=2) || ~cType.checkFileWrite(filename)
        log.printError('Usage: SaveDiagramFP(res,filename)');
        return
    end
    if isa(res,'cThermoeconomicModel')
        log=saveDiagramFP(res,filename);
        printLogger(log);
    else
        log.printError('Invalid result. It sould be a cThermoeconomicModel object');
    end
end