function SaveDataModel(arg,filename)
% SaveResultModel saves the data model into a file and log the result
%   The files *.csv, *.xlsx, *.json, *.xml and *.mat are allowed
%   It calls cReadModel method saveDataModel
%   INPUT:
%       model - cReadModel or cThermoeconomicModel object
%       filename - name of the output file (with extension)
% See also cReadModel
%
    log=cStatus();
    % Check Input Parameters
    if (nargin~=2) || ~ischar(filename)
        log.printError('Usage: SaveDataModel(model,filename)');
        return
    end
    if ~(isa(arg,'cReadModel') || isa(arg,'cThermoeconomicModel'))
        log.printError('Invalid model. It sould be a cReadModel or cThermoeconomicModel object');
        return
    end
    % Save the data model
    log=saveDataModel(arg,filename);
    printLogger(log);
end
        

