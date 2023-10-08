classdef (Sealed) cResultInfo < cModelTables
% cResultsInfo This class store the results on internal memory and provide methods to:
%   - Show the results in console
%   - Show the results in workspace
%   - Show the results in graphic user interfaces
%   - Save the results in files: XLSX, CSV and MAT
%   The diferent types (ResultId) of cResultInfo object are defined in cType.ResultId 
%   Methods:
%       obj.getFuelImpact
%       obj.graphCost(table)
%       obj.graphDiagnosis(table)
%       obj.graphSummary(table)
%       obj.graphRecycling(table)
%       obj.showDiagramFP;
%       obj.showFlowsDiagram;
%   Methods inhereted from cModelTables
%       obj.getTable(table)
%       obj.printTable(table)
%       obj.printResults;
%       obj.printIndexTable;
%       obj.showGraph(table,options)
%       obj.viewTable(table);
%       log=obj.saveResults(filename)
%       res=obj.getResultTables(varmode,fmt)
% See: cResultTableBuilder, cTableResult
%
    properties (GetAccess=public, SetAccess=private)
        Info    % Result Info
    end

    methods
        function obj = cResultInfo(info,tbl)
        % class constructor
            obj=obj@cModelTables(info.ResultId,tbl);
            if ~isa(info,'cResultId') || ~isValid(info)
                obj.messageLog(cType.ERROR,'Invalid Results object')
            end
            obj.Info=info;
            obj.status=info.status;
        end

        function res=getFuelImpact(obj)
        % get the Fuel Impact as a string including format and unit
            res='WARNING: Fuel Impact NOT Available';
            if isValid(obj) && obj.ResultId==cType.ResultId.THERMOECONOMIC_DIAGNOSIS
                format=obj.Tables.dit.Format;
                unit=obj.Tables.dit.Unit;
                tfmt=['Fuel Impact:',format,' ',unit];
                res=sprintf(tfmt,obj.Info.FuelImpact);
            end
        end

        function summaryDiagnosis(obj)
        % Show diagnosis summary results
            if isValid(obj) && obj.ResultId==cType.ResultId.THERMOECONOMIC_DIAGNOSIS
                format=obj.Tables.mfc.Format;
                unit=obj.Tables.mfc.Unit;
                tfmt=['Fuel Impact:',format,' ',unit,'\n'];
                fprintf(tfmt,obj.Info.FuelImpact);
                tfmt=['Malfunction Cost:',format,' ',unit,'\n'];
                fprintf(tfmt,obj.Info.TotalMalfunctionCost);
            end
        end

        function fuelImpact(obj)
        % Print the fuel impact of the actual diagnosis state
            fprintf('%s\n',obj.getFuelImpact);
        end

        function graphCost(obj,graph)
        % Shows a barplot with the irreversibilty cost table values for a given state 
        %   Usage:
        %       obj.graphCost(graph)
        %   Input:   
        %       graph - (optional) table name to plot
        %           cType.Tables.PROCESS_COST (dict)
        %           cType.Tables.PROCESS_GENERALIZED_COST (gict)
        %           cType.Tables.FLOW_COST (dfict)
        %           cType.Tables.FLOW_GENERALIZED_COST (gfict)
        %       If graph is not selected first option is taken
        % See also cGraphResults
            % Check input
            log=cStatus(cType.VALID);
            if ~isValid(obj)
                log.printError('Invalid Result object',obj.ResultName);
                return                
            end
            if (obj.ResultId~=cType.ResultId.THERMOECONOMIC_ANALYSIS) && ...
                (obj.ResultId~=cType.ResultId.EXERGY_COST_CALCULATOR)
                log.printError('Invalid Result Id: %s',obj.ResultName);
                return
            end  
            if nargin==1
                graph=cType.Tables.PROCESS_ICT;
            end
            % Get Result Table info and build graph
            tbl=obj.getTable(graph);
            if isValid(tbl) && isGraph(tbl)
                g=cGraphResults(tbl);
                g.graphCost;
            else
                log.printError('Invalid graph type: %s',graph);
                return
            end
        end
        
        function graphDiagnosis(obj,graph,shout)
        % Shows a barplot of diagnosis table values for a given state 
        %   Usage:
        %       obj.graphDiagnosis(graph)
        %   Input:
        %       graph - table name to plot
        %           cType.Graph.MALFUNCTION (mf)
        %           cType.Graph.MALFUNCTION_COST (mfc)
        %           cType.Graph.IRREVERSIBILITY (dit)
        %       If graph is not selected first option is taken
        %       shout - Show output info bar.
        % See also cGraphResults
        %
            % Check input arguments
            log=cStatus(cType.VALID);
            if ~isValid(obj)
                log.printError('Invalid Result object %s',obj.ResultName);
                return                
            end
            if obj.ResultId~=cType.ResultId.THERMOECONOMIC_DIAGNOSIS
                log.printError('Invalid Result Id: %s',obj.ResultName);
                return
            end  
            if nargin==1
                graph=cType.Tables.MALFUNCTION_COST;
                shout=true;
            end
            if nargin==2
                shout=true;
            end
            % Get Result Table info and build graph
            tbl=obj.getTable(graph);
            if isValid(tbl) && isGraph(tbl)
                g=cGraphResults(tbl,shout);
                g.graphDiagnosis;
            else
                log.printError('Invalid graph type: %s',graph);
                return
            end
        end

        function graphSummary(obj,graph,var)
        % Plot summary tables.
        %   Input:
        %       graph - (optional) type of graph to plot
        %           cType.SummaryTables.UNIT_CONSUMPTION (pku)
        %           cType.SummaryTables.PROCESS_DIRECT_UNIT_COST (dpuc)
        %           cType.SummaryTables.FLOW_UNIT_COST (dfuc)
        %           cType.SummaryTables.PROCESS_GENERALIZED_UNIT_COST (gpuc)
        %           cType.SummaryTables.FLOW_GENERALIZED_UNIT_COST (gfuc)
        %       var - (optional) Cell Array indicating the keys of the variables to plot
        %       If var is not selected only the output flows are show if apply.
        % See also cGraphResults
        %
            % Check input arguments
            log=cStatus(cType.VALID);
            if ~isValid(obj)
                log.printError('Invalid Result object %s',obj.ResultName);
                return                
            end
            if obj.ResultId ~= cType.ResultId.SUMMARY_RESULTS
                log.printError('Invalid cResultInfo object %s',obj.ResultName);
                return
            end
            if nargin==1
                graph=cType.SummaryTables.FLOW_UNIT_COST;
                var=obj.Info.getDefaultFlowVariables;
            end
            tbl=obj.getTable(graph);
            if ~isValid(tbl) || ~isGraph(tbl)
                log.printError('Invalid graph type: %s',graph);
                return
            end
            if (nargin==2) || isempty(var)            
                if tbl.isFlowsTable
                    var=obj.Info.getDefaultFlowVariables;
                else
                    log.printError('Variables are required for this type: %s',graph);
                    return
                end
            end
            if tbl.isFlowsTable
                idx=obj.Info.getFlowIndex(var);
            else
                idx=obj.Info.getProcessIndex(var);
            end
            if cType.isEmpty(idx)
                log.printError('Invalid Variable Names');
                return
            end
            % Plot the table
            g=cGraphResults(tbl,idx);
            g.graphSummary;
        end

        function graphRecycling(obj,graph)
        % Shows the recycling graph
        %   Usage:
        %       obj.graphRecycling(obj)
        %   Input:
        %       graph - (optional) name of the table to plot
        %           cType.Graph.WASTE_RECYCLING_DIRECT (rag)
        %           cType.Graph.WASTE_RECYCLING_GENERALIZED (rag)
        % See also cGraphResults
        %
            % Check Input
            log=cStatus(cType.VALID);
            if obj.ResultId~=cType.ResultId.RECYCLING_ANALYSIS
                log.printError('Invalid Result Id: %s',obj.ResultName);
                return
            end
            if ~isValid(obj)
                log.printError('Invalid Result object %s',obj.ResultName);
                return                
            end
            if nargin==1 || isempty(graph)
                graph=cType.Tables.WASTE_RECYCLING_DIRECT;
            end
            % get result table and plot the graph
            tbl=obj.getTable(graph);
            if ~isValid(tbl)
                log.printError('Table %s is NOT available',graph);
                return
            end
            g=cGraphResults(tbl);
            g.graphRecycling;
        end

        function graphWasteAllocation(obj,wkey)
        % Shows a pie chart of the waste allocation table
        %   Usage:
        %       obj.graphWasteAllocation(wkey)
        %   Input:
        %       wkey - (optional) waste key key.
        %       If not selected first waste is taken.
        % See also cGraphResults
        %
            log=cStatus(cType.VALID);
            if ~isValid(obj)
                log.printError('Invalid object %s',obj.ResultName);
                return
            end   
            if obj.ResultId==cType.ResultId.WASTE_ANALYSIS || ...
                obj.ResultId==cType.ResultId.EXERGY_COST_CALCULATOR || ...
                obj.ResultId==cType.ResultId.THERMOECONOMIC_ANALYSIS
                tbl=obj.Tables.wa;
            else
                log.printError('Invalid Result Id: %s',obj.ResultName);
                return
            end
            if nargin==1
                wkey=tbl.ColNames{2};
            end
            g=cGraphResults(tbl,wkey);
            if isValid(g)
                g.graphWasteAllocation;
            else
                log.printError('Invalid waste key %s',wkey);
                return
            end
        end

        function showDiagramFP(obj,graph)
        % Show the FP table digraph [only Matlab]
        %   Usage:
        %       obj.showDiagramFP;
        % See also cGraphResults
        %
            log=cStatus(cType.VALID);
            if isOctave
                log.printError('Function not implemented')
                return
            end
            if nargin==1
                graph=cType.Tables.TABLE_FP;
            end
            tbl=obj.getTable(graph);
            if ~isValid(tbl)
                log.printError('Table %s is NOT available',graph);
                return
            end
            % Show Graph
            g=cGraphResults(tbl);
            g.showDigraph;
        end

        function showFlowsDiagram(obj)
        % Show the flows diagram of the productive structure [Only Matlab]
        %   Usage:
        %       obj.showFlowsDiagram;
        % See also cGraphResults
        %
            log=cStatus(cType.VALID);
            if isOctave
                log.printError('Function not implemented')
                return
            end
            if obj.ResultId ~= cType.ResultId.PRODUCTIVE_DIAGRAM
                log.printError('Invalid Result Object %s', obj.ResultName);
                return
            end
            g=cGraphResults(obj.Tables.fat);
            g.showDigraph;
        end
    end
end