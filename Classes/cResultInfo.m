classdef (Sealed) cResultInfo < cModelTables
% cModelResults This class store the results of ExIoLab and provide methods to:
%   - Show the results in console
%   - Show the results in workspace
%   - Show the results in graphic user interfaces
%   - Save the results in files: XLSX, CSV and MAT
%   Methods:
%       obj.graphCost(graph_id)
%       obj.graphDiagnosis(graph_id)
%       obj.graphRecycling
%       obj.showDiagramFP()
%       obj.flowsDiagram(opt)
%       obj.streamProcessDiagram(opt)
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
            if ~isempty(obj) && isValid(obj) && obj.Id==cType.ResultId.THERMOECONOMIC_DIAGNOSIS
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
            log=cStatusLogger(cType.VALID);
            if ~isValid(obj)
                log.messageLog(cType.ERROR,'Invalid Result object',obj.Name);
                log.addLogger(obj);
                return                
            end
            if (obj.Id~=cType.ResultId.THERMOECONOMIC_ANALYSIS) && ...
                (obj.Id~=cType.ResultId.EXERGY_COST_CALCULATOR)
                log.messageLog(cType.ERROR,'Invalid Result Id: %s',obj.Name);
                return
            end  
            if nargin<2
                graph=cType.Tables.PROCESS_ICT;
            end
            if obj.existTable(graph)
                g=cGraphResults(obj.Tables.(graph));
                g.graphCost;
            else
                log.messageLog(cType.ERROR,'Table %s is NOT available',graph);
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
            log=cStatusLogger(cType.VALID);
            if ~isValid(obj)
                log.messageLog(cType.ERROR,'Invalid Result object',obj.Name);
                log.addLogger(obj);
                return                
            end
            if obj.Id~=cType.ResultId.THERMOECONOMIC_DIAGNOSIS
                log.messageLog(cType.ERROR,'Invalid Result Id: %s',obj.Name);
                return
            end  
            if nargin<2
                graph=cType.Tables.MALFUNCTION_COST;
            end
            if obj.existTable(graph)  
                g=cGraphResults(obj.Tables.(graph));
                g.graphDiagnosis;
            else
                log.messageLog(cType.ERROR,'Invalid Table %s',graph);
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
            log=cStatusLogger(true);
            if obj.Id ~= cType.ResultId.SUMMARY_RESULTS
                log.messageLog(cType.ERROR,'Invalid cResultInfo object %s',obj.Name);
                return
            end
            info=obj.Info;
            if nargin==1
                graph=cType.SummaryTables.FLOW_DIRECT_UNIT_COST;
                var=info.getDefaultFlowVariables;
            end
            tbl=obj.getTable(graph);
            if ~isValid(tbl) || ~isGraph(tbl)
                log.messageLog(cType.ERROR,'Invalid graph type: %s',graph);
                return
            end
            if (nargin==2) && ~tbl.isFlowsTable
                log.messageLog(cType.ERROR,'Variables are required for this type: %s',graph);
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
                log.messageLog(cType.ERROR,'Invalid Variable Names');
                return
            end
            % Plot the table
            g=cGraphResults(tbl,idx);
            g.graphSummary;
        end

        function log=graphRecycling(obj,graph)
        % show the recycling graph
            log=cStatusLogger(cType.VALID);
            if obj.Id~=cType.ResultId.RECYCLING_ANALYSIS
                obj.printError('Invalid Result Id: %s',obj.Name);
                return
            end
            if ~isValid(obj.Info)
                obj.PrintError('Invalid Recycling Analysis');
                return
            end
            if nargin==1 || isempty(graph)
                graph=cType.Tables.WASTE_RECYCLING_DIRECT;
            end
            tbl=obj.getTable(graph);
            if ~isValid(tbl)
                obj.printError('Invalid graph table %s',graph);
                return
            end
            wasteFlow=obj.Info.wasteFlow;
            g=cGraphResults(tbl,wasteFlow);
            g.graphRecycling;
        end
        
        function log=showDiagramFP(obj)
        % Show the FP table digraph [only Matlab]
            log=cStatusLogger(cType.VALID);
            if isOctave
                log.messageLog(cType.WARNING,'Function not implemented')
                return
            end
            switch obj.Id
            case cType.ResultId.THERMOECONOMIC_STATE
                graph=cType.Tables.TABLE_FP;
            case cType.ResultId.THERMOECONOMIC_ANALYSIS
                graph=cType.Tables.COST_TABLE_FP;
            case cType.ResultId.DIAGRAM_FP
                obj.Info.plotDiagram;
                return;
            otherwise
                obj.printWarning('Invalid Result Id: %s',obj.Name);
                return
            end
            tbl=obj.getTable(graph);
            if ~isValid(tbl)
                obj.printError('Invalid graph table %s',graph);
                return
            end
            g=cDiagramFP(tbl);
            g.plotDiagram;
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
            if obj.Id~=cType.ResultId.PRODUCTIVE_STRUCTURE
                obj.printWarning('Invalid Result Id: %s',obj.Name);
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

        function log=saveDiagramFP(obj,filename)
        % Save the Adjacency matrix of the Diagram FP in a file
        % The following file types are availables (XLSX,CSV,MAT)
        %  Input:
        %   filename - Name of the file
        %  Output:
        %   log - cStatusLogger object containing the status and error messages
            log=cStatusLogger(cType.VALID);
            if obj.Id==cType.ResultId.DIAGRAM_FP
                log=saveResults(obj,filename);
            else
                log.printError(cType.ERROR,'Result object is NOT a DIAGRAM_FP');
                return
            end
        end

        function res=saveAdjacencyTable(obj,filename)
        % Save the adjacency table of the actual model state
        % to use with a graph application (as yEd)
        %   Input:
        %       filename - Name of the file
        %   Output:
        %       res - Adjacency table            
            res=[];
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
                log.printError('File %s has NOT been saved',filename);
            end
        end
    end
end