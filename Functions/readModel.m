function data=readModel(filename)
% Read a data model file according its extension. Internal Function
%   INPUT:
%       filename - data model file name
%   OUTPUT:
%       model - cReadModel object
%
    % Create the model depending de file extension
    data=cStatusLogger();
    fileType=cType.getFileType(filename);
    switch fileType
        case cType.FileType.JSON
            data=cReadModelJSON(filename);
        case cType.FileType.XML
            data=cReadModelXML(filename);
        case cType.FileType.CSV
            data=cReadModelCSV(filename);
        case cType.FileType.XLSX
            data=cReadModelXLS(filename);
        case cType.FileType.MAT
            data=importMAT(filename);  
        otherwise
            data.messageLog(cType.ERROR,'File extension %s is not supported',filename);
            return
    end
end