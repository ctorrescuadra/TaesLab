function filepath =getExamplesFilename(folder, name)
%getExamplesFilename - Get the full file path for an example file in TaesLab.
%   Syntax:
%     filepath = getExamplesFilename(folder, name)
%   Input Arguments:
%     folder - Subfolder within the 'Examples' directory (char array)
%            If empty, defaults to cType.DEFAULT_EXAMPLE
%     name   - Name of the example file (char array)
%            If empty, defaults to '<folder>_model.json'
%   Output Arguments:
%     filepath - Full file path to the example file (char array)
%   Example:
%     % Get path to default example model file
%     filepath = getExamplesFilename();
%     % Get path to specific example model file
%     filepath = getExamplesFilename('cgam', 'cgam_model.json');
%     % Get path of the default model file in a specific folder
%     filepath = getExamplesFilename('cgam');
%   See also: cType, fullfile
%
    filepath = cType.EMPTY_CHAR;
%   Validate input arguments
    switch nargin
    case 0      
        folder = cType.DEFAULT_EXAMPLE;
        name = strcat(folder, '_model.json');
    case 1
        if ~(ischar(folder) || isstring(folder)) || isempty(folder)
            return
        end
        name = strcat(folder, '_model.json');
    case 2
        % Both arguments provided
        if ~(ischar(folder) || isstring(folder)) || isempty(folder)
            return
        end
        if ~(ischar(name) || isstring(name)) || isempty(name)
            return
        end
    end
    % Construct full file path
    filepath = fullfile(cType.ExamplesPath, folder, name);
    if ~isfile(filepath)
        filepath = cType.EMPTY_CHAR;
    end
end