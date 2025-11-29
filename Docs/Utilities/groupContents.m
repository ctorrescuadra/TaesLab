function groupContents(inFile, outFile)
%groupContents - Read Contents.xlsx and generate grouped Contents.json
%
% Syntax:
%   groupContents()
%   groupContents(inFile)
%   groupContents(inFile, outFile)
%
% Inputs Arguments
%   inFile  - (optional) path to the input JSON (default: ./Contents.xlsx)
%   outFile - (optional) path for the grouped JSON (./Contents.json)
%
% Example:
%   groupFunctions(); % Reads Contents.xlsx and writes Contents.json
%   groupFunctions('C:/MyFolder/Contents.xlsx', 'C:/MyFolder/Contents.json');
%

    log=cMessageLogger();
    scriptFolder = fileparts(mfilename('fullpath'));
    if isempty(scriptFolder)
        scriptFolder = pwd;
    end
    defaultIn = fullfile(scriptFolder, 'Contents.xlsx');

    if nargin < 1 || isempty(inFile)
        inFile = defaultIn;
    end
    inFile = char(inFile);

    if nargin < 2 || isempty(outFile)
        outFile = fullfile(fileparts(inFile), 'Contents.json');
    end
    outFile = char(outFile);

    % Basic checks
    if ~exist(inFile, 'file')
        log.printError(cMessages.FileNotFound, inFile);
        return
    end
    res=struct();
    % Read Index sheet
    sFolder=importXLSX(log,inFile,'Index');
    if ~log.status
        printLogger(log)
        return
    end
    % Validate expected structure
    if ~isfield(sFolder, {'Name','Description','Content','Groups'})
        log.printError('groupContents:InvalidFormat', ...
            'Input XLSX must contain "Name","Description","Content","Groups" fields in Index sheet');
        return
    end
    % Get the output structure by folders (Base, Functions, Classes,...) order by group
    for i=1:length(sFolder)
        fld=sFolder(i);
        content=importXLSX(log,inFile,fld.Content);
        if ~log.status
            printLogger(log);
            return
        end
        groups=importXLSX(log,inFile,fld.Groups);
        if ~log.status
            printLogger(log);
            return
        end
        fldName=fld.Name;
        gFolder=groupFolder(content,groups);
        if ~isempty(gFolder)
            res.(fldName).Name=fld.Name;
            res.(fldName).Description=fld.Description;
            res.(fldName).Groups=gFolder;
        else
            log.printError('groupContent:InvalidData',fldName)
        end
    end
    exportJSON(res,outFile);
end

function sout=groupFolder(content,groups)
%groupFolder - Groups the Files information using the field Group.
% Syntax:
%   sout = groupFolder(content, groups)
%
% Inputs:
%   content - content input structure
%   groups  - groups input structure
%
% Output:
%   sout - output grouped content structure

    % Validate substructure
    sout=cType.EMPTY;
    if ~isfield(content, {'Name','Description','Group'})
        printError(cMessages.InvalidContentData, ...
            'Input JSON must contain second-level "Content" "Description" "Group" fields');
        return
    end
    if ~isfield(groups, {'Name','Description','Id'})
        printError(cMessages.InvalidGroupData, ...
            'Input JSON must contain second-level "Groups" "Description" "Id" fields');
        return
    end
    % Group parameters
    NG=length(groups);
    ginfo=cell(NG,1);
    gfiles=[content.Group];
    % Process each group
    for i=1:NG
        idx=find(gfiles==i);
        N=length(idx);
        dfiles=cell(N,1);
        % Get Files substructure
        for j=1:N
            jdx=idx(j);
            dfiles{j}=struct('Name',content(jdx).Name,...
                        'Description',content(jdx).Description);
        end
        % Get Group structure
        ginfo{i}=struct('Name',groups(i).Name,...
                    'Description',groups(i).Description,...
                    'Files',cell2mat(dfiles));
    end
    sout=cell2mat(ginfo);
end

function res=importXLSX(log, filename, sheet)
%importXLSX - Import data from an Excel sheet into a structure array
% Syntax:  
%   res=importXLSX(log, filename, sheet)
% Inputs:
%   log      - cMessageLogger object for logging errors and warnings
%   filename - path to the Excel file
%   sheet    - name of the sheet to import
% Output:
%   res - structure array with the imported data
%
    res=cType.EMPTY;
    % Read data from Excel
    try
		values=readcell(filename,'Sheet',sheet);
    catch err
		log.printError(cMessages.FileNotFound, err.message);
        return
    end
    % Validate data
    if isempty(values) || size(values,1)<2
        log.printError(cMessages.EmptyData, filename, sheet);
        return
    end
    % Convert to structure
    fields=values(1,:);
    data=values(2:end,:);
    res=cell2struct(data,fields,2);
end

