function saveDocument(fId,tbl,fileType)
%saveDocument - Save class information to file in specified format
%   Syntax:
%     saveDocument(fId,tbl,fileType)
%   Input Arguments:
%     fId      - File identifier of the opened output file
%     tbl      - cTableData object containing class information
%     fileType - Type of the output file format (cType.FileType)
%
    switch fileType
        case cType.FileType.MCNT
            saveAsContents(fId,tbl);
        case cType.FileType.MHLP
            saveAsHelpInfo(fId,tbl)
        case cType.FileType.TXT
            printTable(tbl,fId);
        case cType.FileType.LaTeX
            ltx = cBuildLaTeX(tbl);
            fprintf(fId,'%s',ltx.getLaTeXcode);
        case cType.FileType.MD
            md = cBuildMarkdown(tbl);
            fprintf(fId,'%s',md.getMarkdownCode);
        case cType.FileType.HTML
            html = cBuildHTML(tbl);
            fprintf(fId,'%s',html.getMarkupHTML);
    end
end

function saveAsContents(fId,tbl)
%saveAsContents - Save tables in the .mhlp format
%   Syntax:
%     saveAsContents(log,tables,filename)
%   Input Arguments:
%     log - (cMessageLogger) Logger object for logging messages
%     tables - (cell array of cTableData) Documentation tables to be saved
%     filename - (char or string) Name of the file to save the tables
%
    % Determine the maximum length of first column
    cw = getColumnWidth(tbl);
    fmt = sprintf('%s %%-%ds - %%s\n','%%  ',cw(1));
    % Print tables into file
    fprintf(fId,'%%\n');
    fprintf(fId,'%% %s\n',tbl.Description);
    for k = 1:tbl.NrOfRows
        fprintf(fId, fmt, tbl.RowNames{k}, tbl.Data{k,1});
    end
end

function saveAsHelpInfo(fId,tbl)
%saveAsContents - Save table in the .mhlp format
%   Syntax:
%     saveAsContents(fId,tbl)
%   Input Arguments:
%     fId - File identifier of the opened output file
%     tbl - cTableData containing the documentation table to be saved
%
    % Determine the maximum length of first column
    cw = getColumnWidth(tbl);
    fmt = sprintf('%s %%-%ds - %%s\n','%%    ',cw(1));
    % Print tables into file
    fprintf(fId,'%%   %s:\n',tbl.Description);
    for k = 1:tbl.NrOfRows
        fprintf(fId, fmt, tbl.RowNames{k}, tbl.Data{k,1});
    end
    fprintf(fId,'%%\n');
end