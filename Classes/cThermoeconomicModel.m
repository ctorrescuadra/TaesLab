classdef cThermoeconomicModel < cResultSet
% cThermoeconomicModel is an interactive tool for thermoeconomic analysis
% It is the main class of TaesLab package, and provide the following functionality:
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
%       obj.setActiveWaste(value)
%       obj.setRecycling(value)
%       obj.setDebug(value)
%       obj.setSumary(value)
%   Results Info Methods
%       res=obj.productiveStructure
%       res=obj.termoeconomicState(state)
%       res=obj.thermoeconomicAnalysis
%       res=obj.thermoeconomicDiagnosis
%       res=obj.summaryDiagnosis
%       res=obj.wasteAnalysis
%       res=obj.diagramFP
%       res=obj.productiveDiagram
%       res=obj.summaryResults
%       res=obj.dataModelInfo
%       res=obj.resultModelInfo
%       res=obj.getResultInfo(Id)
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
%       res=obj.getResultStates
%       res=obj.getModelResults
%   Tables Info Methods
%       res=obj.getTablesDirectiory
%       res=obj.getTableInfo(name)
%       res=obj.getResultInfoTable(name)
%       res=obj.getTable(name,options)
%       res=obj.getTableIndex(options)
%   Show Methods
%       obj.printResults
%       obj.showResults(name,options)
%       obj.showTableIndex(options)
%       obj.showGraph(name,options)
%       obj.showSummary(name)
%       obj.showSummaryGraph(name,options)
%       obj.showTableDirectory(option)
%   Save Methods
%       log=obj.saveResults(filename)
%       log=obj.saveDataModel(filename)
%       log=obj.saveDiagramFP(filename)
%       log=obj.saveProductiveDiagram(filename)
%       log=obj.saveSummary(filename)
%       log=obj.saveTable(name,filename)
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
%
    properties(GetAccess=public,SetAccess=private)
        DataModel           % Data Model
        ModelName           % Model Name
        StateNames          % Names of the defined states
        SampleNames         % Names of the defined resource samples
        WasteFlows          % Names of the waste flows
        ResourceData        % Resource Data object
        ResourceCost        % Resource Cost object
    end

    properties(Access=public)
        State                  % Active thermoeconomic state
        ReferenceState         % Active Reference state
        ResourceSample         % Active resource cost sample
        CostTables             % Select tables to cost results
        DiagnosisMethod        % Method to calculate fuel impact of wastes
        Summary                % Calculate Summary Results
        Recycling              % Activate Recycling Analysis
        ActiveWaste            % Active Waste Flow for Recycling Analysis and Waste Allocation
    end

    properties(Access=private)
        results            % cResultInfo cell array
        rstate             % cExergyCost object cell array
        fmt                % cResultTableBuilder object
        rsd                % cResourceData object
        rsc                % cResourceCost object
        fp0                % Actual reference cExergyCost
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
            obj=obj@cResultSet(cType.ClassId.RESULT_MODEL);
            if ~isa(data,'cDataModel')
                obj.messageLog(cType.ERROR,'Invalid data model');
                printLogger(obj);
                return
            end
            % Check Data Model
            obj.addLogger(data);
            if ~data.isValid
                obj.messageLog(cType.ERROR,'Invalid data model. See error log');
                printLogger(obj);
                return
            end
            % Create Results Container.
            obj.results=cModelResults(data);
            obj.DataModel=data;
            obj.ModelName=data.ModelName;
            % Check optional input parameters
            p = inputParser;
            p.addParameter('State',data.States{1},@ischar);
            p.addParameter('ReferenceState',data.States{1},@ischar);
            p.addParameter('ResourceSample','',@ischar);
            p.addParameter('CostTables',cType.DEFAULT_COST_TABLES,@cType.checkCostTables);
            p.addParameter('DiagnosisMethod',cType.DEFAULT_DIAGNOSIS,@cType.checkDiagnosisMethod);
            p.addParameter('Summary',false,@islogical);
            p.addParameter('Recycling',false,@islogical);
            p.addParameter('ActiveWaste','',@ischar);
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
            if data.isWaste
                if param.ActiveWaste
                    obj.ActiveWaste=param.ActiveWaste;
                else
                    obj.ActiveWaste=obj.WasteFlows{1};
                end
            end
            % Read print formatted configuration
            obj.fmt=data.FormatData;
            % Load Exergy values (all states)
            obj.rstate=cell(1,data.NrOfStates);
            for i=1:data.NrOfStates
                rex=data.ExergyData{i};
                if ~rex.isValid
                    obj.addLogger(rex);
                    obj.messageLog(cType.ERROR,'Invalid exergy values. See error log');
                    return
                end
                if obj.isWaste
                    wd=data.WasteData;
                    obj.rstate{i}=cExergyCost(rex,wd);
                else
                    obj.rstate{i}=cExergyCost(rex);
                end
            end
            % Set Operation and Reference State
            if isempty(param.State)
                obj.State=data.States{1};
            elseif data.existState(param.State)
                obj.State=param.State;
            else
                obj.printError('Invalid state name %s',param.State);
                return
            end
            if isempty(param.ReferenceState)
                obj.ReferenceState=data.States{1};
            elseif data.existState(param.State)
                obj.ReferenceState=param.ReferenceState;
            else
                obj.printError('Invalid state name %s',param.ReferenceState);
                return
            end
            % Read ResourcesCost
            if ~data.checkCostTables(param.CostTables)
                res.printError('Invalid CostTables parameter %s',param.CostTables);
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
            obj.setProductiveStructure;
            obj.setStateInfo;
            obj.setThermoeconomicAnalysis;
            obj.setThermoeconomicDiagnosis;
            obj.Recycling=param.Recycling;   
            obj.Summary=param.Summary;
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
            end
        end

        function set.Summary(obj,value)
        % Set Summary parameter
            if obj.checkSummary(value)
                obj.Summary=value;
                if obj.Summary
                    obj.printDebugInfo('Summary is active');
                else
                    obj.printDebugInfo('Summary is not active')
                end
                obj.setSummaryResults;
            end
        end

        function set.Recycling(obj,value)
            if obj.checkRecycling(value)
                obj.Recycling=value;
                if obj.Recycling
                    obj.printDebugInfo('Recycling is active');
                else
                    obj.printDebugInfo('Recycling is not active')
                end
                obj.setRecyclingResults;
            end
        end

        function set.ActiveWaste(obj,value)
        % Set Active Waste
            if obj.checkActiveWaste(value)
                obj.ActiveWaste=value;
            end
            obj.setRecyclingResults;
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

        function setActiveWaste(obj,key)
            obj.ActiveWaste=key;
        end

        function setSummary(obj,value)
            obj.Summary=value;
        end

        function setRecycling(obj,value)
            obj.Recycling=value;
        end

        function setDebug(obj,dbg)
        % Set debug control variable
            if islogical(dbg) && (obj.debug~=dbg)
                obj.debug=dbg;
            end
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

        function res=wasteAnalysis(obj)
        % Get the Recycling Analysis cResultInfo object
            res=obj.getResults(cType.ResultId.WASTE_ANALYSIS);
        end

        function res=summaryResults(obj)
        % Get the Summary Results cResultInfo object
            res=obj.getResults(cType.ResultId.SUMMARY_RESULTS);
        end

        function res=productiveDiagram(obj)
        % Get the productive diagram cResultInfo object
            res=obj.getResults(cType.ResultId.PRODUCTIVE_DIAGRAM);
        end

        function res=diagramFP(obj)
        % Get the diagram FP cResultInfo object
            res=obj.getResults(cType.ResultId.DIAGRAM_FP);
        end

        function res=dataModelInfo(obj)
        % Get the data model cResultInfo object
          res=obj.getResults(cType.ResultId.DATA_MODEL);
        end
            
        function summaryDiagnosis(obj)
        % Get the diagnosis results summary
            res=obj.thermoeconomicDiagnosis;
            if ~isempty(res)
                res.summaryDiagnosis;
            end
        end

        function res=resultModelInfo(obj)
        % Get a cResultInfo object with all tables of the active model
            id=cType.ResultId.RESULT_MODEL;
            tables=struct();
            tmp=obj.getModelResults;
            for k=1:numel(tmp)
                dm=tmp{k};
                list=dm.getListOfTables;
                for i=1:dm.NrOfTables
                    tables.(list{i})=dm.Tables.(list{i});
                end
            end
            res=cResultInfo(cResultId(id),tables);
            res.setProperties(obj.ModelName,obj.State);
            obj.setResults(res);
        end

        %%%
        % Utility methods
        %
        function showProperties(obj)
        % Show the values of the actual parameters of the model
            s=struct('State',obj.State,...
                'ReferenceState',obj.ReferenceState,...
                'ResourceSample',obj.ResourceSample,...
                'CostTables',obj.CostTables,...
                'DiagnosisMethod',obj.DiagnosisMethod,...
                'IsResourceCost',log2str(obj.isResourceCost),...
                'IsDiagnosis',log2str(obj.isDiagnosis),...
                'IsWaste',log2str(obj.isWaste),...
                'ActiveWaste',obj.ActiveWaste,...
                'Summary',log2str(obj.Summary),...
                'Recycling',log2str(obj.Recycling),...
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

        function res=get.WasteFlows(obj)
        % Get waste flows list (cell array)
            res=getWasteFlows(obj.DataModel);
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
            if ~all(obj.fp0.ActiveProcesses==obj.fp1.ActiveProcesses)
                obj.printDebugInfo('Compare two diferent configurations is not available');
                return
            end
            %Check if operation and reference states are diferent 
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

        function res=getResultStates(obj)
        % Get the cExergyCost object of each state 
        %   Internal application use: cModelSummary
            res=obj.rstate;
        end

        function res=getModelResults(obj)
        % Get a cell array of cResultInfo objects of the current state (internal application use)
            res=getModelResults(obj.results);
        end

        %%%
        % Tables Directory methods
        function res=getTablesDirectory(obj,varargin)
        % Create the tables directory of the active model
        %   Input:
        %       options - VarMode options
        %
            tbl=obj.fmt.getTablesDirectory;
            tDict=obj.fmt.tDictionary;
            atm=zeros(tbl.NrOfRows,1);
            % Get the initial state of the table
            for i=1:cType.ResultId.SUMMARY_RESULTS
                rid=obj.getResults(i);
                if ~isempty(rid)
                    list=rid.getListOfTables;
                    idx=cellfun(@(x) getIndex(tDict,x),list);
                    atm(idx)=true;
                end
            end
            % Create the table
            rows=find(atm);
            data=tbl.Data(rows,:);
            rowNames=tbl.RowNames(rows);
            colNames=tbl.ColNames;
            tmp=cTableData(data,rowNames,colNames);
            if nargin==1
                res=tmp;
                res.setProperties('tdir','Tables Directory');
            else
                res=exportTable(tmp,varargin{:});
            end
        end

        function showTablesDirectory(obj,option)
        % View Tables directory
        %   Input:
        %       options - TableView options
            tbl=getTablesDirectory(obj);
            if nargin==1
                option=cType.DEFAULT_TABLEVIEW;
            end
            showTable(tbl,cType.getTableView(option));
        end

        function res=getTableInfo(obj,name)
        % Get table properties
        % 
            res=getTableInfo(obj.fmt,name);
        end

        function res=getResultInfoTable(obj,table)
        % Get the resultId associated to a table
            res=[];
            tinfo=obj.getTableInfo(table);
            if isempty(tinfo)
                printDebugInfo(obj,'Table %s does not exists',table);
                return
            end
            res=obj.getResults(tinfo.resultId);
            if isempty(res)
                printDebugInfo(obj,'Table %s is not available',table);
                return
            end
        end
        
        %%%
        % Result presentation methods
        %%%

        function showGraph(obj,graph,varargin)
        % Show a graph table. 
        % Find the resultId asociated to the table
        % and call ResultInfo/showGraph
        %  Input:
        %   graph - name of the table
        %   options - graph options (see cResultInfo)
            if nargin < 2
                obj.printDebugInfo('Not enough input arguments');
                return
            end
            res=obj.getResultInfoTable(graph);
            showGraph(res,graph,varargin{:});
        end

        function showSummary(obj,name,varargin)
        % Show Summary tables
            res=obj.getSummaryResults;
            if isempty(res)
                obj.printDebugInfo('Summary Results not available')
                return
            end
            if nargin==1
                printResults(res)
            else
                showResults(res,name,varargin{:})
            end
        end

        function showSummaryGraph(obj,varargin)
        % Show Summary Graphs
            res=obj.getSummaryResults;
            if isempty(res)
                obj.printDebugInfo('Summary Results not available')
                return
            end
            showGraph(res,varargin{:});
        end

        function showDataModel(obj,name,varargin)
        % Show Data Model tables
            res=obj.DataModel;
            if nargin==1
                printResults(res)
            else
                showResults(res,name,varargin{:})
            end
        end
        %%%
        % Save Results methods
        %%%
        function log=saveSummary(obj,filename)
        % Save the summary tables into a filename
        % The following file types are availables (JSON,XML,XLSX,CSV,MAT)
        %  Input:
        %   filename - Name of the file
        %  Output:
        %   log - cStatusLogger object containing the status and error messages
            log=cStatus();
            if nargin~=2
                log.printError('Usage: saveDataModel(model,filename)');
                return
            end       
            msr=obj.getSummaryResults;
            if isempty(msr) || ~isValid(msr)
                obj.printDebugInfo('Summary Results not available');
                return
            end
            log=saveResults(msr,filename);
        end
    
        function log=saveDataModel(obj,filename)
        % Save the data model in a file
        % The following file types are availables (JSON,XML,XLSX,CSV,MAT)
        %  Input:
        %   filename - Name of the file
        %  Output:
        %   log - cStatusLogger object containing the status and error messages
            log=cStatus();
            if nargin~=2
                log.printError('Usage: saveDataModel(model,filename)');
                return
            end
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
            if nargin~=2
                log.printError('Usage: saveDiagramFP(model,filename)');
                return
            end
            % Save tables atfp, atcfp
            res=obj.diagramFP;
            if ~isValid(res)
                printLogger(res)
                log.printError('DiagramFP object not available');
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
            if nargin~=2
                log.printError('Usage: saveProductiveDiagram(model,filename)');
                return
            end
            % Save fat,pat and fpat tables
            res=obj.productiveDiagram;
            if ~isValid(res)
                res.printLogger(res)
                log.printError('Productive Diagram object not available');
                return
            end
            log=saveResults(res,filename);
        end
       
        %%%
        % Waste Analysis methods
        %
        function wasteAllocation(obj)
        % Show waste information
            res=obj.wasteAnalysis;
            printTable(res.Tables.wd)
            printTable(res.Tables.wa)
        end

        function log=setWasteType(obj,key,wtype)
        % Set the waste type allocation method for Active Waste
        %  Input
        %   wtype - waste allocation type (see cType)
        %
            log=cStatus(cType.VALID);
            if nargin~=3
               log.printError('Usage: obj.setWasteType(key,wtype)');
               return
            end  
            wt=obj.fp1.WasteTable;
            if ~wt.setType(key,wtype)  
                log.printError('Invalid waste type %s - %s',key,wtype);
                return
            end
            obj.fp1.updateWasteOperators;
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
            wt=obj.fp1.WasteTable;
            if ~wt.setValues(key,val)
                log.prinError('Invalid waste %s allocation values',key);
                return
            end
            obj.fp1.updateWasteOperators;
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
            wt=obj.fp1.WasteTable;
            if ~wt.setRecycleRatio(key,val)
                log.printError('Invalid waste %s recycling values',key);
                return 
            end
            obj.fp1.updateWasteOperators;
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
            % Compute cExergyCost
            if obj.isWaste
                wd=data.WasteData;
                obj.rstate{idx}=cExergyCost(rex,wd);
            else
                obj.rstate{idx}=cExergyCost(rex);
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

        function setStateInfo(obj)
        % Trigger exergy analysis
            idx=obj.DataModel.getStateId(obj.State);
            obj.fp1=obj.rstate{idx};
            if ~obj.activeSet
                return
            end
            res=getExergyResults(obj.fmt,obj.fp1);
            obj.setResults(res);
            obj.printDebugInfo('Set State: %s',obj.State);
            obj.setDiagramFP;
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
                res=getResultInfo(obj.fp1,obj.fmt,options);
                obj.setResults(res);
                obj.printDebugInfo('Compute Thermoeconomic Analysis for State: %s',obj.State);
            else
                obj.fp1.printLogger;
                obj.fp1.printError('Thermoeconomic Analysis cannot be calculated')
            end
            obj.setRecyclingResults;
        end

        function setThermoeconomicDiagnosis(obj)
        % Set thermoeconomic diagnosis computation
            id=cType.ResultId.THERMOECONOMIC_DIAGNOSIS;
            if ~obj.activeSet
                return
            end
            if ~obj.isDiagnosis
                obj.clearResults(id);
                obj.printDebugInfo('Thermoeconomic Diagnosis is not active');
                return
            end
            % Compute diagnosis analysis
            method=cType.getDiagnosisMethod(obj.DiagnosisMethod);
            sol=cDiagnosis(obj.fp0,obj.fp1,method);
            % get cModelResult object
            if sol.isValid
                res=sol.getResultInfo(obj.fmt);
                obj.setResults(res);
                obj.printDebugInfo('Compute Thermoeconomic Diagnosis for State: %s',obj.State);
            else
                sol.printLogger;
                sol.printError('Thermoeconomic Diagnosis cannot be calculated');
                obj.clearResults(id);
            end
        end

        function res=getSummaryResults(obj)
        % Force to obtain summary results
            res=[];
            if ~obj.isSummaryEnable
                return
            end
            if ~obj.Summary
                obj.setSummary(true);
            end
            res=obj.getResults(cType.ResultId.SUMMARY_RESULTS);
        end

        function setSummaryResults(obj)
        % Obtain Summary Results
            if ~obj.activeSet || ~obj.isSummaryEnable
                return
            end
            id=cType.ResultId.SUMMARY_RESULTS;
            res=obj.getResults(id);
            if obj.Summary
                sr=cModelSummary(obj);
                if sr.isValid
                    res=sr.getResultInfo(obj.fmt);
                    obj.setResults(res);
                    obj.printDebugInfo('Compute Summary Results');
                else
                    sr.printLogger;
                end
            elseif ~isempty(res)
                obj.clearResults(id);
            end
        end

        function setRecyclingResults(obj)
        % Set Recycling Analysis Results
            if ~obj.activeSet || ~obj.isWaste
                return
            end
            if obj.Recycling
                if obj.isGeneralCost 
                    ra=cWasteAnalysis(obj.fp1,true,obj.ActiveWaste,obj.rsd);
                else
                    ra=cWasteAnalysis(obj.fp1,true,obj.ActiveWaste);
                end
                obj.printDebugInfo('Compute Recycling Analysis');
            else
                ra=cWasteAnalysis(obj.fp1);
            end
            if isValid(ra)
                param=struct('DirectCost',obj.directCost,'GeneralCost',obj.generalCost);
                res=ra.getResultInfo(obj.fmt,param);
                obj.setResults(res);
            else
                ra.printLogger;
            end
        end

        function setDiagramFP(obj)
        % Get the Diagram FP cResultInfo object
        %   Input:
        %       varargin - Optional FP table name
        %           cType.Tables.TABLE_FP (default)
        %           cType.Tables.COST_TABLE_FP
        %   Output:
        %       res - cResultInfo (DIAGRAM_FP)
            dfp=cDiagramFP(obj.fp1);
            if isValid(dfp)
                res=dfp.getResultInfo(obj.fmt);
                obj.setResults(res);
                obj.printDebugInfo('DiagramFP active')
            else
                dfp.printLogger;
            end
        end

        function setProductiveStructure(obj)
        % Set the productive structure cResultInfo objects
            ps=obj.DataModel.ProductiveStructure;
            res=ps.getResultInfo(obj.fmt);
            obj.setResults(res)
            pd=cProductiveDiagram(ps);
            if isValid(pd)
                res=pd.getResultInfo(obj.fmt);
                obj.setResults(res);
                obj.printDebugInfo('Productive Diagram active')
            else
                pd.printLogger;
            end
        end
        %%%
        % Internal set methods
        function res=checkState(obj,state)
        % Ckeck the state information
            res=false;
            log=cStatus();    
            if ~obj.DataModel.existState(state)
                log.printWarning('Invalid state name %s',state);
                return
            end
            if strcmp(obj.State,state)
                obj.printDebugInfo('No state change. The new state is equal to the previous one');
                return
            end
            res=true;
        end

        function triggerStateChange(obj)
        % Trigger State Change
            obj.setStateInfo;
            obj.setThermoeconomicAnalysis;
            obj.setThermoeconomicDiagnosis;
            obj.setSummaryResults;
        end

        function res=checkReferenceState(obj,state)
        % Check the reference state value
            res=false;
            log=cStatus();
            if ~obj.DataModel.existState(state)
                log.printWarning('Invalid state name %s',state);
                return
            end
            if strcmp(obj.ReferenceState,state)
                obj.printDebugInfo('Reference and Operation State are the same');
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
                obj.printDebugInfo('No sample change. The new sample is equal to the previous one');
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
                obj.printDebugInfo('No parameter change. The new value is equal to the previous one');
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
        end

        function res=checkDiagnosisMethod(obj,value)
        % Check Diagnosis Method parameter
            res=false;
            log=cStatus();
            if ~cType.checkDiagnosisMethod(value)
                log.printWarning('Invalid Diagnosis method: %s',value);
                return
            end
            if strcmp(obj.DiagnosisMethod,value)
                obj.printDebugInfo('No parameter change. The new value is equal to the previous one');
                return
            end
            res=true;
        end

        function res=checkActiveWaste(obj,value)
        % Check Active Waste Parameter
            res=false;
            log=cStatus();
            if ~ismember(value,obj.WasteFlows)
                log.printWarning('Invalid waste flow: %s',value);
                return
            end
            if strcmp(obj.ActiveWaste,value)
                obj.printDebugInfo('No parameter change. The new value is equal to the previous one');
                return
            end
            res=true;
        end

        function res=checkSummary(obj,value)
        % Ckeck Summary parameter
            res=false;
            if ~obj.activeSet
                return
            end
            if ~obj.isSummaryEnable
                obj.printDebugInfo('Summary Results requires more than one state');
                return
            end
            if obj.Summary==value
                obj.printDebugInfo('No parameter change. The new value is equal to the previous one');
                return
            end
            res=true;
        end

        function res=checkRecycling(obj,value)
        % Ckeck Summary parameter
            res=false;
            if ~obj.activeSet
                return
            end
            if ~obj.isWaste
                obj.printDebugInfo('Recycling Analysis requires waste');
                return
            end
            if obj.Recycling==value
                obj.printDebugInfo('No parameter change. The new value is equal to the previous one');
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