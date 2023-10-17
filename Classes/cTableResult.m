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

        function res=isGraph(obj)
        % Check if the table has a graph associated
            res=(obj.GraphType ~= cType.GraphType.NONE);
        end

        function showGraph(obj, varargin)
        % Show table values as graph
        %  Input:
        %   varargin - Options depending on graph type. 
        %  See cResultInfo/showGraph
        %
            g=cGraphResults(obj, varargin{:});
            if ~isValid(g)
                g.printLogger;
                g.printError('Invalid graph parameters. See error log.');
                return
            end
            g.showGraph;
        end
    end
end
