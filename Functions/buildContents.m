function tbl=buildContents(filename,folder)
%buildContents - Get a cTableData object with the description of .m files in a folder
%   By default, MATLAB uses the Contents.m file to show the help of a directory.
%   This function builds the Contents.m file scanning all the .m files in a folder.
%   The first comment line of each .m file is extracted and used as the
%   description for that file in the Contents.m file.
%   If a file does not have comments, the description '(No Description)' is used.
%   If filename is 'Contents.m', the file is saved in the MATLAB help format.
%   If filename has a different extension than .m, the file is saved in that
%   format using the cTableData/saveTable method.
%
%   Syntax;
%     buildContents(filename,folder)
%
%   Input Arguments:
%     filename - file name of the Contents help (default: 'Contents.m')
%     folder - folder to scan (default: current folder)
%   Output Arguments:
%     tbl - cTableData object with the contents information
%
%   Examples:
%     tbl = buildContents('Contents.m','C:\MyFolder');
%     This command builds the Contents.m file in the folder C:\MyFolder
%     scanning all the .m files in the folder.
%     tbl = buildContents('Contents.m');
%     This command builds the Contents.m file in the current folder
%     scanning all the .m files in the folder.
%   See also: cTableData/saveTable
%
    tbl=cMessageLogger();
    % Default Parameters
    try 
        narginchk(0,2); 
    catch
        tbl.printError(cMessages.NarginError,cMessages.ShowHelp);
        return
    end
    if nargin == 0
        filename = 'Contents.m';
        folder = '.';
    end
    if nargin == 1
        folder = '.';
    end
    % Get the files of the directory
    files = dir(fullfile(folder, '*.m'));
    % Exclude Contents.m from the list
    fileNames = {files.name};
    idx = strcmpi(fileNames, 'Contents.m');
    files(idx) = [];
    % Check if there are still files after exclusion
    if isempty(files)
        tbl.printWarning(cMessages.NoMFilesInDir,folder);
        return
    end
    % Extract names and descriptions
    N=length(files);
    Name=cell(1,N);
    Description=cell(N,1);
    for k = 1:N
        tmp = files(k).name;
        [~,Name{k}] = fileparts(tmp);
        path = fullfile(folder, tmp);
        Description{k} = getComment(path);
    end
    p=struct('Name','Contents','Description','Contents of the file index');
    fields={'Name','Description'};
    tbl=cTableData(Description,Name,fields,p);
    if ~tbl.status
        tbl.messageLog(cType.ERROR,cMessages.InvalidTableData);
        printLogger(tbl);
        return
    end
    % Save the Contents file
    fileType =cType.getFileType(filename);
    if fileType == cType.FileType.MHLP
        log=exportContents(tbl,filename);
    else
        log=tbl.saveTable(filename);
    end
    % Print log messages
    if log.status
        log.printInfo(cMessages.TableFileSaved,tbl.Name,filename);
    else
        printLogger(log);
        return
    end
end

function res = getComment(filename)
%getComment - read file until first comment line and extract it
%   Input:
%     filename - Name of file to extact comment
%   Output:
%     res - Comment line
%
    % Open the file
    fid = fopen(filename, 'r');
    res = '(No Description)';
    if fid == -1
        return;
    end
    % Read lines until first comment
    while ~feof(fid)
        line = strtrim(fgetl(fid));
        if startsWith(line, '%')
            res = regexprep(line,'%\w+ - ',cType.EMPTY_CHAR);
            break;
        end
    end
    fclose(fid);
end

function log=exportContents(obj,filename)
%exportContents - Save the Contents.m file in the folder
%   Input:
%     filename - Name of the Contents.m file
%     Name - Cell array with names of functions/files
%     Description - Cell array with descriptions of functions/files
%   Output:
%     log - cMessageLogger object with status and messages
%
    log = cMessageLogger();
    fnames=obj.RowNames;
    fdesc=obj.Data;
    cw = getColumnWidth(obj);
    fmt=sprintf('%s %%-%ds - %%s\n','%%',cw(1));
    try
        fid = fopen(filename, 'w');
        for k = 1:length(fnames)
            fprintf(fid, fmt, fnames{k}, fdesc{k});
        end
        fclose(fid);
    catch
        log.messageLog(cType.ERROR,err.message)
        log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
        return;
    end
end


