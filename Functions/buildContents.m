function buildContents(folder, output)
%buildContents - Build the Content.m file of a directory
%
%   Syntax;
%     buildContents(dir, output)
%
%   Input Arguments:
%     folder - directory name 
%     output - file name of the Contents help
%
    % Default Parameters
    if nargin < 1
        folder = '.'; 
    end
    if nargin < 2
        output = 'Contents.txt';
    end
    % Get the files of the directory
    files = dir(fullfile(folder, '*.m'));
    flen=max(cellfun(@length,{files.name}))+2;
    fmt=sprintf('%s %%-%ds - %%s\n','%%',flen);
    % Open output file
    fid = fopen(output, 'w');
    if fid == -1
        error('Output file could not be opem.');
    end

    for k = 1:length(files)
        name = files(k).name;
        path = fullfile(folder, name);
        Description = getComment(path);      
        fprintf(fid, fmt, name, Description);
    end

    fclose(fid);
    fprintf('Contents Index created in: %s\n', fullfile(folder,output));
end

function res = getComment(filename)
%getComment - read file until first comment line and extract it
%   Input:
%     filename - Name of file to extact comment
%   Output:
%     res - Comment line 
    fid = fopen(filename, 'r');
    res = '(No Description)';
    if fid == -1
        return;
    end

    while ~feof(fid)
        line = strtrim(fgetl(fid));
        if startsWith(line, '%')
            res = regexprep(line,'%\w+ - ',cType.EMPTY_CHAR);
            break;
        end
    end
    fclose(fid);
end


