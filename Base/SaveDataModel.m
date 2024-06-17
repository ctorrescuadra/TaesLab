function SaveDataModel(arg,filename)
%SaveDataModel - Saves the data model into a file 
%   The file extensions *.csv, *.xlsx, *.json, *.xml and *.mat are allowed
%   It could use a cDataModel or a cThermoeconomicModel object as input
%   
%   Syntax
%     SaveDataModel(arg,filename)
%
%   Input Arguments:
%     arg - cDataModel or cThermoeconomicModel object
%     filename - name of the output file (with extension)
%
%   Example
%     <a href="matlab:open SaveDataModelDemo.mlx">Save Data Model Demo</a>
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
        log.printError('File NOT saved. Invalid data model');
    end
    if isa(arg,'cDataModel')
        data=arg;
    elseif isa(arg,'cThermoeconomicModel')
        data=arg.DataModel;
    else
        log.printError('File NOT saved. It should be a cDataModel or cThermoeconomicModel object');
        return
    end
    if isstring(filename)
        filename=convertStringsToChars(filename);
    end
    % Save the data model
    log=saveDataModel(data,filename);
    printLogger(log);
end