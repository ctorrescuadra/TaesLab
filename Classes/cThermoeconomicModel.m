classdef cThermoeconomicModel < cStatusLogger
% cThermoeconomicModel is an interactive tool for thermoeconomic analysis
% It is the main class of ExIoLab package, and provide the following functionality:
%   - Read and check a thermoeconomic data model
%   - Compute direct and generalized exergy cost
%   - Compare two thermoeconomic states (thermoeconomic diagnosis)
%   - Analize Recycling effects (recycling analysis)
%   - Get Summary Results
%   - Save the data model and results in diferent formats, for further analysis
%   - Show the results tables in console, as GUI tables or graphs
% Methods:
%   Set Methods
%       obj.setState(value)
%       obj.setReferenceState(value)
%       obj.setResourceSample(value)
%       obj.setCostTables(value)
%       obj.setDiagnosisMethod(value)
%       obj.setDebug(value)
%       obj.setSumary(value)
%   Results Info Methods
%       res=obj.productiveStructure
%       res=obj.termoeconomicState(state)
%       res=obj.thermoeconomicAnalysis
%       res=obj.thermoeconomicDiagnosis
%       res=obj.fuelImpact
%       res=obj.recyclingAnalysis
%       res=obj.diagramFP
%       res=obj.productiveDiagram
%       res=obj.summaryResults
%   Model Info Methods
%       res=obj.showProperties
%       res=obj.StateNames
%       res=obj.SampleNames
%       res=obj.WasteFlows
%       res=obj.isResourceCost
%       res=obj.isGeneralCost
%       res=obj.isDiagnosis
%       res=obj.isWaste
%       res=obj.isSummaryEnable
%   Print Methods
%       obj.printIndexTable
%       obj.printResults
%       obj.printSummary(tbl)
%       obj.printResultTable(tbl)
%   View Table Methods
%       obj.viewResultsTable(tbl)
%       obj.viewSummaryTable(tbl)
%   Save Methods
%       log=obj.saveModelResults(filename)
%       log=obj.saveDataModel(filename)
%       log=obj.saveDiagramFP(filename)
%       log=obj.saveProductiveDiagram(filename)
%       log=obj.saveSummary(filename)
%   Graph Methods
%       obj.graphCost(graph)
%       obj.graphDiagnosis(graph,shout)
%       obj.graphSummary(graph,list)
%       obj.graphDiagramFP(graph)
%       obj.graphWasteAllocation(wkey)
%       obj.flowsDiagram
%       obj.resultsGraph(graph, options)
%   Waste Methods
%       res=obj.wasteAllocation
%       res=obj.setWasteType(key,type)
%       res=obj.setWasteValues(key,values)
%       res=obj.setWasteRecycled(key,value)
%   Resources Methods
%       res=obj.ResourceData
%       res=obj.ResourceCost
%       res=obj.getResourceData(sample)
%       res=obj.resourceAnalysis(active)
%       obj.setFlowResource(value)
%       obj.setProcessResource(value)
%       obj.setFlowResourceValue(key,value)
%       obj.setProcessResourceValue(key,value)
%   Exergy Data Methods
%       rex=obj.getExergyData(state)
%       log=obj.setExergyData(state,values)
    properties(GetAccess=public,SetAccess=private)
        DataModel      % Data Model
        ModelName      % Model Name
        StateNames     % Names of the defined states
        SampleNames    % Names of the defined resource samples
        WasteFlows     % Names of the waste flows
        ResourceData   % Resource Data object
        ResourceCost   % Resource Cost object
        FormatData     % cResultTableBuilder object
    end

    properties(Access=public)
        State                  % Active thermoeconomic state
        ReferenceState         % Active Reference state
        ResourceSample         % Active resource cost sample
        CostTables             % Select tables to cost results
        DiagnosisMethod        % Method to calculate fuel impact of wastes
        Summary=false;         % Calculate Summary Results
    end

    properties(Access=private)
        results            % cResultInfo cell array
        rstate             % cModelFPR object cell array
        fmt                % cResultTableBuilder object
        rsd                % cResourceData object
        rsc                % cResourceCost object
        fp0                % Actual reference cModelFPR
        fp1                % Actual operation cModelFRR
        debug              % debug info control
        directCost=true    % Direct cost are obtained
        generalCost=false  % General cost are obtained
        activeSet=false    % set variables control
        activeResource=false % set active resource analysis
    end

    methods
        function obj=cThermoeconomicModel(data,varargin)
        % Construct an instance of the thermoeconomic model
        %   Input:
        %     data - cReadModel object 
        %     varargin - optional paramaters (see ThermoeconomicTool)
        %   
            obj=obj@cStatusLogger(cType.VALID);
            if ~isa(data,'cDataModel')
                obj.messageLog(cType.ERROR,'Invalid data model object');
                printLogger(obj);
                return
            end
            % Check Data Model and Productive Structure
            obj.addLogger(data);
            if ~data.isValid
                obj.messageLog(cType.ERROR,'Invalid data model. See Log');
                printLogger(obj);
                return
            end
            % Create Results Container
            obj.results=cModelResults(data);
            obj.DataModel=data;
            obj.ModelName=data.ModelName;
            % Check optional input parameters
            p = inputParser;
            p.addParameter('State',data.States{1},@ischar);
            p.addParameter('ReferenceState',data.States{1},@ischar)
            p.addParameter('ResourceSample','',@ischar);
            p.addParameter('CostTables',cType.DEFAULT_COST_TABLES,@cType.checkCostTables);
            p.addParameter('DiagnosisMethod',cType.DEFAULT_DIAGNOSIS,@cType.checkDiagnosisMethod);
            p.addParameter('Summary',false,@islogical)
            p.addParameter('Debug',false,@islogical);
            try
                p.parse(varargin{:});
            catch err
                obj.printError(err.message);
                obj.printError('Usage: cThermoeconomicModel(data,param)');
                return
            end
            param=p.Results; 
            % Update Variables
            obj.debug=param.Debug;
            obj.CostTables=param.CostTables;
            obj.DiagnosisMethod=param.DiagnosisMethod;
            if obj.isSummaryEnable
                obj.Summary=param.Summary;
            end
            % Load Exergy values (all states)
            obj.rstate=cell(1,data.NrOfStates);
            for i=1:data.NrOfStates
                rex=data.ExergyData{i};
                if ~rex.isValid
                    obj.addLogger(rex);
                    obj.messageLog(cType.ERROR,'Invalid Exergy Values. See error log');
                    return
                end
                if obj.isWaste
                    wd=data.WasteData;
                    obj.rstate{i}=cModelFPR(rex,wd);
                else
                    obj.rstate{i}=cModelFPR(rex);
                end
            end
            % Set Operation and Reference State
            if isempty(param.State)
                obj.State=data.States{1};
            elseif data.existState(param.State)
                obj.State=param.State;
            else
                obj.printError('Invalid state %s',param.State);
                return
            end
            if isempty(param.ReferenceState)
                obj.ReferenceState=data.States{1};
            elseif data.existState(param.State)
                obj.ReferenceState=param.ReferenceState;
            else
                obj.printError('Invalid state %s',param.RefeenceState);
                return
            end
            % Read print formatted configuration
            obj.fmt=data.FormatData;
            % Read ResourcesCost
            if ~data.checkCostTables(param.CostTables)
                res.printError('Invalid CostTables parameter %s',param.DiagnosisTables);
                return
            end
            if data.isResourceCost
                if isempty(param.ResourceSample)
                    obj.ResourceSample=data.ResourceSamples{1};
                elseif data.existSample(param.ResourceSample)
                    obj.ResourceSample=param.ResourceSample;
                else % Default is used
                    obj.printError('Invalid ResourceSample %s',param.ResourceSample);
                    return
                end
            end
            % Compute initial state results
            obj.activeSet=true;
            obj.setStateInfo;
            obj.setThermoeconomicAnalysis;
            obj.setSummaryResults;
            obj.setThermoeconomicDiagnosis;
        end
        %%%
        % Set (assign) Methods
        function set.State(obj,state)
        % Set State object
            if checkState(obj,state)
                obj.State=state;
                obj.triggerStateChange;
            end
        end

        function set.ReferenceState(obj,state)
        % Set Reference State
            if checkReferenceState(obj,state)
                obj.ReferenceState=state;
                obj.printDebugInfo('Set Reference State: %s',state);
                obj.setThermoeconomicDiagnosis;
                obj.clearResults(cType.ResultId.RESULT_MODEL);
            end
        end

        function set.CostTables(obj,value)
        % Set CostTables parameter
            if obj.checkCostTables(value)
                obj.CostTables=value;
                obj.triggerCostTablesChange;
            end
        end

        function set.ResourceSample(obj,sample)
        % Set Resources sample
            if obj.checkResourceSample(sample)
                obj.ResourceSample=sample;
                obj.triggerResourceSampleChange;
            end
        end

        function set.DiagnosisMethod(obj,value)
        % Set Diagnosis method
            if obj.checkDiagnosisMethod(value)
                obj.DiagnosisMethod=value;
                obj.setThermoeconomicDiagnosis;
                obj.clearResults(cType.ResultId.RESULT_MODEL);
            end
        end

        function set.Summary(obj,value)
        % Set Summary parameter
            if obj.checkSummary(value)
                obj.Summary=value;
                obj.setSummaryResults;
            end
        end

        % Set methods
        function setState(obj,state)
            obj.State=state;
        end
        function setReferenceState(obj,state)
            obj.ReferenceState=state;
        end
        function setCostTables(obj,type)
            obj.CostTables=type;
        end
        function setResourceSample(obj,sample)
            obj.ResourceSample=sample;
        end
        function setDiagnosisMethod(obj,method)
            obj.DiagnosisMethod=method;
        end
        function setSummary(obj,value)
            obj.Summary=value;
        end

        %%%
        % get cResultInfo object
        function res=productiveStructure(obj)
        % Get the Productive Structure cResultInfo object
            res=obj.getResults(cType.ResultId.PRODUCTIVE_STRUCTURE);
        end

        function res=thermoeconomicState(obj,state)
        % Get the Thermoeconomic State cResultInfo object
        % containing the exergy and fuel product table
            if nargin==2
                obj.State=state;
            end
            res=obj.getResults(cType.ResultId.THERMOECONOMIC_STATE);
        end

        function res=thermoeconomicAnalysis(obj)
        % Get the Thermoeconomic Analysis cResultInfo object
        % containing the direct and generalized cost tables
            res=obj.getResults(cType.ResultId.THERMOECONOMIC_ANALYSIS);
        end

        function res=thermoeconomicDiagnosis(obj)
        % Get the Thermoeconomic Diagnosis cResultInfo object
        res=obj.getResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
        end

        function res=summaryResults(obj)
        % Get the Summary Results cResultInfo object
            res=obj.getResults(cType.ResultId.SUMMARY_RESULTS);
        end

        function res=diagramFP(obj)
        % Get the Diagram FP cResultInfo object
        %   Input:
        %       varargin - Optional FP table name
        %           cType.Tables.TABLE_FP (default)
        %           cType.Tables.COST_TABLE_FP       %
        %   Output:
        %       res - cResultInfo (DIAGRAM_FP)
            id=cType.ResultId.DIAGRAM_FP;
            res=obj.getResults(id);
            if isempty(res)
                res=getDiagramFP(obj.fmt,obj.fp1);
                res.setProperties(obj.ModelName,obj.State);
                obj.setResults(res);
                obj.printDebugInfo('DiagramFP activated')
            end
        end

        function res=recyclingAnalysis(obj,wkey)
        % Get the Recycling Analysis cResultInfo object
        %   Input:
        %       wkey - key of the analyzed waste
        %   Output
        %       res - cResultInfo containing the recycling analysis tables:
        %           cType.Tables.RECYCLING_ANALISIS_DIRECT
        %           cType.Tables.RECYCLING_ANALISIS_GENERAL
            log=cStatus();
            if ~obj.isWaste
                log.printError('Model do not has wastes');
                return
            end
            if obj.isGeneralCost
                ra=cRecyclingAnalysis(obj.fp1,obj.rsd);
            else
                ra=cRecyclingAnalysis(obj.fp1);
            end
            if (nargin==1) || isempty(wkey)
                wkey=obj.WasteFlows{1};
            end
            ra.doAnalysis(wkey);
            if isValid(ra)
                param=struct('DirectCost',obj.directCost,'GeneralCost',obj.generalCost);
                res=getRecyclingAnalysisResults(obj.fmt,ra,param);
                res.setProperties(obj.ModelName,obj.State);
            else
                ra.printLogger;
            end
        end

        function res=productiveDiagram(obj)
        % Get the productive diagrams cResultInfo object
        %   Output:
        %       res - cResultInfo (PRODUCTIVE_STRUCTURE) 
            id=cType.ResultId.PRODUCTIVE_DIAGRAM;
            res=obj.getResults(id);
            if isempty(res)
                res=getProductiveDiagram(obj.fmt,obj.productiveStructure.Info);
                res.setProperties(obj.ModelName,'SUMMARY');
                obj.setResults(res);
                obj.printDebugInfo('Productive Diagram has been calculated');
            end
        end

        function res=getFuelImpact(obj)
        % Get the fuel impact (value and unit) of the actual diagnosis state
            res='WARNING: Fuel Impact NOT Available';       
            dgn=obj.thermoeconomicDiagnosis;
            if ~isempty(dgn) && isa(dgn,'cResultInfo')
                res=getFuelImpact(dgn);
            end
        end
    
        function fuelImpact(obj)
        % Print the fuel impact of the actual diagnosis statate
            res=obj.getFuelImpact;
            fprintf('%s\n',res);
        end

        function summaryDiagnosis(obj)
        % Get the diagnosis results summary
            res=obj.thermoeconomicDiagnosis;
            res.summaryDiagnosis;
        end

        %%%
        % Utility methods
        %
        function showProperties(obj)
        % Show the values of the actual parameters of the model
            s=struct('State',obj.State,'ReferenceState',obj.ReferenceState,...
                'ResourceSample',obj.ResourceSample,'CostTables',obj.CostTables,...
                'DiagnosisMethod',obj.DiagnosisMethod,...
                'IsResourceCost',log2str(obj.isResourceCost),...
                'IsDiagnosis',log2str(obj.isDiagnosis),...
                'IsWaste',log2str(obj.isWaste),...
                'Summary',log2str(obj.Summary),...
                'Debug',log2str(obj.debug));
            disp(s);
        end

        function res=get.StateNames(obj)
        % Show a list of the available state names
            res=obj.DataModel.States;
        end

        function res=get.SampleNames(obj)
        % Show a list of the avaliable resource samples
            res=obj.DataModel.ResourceSamples;
        end

        function res=isResourceCost(obj)
        % Indicates if resources cost are defined
            res=obj.DataModel.isResourceCost;
        end

        function res=isGeneralCost(obj)
            res=obj.isResourceCost && obj.generalCost;
        end

        function res=isDiagnosis(obj)
        % Indicates if diagnosis is available.
            res=false;
            %Check is there is more than one state
            if ~obj.DataModel.isDiagnosis
                return
            end
            %Check if diagnosis method is activated
            if cType.getDiagnosisMethod(obj.DiagnosisMethod)==cType.DiagnosisMethod.NONE 
                return
            end
            %Check is operation and reference state are defined
            if isempty(obj.ReferenceState) || isempty(obj.State)
                return
            end
            %Check if operation and refernce states are diferent 
            res=~strcmp(obj.ReferenceState,obj.State);
        end

        function res=isWaste(obj)
        % Indicates if model has wastes
            res=logical(obj.DataModel.isWaste);
        end

        function res=isSummaryEnable(obj)
        % Indicates if summary is available
            res=obj.DataModel.NrOfStates>1;
        end

        function res=get.WasteFlows(obj)
        % get waste flows list (cell aarray)
            res=getWasteFlows(obj.DataModel);
        end

        function res=get.FormatData(obj)
            res=obj.fmt.PrintConfig;
        end

        function res=getResultStates(obj)
        % Get the cModelFPR object of each state (cModelSummary)
            res=obj.rstate;
        end

        function res=getModelInfo(obj)
        % Get the cResultInfo objects of the current state (internal application use)
            res=getModelInfo(obj.results);
        end

        function res=getModelTables(obj)
        % Get a cModelTables object with all tables of the active model
            res=getResults(obj,cType.ResultId.RESULT_MODEL);
            if isempty(res)
                res=getModelTables(obj.results);
                obj.setResults(res)
            end
        end

        function setDebug(obj,dbg)
        % Set debug control variable
            if islogical(dbg) && (obj.debug~=dbg)
                obj.debug=dbg;
            end
        end

        %%%
        % Result presentation methods
        %
        function printResults(obj)
        % Print the result tables on console
            cellfun(@(x) printResults(x), obj.getModelInfo)
        end

        function printSummary(obj,table)
        % Print the summary tables
            log=cStatus();
            if ~obj.isSummaryEnable
                log.printWarning('Summary Requires more than one State');
                return
            end
            if ~obj.Summary
                obj.setSummary(true);
            end
            msr=obj.getResults(cType.ResultId.SUMMARY_RESULTS);
            switch nargin
            case 1
                printResults(msr);
            case 2
                printTable(msr,table);
            end
        end

        function printIndexTable(obj)
        % Print tables index of the result model
            mt=obj.getModelTables;
            mt.printIndexTable;
        end

        function printTable(obj,name)
        % Print an individual table
        %   Input:
        %       name - Name of the table
            mt=obj.getModelTables;
            mt.printTable(name);
        end

        function viewResultsTable(obj,name)
        % View a table in a GUI Table
        %   Input:
        %       name - Name of the table
            mt=obj.getModelTables;
            mt.viewTable(name);
        end

        function viewSummaryTable(obj,name)
        % View a summary table in a GUI Table
            log=cStatus();
            if ~obj.isSummaryEnable
                log.printWarning('Summary Requires more than one State');
                return
            end
            msr=obj.getResults(cType.ResultId.SUMMARY_RESULTS);
            if ~obj.Summary
                obj.setSummary(true);
            end
            viewTable(msr,name);
        end

        %%%
        % Save Results methods
        %
        function log=saveResultsModel(obj,filename)
        % Save results in a file 
        % The following types are availables (XLSX, CSV, MAT)
        %  Input:
        %   filename - Name of the file
        %  Output:
        %   log - cStatusLogger object containing the status and error messages
            mt=obj.getModelTables;
            log=saveResults(mt,filename);
        end

        function log=saveSummary(obj,filename)
        % Save the summary tables into a filename
        % The following file types are availables (JSON,XML,XLSX,CSV,MAT)
        %  Input:
        %   filename - Name of the file
        %  Output:
        %   log - cStatusLogger object containing the status and error messages
            log=cStatus();
            if ~obj.isSummaryEnable
                log.printWarning('Summary Requires more than one State');
                return
            end
            if ~obj.Summary
                obj.setSummary(true);
            end
            msr=obj.getResults(cType.ResultId.SUMMARY_RESULTS);
            log=saveResults(msr,filename);
        end
    
        function log=saveDataModel(obj,filename)
        % Save the data model in a file
        % The following file types are availables (JSON,XML,XLSX,CSV,MAT)
        %  Input:
        %   filename - Name of the file
        %  Output:
        %   log - cStatusLogger object containing the status and error messages
            log=saveDataModel(obj.DataModel,filename);
        end

        function log=saveDiagramFP(obj,filename)
        % Save the Adjacency matrix of the Diagram FP in a file
        % The following file types are availables (XLSX,CSV,MAT)
        %  Input:
        %   filename - Name of the file
        %  Output:
        %   log - cStatusLogger object containing the status and error messages
            log=cStatus();
            res=obj.diagramFP;
            if ~isValid(res)
                printLogger(res)
                log.printError('Result object not available');
                return
            end
            log=saveResults(res,filename);
        end

        function log=saveProductiveDiagram(obj,filename)
        % Save the proctive diagram adjacency tables into a file
        % The following file types are availables (XLSX,CSV,MAT)
        %  Input:
        %   filename - Name of the file
        %  Output:
        %   log - cStatusLogger object containing the status and error messages
            log=cStatus();
            res=obj.productiveDiagram;
            if ~isValid(res)
                res.printLogger(res)
                log.printError('Result object not available');
                return
            end
            log=saveResults(res,filename);
        end

        %%%
        % Graphical methods
        %
        function graphCost(obj,varargin)
        % Shows a barplot with the irreversibilty cost table values for a given state
        %   Usage:
        %     obj.graphCost(graph)
        %   Input:   
        %   graph - table name to plot. Valid Values: 
        %     cType.Tables.PROCESS_COST (dict)
        %     cType.Tables.PROCESS_GENERALIZED_COST (gict)
        %     cType.Tables.FLOW_COST (dfict)
        %     cType.Tables.FLOW_GENERALIZED_COST (gfict)
        %   If graph is ommited first valid value is used.
        % See also cResultInfo/graphCost
            log=cStatus(cType.VALID);
            res=obj.thermoeconomicAnalysis;
            if isempty(res) || ~isValid(res)
                log.printWarning('Thermoeconomic Analysis Results not available');
                return
            end
            graphCost(res,varargin{:});
        end

        function graphDiagnosis(obj,varargin)
        % Shows a barplot of diagnosis table values for a given state
        %   Usage:
        %       obj.graphDiagnosis(graph, shout)
        %   Input:
        %       graph - table name to plot. Valid values
        %           cType.Graph.MALFUNCTION_COST (mfc)
        %           cType.Graph.MALFUNCTION (mf)
        %           cType.Graph.IRREVERSIBILITY (dit)
        %           If graph is ommited first valid value is used. 
        %       shout - Plot output info (true/false)
        % See also cResultInfo/graphDiagnosis
            log=cStatus(cType.VALID);
            res=obj.thermoeconomicDiagnosis;
            if isempty(res) || ~isValid(res)
                log.printWarning('Diagnosis Results not available');
                return
            end
            graphDiagnosis(res,varargin{:});
        end

        function graphSummary(obj,varargin)
        % Show a barplot of the summary cost tables
        %   Usage:
        %       obj.graphSummary(graph, list)
        %   Input:
        %       graph - summary table name to plot.
        %       list (optional) - list of variables to plot
        % See also cResultInfo/graphSummary
            log=cStatus();
            if ~obj.isSummaryEnable
                log.printWarning('Summary Requires more than one State');
                return
            end
            if ~obj.Summary 
                obj.setSummary(true);
            end
            msr=obj.getResults(cType.ResultId.SUMMARY_RESULTS);
            graphSummary(msr,varargin{:});
        end

        function showDiagramFP(obj,graph)
        % Show the diagram FP graph (only Matlab)
        %   Usage:
        %       obj.showDiagramFP(graph)
        %   Input:
        %    graph - Table name to show
        %       cType.Tables.TABLE_FP (tfp)
        %       cType.Tables.COST_TABLE_FP (dcfp)  
            log=cStatus();
            if isOctave
                log.printError('Function NOT inmplemented in Octave');
                return
            end
            if nargin==1
                graph=cType.Tables.TABLE_FP;
            end
            res=obj.thermoeconomicAnalysis;
            if ~isValid(res)
                res.printLogger(res)
                log.printError('Result object not available');
                return
            end
            showDiagramFP(res,graph);
        end

        function graphWasteAllocation(obj,varargin)
        % Show a pie chart with the waste allocation
        %   Usage:
        %       graphWasteAllocation(wkey)
        %   Input:
        %       wkey - (optional) waste key.
        %       If not selected first waste is selected
        % See also cResultInfo/graphWasteAllocation
            res=obj.thermoeconomicAnalysis;
            graphWasteAllocation(res,varargin{:});
        end

        function showFlowsDiagram(obj)
        % Show the flow diagram of a system
        %   Usage:
        %       obj.showFlowsDiagram
        % See also cResultInfo/showFlowDiagram
            res=obj.productiveDiagram;
            res.showFlowsDiagram;
        end
        
        %%%
        % Waste Analysis methods
        %
        function res=wasteAllocation(obj)
        % Show waste information
            res=getWasteResults(obj.fmt,obj.fp1.WasteData);
            res.setProperties(obj.ModelName,obj.State);
            printResults(res);
        end

        function log=setWasteType(obj,key,wtype)
        % Set the waste type allocation method
        %  Input
        %   id - Waste id
        %   wtype - waste allocation type (see cType)
        %
            log=cStatus(cType.VALID);
            if nargin~=3
               log.printError('Usage: obj.setWasteType(key,wtype)');
               return
            end  
            wt=obj.fp1.WasteData;
            if ~wt.setType(key,wtype)  
                log.printError('Invalid waste type %s - %s',key,wtype);
                return
            end
            obj.fp1.setWasteOperators;
            obj.setThermoeconomicAnalysis;
            obj.setSummaryResults;
            if obj.isDiagnosis
                obj.setThermoeconomicDiagnosis;
            end
        end

        function log=setWasteValues(obj,key,val)
        % Set the waste table values
        % Input
        %  id - Waste key
        %  val - vector containing the waste values
            log=cStatus(cType.VALID);
            if nargin~=3
               log.printError('Usage: obj.setWasteValues(key,values)');
               return
            end  
            wt=obj.fp1.WasteData;
            if ~wt.setValues(key,val)
                log.prinError('Invalid waste %s allocation values',key);
                return
            end
            obj.fp1.setWasteOperators;
            obj.setThermoeconomicAnalysis;
            obj.setSummaryResults;
            if obj.isDiagnosis
                obj.setThermoeconomicDiagnosis;
            end
        end
   
        function log=setWasteRecycled(obj,key,val)
        % Set the waste table values
        % Input
        %  id - Waste id
        %  val - vector containing the waste values
            log=cStatus(cType.VALID);
            if nargin~=3
               log.printError('Usage: obj.setWasteRecycled(key,value)');
               return
            end 
            wt=obj.fp1.WasteData;
            if ~wt.setRecycleRatio(key,val)
                log.printError('Invalid waste %s recycling values',key);
                return 
            end
            obj.fp1.setWasteOperators;
            obj.setThermoeconomicAnalysis;
            obj.setSummaryResults;
            if obj.isDiagnosis
                obj.setThermoeconomicDiagnosis;
            end
        end

        %%%
        % Resource Cost Methods
        %
        function res=resourceAnalysis(obj,active)
        % Manage the resource cost analysis
        %   Input:
        %       active - Indicate if resource analysis is active
        %           TRUE: Create a new cResourceData object where changes are made
        %           FALSE: Use the Model Resources Data as usual
        %   Output:
        %       res - cResourceCost object
            res=cStatus(cType.VALID);
            if nargin==1
                active=false;
            end
            if ~obj.isGeneralCost
                res.printError('No Generalized Cost activated');
                return
            end
            obj.activeResource=active;
            sample=obj.ResourceSample;
            if active
                id=obj.DataModel.getSampleId(sample);
                dm=obj.DataModel;
                data=dm.ModelData.ResourcesCost.Samples(id);
                ps=obj.DataModel.ProductiveStructure;
                obj.rsd=cResourceData(data,ps);
                obj.rsc=getResourceCost(obj.rsd,obj.fp1);
            else
                obj.rsd=obj.getResourceData;
                obj.rsc=getResourceCost(obj.rsd,obj.fp1);
                obj.setThermoeconomicAnalysis;
                obj.setSummaryResults;
            end
            res=obj.rsc;
        end

        function res=setFlowResource(obj,c0)
        % Set the resources cost of the flows
        %   Input:
        %       c0 - array containing the flows cost
        %   Output:
        %       res - cResourceCost object 
            res=cStatus(cType.VALID);
            if ~obj.isGeneralCost || ~obj.activeResource
                res.printError('No Generalized Cost activated');
				return
            end
            log=setFlowResource(obj.rsd,c0);
            if isValid(log)
                obj.setThermoeconomicAnalysis;
                obj.setSummaryResults;
                res=obj.rsc;
            else
                printLogger(log);
                res.printError('Invalid Resources Values');
            end
        end

        function res=setFlowResourceValue(obj,key,value)
        % Set resource flow cost value
        %   Input:
        %       key - key of the resource flow
        %       value - resource cost value
        %   Output:
        %       res - cResourceCost object
            res=cStatus(cType.VALID);
            if ~obj.isGeneralCost || ~obj.activeResource
                res.printError('No Generalized Cost activated');
                return
            end
            log=setFlowResourceValue(obj.rsd,key,value);
            if isValid(log)
                obj.setThermoeconomicAnalysis;
                obj.setSummaryResults;
                res=obj.rsc;
            else
                printLogger(log);
                res.printError('Invalid Resources Value %s',key);
            end
        end

        function res=setProcessResource(obj,Z)
        % Set the resource cost of the processes
        %   Input:
        %       Z - array containing the processes cost
        %   Output:
        %       res - cResourceCost object
            res=cStatus(cType.VALID);
            if ~obj.isGeneralCost || ~obj.activeResource
                res.printError('No Generalized Cost activated');
                return
            end          
            log=setProcessResource(obj.rsd,Z);
            if isValid(log)
                obj.setThermoeconomicAnalysis;
                obj.setSummaryResults;
                res=obj.rsc;
            else
                printLogger(log);
                res.printError('Invalid Resources Values');
            end
        end

        function res=setProcessResourceValue(obj,key,value)
        % Set the recource cost of the processes
        %   Input:
        %       key - Process key
        %       value - cost value of the process
        %   Output:
        %       res - cResourceCost object
            res=cStatus(cType.VALID);
            if ~obj.isGeneralCost || ~obj.activeResource
                res.printError('No Generalized Cost activated');
                return
            end
            log=setProcessResourceValue(obj.rsd,key,value);
            if isValid(log)
                obj.setThermoeconomicAnalysis;
                obj.setSummaryResults;
                res=obj.rsc;
            else
                printLogger(log);
                res.printError('Invalid Resources Values');
            end
        end

        function res=getResourceData(obj,sample)
        % get the resource data cost values of sample
            if nargin==1
                sample=obj.ResourceSample;
            end
            res=obj.DataModel.getResourceData(sample);
        end

        function res=get.ResourceData(obj)
        % Get the current values of resource data
            res=obj.rsd;
        end
 
        function res=get.ResourceCost(obj)
        % Get the current values of resource cost
            res=obj.rsc;
        end

        %%%
        % Exergy Data methods
        %
        function res=getExergyData(obj,state)
        % Get cExergyData object of a state
        %   Input:
        %       state - State name. If missing, actual state is used 
            if nargin==1
                state=obj.State;
            end
            res=getExergyData(obj.DataModel,state);
        end
        function log=setExergyData(obj,state,values)
        % Set exergy data values to a state
        %   Input:
        %       state - Name of the State
        %       values - Array with the exergy values of the flows
            log=cStatusLogger(cType.VALID);
            % Check state is no reference 
            if strcmp(obj.ReferenceState,state)
                log.printError('Cannot change ReferenceState values');
                return
            end
            % Set exergy data for state
            data=obj.DataModel;
            log=data.setExergyData(state,values);
            if ~isValid(log)
                printLogger(log);
                return
            end
            idx=data.getStateId(state);
            rex=data.ExergyData{idx};
            % Compute cModelFPR
            if obj.isWaste
                wd=data.WasteData;
                obj.rstate{idx}=cModelFPR(rex,wd);
            else
                obj.rstate{idx}=cModelFPR(rex);
            end
            % Get results
            if strcmp(obj.State,state)
                obj.triggerStateChange;
            else
                obj.State=state;
            end
            obj.setSummaryResults;
        end
    end
    %%%
    % Internal Methods
    methods(Access=private)

        function printDebugInfo(obj,varargin)
        % Print info messages if debug mode is activated
            if obj.debug
                obj.printInfo(varargin{:});
            end
        end

        function res=setStateInfo(obj)
        % Trigger exergy analysis
            idx=obj.DataModel.getStateId(obj.State);
            obj.fp1=obj.rstate{idx};
            if ~obj.activeSet
                return
            end
            res=getExergyResults(obj.fmt,obj.fp1);
            res.setProperties(obj.ModelName,obj.State);
            obj.setResults(res);
            obj.printDebugInfo('Set State: %s',obj.State);
        end

        function setThermoeconomicAnalysis(obj)
        % Trigger thermoeconomic analysis
            if ~obj.activeSet
                return
            end
            % Read resources
            options=struct('DirectCost',obj.directCost,'GeneralCost',obj.generalCost);
            if obj.isGeneralCost
                obj.rsc=getResourceCost(obj.rsd,obj.fp1);
                options.ResourcesCost=obj.rsc;
            end
            % Get cModelResults info
            if obj.fp1.isValid
                res=getThermoeconomicAnalysisResults(obj.fmt,obj.fp1,options);
	            res.setProperties(obj.ModelName,obj.State);
                obj.setResults(res);
                obj.printDebugInfo('Compute Thermoeconomic Analysis for State: %s',obj.State);
            else
                obj.fp1.printLogger;
                obj.fp1.printError('Thermoeconomic Analysis cannot be calculated')
            end
        end

        function res=setThermoeconomicDiagnosis(obj)
        % Trigger thermoeconomic diagnosis
            id=cType.ResultId.THERMOECONOMIC_DIAGNOSIS;
            if ~obj.activeSet
                return
            end
            if ~obj.isDiagnosis
                obj.clearResults(id);
                return
            end
            % Compute diagnosis analysis
            method=cType.getDiagnosisMethod(obj.DiagnosisMethod);
            sol=cDiagnosis(obj.fp0,obj.fp1,method);
            % get cModelResult object
            if sol.isValid
                res=getDiagnosisResults(obj.fmt,sol);
                res.setProperties(obj.ModelName,obj.State);
                obj.setResults(res);
                obj.printDebugInfo('Compute Thermoeconomic Diagnosis for State: %s',obj.State);
            else
                sol.printLogger;
                sol.printError('Thermoeconomic Diagnosis cannot be calculated');
                obj.clearResults(id);
            end
        end

        function res=setSummaryResults(obj)
        % Obtain Summary Results
            id=cType.ResultId.SUMMARY_RESULTS;
            if ~obj.activeSet || ~obj.isSummaryEnable
                return
            end
            res=obj.getResults(id);
            if obj.Summary
                tmp=cModelSummary(obj);
                if tmp.isValid
                    res=getSummaryResults(obj.fmt,tmp);
                    res.setProperties(obj.ModelName,'SUMMARY');
                    obj.setResults(res);
                    obj.printDebugInfo('Summary Results have been Calculated');
                else
                    tmp.printLogger;
                end
            elseif ~isempty(res)
                obj.clearResults(id);
                obj.printDebugInfo('Summary Results have been Desactivated');
            end
        end
        %%%
        % Internal set methods
        function res=checkState(obj,state)
        % Ckeck the state information
            res=false;
            log=cStatus();    
            if ~obj.DataModel.existState(state)
                log.printWarning('Invalid state %s',state);
                return
            end
            if strcmp(obj.State,state)
                log.printWarning('No state change. The new state is equal to the previous one');
                return
            end
            res=true;
        end

        function triggerStateChange(obj)
            obj.setStateInfo;
            obj.setThermoeconomicAnalysis;
            obj.setThermoeconomicDiagnosis;
            obj.clearResults(cType.ResultId.DIAGRAM_FP);
            obj.clearResults(cType.ResultId.RESULT_MODEL);
        end

        function res=checkReferenceState(obj,state)
        % Check the reference state value
            res=false;
            log=cStatus();
            if ~obj.DataModel.existState(state)
                log.printWarning('Invalid state %s',state);
                return
            end
            if strcmp(obj.ReferenceState,state)
                log.printWarning('Reference and Operation State are the same');
                return
            end
            idx=obj.DataModel.getStateId(state);
            obj.fp0=obj.rstate{idx};
            res=true;
        end
 
        function res=checkResourceSample(obj,sample)
        % Check the resource sample value
            res=false;
            log=cStatus(cType.VALID);
            if ~obj.DataModel.existSample(sample)
                log.printWarning('Invalid resource sample %s',sample);
                return       
            end
            if isempty(sample) || strcmp(obj.ResourceSample,sample)
                log.printWarning('No sample change. The new sample is equal to the previous one');
                return
            end
            % Read resources and check if are valid
            obj.rsd=obj.getResourceData(sample);
            res=isValid(obj.rsd);
        end

        function triggerResourceSampleChange(obj)
        % trigger ResourceSample parameter change
            if obj.isGeneralCost
                obj.setThermoeconomicAnalysis;
            end
            obj.setSummaryResults;
            obj.clearResults(cType.ResultId.RESULT_MODEL);
        end
        
        function res=checkCostTables(obj,value)
        % check CostTables parameter
            res=false;
            log=cStatus();
            pct=cType.getCostTables(value);
            if cType.isEmpty(pct)
                log.printWarning('Invalid Cost Tables parameter value: %s',value);
                return
            end
            if strcmp(obj.CostTables,value)
                log.printWarning('No parameter change. The new state is equal to the previous one');
                return
            end
            if bitget(pct,cType.GENERALIZED) && ~obj.isResourceCost
                log.printWarning('Invalid Parameter %s. Model does not have external resources defined',value);
                return
            end
            res=true;
        end 
    
        function triggerCostTablesChange(obj)
        % Set cost tables method and trigger thermoeconomic analysis
            pct=cType.getCostTables(obj.CostTables);
            obj.directCost=bitget(pct,cType.DIRECT);
            obj.generalCost=bitget(pct,cType.GENERALIZED);
            if ~obj.activeSet
                return
            end
            obj.setThermoeconomicAnalysis;
            obj.clearResults(cType.ResultId.RESULT_MODEL);
        end

        function res=checkDiagnosisMethod(obj,value)
        % Check Diagnosis Method parameter
            res=false;
            log=cStatus();
            if ~cType.checkDiagnosisMethod(value)
                log.printWarning('Invalid Diagnosis Method parameter value: %s',value);
                return
            end
            if strcmp(obj.DiagnosisMethod,value)
                log.printWarning('No parameter change. The new state is equal to the previous one');
                return
            end
            res=true;
        end

        function res=checkSummary(obj,value)
        % Ckeck Summary parameter
            res=false;
            log=cStatus();
            if ~obj.activeSet
                return
            end
            if ~obj.isSummaryEnable
                log.printWarning('Summary requires more than one state',value);
                return
            end
            if obj.Summary==value
                log.printWarning('No parameter change. The new state is equal to the previous one');
                return
            end
            res=true;
        end

        %%%
        % cModelResults methods
        function res=getResults(obj,index)
        % Get the result info
            res=getResults(obj.results,index);
        end

        function clearResults(obj,index)
        % Clear the result info
            clearResults(obj.results,index);
        end

        function setResults(obj,res)
        % Set the result info
            setResults(obj.results,res);
        end
    end
end