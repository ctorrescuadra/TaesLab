function res=readModel(filename)
% Read a data model file according its extension. Internal Function
%   INPUT:
%       filename - data model file name
%   OUTPUT:
%       res - cReadModel object
%
    % Create the model depending de file extension
    res=cStatusLogger(cType.VALID);
    fileType=cType.getFileType(filename);
    switch fileType
        case cType.FileType.JSON
            res=cReadModelJSON(filename);
        case cType.FileType.XML
            res=cReadModelXML(filename);
        case cType.FileType.CSV
            res=cReadModelCSV(filename);
        case cType.FileType.XLSX
            res=cReadModelXLS(filename);
        case cType.FileType.MAT
            res=importMAT(filename);  
        otherwise
            res.messageLog(cType.ERROR,'File extension %s is not supported',filename);
            return
    end
end