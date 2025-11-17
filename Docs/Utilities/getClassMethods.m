function [res, tbl] = getClassMethods(obj)
%getClassMethods - Get a cTableData object with method information using metaclass
%
% Syntax:
%   tbl = getClassMethods(obj)
%
% Input Arguments:
%   obj - Any MATLAB object or class name (string/char)
%
% Output Arguments:
%   res - cTableData object with method information
%   tbl - MATLAB table with columns (optional):
%         Name          - Method name
%         Description   - Method description from help text
%         Access        - Access level (public, private, protected, etc.)
%         DefiningClass - Class where method is defined
%
% Example:
%   tbl = getClassMethods('cTable');
%   printTable(tbl);
%
    tbl=cType.EMPTY;
    % Handle input: object or class name
    if ischar(obj) || isstring(obj)
        className = char(obj);
        mc = meta.class.fromName(className);
        if isempty(mc)
            error('getClassMethods:InvalidClass', 'Class "%s" not found', className);
        end
    else
        error('getClassMethods:InvalidInput', 'Input must be an cTaesLab or class name (string/char)');
    end

    % Get all methods from the metaclass
    methods = mc.MethodList;
    numMethods = numel(methods);
    if numMethods == 0
        return
    end

    % Preallocate cell arrays
    Name = cell(numMethods, 1);
    Description = cell(numMethods, 1);
    Access = cell(numMethods, 1);
    DefiningClass = cell(numMethods, 1);

    % Extract method information
    for k = 1:numMethods
        m = methods(k);
        Name{k} = m.Name;
        Description{k} = m.Description;
        Access{k} = char(m.Access);
        DefiningClass{k} = m.DefiningClass.Name;
    end

    % Create MATLAB table to filter and sort
    tbl = table(Name, Description, DefiningClass, Access, ...
        'VariableNames', {'Name', 'Description', 'DefiningClass', 'Access'});
    tbl.Properties.Description = mc.Description;  % Add class description
    tbl.Properties.UserData = mc.Name;        % Add class name
    % Sort by Name for easier reading
    tbl = tbl(~ismember(tbl.DefiningClass, {'handle','cTaesLab','cMessageLogger'}), :);
    tbl = tbl(strcmp(tbl.Access, 'public'), :);
    tbl = tbl(~strcmp(tbl.Name, 'empty'), :);
    tbl = sortrows(tbl, {'DefiningClass', 'Name'});
    % Create cTableData object
    data = table2cell(tbl);
    rowNames = tbl.Name';
    colNames = tbl.Properties.VariableNames(1:2);
    props.Name=tbl.Properties.UserData;
    props.Description=[props.Name,' - ',tbl.Properties.Description];
    res = cTableData(data(:,2), rowNames, colNames, props);
end