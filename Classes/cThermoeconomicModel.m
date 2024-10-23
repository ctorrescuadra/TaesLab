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
%     ListOfTables          - Get the tables of the cResultInfo
%     getTable              - Get a table by name
%     getTableIndex         - Get the table index
%     saveTable             - Save the results in a external file 
%     exportTable           - Export a table to another format
%     printResults          - Print results on console
%     showResults           - Show results in different interfaces
%     showGraph             - Show the graph associated to a table
%     showTableIndex        - Show the table index in different interfaces
%     exportResults         - Export all the result Tables to another format
%     saveResults           - Save all the result tables in a external file
%     saveDataModel         - Save the data model tables into a file
%     saveDiagramFP         - Save the Diagram FP table into a file
%     saveProductiveDiagram - Save the Productive Diagram tables into a file
%     saveSummary           - Save Summary results into a file
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
        StateNames          % Names of the defined states
        SampleNames         % Names of the defined resource samples
        WasteFlows          % Names of the waste flows
        ResourceData        % Resource Data object
        ResourceCost        % Resource Cost object
        ReferenceState      % Active Reference state
        CostTables          % Selected Cost Result Tables
        DiagnosisMethod     % Method to calculate fuel impact of wastes
        Summary             % Summary Result Selected 
        Recycling           % Activate Recycling Analysis
        ActiveWaste         % Active Waste Flow for Recycling Analysis and Waste Allocation
        sopt                % cSummary Option class
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
        directCost         % Direct cost are obtained
        generalCost        % General cost are obtained
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
            if ~isObject(data,'cDataModel')
                obj.printError('Invalid data model');
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
            obj.DefaultGraph=cType.Tables.PROCESS_ICT;
            % Check optional input parameters
            p = inputParser;
            refstate=data.StateNames{1};
            sopt=cSummaryOptions(data);
            p.addParameter('State',refstate,@ischar);
            p.addParameter('ReferenceState',refstate,@ischar);
            p.addParameter('ResourceSample',cType.EMPTY_CHAR,@ischar);
            p.addParameter('CostTables',cType.DEFAULT_COST_TABLES,@cType.checkCostTables);
            p.addParameter('DiagnosisMethod',cType.DEFAULT_DIAGNOSIS,@cType.checkDiagnosisMethod);
            p.addParameter('Summary',cType.DEFAULT_SUMMARY,@sopt.checkNames);
            p.addParameter('Recycling',false,@islogical);
            p.addParameter('ActiveWaste',cType.EMPTY_CHAR,@ischar);
            p.addParameter('Debug',false,@islogical);
            try
                p.parse(varargin{:});
            catch err
                obj.printError(err.message);
                obj.printError('Usage: cThermoeconomicModel(data,options)');
                return
            end
            param=p.Results;
            obj.sopt=sopt;
            % Set Variables
            obj.fmt=data.FormatData;
            obj.debug=param.Debug;
            obj.DiagnosisMethod=param.DiagnosisMethod;
            obj.Summary=cType.EMPTY_CHAR;
            if data.isWaste
                obj.wd=data.WasteData;
                if isempty(param.ActiveWaste)
                    param.ActiveWaste=data.WasteFlows{1};
                end
                obj.ActiveWaste=param.ActiveWaste;
            end
            % Load Exergy values (all states)
            obj.rstate=cDataset(data.StateNames);
            for i=1:data.NrOfStates
                rex=data.getExergyData(i);
                if ~rex.status
                    obj.addLogger(rex);
                    obj.messageLog(cType.ERROR,'Invalid exergy values. See error log');
                    return
                end
                if obj.isWaste
                    cex=cExergyCost(rex,obj.wd);
                else
                    cex=cExergyCost(rex);
                end
                setValues(obj.rstate,i,cex);
            end
            % Set Operation and Reference State
            if obj.checkReferenceState(param.ReferenceState)
                obj.ReferenceState=param.ReferenceState;
            else
                obj.printError('Invalid state name %s',param.ReferenceState);
                return
            end
            if obj.checkState(param.State)
                obj.State=param.State;
            else
                obj.printError('Invalid state name %s',param.State);
                return
            end
            % Read ResourcesCost
            if obj.checkCostTables(param.CostTables)
                obj.CostTables=param.CostTables;
            else
                res.printError('Invalid CostTables parameter %s',param.CostTables);
                return
            end
            if data.isResourceCost
                if isempty(param.ResourceSample)
                    param.ResourceSample=data.SampleNames{1};
                end
                if obj.checkResourceSample(param.ResourceSample)
                    obj.Sample=param.ResourceSample;
                else 
                    obj.printError('Invalid ResourceSample %s',param.ResourceSample);
                    return
                end
            end
            % Compute initial state results
            obj.setProductiveStructure;
            obj.setStateInfo;
            obj.setThermoeconomicAnalysis;
            obj.setThermoeconomicDiagnosis;
            obj.setRecycling(param.Recycling);   
            obj.setSummary(param.Summary);
        end

        %%%
        % Define get Properties
        %%%
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
        
        function res=get.ResourceData(obj)
        % Get the current values of resource data
            res=obj.rsd;
        end
     
        function res=get.ResourceCost(obj)
        % Get the current values of resource cost
            res=obj.rsc;
        end

        %%%%
        % Set methods
        %%%%
        function setState(obj,state)
        % Set a new valid state from StateNames
        % Syntax:
        %   obj.setState(state)
        % Input Parameters
        %   state - Valid state.
        %     array of chars 
            if checkState(obj,state)
                obj.State=state;
                obj.triggerStateChange;
            end
        end

        function setReferenceState(obj,state)
        % Set a new valid reference state from StateNames
        % Syntax:
        %   obj.setState(state)
        % Input Parameters
        %   state - Valid state.
        %     array of chars
            if checkReferenceState(obj,state)
                obj.ReferenceState=state;
                obj.printDebugInfo('Set Reference State: %s',state);
                obj.setThermoeconomicDiagnosis;
            end
        end

        function setResourceSample(obj,sample)
        % Set a new valid ResourceSample from SampleNames
        % Syntax:
        %   obj.setResourceSample(state)
        % Input Parameters
        %   state - Valid state.
        %     array of chars
            if obj.checkResourceSample(sample)
                obj.Sample=sample;
                obj.triggerResourceSampleChange;
            end
        end

        function setCostTables(obj,value)
        % Set a new value of CostTables parameter
        % Syntax:
        %   obj.setCostTables(type)
        % Input Parameters
        %   value - Type of thermoeconomic tables
        %     'DIRECT' | 'GENERALIZED' | 'ALL'
            if obj.checkCostTables(value)
                obj.CostTables=value;
                obj.triggerCostTablesChange;
            end
        end

        function setDiagnosisMethod(obj,method)
        % Set a new value of DiagnosisMethod parameter
        % Syntax:
        %   obj.setDiagnosisMethod(method)
        % Input Parameters
        %   method - Method used to compute diagnosis
        %     'NONE' | 'WASTE_EXTERNAL' | 'WASTE_INTERNAL'
            if obj.checkDiagnosisMethod(method)
                obj.DiagnosisMethod=method;
                obj.setThermoeconomicDiagnosis;
            end
        end

        function setActiveWaste(obj,value)
        % Set a new waste flow for recycling analysis
        % Syntax:
        %   setActiveWaste(obj,method)
        % Input Parameters
        %   value - waste flow key
        %     char array
            if obj.checkActiveWaste(value)
                obj.ActiveWaste=value;
                obj.printDebugInfo('Set Active Waste to %s',value);
            end
            obj.setRecyclingResults;
        end

        function setSummary(obj,value)
        % Set Summary parameter
        % Syntax:
        %   model.setSummary(value)
        % Input Arguments
        %   value - Activate/Deactivate summary results
        %     false | true
        %
            if obj.checkSummary(value)
                obj.Summary=value;
                obj.printDebugInfo('Summary Mode is %s',value);
                obj.setSummaryResults;
            end
        end
    
        function setRecycling(obj,value)
        % Set Recycling parameter
        % Syntax:
        %   model.setRecycling(value)
        % Input Parameters:
        %   value - Activat/Deactivate recycling analysis
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

        function setDebug(obj,dbg)
        % Set debug control variable
            if islogical(dbg) && (obj.debug~=dbg)
                obj.debug=dbg;
                obj.printInfo('Debug is set to %s',upper(log2str(dbg)));
            end
        end

        function toggleSummary(obj)
        % Toggle summary results property
        % Syntax:
        %   obj.toggleSummary
            obj.setSummary(~obj.Summary);
        end

        function toggleRecycling(obj)
        % toggle recycling analysis property
        % Syntax:
        %   obj.toggleRecycling

            obj.setRecycling(~obj.Recycling);
        end

        function toggleDebug(obj)
        % Toggle debug property
        % Syntax:
        %   obj.toggleDebug
            setDebug(obj,~obj.debug);
        end
        %%%
        % get cResultInfo objects
        %%%
        function res=productiveStructure(obj)
        % Get the Productive Structure cResultInfo object
        % Syntax:
        %   res = obj.productiveStructure
        % Output Argument
        %   res - cResultInfo with the productive structure info
            res=obj.getResults(cType.ResultId.PRODUCTIVE_STRUCTURE);
        end

        function res=exergyAnalysis(obj)
        % Get the ExergyAnalysis cResultInfo object
        %   It containing the exergy and fuel product table
        % Syntax:
        %   res = obj.exergyAnalysis
        % Output Arguments
        %   res - cResultInfo with the exergy analysis info
            res=obj.getResults(cType.ResultId.THERMOECONOMIC_STATE);
        end

        function res=thermoeconomicAnalysis(obj)
        % Get the Thermoeconomic Analysis cResultInfo object
        %   It contains the direct and/or generalized cost tables, 
        %   depending on CostTables property
        % Syntax:
        %   res = obj.thermoeconomicAnalysis
        % Output Argument:
        %   res - cResultInfo with thermoeconomic analysis info
            res=obj.getResults(cType.ResultId.THERMOECONOMIC_ANALYSIS);
        end

        function res=wasteAnalysis(obj)
        % Get the Waste Analysis cResultInfo object
        % Syntax:
        %   res = obj.wasteAnalysis
        % Output Argument:
        %   res - cResultInfo with waste analysis info
            res=obj.getResults(cType.ResultId.WASTE_ANALYSIS);
        end

        function res=thermoeconomicDiagnosis(obj)
        % Get the Thermoeconomic Diagnosis cResultInfo object
        % Syntax:
        %   res = obj.thermoeconomicDiagnosis
        % Output Argument:
        %   res - cResultInfo with diagnosis info        
            res=obj.getResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
        end

        function summaryDiagnosis(obj)
        % Get the diagnosis results summary
        % Syntax:
        %   res = obj.summaryDiagnosis 
            res=obj.thermoeconomicDiagnosis;
            if ~isempty(res)
                res.summaryDiagnosis;
            end
        end

        function res=summaryResults(obj)
        % Get the Summary Results cResultInfo object
        % Syntax:
        %   res = obj.summaryResults 
        % Output Argument:
        %   res - cResultInfo with summary info            
            res=obj.getResults(cType.ResultId.SUMMARY_RESULTS);
        end

        function res=productiveDiagram(obj)
        % Get the productive diagram cResultInfo object
        % Syntax:
        %   res = obj.productiveDiagram 
        % Output Argument:
        %   res - cResultInfo with productive diagram        
            res=obj.getResults(cType.ResultId.PRODUCTIVE_DIAGRAM);
        end

        function res=diagramFP(obj)
        % Get the diagram FP cResultInfo object
        % Syntax:
        %   res = obj.diagramFP
        % Output Argument:
        %   res - cResultInfo with diagram FP    
            res=obj.getResults(cType.ResultId.DIAGRAM_FP);
        end

        function res=dataInfo(obj)
        % Get the data model cResultInfo object
        % Syntax:
        %   res = obj.dataInfo
        % Output Argument:
        %   res - cResultInfo with data model   
          res=getResults(obj.results,cType.ResultId.DATA_MODEL);
        end

        function res=getResultInfo(obj,arg)
        % Get the cResultInfo with optional parameters
        %   If arg is a ResultId number the function returns
        %   the corresponding cResultInfo
        %   If arg is a table name it returns the cResultInfo
        %   that contains the tablw 
        % Syntax:
        %   res=obj.getResultInfo
        %   res=obj.getResultInfo(arg)
        % Input Parameters:
        %   arg - ResultId or table name (optional)
        % Output Parameters
        %   res - cResultInfo
        % Examples:
        %   res = obj.getResultInfo;
        %     Return the Model Results of the current state
        %   res = obj.getResultInfo(cType.ResultId.EXERGY_ANALYSIS)
        %     Return the exergy analysis results
        %   res = obj.getResultsInfo('processes');
        %     Return the result info which contains the table 'processes', 
        %     in this case the productive structure
        % 
            if (nargin==1)
                res=buildResultInfo(obj);
            elseif isIndex(arg,1:cType.MAX_RESULT_INFO)
                res=getResults(obj,arg);
            elseif ischar(arg)
                res=getResultTable(obj,arg);
            else
                res=cMessageLogger(cType.INVALID);
            end
        end

        %%%
        % Utility methods
        %%%%
        function showProperties(obj)
        % Show the values of the actual parameters of the model
        % Syntax:
        %   obj.showProperties
            s=struct('State',obj.State,...
                'ReferenceState',obj.ReferenceState,...
                'ResourceSample',obj.Sample,...
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

        function res=getStateId(obj,key)
        % Get the State Id given the name
        % Syntax:
        %   id = obj.getStateId(key)
        % Input Arguments:
        %   key - State name
        % Output Arguments:
        %   id - State Id number
            res=obj.DataModel.ExergyData.getIndex(key);
        end

        function res=getSampleId(obj,key)
        % Get the Sample Id given the resource sample name
        % Syntax:
        %   id = obj.getSampleId(key)
        % Input Arguments:
        %   key - Resource Sample name
        % Output Arguments:
        %   id - Resource State Id number
            res=obj.DataModel.ResourceData.getIndex(key);
        end

        function res=getWasteId(obj,key)
        % Get the Waste flow Id
        % Syntax:
        %   id = obj.getWasteId(key)
        % Input Arguments:
        %   key - Waste name
        % Output Arguments:
        %   id - Waste Id number
            res=obj.wd.getWasteIndex(key);
        end
    
        function res=isResourceCost(obj)
        % Check if the model has resources cost defined
        % Syntax:
        %   obj.isResourceCost
        % Output Argument
        %   true | false
            res=obj.DataModel.isResourceCost;
        end

        function res=isGeneralCost(obj)
        % Check if Generalized cost calculation are activated
        %   It is activated if it has resource samples defined in the data model
        %   and 'CostTables' parameter is defined as 'GENERALIZED' | 'ALL'
        % Syntax:
        %   obj.isResourceCost
        % Output Argument
        %   true | false
            res=obj.isResourceCost && obj.generalCost;
        end

        function res=isDiagnosis(obj)
        % Check if diagnosis computation is available.
        %   It is activate under the following conditions:
        %   - There is more than one state
        %   - Reference and Operation state are differents
        %   - The 'DiagnosisMethod' is not 'NONE'
        %   - Both states has the same processes activated
        % Syntax:
        %   res = obj.isDiagnosis
        % Output Arguments:
        %   res - true | false 
            res=false;
            %Check is there is more than one state
            if ~obj.DataModel.isDiagnosis
                return
            end
            %Check if diagnosis method is activated
            if ~cType.getDiagnosisMethod(obj.DiagnosisMethod) 
                return
            end
            %Check is operation and reference state are defined
            if isempty(obj.ReferenceState) || isempty(obj.State)
                return
            end
            %Check if operation and reference states are diferent 
            if strcmp(obj.ReferenceState,obj.State)
                return
            end
            % Check configurations
            if ~all(obj.fp0.ActiveProcesses==obj.fp1.ActiveProcesses)
                obj.printDebugInfo('Compare two diferent configurations is not available');
                return
            end
            res=true;
        end

        function res=isWaste(obj)
        % Check if model has wastes defined
        % Syntax:
        %   res = obj.isWate
        % Output Arguments:
        %   res - true | false 
            res=logical(obj.DataModel.isWaste);
        end

        function res=isSummaryEnable(obj)
        % Check if Summary is enable
        %   The summary result is enabled if the model has more than one state
        % Syntax:
        %   res = obj.isSummaryEnable
        % Output Arguments:
        %   res - true | false
            res=(obj.DataModel.NrOfStates>1) || (obj.DataModel.NrOfSamples>1);
        end

        function res=isSummaryActive(obj)
        % Check if Summary has been activated
        % Syntax:
        %   res = obj.isSummaryEnable
        % Output Arguments:
        %   res - true | false   
            res=logical(cType.getSummaryId(obj.Summary));
        end

        function res=getResultState(obj,idx)
        % Get the cExergyCost object of each state 
        %   Internal application use: cSummaryResults
        % Syntax:
        %   res = obj.getResultState(idx)
        % Input Argument:
        %   idx - State Name index/key
        % Output Result
        %   res - cExergyCost object
            if nargin==1
                res=obj.fp1;
            else
                res=obj.rstate.getValues(idx);
            end
        end

        function res=getModelResults(obj)
        % Get a cell array of cResultInfo objects of the current state
        %   Internal application use: ViewResults
            res=getModelResults(obj.results);
        end

        %%%
        % Tables Directory methods
        %%%
        function res=getTablesDirectory(obj,columns)
        % Create the tables directory of the active model
        % Syntax:
        %   res=obj.getTablesDirectory(columns)
        % Input Arguments:
        %   columns - Cell array with the names of columns of table
        %     If ommited the the default columns are shown
        % Output Arguments
        %   res - cTable with the active tables of the model and its
        %    properties defined by columns parameters 
        % See also ListResultTables
            if nargin==1
                columns=cType.DIR_COLS_DEFAULT;
            end
            tbl=obj.fmt.getTablesDirectory(columns);
            atm=zeros(tbl.NrOfRows,1);
            % Get the initial state of the table
            for i=1:cType.ResultId.SUMMARY_RESULTS
                rid=obj.getResults(i);
                if isValid(rid)
                    list=rid.ListOfTables;
                    idx=cellfun(@(x) getTableId(obj.fmt,x),list);
                    atm(idx)=true;
                end
            end
            % Create the table
            rows=find(atm);
            data=tbl.Data(rows,:);
            rowNames=tbl.RowNames(rows);
            colNames=tbl.ColNames;
            props.Name='tdir'; props.Description='Tables Directory';
            res=cTableData(data,rowNames,colNames,props);
        end

        function res=getTableInfo(obj,name)
        % Get the properties of a table
        % Syntax:
        %   res = obj.getTableInfo
        % Input Arguments:
        %   name - Name of the table
        % Output Arguments:
        %   res - struct with the properties of the table
            res=getTableInfo(obj.fmt,name);
        end

        %%%
        % Results Set methods
        %%%
        function tbl=getTable(obj,name)
        % Get a table called name, if its available
        % Syntax:
        %   tbl = obj.getTable(name)
        % Input Arguments:
        %   name - name of the table
        % Output Arguments:
        %   tbl - cTable object
        %
            tbl=cMessageLogger();
            if strcmp(name,cType.TABLE_INDEX)
                res=obj.buildResultInfo;
                tbl=res.getTableIndex;
            else
                res=getResultTable(obj,name);
                if res.status
                    tbl=getTable(res,name);
                else
                    tbl.addLogger(res);
                end     
            end
        end

        function showResults(obj,name,varargin)
        % View an individual table
        % Syntax:
        %   obj.showResults(table,option)
        % Input Arguments:
        %   name - Name of the table
        %   option - Table view option
        %     cType.TableView.CONSOLE 
        %     cType.TableView.GUI
        %     cType.TableView.HTML (default)
        %
            if nargin==1
                res=getResultInfo(obj);
                printResults(res);
                return
            end
            tbl=getTable(obj,name);
            if tbl.status
                showTable(tbl,varargin{:});
            else
                printLogger(tbl);
            end
        end

        function showGraph(obj,graph,varargin)
        % Show a graph table. 
        %   Find the resultId asociated to the table
        %   and call cResultInfo.showGraph
        % Syntax:
        %   obj.showGraph(graph,options)
        % Input Arguments:
        %   graph - name of the table
        %   options - graph options
        % See also cResultSet.showGraph
        %
            if nargin == 1
                graph=obj.DefaultGraph;
            end
            res=obj.getResultTable(graph);
            if res.status
                showGraph(res,graph,varargin{:});
            else
                printLogger(res);
            end
        end

        %%%
        %  Specific result presentation methods
        %%%
        function showSummary(obj,name,varargin)
        % Show Summary tables
        % Syntax:
        %   res = obj.showSummary(name,options)
        % Input Arguments:
        %   name - name of the summary table
        %     if no name is provided all summary tables 
        %     are shown in console
        %   options - options to show results
        % See also cResultSet.showResults
        %
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
        % Syntax:
        %   res = obj.showDataModel(name,options)
        % Input Arguments:
        %   name - name of the data model tables
        %     if no name is provided all data model tables 
        %     are shown in console
        %   options - options to show results
        % See also cResultSet.showResults
        %
            res=obj.DataModel;
            if nargin==1
                printResults(res)
            else
                showResults(res,name,varargin{:})
            end
        end

        function showTablesDirectory(obj,varargin)
        % Show the list of available tables
        % Syntax:
        %   obj.showTablesDirectory(options)
        % Input Arguments:
        %   options - show results options
            tbl=obj.getTablesDirectory;
            showTable(tbl,varargin{:})
        end

        %%%
        % Save Results methods
        %%%
        function log=saveSummary(obj,filename)
        % Save the summary tables into a filename
        %   The following file types are available: XLSX,CSV,TXT,TEX,HTML,MAT
        % Syntax:
        %   log = saveSummary(filename)
        % Input Arguments:
        %   filename - Name of the file
        % Output Arguments:
        %   log - cMessageLogger object containing the status and error messages
        %
            log=cMessageLogger();
            if nargin~=2
                log.printError('Usage: saveDataModel(model,filename)');
                return
            end       
            msr=obj.getSummaryResults;
            if ~isValid(msr)
                obj.printDebugInfo('Summary Results not available');
                return
            end
            log=saveResults(msr,filename);
        end
    
        function log=saveDataModel(obj,filename)
        % Save the data model in a file
        %   The following file types are available: JSON,XML,XLSX,CSV,MAT
        % Syntax:
        %   log = obj.saveDataModel(filename)
        % Input Arguments:
        %   filename - Name of the file
        % Output Arguments:
        %   log - cMessageLogger object containing the status and error messages
        %
            log=cMessageLogger();
            if nargin~=2
                log.printError('Usage: saveDataModel(model,filename)');
                return
            end
            log=saveDataModel(obj.DataModel,filename);
        end

        function log=saveDiagramFP(obj,filename)
        % Save the Adjacency matrix of the Diagram FP in a file
        %   The following file types are available: XLSX,CSV,MAT
        %   log = saveDiagramFP(filename)
        %  Input:
        %   filename - Name of the file
        %  Output:
        %   log - cMessageLogger object containing the status and error messages
        %
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
        %   The following file types are available: XLSX,CSV,MAT
        % Syntax:
        %   log = saveProductiveDiagram(filename)
        % Input Arguments:
        %   filename - Name of the file
        % Output Arguments:
        %   log - cMessageLogger object containing the status and error messages
        %
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
        %%%
        function wasteAllocation(obj)
        % Show waste information in console
        % Syntax:
        %   obj.wasteAllocation
        %
            res=obj.wasteAnalysis;
            printTable(res.Tables.wd)
            printTable(res.Tables.wa)
        end

        function log=setWasteType(obj,wtype)
        % Set the waste type allocation method for Active Waste
        % Syntax: 
        %   log = setWasteType(wtype)
        % Input Arguments:
        %   wtype - waste allocation type
        % Output Arguments:
        %   log - cMessageLogger with the status and messages of operation
        % See also cType.WasteAllocation
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
            obj.setSummaryTables;
            if obj.isDiagnosis
                obj.setThermoeconomicDiagnosis;
            end
        end

        function log=setWasteValues(obj,val)
        % Set the waste table values
        % Syntax:
        %   log = obj.setWasteValues(val)
        % Input Arguments:
        %  val - vector containing the waste allocation values for processes
        % Output Arguments:
        %   log - cMessageLogger with the status and messages of operation
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
            obj.setSummaryTables;
            if obj.isDiagnosis
                obj.setThermoeconomicDiagnosis;
            end
        end
   
        function log=setWasteRecycled(obj,val)
        % Set the waste recycling ratios
        % Syntax:
        %   log = obj.setWasteValues(val)
        % Input Arguments:
        %   val - vector containing the recycling ratios of each waste
        % Output Arguments:
        %   log - cMessageLogger with the status and messages of operation
        %
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
            obj.setSummaryTables;
            if obj.isDiagnosis
                obj.setThermoeconomicDiagnosis;
            end
        end

        %%%
        % Resource Cost Methods
        %%%
        function res=setFlowResource(obj,c0)
        % Set the resource cost of the flows
        % Syntax:
        %   res = setFlowResources(c0)
        % Input:
        %   c0 - array containing the resources cost of flows
        % Output:
        %   res - cResourceCost object with the new values
            res=cMessageLogger();
            if ~obj.isGeneralCost
                res.printError('No Generalized Cost activated');
				return
            end
            log=setFlowResource(obj.rsd,c0);
            if log.status
                obj.setThermoeconomicAnalysis;
                obj.setSummaryTables;
                res=obj.rsc;
            else
                printLogger(log);
                res.printError('Invalid Resources Values');
            end
        end

        function res=setFlowResourceValue(obj,key,value)
        % Set resource flow cost value
        % Syntax:
        %   res = setFlowResourceValue(key,value)
        % Input Arguments:
        %   key - key name of the resource flow
        %   value - resource cost value
        % Output Argument:
        %   res - cResourceCost object with the new values
            res=cMessageLogger();
            if ~obj.isGeneralCost
                res.printError('No Generalized Cost activated');
                return
            end
            log=setFlowResourceValue(obj.rsd,key,value);
            if log.status
                obj.setThermoeconomicAnalysis;
                obj.setSummaryTables;
                res=obj.rsc;
            else
                printLogger(log);
                res.printError('Invalid Resources Value %s',key);
            end
        end

        function res=setProcessResource(obj,Z)
        % Set the resource cost of the processes
        % Syntax:
        %   res =obj.setProcessResource(Z)
        % Input Agument:
        %   Z - array containing the processes cost
        % Output Argument:
        %   res - cResourceCost object
        %
            res=cMessageLogger();
            if ~obj.isGeneralCost
                res.printError('No Generalized Cost activated');
                return
            end          
            log=setProcessResource(obj.rsd,Z);
            if log.status
                obj.setThermoeconomicAnalysis;
                obj.setSummaryTables;
                res=obj.rsc;
            else
                printLogger(log);
                res.printError('Invalid Resources Values');
            end
        end

        function res=setProcessResourceValue(obj,key,value)
        % Set the recource cost of the processes
        % Input Argument:
        %   key - Process key
        %   value - cost value of the process
        % Output Argument:
        %   res - cResourceCost object
        %
            res=cMessageLogger();
            if ~obj.isGeneralCost
                res.printError('No Generalized Cost activated');
                return
            end
            log=setProcessResourceValue(obj.rsd,key,value);
            if log.status
                obj.setThermoeconomicAnalysis;
                obj.setSummaryTables;
                res=obj.rsc;
            else
                printLogger(log);
                res.printError('Invalid Resources Values');
            end
        end

        function res=getResourceData(obj,sample)
        % Get the resource data cost values of sample
        % Syntax:
        %   res = obj.getResourceData(sample)
        % Input Argument:
        %   sample - Name of the resource sample
        % Output Argument:
        %   res - cResourceData object 
        %
            if nargin==1
                sample=obj.Sample;
            end
            res=obj.DataModel.getResourceData(sample);
        end

        %%%
        % Exergy Data methods
        %
        function res=getExergyData(obj,state)
        % Get cExergyData object of a state
        % Syntax: 
        %   res = obj.getExergyData(state)
        % Input Arguments:
        %   state - State name. 
        %     If missing, actual state is used
        % Output Arguments
        %   res - cExergyData object
            if nargin==1
                state=obj.State;
            end
            res=getExergyData(obj.DataModel,state);
        end

        function res=setExergyData(obj,values)
        % Set exergy data values to actual state
        % Syntax:
        %   log=obj.setExergyData(values)
        % Input Arguments:
        %   values - Array with the exergy values of the flows
        % Output Arguments:
        %   log - cMessageLogger object with the status and messages of operation
        %
            res=cMessageLogger();
            % Check state is no reference 
            if strcmp(obj.ReferenceState,obj.State)
                res.printError('Cannot change Reference State values');
                return
            end
            % Set exergy data for state
            data=obj.DataModel;
            rex=data.setExergyData(obj.State,values);
            if ~rex.status
                printLogger(rex);
                return
            end
            % Compute cExergyCost
            if obj.isWaste
                res=cExergyCost(rex,obj.wd);
            else
                res=cExergyCost(rex);
            end
            if res.status
                obj.rstate.setValues(obj.State,res);
                obj.fp1=res;
            else
                printLogger(res);
                return
            end
            % Get results
            obj.triggerStateChange;
            obj.setSummaryResults(cType.RESOURCES);
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
            res=getExergyResults(obj.fmt,obj.fp1);
            obj.setResults(res);
            obj.printDebugInfo('Set State: %s',obj.State);
            obj.setDiagramFP;
        end

        function setThermoeconomicAnalysis(obj)
        % Trigger thermoeconomic analysis
            % Read resources
            options=struct('DirectCost',obj.directCost,'GeneralCost',obj.generalCost);
            if obj.isGeneralCost
                obj.rsc=getResourceCost(obj.rsd,obj.fp1);
                options.ResourcesCost=obj.rsc;
            end
            % Get cModelResults info
            if isValid(obj.fp1)
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
            if ~obj.isDiagnosis
                obj.clearResults(id);
                obj.printDebugInfo('Thermoeconomic Diagnosis is not active');
                return
            end
            % Compute diagnosis analysis
            method=cType.getDiagnosisMethod(obj.DiagnosisMethod);
            sol=cDiagnosis(obj.fp0,obj.fp1,method);
            % get cModelResult object
            if sol.status
                res=sol.getResultInfo(obj.fmt);
                obj.setResults(res);
                obj.printDebugInfo('Compute Thermoeconomic Diagnosis for State: %s',obj.State);
            else
                sol.printLogger;
                sol.printError('Thermoeconomic Diagnosis cannot be calculated');
                obj.clearResults(id);
            end
        end

        function setSummaryResults(obj)
        % Obtain Summary Results
            id=cType.ResultId.SUMMARY_RESULTS;
            if ~obj.isSummaryActive
                obj.clearResults(id)
                return
            end
            option=cType.getSummaryId(obj.Summary);
            sr=cSummaryResults(obj,option);
            if sr.status
                res=sr.getResultInfo(obj.fmt);
                obj.setResults(res);
                obj.printDebugInfo('Compute Summary Results');
            else
                sr.printLogger;
            end
        end

        function setSummaryTables(obj,option)
            if ~obj.isSummaryActive
                return
            end
            if nargin==1
                option=cType.getSummaryId(obj.Summary);
            end
            sr=obj.summaryResults.Info;
            sr.setSummaryTables(obj,option);
            if sr.status
                res=sr.getResultInfo(obj.fmt);
                obj.setResults(res);
                obj.printDebugInfo('Compute Summary Results');
            else
                 sr.printLogger;
            end
        end

        function setRecyclingResults(obj)
        % Set Recycling Analysis Results
            if ~obj.isWaste
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
            if ra.status
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
            if dfp.status
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
            if pd.status
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
            obj.fp1=obj.rstate.getValues(state);
            res=true;
        end

        function triggerStateChange(obj)
        % Trigger State Change
            obj.setStateInfo;
            obj.setThermoeconomicAnalysis;
            obj.setThermoeconomicDiagnosis;
            obj.setSummaryTables(cType.RESOURCES);
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
            if isempty(sample) || strcmp(obj.Sample,sample)
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
            obj.setSummaryTables(cType.STATES);
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
            obj.directCost=bitget(pct,cType.DIRECT);
            obj.generalCost=bitget(pct,cType.GENERALIZED);
            if obj.generalCost && ~obj.isResourceCost
                obj.printWarning('Invalid Parameter %s. Model does not have external resources defined',value);
                return
            end
            res=true;
        end 
    
        function triggerCostTablesChange(obj)
        % Set cost tables method and trigger thermoeconomic analysis
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
            if ~checkNames(obj.sopt,value)
                obj.printDebugInfo('Invalid Summary option %s',value);
                return
            end
           if strcmp(obj.Summary,value)
                obj.printDebugInfo('No parameter change. The new value is equal to the previous one');
                return
            end
            res=true;
        end

        function res=checkRecycling(obj,value)
        % Ckeck Summary parameter
            res=false;
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
        %%%
        function res=getResults(obj,index)
        % Get the cResultInfo given the resultId
            if index<cType.MAX_RESULT_INFO
                res=getResults(obj.results,index);
            else
                res=buildResultInfo(obj);
            end
            if isempty(res)
                obj.printDebugInfo('%s is not available',cType.Results{index});
            end
        end
        
        function res=getResultTable(obj,table)
        % Get the cResultInfo object associated to a table
            res=cMessageLogger();
            tinfo=obj.getTableInfo(table);
            if isempty(tinfo)
                res.messageLog(cType.ERROR,'Table %s does not exists',table);
                return
            end
            tmp=obj.getResults(tinfo.resultId);
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