function res=ValidateModelTables(filename,varargin)
%ValidateModelTables - Validate the data tables of a data model file.
%   The function reads a data model file (CSV or XLSX) and validates the data
%   tables according to the rules defined in the cModelTables class.
%
%   Syntax:
%     res = ValidateModelTables(filename,Name,Value)
%   
%   Input Arguments:
%     filename - Name of the data model file.
%       char array | string
%
%   Name-Value Arguments:
%     Show - Show the data tables in the console
%       true | false (default)
%     SaveAs - Name of the file where the data model will be saved. The format
%       is defined by the file extension (JSON, XML).
%       char array | string
%
%   Output Arguments:
%     res - cReadModel object
%
%   Examples:
%     res = ValidateModelTables('dataModel.xlsx','Show',true);
%     res = ValidateModelTables('dataModel.csv','SaveAs','dataModel.json');
%
%   See also cReadModelTables, cModelTables, cModelData
%   
    %Check input arguments
    res=cMessageLogger();
    if nargin<1 
        res.printError(cMessages.ShowHelp);
        return
    end
    if ~isFilename(filename)
        res.printError(cMessages.InvalidInputFile);
        return
    end
    if ~exist(filename,'file')
        res.printError(cMessages.FileNotFound,filename);
        return
    end  
    % Optional parameters
    p = inputParser;
    p.addParameter('Show',false,@islogical);
    p.addParameter('SaveAs',cType.EMPTY_CHAR,@isFilename);
    try
		p.parse(varargin{:});
    catch err
		res.printError(err.message);
        res.printError(cMessages.ShowHelp);
        return
    end
    param=p.Results;
    % Read the data model depending the file extension
    [fileType,ext]=cType.getFileType(filename);
    switch fileType
        case cType.FileType.CSV
            res=cReadModelCSV(filename);
        case cType.FileType.XLSX
            res=cReadModelXLS(filename);
        otherwise
            res.printError(cMessages.InvalidFileExt,upper(ext));
            return
    end
    % Print log messages
    printLogger(res)
    if res.status
        res.printInfo(cMessages.ValidDataModel,res.ModelName);
    else
        res.printError(cMessages.InvalidDataModelFile,filename);
    end
    % Show data tables
    if param.Show && res.status
        printModelTables(res);
    end
    % Optional copy
    if ~isempty(param.SaveAs) && res.status
        saveDataModel(res.ModelData,param.SaveAs);
    end
end

function saveDataModel(data,filename)
%saveDataModel - Save the data model in a different format (JSON, XML)
    log=cMessageLogger();
    [fileType,ext]=cType.getFileType(filename);
    switch fileType
        case cType.FileType.JSON
            log=saveAsJSON(data,filename);
        case cType.FileType.XML
            log=saveAsXML(data,filename);
        otherwise
            log.printError(cMessages.InvalidFileExt,upper(ext));
            return
    end
    % Check if the file was saved
    if log.status
		log.printInfo(cMessages.InfoFileSaved,data.ModelName,filename);
    else
        log.printLogger();
        log.printError(cMessages.ErrorFileNotSaved,filename);
    end
end