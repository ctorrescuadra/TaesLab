classdef (Abstract) cTableResult < cTable
% cTableResult Abstrat class to store results into a cTable
%
% cTableResults Properties
%   Format - Format of the table columns
%   Unit   - Units of the table columns
%
% See also cTable, cTableMatrix, cTableCell
%
    properties (GetAccess=public, SetAccess=protected)
        Format    % Format of the table cells
        Unit      % Units of the table cell
    end
    methods      
        function res=exportTable(obj,varmode,fmt)
        % Get cTable info in diferent types of variables
        % Input:
        %   varmode - type of variable
        %   fmt - use formatted data true | false (default)
            switch nargin
                case 1
                    varmode=cType.VarMode.NONE;
                    fmt=false;
                case 2
                    fmt=false;
            end
            switch varmode
                case cType.VarMode.CELL
                    res=obj.getCellData(fmt);
                case cType.VarMode.STRUCT
                    res=obj.getStructData(fmt);
                case cType.VarMode.TABLE
                    if isMatlab
                        res=obj.getMatlabTable;
                    else
                        res=obj;
                    end
                otherwise
                    res=obj;
            end
        end

        function res=getCellData(obj,fmt)
        % Get table as cell array
        %  Input:
        %   fmt - (true/false) indicate is the numerical values of the table must be formatted
        %  Output
        %   res - cell array with the table values
            if nargin==1
                fmt=false;
            end
            if fmt
                res=[obj.ColNames;[obj.RowNames',obj.formatData]];
            else    
                res=obj.Values;
            end
        end
    end
end
