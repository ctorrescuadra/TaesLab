function CopyDataModel(inputFile, outputFile)
%CopyDataModel - Creates a copy of a data model file in another format
%   The formats supported for both input and output files are: XLSX, CSV, JSON, XML and MAT
%
%   Syntax:
%     CopyDataModel(inputfile, outputfile)
%     CopyDataModel inputfile outputfile
%
%   Input Arguments:
%     inputFile - Name of the input data model file
%       char array | string
%     outputFile - Name of the output data model file
%       char array | string
%
%   Example:
%     <a href="matlab:open SaveDataModelDemo.mlx">Save Data Model Demo</a>
%
%   See also cDataModel, cReadModel
%
    log=cMessageLogger();
    % Check arguments
    if (nargin~=2) || ~isFilename(inputFile) || ~isFilename(outputFile)
        log.printError(cMessages.InvalidArgument)
        log.printError(cMessages.ShowHelp);
        return
    end
    % Read data model
    data=cDataModel.create(inputFile);
    if data.status
        SaveDataModel(data,outputFile);
    else
        printLogger(data);
    end
end