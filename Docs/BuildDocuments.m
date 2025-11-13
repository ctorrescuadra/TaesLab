function [tables,log]=BuildDocuments(folder,filename)
    log=cMessageLogger();
    tables={};
    if nargin~=2 || isempty(folder) || ~(ischar(folder) || isstring(folder))
        log.printError(cMessages.InvalidArgument);
        return
    end
    folder=char(folder);
    if ~isFilename(filename)
        log.printError(cMessages.InvalidArgument)
        return
    end
    Contents=importJSON(log,'Contents.json');
    if ~log.status
        printLogger(log);
    end
    folders=fieldnames(Contents);
    if ~ismember(folder,folders)
        log.printError(cMessages.InvalidArgument,folder);
        return
    end
    docData=Contents.(folder);
    NG=length(docData);
    tables=cell(NG,1);
    for i=1:length(docData)
        group=docData(i);
        colNames=fieldnames(group.Files);
        rowNames={group.Files.Name};
        values={group.Files.Description}';
        p=struct('Name',group.Name,'Description',group.Description);
        tables{i}=cTableData(values,rowNames,colNames,p);
    end
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
