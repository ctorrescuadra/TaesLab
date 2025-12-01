function BuildClassesDoc(outfile)
% BuildClassesDoc - Generate documentation for all classes in the project.
%   This function scans the 'Classes' directory for all class files,
%   retrieves their method information, and generates a documentation file
%   in the specified format (Markdown, LaTeX, TXT, HTML or MHLP).
%
%   Syntax: 
%     BuildClassesDoc(outfile)
%   
%   Input Arguments:
%     outfile - Output file name for the generated documentation (default: 'ClassesDoc.m')
%      The file extension determines the format
% 
%   Example:
%     % Create a Markdown file with all the public methods of the classes.
%     BuildClassesDoc('MyClassesDoc.md')
%
%   See also: getClassInfo, saveDocument
%
    log=cTaesLab();
    if isOctave
        res.printError(cMessages.FunctionNotAvailable)
        return
    end
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
    % Scan 'Classes' directory for class files
    classPath=[cType.TaesLabPath,'\Classes'];
    fileNames = dir(fullfile(classPath,'*.m'));
    % Process each class file
    for k = 1:length(fileNames)
        [~, className] = fileparts(fileNames(k).name);
        tbl=getClassInfo(className,'Methods');
        if isObject(tbl,'cTable')
            saveDocument(fId,tbl,fileType);
        end
    end
    fclose(fId);
    log.printInfo(cMessages.FileSaved,outfile)
end
