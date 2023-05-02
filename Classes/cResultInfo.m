classdef (Sealed) cResultInfo < cModelTables
% cModelResults This class store the results of ExIoLab and provide methods to:
%   - Show the results in console
%   - Show the results in workspace
%   - Show the results in graphic user interfaces
%   - Save the results in files: XLSX, CSV and MAT
%   Methods:
%       obj.getFuelImpact
%       obj.graphCost(graph_id)
%       obj.graphDiagnosis(graph_id)
%       obj.graphSummary(graph_id)
%       obj.graphRecycling(graph_id)
%       obj.showDiagramFP()
%       obj.flowsDiagram(opt)
%       obj.saveDiagramFP(filename)
%       obj.saveAdjacencyTable(filename)
%   Methods inhereted from cModelTables
%       log=obj.saveResults(name)
%       res=obj.printResults(obj)
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
            setProperties@cModelTables(obj,model,state);
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

        function log = graphCost(obj,graph)
        % graphCost shows a barplot with the irreversibilty cost table values for a given state 
        % Input:   
        %   graph: Select the graph to plot
        %     cType.Graph.PROCESS_COST (dict)
        %     cType.Graph.PROCESS_GENERALIZED_COST (gict)
        %     cType.Graph.FLOW_COST (dfict)
        %     cType.GraphMatrixTable.FLOW_GENERALIZED_COST (gfict)
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
            if nargin<2
                graph=cType.Tables.PROCESS_ICT;
            end
            if obj.existTable(graph)
                g=cGraphResults(obj.Tables.(graph));
                g.graphCost;
            else
                log.printError('Table %s is NOT available',graph);
                return
            end
        end
        
        function log=graphDiagnosis(obj,graph)
        % graphDiagnosis shows a barplot of diagnosis table values for a given state 
        % Input:
        %  graph - type of graph to plot
        %    cType.Graph.MALFUNCTION (mf)
        %    cType.Graph.MALFUNCTION_COST (mfc)
        %    cType.Graph.IRREVERSIBILITY (dit)
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
            if nargin<2
                graph=cType.Tables.MALFUNCTION_COST;
            end
            if obj.existTable(graph)  
                g=cGraphResults(obj.Tables.(graph));
                g.graphDiagnosis;
            else
                log.printError('Table %s is NOT available',graph);
                return
            end
        end

        function log=graphSummary(obj,graph,var)
        % Plot summary tables
        %   Input:
        %      graph - Data to plot
        %      var - Variables to plot
        %
            %Check input arguments
            log=cStatus(cType.VALID);
            if ~isValid(obj)
                log.printError('Invalid Result object %s',obj.ResultName);
                return                
            end
            if ~isValid(obj)
                log.printError('Invalid Result object %s',obj.ResultName);
                return                
            end
            if obj.ResultId ~= cType.ResultId.SUMMARY_RESULTS
                log.printError('Invalid cResultInfo object %s',obj.ResultName);
                return
            end
            info=obj.Info;
            if nargin==1
                graph=cType.SummaryTables.FLOW_DIRECT_UNIT_COST;
                var=info.getDefaultFlowVariables;
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
                var=info.getDefaultFlowVariables;
            end
            if tbl.isFlowsTable
                idx=info.getFlowIndex(var);
            else
                idx=info.getProcessIndex(var);
            end
            if cType.isEmpty(idx)
                log.printError('Invalid Variable Names');
                return
            end
            % Plot the table
            g=cGraphResults(tbl,idx);
            g.graphSummary;
        end

        function log=graphRecycling(obj,graph)
        % Show the recycling graph
        %   Input:
        %       graph - Name of the table to graph
            log=cStatus(cType.VALID);
            if ~isValid(obj)
                log.printError('Invalid object %s',obj.ResultName);
                return
            end
            if obj.ResultId~=cType.ResultId.RECYCLING_ANALYSIS
                log.printError('Invalid Result Id: %s',obj.ResultName);
                return
            end
            if ~isValid(obj.Info)
                log.printError('Invalid Recycling Analysis');
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

        function log = graphWasteAllocation(obj,wkey)
        % Show a pie chart of the waste allocation table
        %   Input:
        %       wkey - waste flow key
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

        function log=showDiagramFP(obj)
        % Show the FP table digraph [only Matlab]
            log=cStatus(cType.VALID);
            if isOctave
                log.printError('Function not implemented')
                return
            end
            if obj.ResultId ~= cType.ResultId.DIAGRAM_FP
                log.printError('Invalid Result Object %s', obj.ResultName);
                return
            end
            g=cGraphResults(obj.Tables.atfp);
            g.showDigraph;
        end

        function res=flowsDiagram(obj,opt)
        % Show the flows diagram of the productive structure
        %   Input:
        %       opt - (true/false) show the digraph plot
        %   Output:
        %       res - Flow graph adjacency matrix
            res=[];
            if nargin==1
                opt=false;
            end
            if obj.ResultId~=cType.ResultId.PRODUCTIVE_STRUCTURE
                log.printError('Invalid Result Id: %s',obj.ResultName);
                return
            end
            if ~isValid(obj.Info)
                obj.printError('Invalid Productive Structure');
                return
            end
            opt=opt & isMatlab;
            % Get the characteristic matrix of flows
            A=obj.Info.StructuralMatrix;
            [idx,jdx]=find(A);
            nodenames=obj.Info.FlowKeys;
            source=nodenames(idx);
            target=nodenames(jdx);
            res=[{'source','target'};[source',target']];
            % Plot the graph
            if opt
                dg=digraph(source,target,'omitselfloops');
                figure('menubar','none',...
                    'name','Productive Structure Diagram', ...
                    'resize','on','numbertitle','off');
                plot(dg,'Layout','force');
                title('Flows Digraph');
            end
        end

        function log=saveAdjacencyTable(obj,filename)
        % Save the adjacency table of the actual model state
        % to use with a graph application (as yEd)
        %   Input:
        %       filename - Name of the file
        %   Output:
        %       res - Adjacency table            
            log=cStatusLogger(cType.VALID);
            if isValid(obj.Info) && isa(obj.Info,'cExergyModel')
                res=getAdjacencyTable(obj.Info);
            else
                log.printError('Invalid ResultInfo');
                return
            end
            if ~cType.checkFileWrite(filename)
                log.printError('Invalid file name: %s',filename);
                return
            end
            fileType=cType.getFileType(filename);
            switch fileType
                case cType.FileType.CSV
                    slog=exportCSV(res,filename);
                case cType.FileType.XLSX
                    slog=exportXLS(res,filename);
            otherwise
                log.printError('File extension %s is not supported',filename);
                return
            end
            log.addLogger(slog);
            if log.isValid
                log.printInfo('File %s has been saved',filename);
            else
                log.printLogger;
                log.printError('File %s has NOT been saved',filename)
            end
        end
    end
end