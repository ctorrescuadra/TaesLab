classdef (Abstract) cTableResult < cTable
% cTableResult Abstrat class to store ExIOLab results into a cTable
%   Methods:
%       obj=cTableResult(data,rowNames,colNames)
%       res=obj.getFormattedCell(fmt)
%       obj.ViewTable(state)
%       
%   Methods inhereted from cTable:
%       obj.setDescription(text)
%       status=obj.checkTableSize;
%       res=obj.getStructData
%       res=obj.getMatlabTable [only Matlab]

% See also cTable, cTableMatrix, cTableCell
%
    properties (GetAccess=public, SetAccess=protected)
        State     % State value
        Format    % Format of the table cells
        Unit      % Units of the table cell
        GraphType % Graph Type associated to table
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

        function setState(obj,state)
        % Set state value
            obj.State=state;
        end

        function viewTable(obj)
        % View the values of the table (tbl) in a uitable graphic object
            vt=cViewTable(obj);
            if isValid(vt)
                vt.showTable
            else
                printLogger(vt);
            end
        end

        function res=isGraph(obj)
        % Check if the table has a graph associated
            res=(obj.GraphType ~= cType.GraphType.NONE);
        end

        function showGraph(obj,varargin)
        % Show the graph associated to the table
            g=cGraphResults(obj,varargin{:});
            if isValid(g)
                g.showGraph;
            else
                printLogger(g);
            end
        end
    end
end
