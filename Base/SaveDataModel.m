function SaveDataModel(arg,filename)
%SaveDataModel - Saves a copy of the data model into a file 
%   The available formats are: XLSX, CSV, JSON, XML and MAT.
%   Show a message about the status of the operation
%   Used as the interface of cDataModel/saveDataModel
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
    log=cStatus();
    % Check Input Parameters
    if (nargin~=2)
        log.printError('Usage: SaveDataModel(data,filename)');
        return
    end
    if isa(arg,'cDataModel')
        data=arg;
    elseif isa(arg,'cThermoeconomicModel')
        data=arg.DataModel;
    else
        log.printError('File NOT saved. First input must be a cDataModel or cThermoeconomicModel object');
        return
    end
    if ~isValid(arg)
        log.printError('File NOT saved. Invalid data model');
    end
    if ~isFilename(filename)
        log.printError('File NOT saved. Invalid filename.');
        return
    end
    % Save the data model
    log=saveDataModel(data,filename);
    printLogger(log);
end