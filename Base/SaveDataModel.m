function SaveDataModel(arg,filename)
% SaveDataModel saves the data model into a file 
%   The files *.csv, *.xlsx, *.json, *.xml and *.mat are allowed
%   It calls cReadModel/saveDataModel
%  USAGE:
%   SaveDataModel(arg,filename)
%  INPUT:
%   arg - cDataModel or cThermoeconomicModel object
%   filename - name of the output file (with extension)
%
% See also cDataModel, cThermoecononicModel
%
    log=cStatus(cType.VALID);
    % Check Input Parameters
    if (nargin~=2) || ~isText(filename)
        log.printError('Usage: SaveDataModel(model,filename)');
        return
    end
    if ~isValid(arg)
        log.printError('Invalid data model');
    end
    if isa(arg,'cDataModel')
        data=arg;
    elseif isa(arg,'cThermoeconomicModel')
        data=arg.DataModel;
    else
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
        

