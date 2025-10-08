function SaveDataModel(arg,filename)
%SaveDataModel - Saves the data model tables into a file. 
%   The available formats are: XLSX, CSV, JSON, XML, and MAT.
%   Displays a message about the status of the operation.
%   Used as an interface for cDataModel/saveDataModel.
%   
%   Syntax:
%     SaveDataModel(arg,filename)
%
%   Input Arguments:
%     arg - cDataModel or cThermoeconomicModel object
%     filename - Name of the output file (with extension)
%       array char | string
%
%   Example:
%     <a href="matlab:open SaveDataModelDemo.mlx">Save Data Model Demo</a>
%
%   See also cDataModel, cThermoeconomicModel
%
    log=cMessageLogger();
    % Check Input Arguments:
    if (nargin~=2)
        log.printError(cMessages.DataModelRequired);
        return
    end
    if isObject(arg,'cDataModel')
        data=arg;
    elseif isObject(arg,'cThermoeconomicModel')
        data=arg.DataModel;
    else
        log.printError(cMessages.DataModelRequired);
        log.printError(cMessages.ShowHelp);
        return
    end
    if ~isFilename(filename)
        log.printError(cMessages.InvalidOutputFile,filename);
        log.printError(cMessages.ShowHelp);
        return
    end
    % Save the data model
    log=saveDataModel(data,filename);
    printLogger(log);
end