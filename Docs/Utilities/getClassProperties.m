function [res, tbl] = getClassProperties(obj,filename)
%getClassProperties - Get a MATLAB table with property information using metaclass
%
% Syntax:
%   tbl = getClassProperties(obj)
%
% Input Arguments:
%   obj - Any MATLAB object or class name (string/char)
%
% Output Arguments:
%   res - cTableData object with property information
%   tbl - MATLAB table with columns:
%         Name          - Property name
%         Description   - Property description from help text
%         GetAccess     - Get access level (public, private, protected, etc.)
%         SetAccess     - Set access level (public, private, protected, etc.)
%         DefiningClass - Class where property is defined
%
% Example:
%   tbl = getClassProperties('cTable');
%   disp(tbl);
%

    % Check input and load metaclass info
    if ischar(obj) || isstring(obj)
        className = char(obj);
        mc = meta.class.fromName(className);
        if isempty(mc)
            error('getClassProperties:InvalidClass', 'Class "%s" not found', className);
        end
    else
        error('getClassProperties:InvalidInput', 'Input must be an cTaesLab or class name (string/char)');
    end

    % Get all properties from the metaclass
    props = mc.PropertyList;
    numProps = numel(props);

    if numProps == 0
        return
    end

    % Preallocate cell arrays
    Name = cell(numProps, 1);
    Description = cell(numProps, 1);
    GetAccess = cell(numProps, 1);
    SetAccess = cell(numProps, 1);
    DefiningClass = cell(numProps, 1);

    % Extract property information
    for k = 1:numProps
        p = props(k);
        Name{k} = p.Name;
        Description{k} = p.Description;
        GetAccess{k} = char(p.GetAccess);
        SetAccess{k} = char(p.SetAccess);
        DefiningClass{k} = p.DefiningClass.Name;
    end

    % Create MATLAB table
    tbl = table(Name, Description, DefiningClass, GetAccess, SetAccess, ...
        'VariableNames', {'Name', 'Description', 'DefiningClass','GetAccess', 'SetAccess'});
    tbl.Properties.Description = mc.Description;  % Add class description
    tbl.Properties.UserData = mc.Name;        % Add class name
    % Filter and sort
    tbl = tbl(~ismember(tbl.DefiningClass, {'handle','cTaesLab','cMessageLogger'}), :);
    tbl = tbl(strcmp(tbl.GetAccess, 'public'), :);
    tbl = tbl(~strcmp(tbl.Name, 'empty'), :);
    tbl = sortrows(tbl, {'DefiningClass', 'Name'});
    % Create cTableData object
    data = table2cell(tbl);
    rowNames = tbl.Name';
    colNames = tbl.Properties.VariableNames(1:2);
    pc.Name=tbl.Properties.UserData;
    pc.Description=[pc.Name,' - ',tbl.Properties.Description];
    res = cTableData(data(:,2), rowNames, colNames, pc);
    % Save Properties table if it is required
    if nargin==1
        return
    end
    fileType=cType.getFileType(filename);
    if fileType==cType.FileType.MHLP
        saveAsContents(cMessageLogger,res,filename)
    else
        saveTable(tbl,filename);
    end
end

function saveAsContents(log,tbl,filename)
    % Determine the maximum length of first column
    cw = getColumnWidth(tbl);
    fmt=sprintf('%s     %%-%ds - %%s\n','%%',cw(1));
    % Open the file
    try
        fId = fopen(filename, 'w');
    catch err
        log.messageLog(cType.ERROR,err.message)
        log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
        return;
    end
    % Print tables into file
    fprintf(fId,'%%\n');
    fprintf(fId,'%%   %s Properties:\n',tbl.Name);
    for k = 1:tbl.NrOfRows
        fprintf(fId, fmt, tbl.RowNames{k}, tbl.Data{k,1});
    end
    fprintf(fId,'%%\n');
    fclose(fId);
end
