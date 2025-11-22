function res=mt2td(T)
%MT2TD - Convert MATLAB table to cTableData object.
%   It extracts the data, row names, and column names from the table.
%   Description and Name table properties are also extracted (if available).
%   MATLAB tables could be used for filter or sort the information before
%   convert to cTableData object. cTableData is used to show the data in
%   in the TaesLab interfaces.
%
%   Syntax:
%      res=mt2td(T)
%
%   Input Arguments:
%      T - MATLAB table
%
%   Output Arguments:
%      res - cTableData object containing the data from the table T
%      
%   Examples:
%      % Create a sample MATLAB table
%      T = table([1; 2; 3], [4; 5; 6], 'VariableNames', {'A', 'B'}, 'RowNames', {'Row1', 'Row2', 'Row3'});
%      T.Properties.Description = 'Sample Table';
%      T.Properties.UserData = 'SampleTableName';
%      % Convert to cTableData
%      ctd = mt2td(T);
%
    res=cMessageLogger();
    % Check Input Arguments 
    if nargin < 1 || isOctave || isempty(T) || ~istable(T)
        res.messageLog(cType.ERROR,cMessages.InvalidArgument);
        return
    end
    % Check the size of the table
    if any(size(T)<2)   
        res.messageLog(cType.ERROR,cMessages.NoValuesAvailable);
        return
    end
    % Build the cTableData from table info
    try
        % Get row and column names
        colNames = T.Properties.VariableNames;
        if ~isempty(T.Properties.RowNames)
            rowNames = T.Properties.RowNames';
            data=table2cell(T);
        else
            values=table2cell(T);
            rowNames = values(:,1);
            data=values(:,2:end);
        end
        % Set cTable properties
        if ~isempty(T.Properties.UserData)      
            props.Name = T.Properties.UserData;
        else
            props.Name = 'NoName';
        end
        if ~isempty(T.Properties.Description)
            props.Description = T.Properties.Description;
        else
            props.Description = 'No Description';
        end
    catch err
        res.messageLog(cType.ERROR, err.message);
        res.messageLog(cType.ERROR, cMessages.InvalidTableValues);
        return
    end
    props.Description=horzcat(props.Name,' - ',props.Description);
    res = cTableData(data,rowNames,colNames,props);
end