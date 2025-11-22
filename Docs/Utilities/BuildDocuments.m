function [tables,log]=BuildDocuments(folder,filename)
% BuildDocuments - Build documentation tables of TaesLab and save them to file
%   This functon read the Contents.json file and builds documentation tables
%   for the specified folder. The tables are then saved to the specified file
%   in the format determined by the file extension.
%   The valid file extensions are: .mhlp, .txt, .tex, .md
%   The Contents.json file contains the name and the description of the M-files of
%   the TaesLab toolbox grouped by its functionality.
%
%   Syntax:
%     [tables,log]=BuildDocuments(folder,filename)
%
%   Input Arguments:
%     folder - (char or string) Name of the folder in the Contents.json file
%              for which the documentation tables are to be built.
%              Valid folder names are the field names of the Contents.json file.
%     filename - (char or string) Name of the file where the tables will be saved.
%              The file extension determines the format of the saved file.
%
%   Output Arguments:
%     tables - (cell array of cTableData) Cell array containing the built documentation tables.
%     log - (cMessageLogger) Logger object containing messages about the execution status.
%
%   Examples:
%     % Build documentation tables for the 'Functions' folder and save them as Markdown:
%     BuildDocuments('Functions', 'Functions.md');
%
    log=cMessageLogger();
    tables=cType.EMPTY_CELL;
    % Validate input arguments
    if nargin~=2 || isempty(folder) || ~(ischar(folder) || isstring(folder))
        log.printError(cMessages.InvalidArgument);
        return
    end
    folder=char(folder);
    if ~isFilename(filename)
        log.printError(cMessages.InvalidArgument)
        return
    end
    % Import Contents.json file
    Contents=importJSON(log,'Contents.json');
    if ~log.status
        printLogger(log);
    end
    folders=fieldnames(Contents);
    if ~ismember(folder,folders)
        log.printError(cMessages.InvalidArgument,folder);
        return
    end
    % Build documentation tables
    docData=Contents.(folder);
    NG=length(docData);
    tables=cell(NG,1);
    for i=1:length(docData.Groups)
        group=docData.Groups(i);
        colNames=fieldnames(group.Files);
        rowNames={group.Files.Name};
        values={group.Files.Description}';
        p=struct('Name',group.Name,'Description',group.Description);
        tables{i}=cTableData(values,rowNames,colNames,p);
    end
    % Save tables to file
    fileType =cType.getFileType(filename);
    switch fileType
        case cType.FileType.MHLP
            saveAsContents(log,tables,filename);
        case cType.FileType.TXT
            saveAsText(log,tables,filename);
        case cType.FileType.LaTeX
            saveAsLaTeX(log,tables,filename);
        case cType.FileType.MD
            saveAsMarkdown(log,tables,filename);
    end
end

function saveAsContents(log,tables,filename)
%saveAsContents - Save tables in the .mhlp format
%   Syntax:
%     saveAsContents(log,tables,filename)
%   Input Arguments:
%     log - (cMessageLogger) Logger object for logging messages
%     tables - (cell array of cTableData) Documentation tables to be saved
%     filename - (char or string) Name of the file to save the tables
%
    % Determine the maximum length of first column
    cw=0;
    for i=1:length(tables)
        tmp = getColumnWidth(tables{i});
        cw = max(cw,tmp(1));
    end
    fmt=sprintf('%s %%-%ds - %%s\n','%%  ',cw);
    % Open the file
    try
        fId = fopen(filename, 'w');
    catch err
        log.messageLog(cType.ERROR,err.message)
        log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
        return;
    end
    % Print tables into file
    fprintf(fId,'%%\n');
    for i=1:length(tables)
        tbl=tables{i};
        fnames=tbl.RowNames;
        fdesc=tbl.Data; 
        fprintf(fId,'%% %s\n',tbl.Description);
        for k = 1:length(fnames)
            fprintf(fId, fmt, fnames{k}, fdesc{k});
        end
        fprintf(fId,'%%\n');
    end
    fclose(fId);
end

function saveAsText(log,tables,filename)
%saveAsText - Save tables in plain text format
%   Syntax:
%     saveAsText(log,tables,filename)
%   Input Arguments:
%     log - (cMessageLogger) Logger object for logging messages
%     tables - (cell array of cTableData) Documentation tables to be saved
%     filename - (char or string) Name of the file to save the tables
%
    % Open text file
    try
        fId = fopen (filename, 'wt');
    catch err
        log.messageLog(cType.ERROR,err.message);
        log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
        return
    end
    % Print tables into file
    cellfun(@(x) printTable(x,fId),tables);
    fclose(fId);
end

function saveAsLaTeX(log,tables,filename)
%saveAsLaTeX - Save tables in LaTeX format
%   Syntax:
%     saveAsLaTeX(log,tables,filename)
%   Input Arguments:
%     log - (cMessageLogger) Logger object for logging messages
%     tables - (cell array of cTableData) Documentation tables to be saved
%     filename - (char or string) Name of the file to save the tables
%
    % Open text file
    try
        fId = fopen (filename, 'wt');
    catch err
        log.messageLog(cType.ERROR,err.message);
        log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
        return
    end
    % Save the tables in the file
    for i=1:length(tables)
        ltx=cBuildLaTeX(tables{i});
        fprintf(fId,'%s',ltx.getLaTeXcode);
    end
    fclose(fId);
end

function saveAsMarkdown(log,tables,filename)
%saveAsMarkdown - Save tables in Markdown format
%   Syntax:
%     saveAsMarkdown(log,tables,filename)
%   Input Arguments:
%     log - (cMessageLogger) Logger object for logging messages
%     tables - (cell array of cTableData) Documentation tables to be saved
%     filename - (char or string) Name of the file to save the tables
%
    % Open text file
    try
        fId = fopen (filename, 'wt');
    catch err
        log.messageLog(cType.ERROR,err.message)
        log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
        return
    end
    % Save the tables in the file
    for i=1:length(tables)
        md=cBuildMarkdown(tables{i});
        fprintf(fId,'%s',md.getMarkdownCode);
    end
    fclose(fId);
end
