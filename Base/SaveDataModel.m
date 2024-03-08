function SaveDataModel(data,filename)
% SaveResultModel saves the data model into a file and log the result
%   The files *.csv, *.xlsx, *.json, *.xml and *.mat are allowed
%   It calls cReadModel method saveDataModel
%   USAGE:
%       SaveDataModel(data,filename)
%   INPUT:
%       data - cDataModel or cThermoeconomicModel object
%       filename - name of the output file (with extension)
% See also cDataModel, cThermoecononicModel
%
    log=cStatus(cType.VALID);
    % Check Input Parameters
    if (nargin~=2) || ~isText(filename)
        log.printError('Usage: SaveDataModel(model,filename)');
        return
    end
    if ~isa(data,'cDataModel') || ~isValid(data)
        log.printError('Invalid model. It should be a cDataModel or cThermoeconomicModel object');
        return
    end
    if isstring(filename)
        filename=convertStringsToChars(filename);
    end
    % Save the data model
    log=saveDataModel(data,filename);
    printLogger(log);
end
        

