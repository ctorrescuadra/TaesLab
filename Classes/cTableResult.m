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
        %  Input:
        %   state - (optional) state name
        %
            vt=cViewTable(obj);
            vt.showTable
        end

        function res=isGraph(obj)
        % Check if the table has a graph associated
            res=(obj.GraphType ~= cType.GraphType.NONE);
        end

        function showGraph(obj,varargin)
        % Show the graph associated to the table
            log=cStatus(cType.VALID);
            if obj.isGraph
                g=cGraphResults(obj,varargin{:});
                if ~isValid(g)
                    g.printLogger;
                    return
                end
                switch obj.GraphType
                    case cType.GraphType.COST
                        g.graphCost;
                    case cType.GraphType.DIAGNOSIS
                        g.graphDiagnosis;
                    case cType.GraphType.SUMMARY
                        g.graphSummary;
                    case cType.GraphType.DIAGRAM_FP
                        g.showDigraph;
                    case cType.GraphType.DIGRAPH
                        g.showDigraph;
                    case cType.GraphType.RECYCLING
                        g.graphRecycling;
                    case cType.GraphType.WASTE_ALLOCATION
                        g.graphWasteAllocation;
                    otherwise
                        log.printWarning('Table %s has not a valid graph type',obj.Name);
                end 
            else
                log.printWarning('Table %s has not a graph associated',obj.Name);
            end
        end
    end
end
