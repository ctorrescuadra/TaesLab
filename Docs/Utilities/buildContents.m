function tbl=buildContents(folder,filename)
%buildContents - Get a cTableData object with the description of .m files in a folder
%   If filename is provided, save a file with these information
%   The available formats are:  CSV, XLSX, JSON, XML, TXT, HTML, LaTeX, MD and MAT
%
%   Syntax:
%     tbl=buildContents()
%     tbl=buildContents(folder)
%     buildContents(folder,filename)
%
%   Input Arguments:
%     folder - folder to scan (default: current folder)
%     filename - file name of the Contents help (default: 'Contents.m')
%   Output Arguments:
%     tbl - cTableData object with the contents information
%
%   Examples:
%     tbl = buildContents();
%      This command get a cTableData with the name and description of
%      all *.m files of the current folder
%     tbl = buildContents('C:/MyFolder')
%      This command get a cTableData with the name and description of
%      all *.m files of the folder C:/MyFolder  
%     tbl = buildContents('.','mFiles.txt)
%      This command generate also a file called mFiles.txt
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
        folder = '.';
        filename = cType.EMPTY;
    elseif nargin == 1
        filename = cType.EMPTY;
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
    p.Name = getFolderName(folder);
    p.Description = ['Contents of the folder ', p.Name];
    fields={'Name','Description'};
    tbl=cTableData(Description,Name,fields,p);
    if ~tbl.status
        tbl.messageLog(cType.ERROR,cMessages.InvalidTableData);
        printLogger(tbl);
        return
    end
    % Save the Content file if required.
    if isFilename(filename)
        log=tbl.saveTable(filename);
        if log.status
            log.printInfo(cMessages.TableFileSaved,tbl.Name,filename);
        else
            printLogger(log);
        end
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
    fId = fopen(filename, 'r');
    res = '(No Description)';
    if fId == -1
        return;
    end
    % Read lines until first comment
    while ~feof(fId)
        line = strtrim(fgetl(fId));
        if startsWith(line, '%')
            res = regexprep(line,'%\w+ - ',cType.EMPTY_CHAR);
            break;
        end
    end
    fclose(fId);
end

function res = getFolderName(folder)
%getFolderName - extract the folder name from a path
    oldpwd = pwd;
    cd(folder);
    tokens = regexp(pwd, '[^\\/]+', 'match');
    res = tokens{end};
    cd(oldpwd);
end