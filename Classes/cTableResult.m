classdef (Abstract) cTableResult < cTable
% cTableResult Abstrat class to store ExIOLab results into a cTable
%   Methods:
%       obj=cTableResult(data,rowNames,colNames)
%       res=obj.getFormattedCell(fmt)
%       obj.ViewTable(state)
%   Methods inhereted from cTable:
%       obj.setDescription(text)
%       status=obj.checkTableSize;
%       res=obj.getStructData
%       res=obj.getMatlabTable [only Matlab]

% See also cTable, cTableMatrix, cTableCell
%
    properties (GetAccess=public, SetAccess=protected)
        Format  % Cell array with data format (optional)
        Unit    % Cell array with data units (optional)
    end
    methods    
        function res=getFormattedCell(obj,fmt)
        % Return the table as formatted cell
        %  Input:
        %   fmt - (true/false) indicate is the numerical values of the table must be formatted
        %  Output
        %   res - cell array with the table values
            if fmt
                res=[obj.ColNames;[obj.RowNames',obj.formatData]];
            else    
                res=obj.Values;
            end
        end

        function viewTable(obj,state)
        % View the values of the table (tbl) in a uitable graphic object
        %  Input:
        %   state - (optional) state name
        %
            if nargin==1
                state='';
            end
            vt=cViewTable(obj,state);
            vt.showTable
        end
    end
end
