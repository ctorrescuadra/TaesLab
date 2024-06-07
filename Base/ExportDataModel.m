function ExportDataModel(inputFile, outputFile)
% ExportDataModel creates a copy of the data model file in a different format.
%   The formats supported for both input and output are: XLSX, CSV, JSON, XML, MAT
% USAGE:
%   ExportDataModel inputfile outputfile
% INPUT:
%   inputFile - Name of the input data model file % outputFile - Name of the input data model file
%   outputFile - File name of the output data model file
%
% See also cReadModel
%
    data=ReadDataModel(inputFile);
    if isValid(data)
        SaveDataModel(data,outputFile);
    end
end