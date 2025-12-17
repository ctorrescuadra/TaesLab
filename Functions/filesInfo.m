function res = filesInfo(folder, pattern)
%filesInfo - Get information about files in a TaesLab folder matching a pattern.
%   Syntax:
%     res = filesInfo(folder, pattern)
%   Input Arguments:
%     folder - Folder path relative to TaesLab root
%       if empty, current working directory is used
%     pattern - File name pattern (e.g., '*.mat')
%   Output Arguments:
%     res - Structure array with file information
%   Example:
%     info = filesInfo('Classes', '*.m' ); % Get info about .m files in 'Classes' folder
%     info = filesInfo('', '*.txt' ); % Get info about .txt files in current folder
%   See also: dir, isfolder, fullfile, cType
%
    res = cType.EMPTY;
    % Validate input arguments
    if nargin~=2 || ~ischar(folder) || ~ischar(pattern)
        return
    end
    % Determine full folder path    
    if isempty(folder)
        folder = pwd;
    else
        folder = fullfile(cType.TaesLabPath, folder);
    end
    % Get file information
    try
        res = dir (fullfile(folder, pattern));
    catch
        return
    end
end