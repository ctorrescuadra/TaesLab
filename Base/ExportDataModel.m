function ExportDataModel(inputFile, outputFile)
% ExportDataModel creates a copy of the data model file in a diferent format
%   The supported formats for both input and output are: XLSX, CSV, JSON, XML, MAT
%   USAGE:
%       ExportDataModel inputfile outputfile
%   INPUT:
%       inputFile - Input data model file name
%       outputFile - Output data model file name
%
    data=ReadDataModel(inputFile);
    if isValid(data)
        SaveDataModel(data,outputFile);
    end
end