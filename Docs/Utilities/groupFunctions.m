function outFile = groupFunctions(inFile, outFile)
%groupTablesByGroup - Read list.json and produce a grouped JSON by Group field
%
% Syntax:
%   outFile = groupTablesByGroup()
%   outFile = groupTablesByGroup(inFile)
%   outFile = groupTablesByGroup(inFile, outFile)
%
% Inputs:
%   inFile  - (optional) path to the input JSON (default: Functions/list.json
%             located next to this script)
%   outFile - (optional) path for the grouped JSON (default:
%             same-folder/list_grouped.json)
%
% Output:
%   outFile - full path to the written grouped JSON file
%
% The output JSON has this structure:
%  {
%    Folder: {
%      Groups: [
%        "Name": "rdmb",
%        "Description": "Read Data Model Function",
%        "Files": [ { ... }, { ... } ]
%      },
%      ...
%    ]
%  }
%
% Example:
%   groupFunctions(); % reads Docs/Contents.json and writes Dosc/Contents_grouped.json
%

    % locate default input (Functions/Contents.json next to this script)
    log=cMessageLogger();
    scriptFolder = fileparts(mfilename('fullpath'));
    if isempty(scriptFolder)
        scriptFolder = pwd;
    end
    defaultIn = fullfile(scriptFolder, 'Contents.json');

    if nargin < 1 || isempty(inFile)
        inFile = defaultIn;
    end
    inFile = char(inFile);

    if nargin < 2 || isempty(outFile)
        outFile = fullfile(fileparts(inFile), 'Contents_grouped.json');
    end
    outFile = char(outFile);

    % Basic checks
    if ~exist(inFile, 'file')
        error('groupFunctions:FileNotFound', 'Input file not found: %s', inFile);
    end
    % Read and decode JSON
    data=importJSON(log,inFile);
    if ~log.status
        printLogger(log)
        return
    end
    % Validate expected structure
    if ~isfield(data, {'Base','Functions','Classes'})
        error('groupFunctions:InvalidFormat', ...
            'Input JSON must contain top-level "Base" "Functions" and "Classes" fields');
    end
    % Get the output structure by folders (Base, Functions, Classes,...) order by group
    folders=fieldnames(data);
    for i=1:length(folders)
        fld=folders{i};
        res.(fld)=groupFolder(data.(fld));
    end
    exportJSON(res,outFile);
end

function sout=groupFolder(sin)
%groupFolder - Groups the Files information using the field Group.
% Syntax:
%   sout = groupFolder(sin)
%
% Inputs:
%   sin - input structure
%
% Output:
%   sout - output structure

    % Validate substructure
    if ~isfield(sin, {'Groups','Files'})
        error('groupFunctions:InvalidFormat', ...
            'Input JSON must contain second-level "Groups" "Files" fields');
    end
    % Group parameters
    NG=length(sin.Groups);
    ginfo=cell(NG,1);
    gfiles=[sin.Files.Group];
    % Process each group
    for i=1:NG
        idx=find(gfiles==i);
        N=length(idx);
        dfiles=cell(N,1);
        % Get Files substructure
        for j=1:N
            jdx=idx(j);
            dfiles{j}=struct('Name',sin.Files(jdx).Name,...
                        'Description',sin.Files(jdx).Description);
        end
        % Get Group structure
        ginfo{i}=struct('Name',sin.Groups(i).Name,...
                    'Description',sin.Groups(i).Description,...
                    'Files',cell2mat(dfiles));
    end
    sout=cell2mat(ginfo);
end

