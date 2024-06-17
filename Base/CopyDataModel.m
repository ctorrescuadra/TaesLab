function CopyDataModel(inputFile, outputFile)
%CopyDataModel - Copy a data model file to another format.
%   The formats supported for both input and output are: XLSX, CSV, JSON, XML and MAT
%
%   Syntax
%     CopyDataModel(inputfile,outputfile)
%
%   Input Arguments
%     inputFile - Name of the input data model file
%       char array | string
%     outputFile - Name of the output data model file
%       char array | string
%
%   Example
%     <a href="matlab:open SaveDataModelDemo.mlx">Save Data Model Demo</a>
%
% See also cDataModel, cReadModel
%
    data=ReadDataModel(inputFile);
    if isValid(data)
        SaveDataModel(data,outputFile);
    end
end