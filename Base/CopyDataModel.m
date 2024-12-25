function CopyDataModel(inputFile, outputFile)
%CopyDataModel - Copy a data model file to another format.
%   The formats supported for both input and output are: XLSX, CSV, JSON, XML and MAT
%
% Syntax
%   CopyDataModel(inputfile,outputfile)
%
% Input Arguments
%   inputFile - Name of the input data model file
%     char array | string
%   outputFile - Name of the output data model file
%     char array | string
%
% Example
%   <a href="matlab:open SaveDataModelDemo.mlx">Save Data Model Demo</a>
%
% See also cDataModel, cReadModel
%
    log=cMessageLogger();
    if (nargin~=2) || ~isFilename(inputFile) || ~isFilename(outputFile)
        log.printError(cMessages.InvalidArgument,cMessages.ShowHelp);
        return
    end
    data=readModel(inputFile);
    if data.status
        SaveDataModel(data,outputFile);
    else
        printLogger(data);
    end
end