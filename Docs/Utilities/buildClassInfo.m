function buildClassInfo()
%buildClassInfo - Build the class info configuration file
%   This function create/update the file 'ClassInfo.json'
%   which contains the name and description of all public methods
%   of the TaesLab toolbox classes
%
%   Syntax:
%     buildClassInfo();
%
    % Get the classes file names
    classPath=[cType.TaesLabPath,'\Classes'];
    fileNames = dir(fullfile(classPath,'*.m'));
    % Process each class file
    N=length(fileNames);
    classes=cell(N,1); cnt=0;
    for k = 1:length(fileNames)
        [~, className] = fileparts(fileNames(k).name);
        tbl=getClassInfo(className,'Methods');
        if isObject(tbl,'cTable')
            cnt=cnt+1;
            classes{cnt}=struct('Name',tbl.Name,...
                        'Description',tbl.Description,...
                        'Methods',tbl.exportTable(cType.VarMode.STRUCT));
        end
    end
    sout=cell2mat(classes(1:cnt));
    % Create the output file 'ClassInfo.json'
    outPath=fileparts(mfilename('fullpath'));
    outfile=fullfile(outPath,'ClassInfo.json');
    log=exportJSON(sout,outfile);
    if log.status
        log.printInfo(cMessages.FileSaved,outfile);
    else
        log.printLogger;
    end
end