function res=readModel(filename)
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
    res=cMessageLogger(cType.INVALID);
    if nargin~=1 || isempty(filename) || ~isFileName(filename)
        res.messageLog(cType.ERROR,cMessages.InvalidFileName);
        return
    end
    % Read the data model depending de file extension
    fileType=cType.getFileType(filename);
    switch fileType
        case cType.FileType.JSON
            rdm=cReadModelJSON(filename);
        case cType.FileType.XML
            rdm=cReadModelXML(filename);
        case cType.FileType.CSV
            rdm=cReadModelCSV(filename);
        case cType.FileType.XLSX
            rdm=cReadModelXLS(filename);
        case cType.FileType.MAT
            rdm=importDataModel(filename); 
        otherwise
            res.messageLog(cType.ERROR,cMessages.InvalidFileExt,filename);
            return
    end
    % Check if the model read is correct
    if ~rdm.status
        res.addLogger(rdm);
        res.messageLog(cType.ERROR,cMessages.InvalidDataModelFile,filename);
        return
    end
    % If filename is a MAT file then is already done 
    if isa(rdm,'cDataModel') 
        res=rdm;   
    elseif isa(rdm,'cReadModel')
        res=rdm.getDataModel;
    end
    % Set log message
    if res.status
        res.messageLog(cType.INFO,cMessages.ValidDataModel,res.ModelName);
    else
        res.messageLog(cType.ERROR,cMessages.InvalidDataModelFile,filename);
    end
end