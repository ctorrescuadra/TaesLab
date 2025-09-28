function res=ValidateModelTables(filename)
%readModel - Read a data model file according its extension.
%   Internal Function of ReadDataModel
%
%   Syntax
%     res = readModel(filename)
%   
%   Input Arguments
%     filename - data model file name
%
%   Output Arguments
%     res - cDataModel object
%
%   Example
%     res = readModel('dataModel.json'); %returns a cDataModel object from a JSON file 
%
%   See also cReadModel, cDataModel, ReadDataModel
%   
    %Check input arguments
    res=cMessageLogger();
    if nargin~=1 || isempty(filename) || ~isFilename(filename)
        res.messageLog(cType.ERROR,cMessages.InvalidFileName);
        return
    end
    % Read the data model depending de file extension
    fileType=cType.getFileType(filename);
    switch fileType
        case cType.FileType.CSV
            res=cReadModelCSV(filename);
        case cType.FileType.XLSX
            res=cReadModelXLS(filename);
        otherwise
            res.messageLog(cType.ERROR,cMessages.InvalidFileExt,filename);
            return
    end
    % Print log messages
    printLogger(res)
    if res.status
        res.printInfo(cMessages.ValidDataModel,res.ModelName);
    else
        res.printError(cMessages.InvalidDataModelFile,filename);
    end
end