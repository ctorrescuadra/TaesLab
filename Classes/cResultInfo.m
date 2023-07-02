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
%       obj.showsFlowsDiagram;
%   Methods inhereted from cModelTables
%       obj.getTable(table)
%       obj.printTable(table)
%       obj.printResults;
%       obj.printIndexTable;
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

        function setProperties(obj,model,state)
        % Set model and state properties
        %   Input:
        %       model - Model name
        %       state - state of the results
            setProperties@cModelTables(obj,model,state);
            % Assign the state value to all the tables of the object
            cellfun(@(x) setState(x,state),obj.tableIndex);
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
        %
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
            tbl=obj.getTable(graph);
            if isValid(tbl) && isGraph(tbl)
                g=cGraphResults(tbl);
                g.graphCost;
            else
                log.printError('Invalid graph type: %s',graph);
                return
            end
        end
        
        function graphDiagnosis(obj,graph)
        % Shows a barplot of diagnosis table values for a given state 
        %   Usage:
        %       obj.graphDiagnosis(graph)
        %   Input:
        %       graph - (optional) table name to plot
        %           cType.Graph.MALFUNCTION (mf)
        %           cType.Graph.MALFUNCTION_COST (mfc)
        %           cType.Graph.IRREVERSIBILITY (dit)
        %       If graph is not selected first option is taken
        %  
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
            end
            tbl=obj.getTable(graph);
            if isValid(tbl) && isGraph(tbl)
                g=cGraphResults(tbl);
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
            if (nargin==2) && ~tbl.isFlowsTable
                log.printError('Variables are required for this type: %s',graph);
                return
            end
            if nargin==2
                var=obj.Info.getDefaultFlowVariables;
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
        %
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
            tbl=obj.getTable(graph);
            if ~isValid(tbl)
                log.printError('Table %s is NOT available',graph);
                return
            end
            wasteFlow=obj.Info.wasteFlow;
            g=cGraphResults(tbl,wasteFlow);
            g.graphRecycling;
        end

        function graphWasteAllocation(obj,wkey)
        % Shows a pie chart of the waste allocation table
        %   Usage:
        %       obj.graphWasteAllocation(wkey)
        %   Input:
        %       wkey - (optional) waste key key.
        %       If not selected first waste is taken.
            log=cStatus(cType.VALID);
            if ~isValid(obj)
                log.printError('Invalid object %s',obj.ResultName);
                return
            end
    
            if obj.ResultId==cType.ResultId.WASTE_ANALYSIS
                wt=obj.Info;
            elseif obj.ResultId==cType.ResultId.EXERGY_COST_CALCULATOR || ...
                   obj.ResultId==cType.ResultId.THERMOECONOMIC_ANALYSIS
                wt=obj.Info.WasteData;
            else
                log.printError('Invalid Result Id: %s',obj.ResultName);
                return
            end
            if nargin==2
                wid=wt.getWasteIndex(wkey);
                if isempty(wid)
                    log.printError('Invalid waste flow key %s',wkey);
                    return
                end
            else
                wid=1;
            end
            g=cGraphResults(obj.Tables.wa,wid);
            g.graphWasteAllocation;
        end

        function showDiagramFP(obj)
        % Show the FP table digraph [only Matlab]
        %   Usage:
        %       obj.showDiagramFP;
            log=cStatus(cType.VALID);
            if isOctave
                log.printError('Function not implemented')
                return
            end
        switch obj.ResultId
        case cType.ResultId.DIAGRAM_FP
            tbl=obj.Tables.tfp;
        case cType.ResultId.THERMOECONOMIC_STATE
            tbl=obj.Tables.tfp;
        case cType.ResultId.THERMOECONOMIC_ANALYSIS
            tbl=obj.Tables.dcfp;
        otherwise
            printWarning('Invalid Result Info %s',obj.ResltName)
        end
        g=cGraphResults(tbl);
        g.showDigraph;
        end

        function showFlowsDiagram(obj)
        % Show the flows diagram of the productive structure [Only Matlab]
        %   Usage:
        %       obj.showFlowsDiagram;
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