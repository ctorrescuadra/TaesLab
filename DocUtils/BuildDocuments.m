function BuildDocuments(folder,outfile)
% BuildDocuments - Build documentation tables of TaesLab and save them to file
%   This functon read the Contents.json file and builds documentation tables
%   for the specified folder. The tables are then saved to the specified file
%   in the format determined by the file extension.
%   The valid file extensions are: .m, .mhlp, .txt, .tex, .md, .html
%   The Contents.json file contains the name and the description of the 
%   M-files of the TaesLab toolbox grouped by its functionality.
%   By default it builds the Contents.m file for TaesLab that contains the
%   base functions
%
%   Syntax:
%     Build
%     BuildDocuments(folder,filename)
%
%   Input Arguments:
%     folder - (char or string) Name of the folder in the Contents.json file
%              for which the documentation tables are to be built.
%              Valid folder names are the field names of the Contents.json file.
%              If missing 'Base' folder is used.
%     filename - (char or string) Name of the file where the tables will be saved.
%              The file extension determines the format of the saved file.
%              If missing 'Contents.m' is used.
%
%   Examples:
%     % Build the Contents.m file for Base functions
%     BuildDocuments;
%     % Build documentation tables for the 'Functions' folder and save them as Markdown:
%     BuildDocuments('Functions', 'Functions.md');
%
    log=cTaesLab();
    % Set default arguments if missing
    if nargin < 1 
        folder = 'Base';
        outfile = 'Contents.m';
    elseif nargin==1
        outfile = 'Contents.m';
    end
    % Check folder argument
    if isempty(folder) || ~(ischar(folder) || isstring(folder))
        log.printError(cMessages.InvalidArgument,cMessages.ShowHelp);
        return
    end
    % Validate output file name
    if ~isFilename(outfile)
        log.printError(cMessages.InvalidArgument,'outfile')
        return
    end
    % Import Contents.json file
    path=fileparts(mfilename("fullpath"));
    cfgfile=fullfile(path,'Contents.json');
    Contents=importJSON(log,cfgfile);
    if ~log.status
        printLogger(log);
    end
    folders=fieldnames(Contents);
    if ~ismember(folder,folders)
        log.printError(cMessages.InvalidArgument,folder);
        return
    end
    % Open the output file
    try
        fId = fopen (outfile, 'wt');
    catch err
        log.printError(err.message);
        log.printError(cMessages.FileNotSaved,outfile);
        return
    end
    [fileType,fileExt] = cType.getFileType(outfile);
    if fileType < cType.FileType.TXT
        log.printWarning(cMessages.InvalidFileExt, upper(fileExt));
        return
    end
    % Build documentation tables
    docData=Contents.(folder);
    for i=1:length(docData.Groups)
        group=docData.Groups(i);
        colNames=fieldnames(group.Files);
        rowNames={group.Files.Name};
        values={group.Files.Description}';
        p=struct('Name',group.Name,'Description',group.Description);
        tbl=cTableData(values,rowNames,colNames,p);
        if isObject(tbl,'cTable')
            saveDocument(fId,tbl,fileType);
        else
            printLogger(tbl);
        end
    end
    fclose(fId);
    log.printInfo(cMessages.FileSaved,outfile)
end