classdef cThermoeconomicModel < cResultSet
% cThermoeconomicModel - Interactive tool for thermoeconomic analysis
%   It is the main class of TaesLab package, and provide the following functionality:
%   - Read and check a thermoeconomic data model
%   - Compute direct and generalized exergy cost
%   - Compare two thermoeconomic states (thermoeconomic diagnosis)
%   - Analize Recycling effects (recycling analysis)
%   - Get Summary Results
%   - Save the data model and results in diferent formats, for further analysis
%   - Show the results tables in console, as GUI tables or graphs
%
% cThermoeconomicModel Properties:
%   Public Properties
%     State - Active thermoeconomic state
%		char array
%     ReferenceState - Active Reference state
%	    char array
%     ResourceSample - Active resource cost sample
%	    char array
%     CostTables - Type of selected Cost Result Tables
%	    'DIRECT' | 'GENERALIZED' | 'ALL'
%     DiagnosisMethod - Method to calculate diagnosis
%	    'NONE' | 'WASTE_EXTERNAL' | 'WASTE_INTERNAL'
%     Summary - Calculate Summary Results
%	    true | false
%     Recycling - Activate Recycling Analysis
%	    true | false
%     ActiveWaste - Active Waste for Recycling Analysis
%		true | false
%
%   Public Get Access Properties
%     DataModel - Data Model
%       cDataModel object
%     ModelName - Model Name
%       char array
%     StateNames - Names of the defined states
%       cell array of chars
%     SampleNames - Names of the defined resource samples
%       cell array of chars
%     WasteFlows - Names of the waste flows
%       cell array of chars
%     ResourceData - Current Resource Data values
%       cResourceData object
%     ResourceCost - Current Resource Cost values
%       cResourceCost object
%
% cThermoeconomicModel methods
%   Set Methods
%     setState            - Set State value
%     setReferenceState   - Set Reference State value
%     setResourceSample   - Set Resource Sample value
%     setCostTables       - Set CostTables parameter
%     setDiagnosisMethod  - Set DiagnosisMethod parameter
%     setActiveWaste      - Set Active Waste value
%     setRecycling        - Activate Recycling Analysis
%     setSummary          - Activate Summary Results
%     setDebug            - Set Debug mode
%
%   Results Info Methods
%     productiveStructure     - Get Productive Structure cResultInfo
%     exergyAnalysis          - Get ExergyAnalysis cResultInfo
%     thermoeconomicAnalysis  - Get Thermoeconomic Analysis cResultInfo
%     thermoeconomicDiagnosis - Get Thermoeconomic Diagnosis cResultInfo
%     summaryDiagnosis        - Get Diagnosis Summary
%     wasteAnalysis           - Get Waste Analysis cResultInfo
%     diagramFP               - Get Diagram FP cResultInfo
%     productiveDiagram       - Get Productive Diagrams cResultInfo
%     summaryResults          - Get Summary cResultInfo
%     dataInfo                - Get Data Model cResultInfo
%     stateResults            - Get Model Results cResultInfo
%
%   Model Info Methods
%     showProperties  - Show model properties
%     isResourceCost  - Check if model has Resource Cost Data
%     isGeneralCost   - Check if model compute Generalized Costs
%     isDiagnosis     - Check if model compute Diagnosis
%     isWaste         - Check if model has waste
%     isSummaryEnable - Check if Summary Results are enabled
%
%   Tables Info Methods
%     getTablesDirectory  - Get the tables directory 
%     showTablesDirectory - Show the tables directory
%
%   ResultSet Methods
%     getResultInfo         - Get cResultInfo objects
%     ListOfTables          - Get the current list of available tables
%     getTable              - Get a cTable object by name
%     getTableIndex         - Get the current Table Index object
%     printResults          - Print on console the current results
%     showResults           - Show the current results
%     showSummary           - Show Summary results
%     showTableIndex        - Show the Table Index
%     showGraph             - Show a graph of the current model
%     saveResults           - Save the curernt model in a file
%     saveTable             - Save a table of the current model in a file
%     saveDataModel         - Save the data model tables into a file
%     saveDiagramFP         - Save the Diagram FP table into a file
%     saveProductiveDiagram - Save the Productive Diagram tables into a file
%     saveSummary           - Save Summary results into a file
%     exportResults         - Export the model tables into a internal variable
%     exportTable           - Export a table into a internal variable
%
%   Waste Methods
%     wasteAllocation  - Show waste allocation info 
%     setWasteType     - Set the type of a waste
%     setWasteValues   - Set the allocation values of a waste
%     setWasteRecycled - Set the recycled ratio of a waste
%
%   Resources Methods
%     getResourceData         - Get the resource data of a sample
%     setFlowResource         - Set the resource flows values
%     setProcessResource      - Set the processes resource values
%     setFlowResourceValue    - Set a value of the resource flows
%     setProcessResourceValue - Set a value of the process resources
%
%   Exergy Data Methods
%     getExergyData - Get the exergy data of a state
%     setExergyData - Set the exergy values of a state
%
% See also cResultSet, cResultId
%
    properties(GetAccess=public,SetAccess=private)
        DataModel           % Data Model
        ModelName           % Model Name
        StateNames          % Names of the defined states
        SampleNames         % Names of the defined resource samples
        WasteFlows          % Names of the waste flows
        ResourceData        % Resource Data object
        ResourceCost        % Resource Cost object
        ResultId            % ResultId (cResultId properties)
        ResultName          % Result Name (cResultId properties)
        DefaultGraph        % Default Graph (cResultId properties)
    end

    properties(Access=public)
        State                  % Active thermoeconomic state
        ReferenceState         % Active Reference state
        ResourceSample         % Active resource cost sample
        CostTables             % Selected Cost Result Tables
        DiagnosisMethod        % Method to calculate fuel impact of wastes
        Summary                % Calculate Summary Results
        Recycling              % Activate Recycling Analysis
        ActiveWaste            % Active Waste Flow for Recycling Analysis and Waste Allocation
    end

    properties(Access=private)
        results            % cModelResults object
        rstate             % cDataset of cExergyCost object
        fmt                % cResultTableBuilder object
        wd                 % cWasteData object
        rsd                % cResourceData object
        rsc                % cResourceCost object
        fp0                % cExergyCost actual reference state
        fp1                % cExergyCost actual operation state
        debug              % debug info control
        directCost=true    % Direct cost are obtained
        generalCost=false  % General cost are obtained
        activeSet=false    % set variables control
    end

    methods
        function obj=cThermoeconomicModel(data,varargin)
        % Construct an instance of the thermoeconomic model
        % Syntax:
        %   model = cThermoeconomicModel(data)
        %     data - cDataModel object 
        %     varargin - optional paramaters (see ThermoeconomicModel)
        %   
            obj=obj@cResultSet(cType.ClassId.RESULT_MODEL);
            if ~isDataModel(data)
                obj.printError(cType.ERROR,'Invalid data model');
                return
            end
            obj.addLogger(data);
            % Create Results Container.
            obj.results=cModelResults(data);
            obj.DataModel=data;
            % Set cResultId properties
            obj.ResultId=cType.ResultId.RESULT_MODEL;
            obj.ResultName=cType.Results{obj.ResultId};
            obj.ModelName=data.ModelName;
            obj.DefaultGraph=cType.EMPTY_CHAR;
            % Check optional input parameters
            p = inputParser;
            refstate=data.StateNames{1};
            p.addParameter('State',refstate,@ischar);
            p.addParameter('ReferenceState',refstate,@ischar);
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
                obj.printError('Usage: cThermoeconomicModel(data,options)');
                return
            end
            param=p.Results;
            % Update Variables
            obj.debug=param.Debug;
            obj.CostTables=param.CostTables;
            obj.DiagnosisMethod=param.DiagnosisMethod;
            if data.isWaste
                obj.wd=data.WasteData;
                if isempty(param.ActiveWaste)
                    param.ActiveWaste=data.WasteFlows{1};
                end
                obj.ActiveWaste=param.ActiveWaste;
            end
            % Read print formatted configuration
            obj.fmt=data.FormatData;
            % Load Exergy values (all states)
            obj.rstate=cDataset(data.StateNames);
            for i=1:data.NrOfStates
                rex=data.getExergyData(i);
                if ~rex.isValid
                    obj.addLogger(rex);
                    obj.messageLog(cType.ERROR,'Invalid exergy values. See error log');
                    return
                end
                if obj.isWaste
                    cex=cExergyCost(rex,obj.wd);
                else
                    cex=cExergyCost(rex);
                end
                obj.rstate.setValues(i,cex);
            end
            % Set Operation and Reference State
            if data.existState(param.State)
                obj.State=param.State;
            else
                obj.printError('Invalid state name %s',param.State);
                return
            end
            if data.existState(param.ReferenceState)
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
                    param.ResourceSample=data.SampleNames{1};
                end
                if data.existSample(param.ResourceSample)
                    obj.ResourceSample=param.ResourceSample;
                else 
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
        % Syntax:
        %   model.State = value
            if checkState(obj,state)
                obj.State=state;
                obj.triggerStateChange;
            end
        end

        function set.ReferenceState(obj,state)
        % Set Reference State
        % Syntax:
        %   model.ReferenceState = value
            if checkReferenceState(obj,state)
                obj.ReferenceState=state;
                obj.printDebugInfo('Set Reference State: %s',state);
                obj.setThermoeconomicDiagnosis;
            end
        end

        function set.CostTables(obj,value)
        % Set CostTables parameter
        % Syntax:
        %   model.ReferenceState = value
            if obj.checkCostTables(value)
                obj.CostTables=value;
                obj.triggerCostTablesChange;
            end
        end

        function set.ResourceSample(obj,sample)
        % Set Resources sample
        % Syntax:
        %   model.ResourceSample = value
            if obj.checkResourceSample(sample)
                obj.ResourceSample=sample;
                obj.triggerResourceSampleChange;
            end
        end

        function set.DiagnosisMethod(obj,value)
        % Set Diagnosis method
        % Syntax:
        %   model.DiagnosisMethod = value
            if obj.checkDiagnosisMethod(value)
                obj.DiagnosisMethod=value;
                obj.setThermoeconomicDiagnosis;
            end
        end

        function set.Summary(obj,value)
        % Set Summary parameter
        % Syntax:
        %   model.Summary = value
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
        % Set Recycling parameter
        % Syntax:
        %   model.Recycling = value
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
        % Syntax:
        %   model.Recycling = value
            if obj.checkActiveWaste(value)
                obj.ActiveWaste=value;
                obj.printDebugInfo('Set Active Waste to %s',value);
            end
            obj.setRecyclingResults;
        end


        % Set methods
        function setState(obj,state)
        % Set a new valid state from StateNames
        % Syntax:
        %   obj.setState(state)
        % Input Parameters
        %   state - Valid state.
        %     array of chars 
            obj.State=state;
        end

        function setReferenceState(obj,state)
        % Set a new valid reference state from StateNames
        % Syntax:
        %   obj.setState(state)
        % Input Parameters
        %   state - Valid state.
        %     array of chars
            obj.ReferenceState=state;
        end

        function setResourceSample(obj,sample)
        % Set a new valid ResourceSample from SampleNames
        % Syntax:
        %   obj.setResourceSample(state)
        % Input Parameters
        %   state - Valid state.
        %     array of chars
            obj.ResourceSample=sample;
        end

        function setCostTables(obj,type)
        % Set a new value of CostTables parameter
        % Syntax:
        %   obj.setCostTables(type)
        % Input Parameters
        %   type - Type of thermoeconomic tables
        %     'DIRECT' | 'GENERALIZED' | 'ALL'
            obj.CostTables=type;
        end

        function setDiagnosisMethod(obj,method)
        % Set a new value of DiagnosisMethod parameter
        % Syntax:
        %   obj.setDiagnosisMethod(method)
        % Input Parameters
        %   method - Method used to compute diagnosis
        %     'NONE' | 'WASTE_EXTERNAL' | 'WASTE_INTERNAL'
            obj.DiagnosisMethod=method;
        end

        function setActiveWaste(obj,key)
        % Set a new waste flow for recycling analysis
        % Syntax:
        %   setActiveWaste(obj,method)
        % Input Parameters
        %   method - Method used to compute diagnosis
        %     'NONE' | 'WASTE_EXTERNAL' | 'WASTE_INTERNAL'
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
                obj.printInfo('Debug is set to %s',upper(log2str(dbg)));
            end
        end

        function toggleSummary(obj)
        % toggle summary status
            obj.Summary = ~obj.Summary;
        end

        function toggleRecycling(obj)
        % toggle recycling status
            obj.Recycling = ~obj.Recycling;
        end

        function toggleDebug(obj)
        % toggle debug variable
            setDebug(obj,~obj.debug);
        end
        %%%
        % get cResultInfo object
        function res=productiveStructure(obj)
        % Get the Productive Structure cResultInfo object
            res=obj.getResultId(cType.ResultId.PRODUCTIVE_STRUCTURE);
        end

        function res=exergyAnalysis(obj)
        % Get the ExergyAnalysis cResultInfo object
        % containing the exergy and fuel product table
            res=obj.getResultId(cType.ResultId.THERMOECONOMIC_STATE);
        end

        function res=thermoeconomicAnalysis(obj)
        % Get the Thermoeconomic Analysis cResultInfo object
        % containing the direct and generalized cost tables
            res=obj.getResultId(cType.ResultId.THERMOECONOMIC_ANALYSIS);
        end

        function res=wasteAnalysis(obj)
        % Get the Recycling Analysis cResultInfo object
            res=obj.getResultId(cType.ResultId.WASTE_ANALYSIS);
        end

        function res=thermoeconomicDiagnosis(obj)
        % Get the Thermoeconomic Diagnosis cResultInfo object
            res=obj.getResultId(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
        end

        function summaryDiagnosis(obj)
        % Get the diagnosis results summary
            res=obj.thermoeconomicDiagnosis;
            if ~isempty(res)
                res.summaryDiagnosis;
            end
        end

        function res=summaryResults(obj)
        % Get the Summary Results cResultInfo object
            res=obj.getSummaryResults;
        end

        function res=productiveDiagram(obj)
        % Get the productive diagram cResultInfo object
            res=obj.getResultId(cType.ResultId.PRODUCTIVE_DIAGRAM);
        end

        function res=diagramFP(obj)
        % Get the diagram FP cResultInfo object
            res=obj.getResultId(cType.ResultId.DIAGRAM_FP);
        end

        function res=dataInfo(obj)
        % Get the data model cResultInfo object
          res=obj.getResultId(cType.ResultId.DATA_MODEL);
        end

        function res=stateResults(obj)
        % Get the results model cResultInfo object
            res=obj.buildResultInfo;
        end

        function res=getResultInfo(obj,arg)
        % Get the cResultInfo with option
        %   Internal funcion of TaesLab
            if nargin==1
                res=obj.buildResultInfo;
            elseif cType.isInteger(arg,1:cType.MAX_RESULT_INFO)
                res=getResultId(obj,arg);
            elseif ischar(arg)
                res=getResultTable(obj,arg);
            else
                res=cMessageLogger;
                res.messageLog(cType.ERROR,'Invalid argument');
            end
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
                'ActiveWaste',obj.ActiveWaste,...
                'Summary',log2str(obj.Summary),...
                'Recycling',log2str(obj.Recycling),...
                'Debug',log2str(obj.debug),...
                'IsResourceCost',log2str(obj.isResourceCost),...
                'IsDiagnosis',log2str(obj.isDiagnosis),...
                'IsWaste',log2str(obj.isWaste));
            disp(s);
        end

        function res=get.StateNames(obj)
        % Show a list of the available state names
            res=obj.DataModel.StateNames;
        end

        function res=get.SampleNames(obj)
        % Show a list of the avaliable resource samples
            res=obj.DataModel.SampleNames;
        end

        function res=get.WasteFlows(obj)
        % Get waste flows list (cell array)
            res=obj.DataModel.WasteFlows;
        end

        function res=getStateId(obj,key)
        % Get the State Id 
            res=obj.DataModel.ExergyData.getIndex(key);
        end

        function res=getSampleId(obj,key)
        % Get the Sample Id
            res=obj.DataModel.ResourceData.getIndex(key);
        end

        function res=getWasteId(obj,key)
        % Get the Waste flow Id
            res=obj.wd.getWasteIndex(key);
        end
    
        function res=isResourceCost(obj)
        % Indicates if resources cost are defined
            res=obj.DataModel.isResourceCost;
        end

        function res=isGeneralCost(obj)
        % Indicates if Generalized cost is activated
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

        function res=getResultState(obj,idx)
        % Get the cExergyCost object of each state 
        %   Internal application use: cModelSummary
            res=obj.rstate.getValues(idx);
        end

        function res=getModelResults(obj)
        % Get a cell array of cResultInfo objects of the current state
        %   Internal application use: ViewResults
            res=getModelResults(obj.results);
        end

        %%%
        % Tables Directory methods
        function res=getTablesDirectory(obj,columns)
        % Create the tables directory of the active model
        %   Input:
        %     options - Columns of table
        %
            if nargin==1
                columns=cType.DIR_COLS_DEFAULT;
            end
            tbl=obj.fmt.getTablesDirectory(columns);
            tDict=obj.fmt.tDictionary;
            atm=zeros(tbl.NrOfRows,1);
            % Get the initial state of the table
            for i=1:cType.ResultId.SUMMARY_RESULTS
                rid=obj.getResultId(i);
                if isValid(rid)
                    list=rid.ListOfTables;
                    idx=cellfun(@(x) getIndex(tDict,x),list);
                    atm(idx)=true;
                end
            end
            % Create the table
            rows=find(atm);
            data=tbl.Data(rows,:);
            rowNames=tbl.RowNames(rows);
            colNames=tbl.ColNames;
            res=cTableData(data,rowNames,colNames);
            res.setProperties('tdir','Tables Directory');
        end

        function res=getTableInfo(obj,name)
        % Get table properties
        % 
            res=getTableInfo(obj.fmt,name);
        end

        %%%
        % Results Set methods
        %%%
        function tbl=getTable(obj,name)
        % Get a table called name
        %   Input:
        %     name - name of the table
        %
            tbl=cMessageLogger();
            if strcmp(name,cType.TABLE_INDEX)
                res=obj.buildResultInfo;
                tbl=res.getTableIndex;
            else
                res=getResultTable(obj,name);
                if isValid(res)
                    tbl=getTable(res,name);
                else
                    tbl.addLogger(res);
                end     
            end
        end

        function showResults(obj,name,varargin)
        % View an individual table
        %   Usage:
        %     obj.showResults(table,option)
        %   Input:
        %     name - Name of the table
        %     option - Table view option
        %       cType.TableView.CONSOLE 
        %       cType.TableView.GUI
        %       cType.TableView.HTML (default)
        %
            if nargin==1
                res=getResultInfo(obj);
                printResults(res);
                return
            end
            tbl=getTable(obj,name);
            if isValid(tbl)
                showTable(tbl,varargin{:});
            else
                printLogger(tbl);
            end
        end

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
            res=obj.getResultTable(graph);
            if isValid(res)
                showGraph(res,graph,varargin{:});
            else
                printLogger(res);
            end
        end

        %%%
        %  Specific result presentation methods
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

        function showDataModel(obj,name,varargin)
        % Show Data Model tables
            res=obj.DataModel;
            if nargin==1
                printResults(res)
            else
                showResults(res,name,varargin{:})
            end
        end

        function showTablesDirectory(obj,varargin)
        % Show tables directory
            tbl=obj.getTablesDirectory;
            showTable(tbl,varargin{:})
        end

        %%%
        % Save Results methods
        %%%
        function log=saveSummary(obj,filename)
        % Save the summary tables into a filename
        % The following file types are availables (JSON,XML,XLSX,CSV,MAT)
        %   Input:
        %     filename - Name of the file
        %   Output:
        %     log - cMessageLogger object containing the status and error messages
        %
            log=cMessageLogger();
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
        %   log - cMessageLogger object containing the status and error messages
            log=cMessageLogger();
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
        %   log - cMessageLogger object containing the status and error messages
            log=cMessageLogger();
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
        % Save the productive diagram adjacency tables into a file
        % The following file types are availables (XLSX,CSV,MAT)
        %  Input:
        %   filename - Name of the file
        %  Output:
        %   log - cMessageLogger object containing the status and error messages
            log=cMessageLogger();
            if nargin~=2
                log.printError('Usage: saveProductiveDiagram(model,filename)');
                return
            end
            % Save fat,pat and fpat tables
            res=obj.productiveDiagram;
            if ~isValid(res)
                res.printLogger;
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

        function log=setWasteType(obj,wtype)
        % Set the waste type allocation method for Active Waste
        %  Input
        %   wtype - waste allocation type (see cType)
        %
            log=cMessageLogger();
            if nargin~=2
               log.printError('Usage: obj.setWasteType(key,wtype)');
               return
            end  
            wt=obj.fp1.WasteTable;
            if wt.setType(obj.ActiveWaste,wtype)
                obj.printDebugInfo('Change allocation type for waste %s',obj.ActiveWaste);
            else
                log.printError('Invalid waste type %s / %s',obj.ActiveWaste,wtype);
                return
            end
            obj.fp1.updateWasteOperators;
            obj.setThermoeconomicAnalysis;
            obj.setSummaryResults;
            if obj.isDiagnosis
                obj.setThermoeconomicDiagnosis;
            end
        end

        function log=setWasteValues(obj,val)
        % Set the waste table values
        % Input
        %  id - Waste key
        %  val - vector containing the waste values
            log=cMessageLogger();
            if nargin~=2
               log.printError('Usage: obj.setWasteValues(key,values)');
               return
            end  
            wt=obj.fp1.WasteTable;
            if wt.setValues(obj.ActiveWaste,val)
                obj.printDebugInfo('Change allocation values for waste %s',obj.ActiveWaste);
            else
                log.printError('Invalid waste %s allocation values',obj.ActiveWaste);
                return
            end
            obj.fp1.updateWasteOperators;
            obj.setThermoeconomicAnalysis;
            obj.setSummaryResults;
            if obj.isDiagnosis
                obj.setThermoeconomicDiagnosis;
            end
        end
   
        function log=setWasteRecycled(obj,val)
        % Set the waste table values
        % Input
        %  id - Waste id
        %  val - vector containing the waste values
            log=cMessageLogger();
            if nargin~=2
               log.printError('Usage: obj.setWasteRecycled(key,value)');
               return
            end 
            wt=obj.fp1.WasteTable;
            if wt.setRecycleRatio(obj.ActiveWaste,val)
                obj.printDebugInfo('Change recycling ratio for waste %s',obj.ActiveWaste)
            else
                log.printError('Invalid waste %s recycling values',obj.ActiveWaste);
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
        function res=setFlowResource(obj,c0)
        % Set the resources cost of the flows
        %   Input:
        %       c0 - array containing the flows cost
        %   Output:
        %       res - cResourceCost object 
            res=cMessageLogger();
            if ~obj.isGeneralCost
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
            res=cMessageLogger();
            if ~obj.isGeneralCost
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
            res=cMessageLogger();
            if ~obj.isGeneralCost
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
            res=cMessageLogger();
            if ~obj.isGeneralCost
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
        %     state - State name. If missing, actual state is used 
            if nargin==1
                state=obj.State;
            end
            res=getExergyData(obj.DataModel,state);
        end

        function log=setExergyData(obj,values)
        % Set exergy data values to actual state
        %   Input:
        %     values - Array with the exergy values of the flows
        %
            log=cMessageLogger();
            % Check state is no reference 
            if strcmp(obj.ReferenceState,obj.State)
                log.printError('Cannot change Reference State values');
                return
            end
            % Set exergy data for state
            data=obj.DataModel;
            rex=data.setExergyData(obj.State,values);
            if ~isValid(rex)
                printLogger(rex);
                return
            end
            % Compute cExergyCost
            if obj.isWaste
                cex=cExergyCost(rex,obj.wd);
            else
                cex=cExergyCost(rex);
            end
            if ~isValid(cex)
                printLogger(cex);
                return
            else
                obj.rstate.setValues(obj.State,cex);
            end
            % Get results
            obj.triggerStateChange;
            obj.setSummaryResults;
        end
    end
    %%%%%%
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
            obj.fp1=obj.rstate.getValues(obj.State);
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
            res=cMessageLogger(cType.INVALID);
            if ~obj.isSummaryEnable
                return
            end
            if ~obj.Summary
                obj.setSummary(true);
            end
            res=obj.getResultId(cType.ResultId.SUMMARY_RESULTS);
        end

        function setSummaryResults(obj)
        % Obtain Summary Results
            if ~obj.activeSet || ~obj.isSummaryEnable
                return
            end
            id=cType.ResultId.SUMMARY_RESULTS;
            res=obj.getResultId(id);
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
                obj.printDebugInfo('Compute Recycling Analysis: %s',obj.ActiveWaste);
            else
                ra=cWasteAnalysis(obj.fp1,false,obj.ActiveWaste);
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
            if ~obj.DataModel.existState(state)
                obj.printWarning('Invalid state name %s',state);
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
        end

        function res=checkReferenceState(obj,state)
        % Check the reference state value
            res=false;
            if ~obj.DataModel.existState(state)
                obj.printWarning('Invalid state name %s',state);
                return
            end
            if strcmp(obj.ReferenceState,state)
                obj.printDebugInfo('Reference and Operation State are the same');
                return
            end
            obj.fp0=obj.rstate.getValues(state);
            res=true;
        end
 
        function res=checkResourceSample(obj,sample)
        % Check the resource sample value
            res=false;
            if ~obj.DataModel.existSample(sample)
                obj.printWarning('Invalid resource sample %s',sample);
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
            pct=cType.getCostTables(value);
            if isempty(pct)
                obj.printWarning('Invalid Cost Tables parameter value: %s',value);
                return
            end
            if strcmp(obj.CostTables,value)
                obj.printDebugInfo('No parameter change. The new value is equal to the previous one');
                return
            end
            if bitget(pct,cType.GENERALIZED) && ~obj.isResourceCost
                obj.printWarning('Invalid Parameter %s. Model does not have external resources defined',value);
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
            if ~cType.checkDiagnosisMethod(value)
                obj.printWarning('Invalid Diagnosis method: %s',value);
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
            if ~obj.wd.existWaste(value)
                obj.printWarning('Invalid waste flow: %s',value);
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
            if ~islogical(value)
                obj.printDebugInfo('Invalid value. Must be true/false');
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
            if ~islogical(value)
                obj.printDebugInfo('Invalid value. Must be true/false');
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
        function res=getResultId(obj,index)
        % Get the cResultInfo given the resultId
            res=getResults(obj.results,index);
%            if isempty(res)
%                res=cMessageLogger(cType.INVALID);
%            end
        end
        
        function res=getResultTable(obj,table)
        % Get the cResultInfo object associated to a table
            res=cMessageLogger();
            tinfo=obj.getTableInfo(table);
            if isempty(tinfo)
                res.messageLog(cType.ERROR,'Table %s does not exists',table);
                return
            end
            tmp=obj.getResultId(tinfo.resultId);
            if ~isValid(tmp)
                res.messageLog(cType.ERROR,'Table %s is not available',table);
                return
            end
            res=tmp;
        end

        function res=buildResultInfo(obj)
        % Get a cResultInfo object with all tables of the active model
            res=getResults(obj.results,cType.ResultId.RESULT_MODEL);
            if ~isempty(res)
                return
            end
            tables=struct();
            tmp=getModelResults(obj.results);
            for k=1:numel(tmp)
                dm=tmp{k};
                list=dm.ListOfTables;
                for i=1:dm.NrOfTables
                    tables.(list{i})=dm.Tables.(list{i});
                end
            end
            res=cResultInfo(obj,tables);
            obj.setResults(res);
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