function SaveDataModel(arg,filename)
%SaveDataModel - Saves a copy of the data model into a file 
%   The available formats are: XLSX, CSV, JSON, XML and MAT.
%   Show a message about the status of the operation
%   Used as the interface of cDataModel/saveDataModel
%   
% Syntax
%   SaveDataModel(arg,filename)
%
% Input Arguments:
%   arg - cDataModel or cThermoeconomicModel object
%   filename - name of the output file (with extension)
%
% Example
%     <a href="matlab:open SaveDataModelDemo.mlx">Save Data Model Demo</a>
%
% See also cDataModel, cThermoeconomicModel
%
    log=cMessageLogger();
    % Check Input Parameters
    if (nargin~=2)
        log.printError('Usage: SaveDataModel(data,filename)');
        return
    end
    if isObject(arg,'cDataModel')
        data=arg;
    elseif isObject(arg,'cThermoeconomicModel')
        data=arg.DataModel;
    else
        log.printError('First argument input must be a cDataModel or cThermoeconomicModel object');
        log.printError('Usage: SaveDataModel(data,filename)');
        return
    end
    if ~isFilename(filename)
        log.printError('File NOT saved. Invalid filename.');
        log.printError('Usage: SaveDataModel(data,filename)');
        return
    end
    % Save the data model
    log=saveDataModel(data,filename);
    printLogger(log);
end