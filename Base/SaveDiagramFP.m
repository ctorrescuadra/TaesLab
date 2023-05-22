function SaveDiagramFP(model,filename,varargin)
% SaveDiagramFP saves the Diagram FP adjacency tables into a file
%   The type of file depends on the file extension
%   *.csv, *.xlsx and *.mat are allowed
%   INPUT:
%       model - cThermoeconomicModel object
%       filename - name of the output file (with extension)
%       varargin - optional parameter indicanting the type of FP table
%           cType.Tables.TABLE_FP (default)
%           cType.Tables.COST_TABLE_FP
% See also cResultInfo, cThermoeconomicModel
%
    log=cStatus(cType.VALID);
    % Check Input parameters
    if (nargin<2) || ~cType.checkFileWrite(filename)
        log.printError('Usage: SaveDiagramFP(res,filename)');
        return
    end
    if isa(model,'cThermoeconomicModel')
        log=saveDiagramFP(model,filename,varargin{:});
        printLogger(log);
    else
        log.printError('Invalid result. It sould be a cThermoeconomicModel object');
    end
end