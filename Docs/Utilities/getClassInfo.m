function [res, tbl] = getClassInfo(obj,info,filename)
%getClassInfo - Get class information using metaclass
%   Syntex:
%      [res, tbl] = getClassInfo(obj,info,filename)
%   Input Arguments:
%      obj      - class name (string or char)
%      info     - type of information to get. It could be:
%                   cType.ClassInfo.PROPERTIES
%                   cType.ClassInfo.METHODS
%      filename - (optional) file name to save the information. If not
%                 provided, the function only return the cTableData object
%   Output Arguments:
%      res  - cTableData object containing the class information
%      tbl  - MATLAB table object containing the class information
%
%   Examples:
%      % Get public properties of cThermoeconomicModel class
%      [res, tbl] = getClassInfo('cThermoeconomicModel', cType.ClassInfo.PROPERTIES);
%      % Save public methods of cThermoeconomicModel class to a text file
%      [res, tbl] = getClassInfo('cThermoeconomicModel', cType.ClassInfo.METHODS, 'cThermoeconomicModel_Methods.txt');
%
    res=cTaesLab();
    tbl=cType.EMPTY;
    % Check Inputs
    if isOctave
        res.printError(cMessages.FunctionNotAvailable)
        return
    end
    try 
        narginchk(2,3)
    catch err
        res.printError(err);
        res.printError(cMessages.NarginError);
        return
    end
    if ~ischar(obj) && ~isstring(obj)
        res.printError(cMessages.InvalidArgument);
        return
    end
    if ~ischar(info) && ~isstring(info)
        res.printError(cMessages.InvalidArgument);
        return
    end
    option=cType.getClassInfo(info);
    if isempty(option)
        res.printError(cMessages.InvalidClassInfo,info);
        return
    end
    % Get metaclass information
    className = char(obj);
    mc = meta.class.fromName(className);
    if isempty(mc)
        res.printError(cMessages.ClassNotFound,className);
        return
    end
    % Prepare table info
    switch option
        case cType.ClassInfo.PROPERTIES
            cInfo = mc.PropertyList;
            Access={cInfo.GetAccess}';
        case cType.ClassInfo.METHODS
            cInfo = mc.MethodList;
            Access={cInfo.Access}';
    end
    VarNames={'Name','Description','DefiningClass','Access'};
    Name={cInfo.Name}';
    Description={cInfo.Description}';
    tmp={cInfo.DefiningClass}';
    DefiningClass=cellfun(@(x) x.Name,tmp,'UniformOutput',false);
    % Create MATLAB table to filter and sort
    tbl = table(Name,Description, DefiningClass, Access, ...
          'VariableNames', VarNames);
    tbl.Properties.Description = mc.Description;
    tbl.Properties.UserData = mc.Name;
    % Sort by Name for easier reading
    tbl = tbl(~strcmp(tbl.Name, 'empty'), :);
    tbl = tbl(~ismember(tbl.DefiningClass, {'handle','cTaesLab','cMessageLogger'}), :);
    tbl = tbl(strcmp(tbl.Access, 'public'), :);
    tbl = sortrows(tbl, {'DefiningClass', 'Name'});
    % Create cTableData object
    data = table2cell(tbl);
    rowNames = tbl.Name';
    colNames = tbl.Properties.VariableNames(1:2);
    props.Name=tbl.Properties.UserData;
    props.Description=[props.Name,' ',info];
    res = cTableData(data(:,2), rowNames, colNames, props);
    % Save Properties table if it is required
    if nargin==2
        return
    end
    fileType=cType.getFileType(filename);
    if fileType==cType.FileType.MHLP
        saveAsContents(cMessageLogger,res,filename)
    else
        saveTable(res,filename);
    end
end

function saveAsContents(log,tbl,filename)
%saveAsContents - Save table in the .mhlp format
%   Syntax:
%     saveAsContents(log,tbl,filename)
%   Input Arguments:
%     log - (cMessageLogger) Logger object for logging messages
%     tbl - (cTableData) Documentation table to be saved
%     filename - (char or string) Name of the file to save the table
%
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
    fprintf(fId,'%%   %s:\n',tbl.Description);
    for k = 1:tbl.NrOfRows
        fprintf(fId, fmt, tbl.RowNames{k}, tbl.Data{k,1});
    end
    fprintf(fId,'%%\n');
    fclose(fId);
end