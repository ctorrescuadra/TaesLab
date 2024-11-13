function res=readModel(filename)
%readModel - Read a data model file according its extension.
%   Internal Function of ReadDataModel
%
%   Syntax:
%     res = readModel(filename)
%   
%   Input Arguments:
%     filename - data model file name
%
%   Output Arguments:
%     res - cDataModel object
%
    % Read the data model depending de file extension
    res=cMessageLogger(cType.INVALID);
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
            rdm=importMAT(filename);  
        otherwise
            res.messageLog(cType.ERROR,'File extension %s is not supported',filename);
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
    elseif isa(rdm,'cReadModel') % Import MAT data model
        res=rdm.getDataModel;
    end
    % Check if data model is valid
    if res.status
        res.messageLog(cType.INFO,cMessages.ValidDataModel,res.ModelName);
    else
        res.messageLog(cType.ERROR,cMessages.InvalidDataModelFile,filename);
    end
end