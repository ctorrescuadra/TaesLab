function SaveClassesInfo(outfile)
%SaveClassesInfo - Save documentation for all classes using ClassInfo.json
%   This function reads the 'ClassInfo.json' configuration file and generates
%   a documentation file in the specified format (Markdown, LaTeX, TXT, HTML or MHLP).
%
%   Syntax: 
%     SaveClassesInfo(outfile)
%
%   Input Arguments:
%     outfile - Output file name for the generated documentation (default: 'ClassesDoc.md')
%       The file extension determines the format
%
%   Example:
%     % Create a Markdown file with all the public methods of the classes.
%     SaveClassesInfo('MyClassesDoc.md')
%
%   See also: buildClassInfo, saveDocument
%
    log=cMessageLogger();
    if isOctave
        res.printError(cMessages.FunctionNotAvailable)
        return
    end
    % Read ClassInfo configuration file
    inPath=fileparts(mfilename('fullpath'));
    infile=fullfile(inPath,'ClassInfo.json');
    cfg=importJSON(log,infile);
    % Set default output file if not provided
    if nargin < 1
        outfile = 'ClassesDoc.md';
    end
    % Validate output file name
    if ~isFilename(outfile)
        log.printError(cMessages.InvalidArgument,'outfile')
        return
    end
    % Try to open the output file
    try
        fId = fopen (outfile, 'wt');
    catch err
        log.printError(err.message);
        log.printError(cMessages.FileNotSaved,outfile);
        return
    end
    [fileType,fileExt] = cType.getFileType(outfile);
    if fileType < cType.FileType.TXT
        log.printError(cMessages.InvalidFileExt, upper(fileExt));
        return
    end
    % Generate output document
    colNames=fieldnames(cfg(1).Methods);
    for i=1:length(cfg)
        p=struct('Name',cfg(i).Name,'Description',cfg(i).Description);
        grp=cfg(i).Methods;
        values=[colNames,struct2cell(grp)];
        tbl=cTableData.create(values',p);
        if isObject(tbl,'cTable')
            saveDocument(fId,tbl,fileType);
        end
    end
    fclose(fId);
    log.printInfo(cMessages.FileSaved,outfile)
end