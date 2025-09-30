classdef (Sealed) cThermoeconomicModel < cResultSet
%cThermoeconomicModel - Create the thermoeconomic model results object.
%   It is the main class of TaesLab package, and provide the following functionality:
%   - Read and check a thermoeconomic data model
%   - Compute direct and generalized exergy cost
%   - Compare two thermoeconomic states (thermoeconomic diagnosis)
%   - Analize Recycling effects (recycling analysis)
%   - Get Summary Results
%   - Save the data model and results in diferent formats, for further analysis
%   - Show the results tables in console, as GUI tables or graphs
%
%   cThermoeconomicModel constructor:
%     obj = cThermoeconomicModel(data, options)
%
%   cThermoeconomicModel properties:
%     DataModel       - cDataModel object
%     StateNames      - cell array with the names of the defined states
%     SampleNames     - cell array with the names of the defined resource samples
%     WasteFlows      - cell array with the names of the waste flows
%     ResourceData    - cResourceData object
%     ResourceCost    - cResource Cost object
%     ReferenceState  - Active Reference state name
%     CostTables      - Selected Cost Result Tables
%     DiagnosisMethod - Method to calculate fuel impact of wastes
%     Summary         - Summary Results Selected
%     Recycling       - Recycling Analysis active (true | false)
%     ActiveWaste     - Active waste flow name for Waste Analysis
%
%   cThermoeconomicModel methods
%    Set Methods
%     setState            - Set State value
%     setReferenceState   - Set Reference State value
%     setResourceSample   - Set Resource Sample value
%     setCostTables       - Set CostTables parameter
%     setDiagnosisMethod  - Set DiagnosisMethod parameter
%     setActiveWaste      - Set Active Waste value
%     setRecycling        - Activate Recycling Analysis
%     setSummary          - Activate Summary Results
%     setDebug            - Set Debug mode
%     toggleDebug         - Toggle Debug mode
%
%    Results Info Methods
%     productiveStructure     - Get Productive Structure cResultInfo
%     exergyAnalysis          - Get ExergyAnalysis cResultInfo
%     thermoeconomicAnalysis  - Get Thermoeconomic Analysis cResultInfo
%     wasteAnalysis           - Get Waste Analysis cResultInfo  
%     thermoeconomicDiagnosis - Get Thermoeconomic Diagnosis cResultInfo
%     summaryDiagnosis        - Get Diagnosis Summary
%     productiveDiagram       - Get Productive Diagrams cResultInfo
%     diagramFP               - Get Diagram FP cResultInfo
%     summaryResults          - Get Summary cResultInfo
%     dataInfo                - Get Data Model cResultInfo
%     showResultInfo          - Get a strcuture with all cResultInfo
%
%    Model Info Methods
%     showProperties  - Show model properties
%     isResourceCost  - Check if model has Resource Cost Data
%     isDirectCost    - Check if model has Direct Cost Tables
%     isGeneralCost   - Check if model compute Generalized Costs
%     isDiagnosis     - Check if model compute Diagnosis
%     isWaste         - Check if model has waste
%
%    Summary Info Methods
%     summaryOptions  - List of available summary Options
%     isSummaryEnable - Check if Summary Results are enabled
%     isSummaryActive - Check if Summary is activated
%     isStateSummary  - Check if States Summary is available
%     isSampleSummary - Check if Samples Summary is available
%
%    Tables Info Methods
%     getTablesDirectory  - Get the tables directory
%     getTableInfo        - Get Information of a table
%
%    ResultSet Methods
%     getResultInfo         - Get cResultInfo objects
%     ListOfTables          - Get the list of available tables
%     getTable              - Get a table by name
%     getTableIndex         - Get the table index
%     saveTable             - Save the results in a external file 
%     exportTable           - Export a table to another format
%     printResults          - Print results on console
%     showResults           - Show results in different interfaces
%     showGraph             - Show the graph associated to a table
%     showDataModel         - Show the data model tables
%     showSummary           - Show the summary tables
%     showTablesDirectory   - Show the tables directory
%     showTableIndex        - Show the table index in different interfaces
%     exportResults         - Export all the result Tables to another format
%     saveResults           - Save all the result tables in a external file
%     saveDataModel         - Save the data model tables into a file
%     saveDiagramFP         - Save the Diagram FP table into a file
%     saveProductiveDiagram - Save the Productive Diagram tables into a file
%     saveSummary           - Save Summary results into a file
%
%    Waste Methods
%     wasteAllocation  - Show waste allocation info 
%     setWasteType     - Set the type of a waste
%     setWasteValues   - Set the allocation values of a waste
%     setWasteRecycled - Set the recycled ratio of a waste
%
%    Resources Methods
%     getResourceData         - Get the resource data of a sample
%     setFlowResource         - Set the resource flows values
%     setProcessResource      - Set the processes resource values
%     addResourceData         - Add a new resource sample
%
%    Exergy Data Methods
%     getExergyData - Get the exergy data of a state
%     setExergyData - Set the exergy values of a state
%     addExergyData - Add a new exergy state
%
%   See also cResultSet, cResultId
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
        debug              % Debug info control
        costTableId        % Cost Table option Id
        summaryId          % Summary Option Id
    end

    methods
        function obj=cThermoeconomicModel(data,varargin)
        %cThermoeconomicModel - Construct an instance of the class
        % Syntax:
        %   model = cThermoeconomicModel(data)
        % Input Arguments
        %   data - cDataModel object 
        %   varargin - optional paramaters (see ThermoeconomicModel)
        %   
            if ~isObject(data,'cDataModel')
                obj.printError(cMessages.InvalidObject,class(data));
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
            obj.ClassId=cType.ClassId.RESULT_MODEL;
            % Check optional input parameters
            p = inputParser;
            refstate=data.StateNames{1};
            p.addParameter('State',refstate,@ischar);
            p.addParameter('ReferenceState',refstate,@ischar);
            p.addParameter('ResourceSample',cType.EMPTY_CHAR,@ischar);
            p.addParameter('CostTables',cType.DEFAULT_COST_TABLES,@cType.checkCostTables);
            p.addParameter('DiagnosisMethod',cType.DEFAULT_DIAGNOSIS,@cType.checkDiagnosisMethod);
            p.addParameter('Summary',cType.DEFAULT_SUMMARY,@obj.checkSummaryOption);
            p.addParameter('Recycling',false,@islogical);
            p.addParameter('ActiveWaste',cType.EMPTY_CHAR,@ischar);
            p.addParameter('Debug',false,@islogical);
            try
                p.parse(varargin{:});
            catch err
                obj.printError(err.message);
                obj.printError(cMessages.ShowHelp);
                return
            end
            param=p.Results;
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
                sname=data.StateNames{i};
                rex=data.getExergyData(i);
                if ~rex.status
                    rex.messageLog(cType.ERROR,cMessages.InvalidExergyData,sname);
                    rex.printLogger;
                end
                if obj.isWaste
                    cex=cExergyCost(rex,obj.wd);
                else
                    cex=cExergyCost(rex);
                end
                setValues(obj.rstate,i,cex);
                if ~cex.status
                    cex.messageLog(cType.ERROR,cMessages.NoComputeTA,sname);
                    cex.printLogger;
                end
            end
            % Set Operation and Reference State
            if obj.checkReferenceState(param.ReferenceState)
                obj.ReferenceState=param.ReferenceState;
            else
                return
            end
            if obj.checkState(param.State)
                obj.State=param.State;
            else
                return
            end
            % Check Cost Tables
            if obj.checkCostTables(param.CostTables)
                obj.CostTables=param.CostTables;
            else
                return
            end
            % Read Resource Data
            if data.isResourceCost
                if isempty(param.ResourceSample)
                    param.ResourceSample=data.SampleNames{1};
                end
                if obj.checkResourceSample(param.ResourceSample)
                    obj.Sample=param.ResourceSample;
                else 
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
            obj.buildResultInfo;
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

        function res=get.costTableId(obj)
        % Get the current cost table Id
            res=cType.getCostTables(obj.CostTables);
        end

        function res=get.summaryId(obj)
        % Get the current summary Id
            res=cType.getSummaryId(obj.Summary);
        end

        %%%%
        % Set methods
        %%%%
        function setState(obj,state)
        %setState - Set a new valid state from StateNames
        %   Syntax:
        %     obj.setState(state)
        %   Input Parameters
        %     state - Valid state.
        %       array of chars 
            if checkState(obj,state)
                obj.State=state;
                obj.triggerStateChange;
            end
        end

        function setReferenceState(obj,state)
        %setReferenceState - Set a new valid reference state from StateNames
        %   Syntax:
        %     obj.setState(state)
        %   Input Parameters
        %     state - Valid state.
        %       array of chars
            if checkReferenceState(obj,state)
                obj.ReferenceState=state;
                obj.printDebugInfo(cMessages.SetReferenceState,state);
                obj.setThermoeconomicDiagnosis;
            end
        end

        function setResourceSample(obj,sample)
        %setResourceSample- Set a new valid ResourceSample from SampleNames
        %   Syntax:
        %     obj.setResourceSample(state)
        %   Input Parameters
        %     state - Valid state.
        %       array of chars
            if obj.checkResourceSample(sample)
                obj.Sample=sample;
                obj.printDebugInfo(cMessages.SetResourceSample,sample);
                obj.triggerResourceSampleChange;
            end
        end

        function setCostTables(obj,value)
        %setCostTables - Set a new value of CostTables parameter
        %   Syntax:
        %     obj.setCostTables(type)
        %   Input Parameters
        %     value - Type of thermoeconomic tables
        %       'DIRECT' | 'GENERALIZED' | 'ALL'
            if obj.checkCostTables(value)
                obj.CostTables=value;
                obj.triggerCostTablesChange;
            end
        end

        function setDiagnosisMethod(obj,method)
        %setDiagnosisMethod - Set a new value of DiagnosisMethod parameter
        %   Syntax:
        %     obj.setDiagnosisMethod(method)
        %   Input Parameters
        %     method - Method used to compute diagnosis
        %       'NONE' | 'WASTE_EXTERNAL' | 'WASTE_INTERNAL'
            if obj.checkDiagnosisMethod(method)
                obj.DiagnosisMethod=method;
                obj.setThermoeconomicDiagnosis;
            end
        end

        function setActiveWaste(obj,value)
        %setActiveWaste - Set a new waste flow for recycling analysis
        %   Syntax:
        %     setActiveWaste(obj,method)
        %   Input Parameters
        %     value - waste flow key
        %       char array
            if obj.checkActiveWaste(value)
                obj.ActiveWaste=value;
                obj.printDebugInfo(cMessages.SetActiveWaste,value);
            end
            obj.setRecyclingResults;
        end

        function setSummary(obj,value)
        %setSummary - Set a new Summary available option
        %   Syntax:
        %     model.setSummary(value)
        %   Input Arguments
        %     value - Summary options
        %       'NONE' | 'STATE' | 'RESOURCE' | 'ALL'     
        %
            if obj.checkSummary(value)
                obj.Summary=value;
                obj.printDebugInfo(cMessages.SetSummaryMode,value);
                obj.setSummaryResults;
            end
        end
    
        function setRecycling(obj,value)
        %setRecycing - Set Recycling parameter
        %   Syntax:
        %     model.setRecycling(value)
        %   Input Parameters:
        %     value - Activate/Deactivate recycling analysis
        %       true | false
            if obj.checkRecycling(value)
                obj.Recycling=value;
                if obj.Recycling
                    obj.printDebugInfo(cMessages.RecycleActive);
                else
                    obj.printDebugInfo(cMessages.RecycleNotActive);
                end
                obj.setRecyclingResults;
            end
        end

        function setDebug(obj,dbg)
        %setDebug - Set debug control variable
        %   Syntax:
        %     model.setDebug(value)
        %   Input Parameters:
        %     value - Debug active
        %       true | false
            if islogical(dbg) && (obj.debug~=dbg)
                obj.debug=dbg;
                if dbg; obj.printInfo(cMessages.InfoDebug,upper(mat2str(dbg))); end
            end
        end

        function toggleDebug(obj)
        %toggleDebug - Toggle debug property
        %   Syntax:
        %     obj.toggleDebug
              setDebug(obj,~obj.debug);
        end
        %%%
        % get cResultInfo objects
        %%%
        function res=productiveStructure(obj)
        %productiveStructure - Get the Productive Structure cResultInfo object
        %   Syntax:
        %     res = obj.productiveStructure
        %   Output Argument
        %     res - cResultInfo with the productive structure info
        %
            res=obj.getResults(cType.ResultId.PRODUCTIVE_STRUCTURE);
        end

        function res=exergyAnalysis(obj)
        %exergyAnalysis - Get the ExergyAnalysis cResultInfo object for the current state 
        %   Syntax:
        %     res = obj.exergyAnalysis
        %   Output Arguments
        %   res - cResultInfo with the exergy analysis info
        %
            res=obj.getResults(cType.ResultId.THERMOECONOMIC_STATE);
        end

        function res=thermoeconomicAnalysis(obj)
        %thermoeconomicAnalysis - Get the Thermoeconomic Analysis cResultInfo object for the current state
        %   Syntax:
        %     res = obj.thermoeconomicAnalysis
        %   Output Argument:
        %     res - cResultInfo with thermoeconomic analysis info
        %
            res=obj.getResults(cType.ResultId.THERMOECONOMIC_ANALYSIS);
        end

        function res=wasteAnalysis(obj)
        %wasteAnalysis - Get the Waste Analysis cResultInfo object for the current state and waste flow
        %   Syntax:
        %     res = obj.wasteAnalysis
        %   Output Argument:
        %     res - cResultInfo with waste analysis info
        %
            res=obj.getResults(cType.ResultId.WASTE_ANALYSIS);
        end

        function res=thermoeconomicDiagnosis(obj)
        %thermoeconomicDiagnosis - Get the Thermoeconomic Diagnosis cResultInfo object
        %   Syntax:
        %     res = obj.thermoeconomicDiagnosis
        %   Output Argument:
        %     res - cResultInfo with diagnosis info
        %       
            res=obj.getResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
        end

        function summaryDiagnosis(obj)
        %summaryDiagnosis - Get the diagnosis results summary
        %   Syntax:
        %     res = obj.summaryDiagnosis
        % 
            res=obj.thermoeconomicDiagnosis;
            if ~isempty(res)
                res.summaryDiagnosis;
            end
        end

        function res=productiveDiagram(obj)
        %productiveDiagram - Get the productive diagram cResultInfo object
        % Syntax:
        %   res = obj.productiveDiagram 
        % Output Argument:
        %   res - cResultInfo with productive diagram        
            res=obj.getResults(cType.ResultId.PRODUCTIVE_DIAGRAM);
        end
    
        function res=diagramFP(obj)
        %diagramFP - Get the diagram FP cResultInfo object of rhe current state
        % Syntax:
        %   res = obj.diagramFP
        % Output Argument:
        %   res - cResultInfo with diagram FP    
                res=obj.getResults(cType.ResultId.DIAGRAM_FP);
        end

        function res=summaryResults(obj)
        %summaryResults - Get the Summary Results cResultInfo object
        % Syntax:
        %   res = obj.summaryResults 
        % Output Argument:
        %   res - cResultInfo with summary info            
            res=obj.getResults(cType.ResultId.SUMMARY_RESULTS);
        end

        function res=dataInfo(obj)
        %dataInfo - Get the data model cResultInfo object
        % Syntax:
        %   res = obj.dataInfo
        % Output Argument:
        %   res - cResultInfo with data model   
          res=getResults(obj.results,cType.ResultId.DATA_MODEL);
        end

        function res=getResultInfo(obj,arg)
        %getResultInfo - Get the cResultInfo with optional parameters
        %   If no arg it returns the model results of the current state
        %   If arg is a ResultId number the function returns
        %   the corresponding cResultInfo
        %   If arg is a table name it returns the cResultInfo
        %   that contains the table 
        %
        %   Syntax:
        %     res=obj.getResultInfo
        %     res=obj.getResultInfo(arg)
        %   Input Parameters:
        %     arg - ResultId or table name (optional)
        %   Output Parameters
        %     res - cResultInfo
        %   Examples:
        %     res = obj.getResultInfo;
        %       Return the Model Results of the current state
        %     res = obj.getResultInfo(cType.ResultId.EXERGY_ANALYSIS)
        %       Return the exergy analysis results
        %     res = obj.getResultsInfo('processes');
        %       Return the result info which contains the table 'processes', 
        %       in this case the productive structure
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

        function res=showResultInfo(obj)
        %showResultInfo - Show or get a structure containig the results of the model
        %   It shows the available results of the current model.
        %
        %   Syntax:
        %     obj.showResultInfo;
        %     res = obj.showResultInfo;
        %   Output Argument:
        %     res - Struct containing the results of the model
        %
            obj.buildResultInfo;
            val=getResults(obj.results);
            res=cell2struct(val,cType.ResultVar,2);
        end

        %%%
        % Utility methods
        %%%%
        function res=showProperties(obj)
        %showProperties - Show the values of the current parameters of the model
        %   Syntax:
        %     obj.showProperties
        %   Output Arguments:
        %     res - structure containing the current parameters of the model
        %           If missing the properties are show in console
        %
            res=struct('State',obj.State,...
                'ReferenceState',obj.ReferenceState,...
                'ResourceSample',obj.Sample,...
                'CostTables',obj.CostTables,...
                'DiagnosisMethod',obj.DiagnosisMethod,...
                'ActiveWaste',obj.ActiveWaste,...
                'Summary',obj.Summary,...
                'Recycling',mat2str(obj.Recycling),...
                'Debug',mat2str(obj.debug),...
                'IsResourceCost',mat2str(obj.isResourceCost),...
                'IsDiagnosis',mat2str(obj.isDiagnosis),...
                'IsSummary',mat2str(obj.isSummaryEnable),...
                'IsWaste',mat2str(obj.isWaste));
            if nargout==0
                disp(cType.BLANK);
                disp(res)
            end
        end
    
        function res=isResourceCost(obj)
        %isResourceCost - Check if the model has resources cost defined
        %   Syntax:
        %     obj.isResourceCost
        %   Output Argument
        %     res - true | false
        %
            res=logical(obj.DataModel.isResourceCost);
        end

        function res=isDirectCost(obj)
        %isDirectCost - Check if Direct cost tables are selected
        %   Syntax:
        %     obj.isDirectCost
        %   Output Argument
        %     res - true | false
            pct=obj.costTableId;
            if isempty(pct)
                res=false;
            else
               res=logical(bitget(pct,cType.DIRECT));
            end
        end

        function res=isGeneralCost(obj)
        %isGeneralizedCost - Check if Generalized cost calculation are activated
        %   It is activated if it has resource samples defined in the data model
        %   and 'CostTables' parameter is defined as 'GENERALIZED' | 'ALL'
        %   
        %   Syntax:
        %     obj.isGeneralCost
        %   Output Argument
        %     res - true | false
        %
            pct=obj.costTableId;
            if isempty(pct)
                res=false;
            else
                res=obj.isResourceCost & logical(bitget(pct,cType.GENERALIZED));
            end    
        end

        function res=isDiagnosis(obj)
        %isDiagnosis - Check if diagnosis computation is available.
        %   It is activate under the following conditions:
        %   - There is more than one state
        %   - Reference and Operation state are differents
        %   - The 'DiagnosisMethod' is not 'NONE'
        %   - Both states has the same processes activated
        %
        %   Syntax:
        %     res = obj.isDiagnosis
        %   Output Arguments:
        %     res - true | false
        %
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
                obj.printDebugInfo(cMessages.InvalidDiagnosisConf);
                return
            end
            res=true;
        end

        function res=isWaste(obj)
        %isWaste - Check if model has waste defined
        %   Syntax:
        %     res = obj.isWate
        %   Output Arguments:
        %     res - true | false
        %
            res=logical(obj.DataModel.isWaste);
        end

        function res=summaryOptions(obj)
        %summaryOptions - Get the available summary option names
        %   Syntax:
        %     res = obj.summaryOptions
        %   Output Arguments:
        %     res - cell array with the available summary options
        % 
            res=obj.DataModel.SummaryOptions.Names;
        end

        function res=isSummaryEnable(obj)
        %isSummaryEnable - Check if Summary is enable
        %   The summary result is enabled if the model has more than one state
        %
        %   Syntax:
        %     res = obj.isSummaryEnable
        %   Output Arguments:
        %     res - true | false
        %
            res=obj.DataModel.SummaryOptions.isEnable;
        end

        function res=isSummaryActive(obj)
        %isSummaryActive - Check if Summary has been activated
        %   Syntax:
        %     res = obj.isSummaryEnable
        %   Output Arguments:
        %     res - true | false
            if isempty(obj.summaryId)
                res=false;
            else
                res=logical(obj.summaryId);
            end
        end

        function res=isStateSummary(obj)
        %isStateSummary - Check if States Summary results has been activated
        %   Syntax:
        %     res = obj.isStateSummary
        %   Output Arguments:
        %     res - true | false
        %
            if isempty(obj.summaryId)
                res=false;
            else
                res=logical(bitget(obj.summaryId,cType.STATES));
            end           
        end

        function res=isSampleSummary(obj)
        %isSampleSummary - Check if Samples Summary results has been activated
        %   Syntax:
        %     res = obj.isSampleSummary
        %   Output Arguments:
        %     res - true | false
        %
            if isempty(obj.summaryId)
                res=false;
            else
                res=logical(bitget(obj.summaryId,cType.RESOURCES));
            end  
        end

        %%%
        % Tables Directory methods
        %%%
        function res=getTablesDirectory(obj,cols)
        %getTablesDirectory - Create the tables directory of the active model
        %   Syntax:
        %     res=obj.getTablesDirectory(columns)
        %   Input Arguments:
        %     cols - Cell array with the names of columns of table
        %     If ommited the the default columns are shown
        %   Output Arguments
        %     res - cTable with the active tables of the model and its
        %           properties defined by columns parameters
        %
        % See also ListResultTables
        %          
            % Check Parameters
            if nargin==1
                cols=cType.DIR_COLS_DEFAULT;
            end
            if iscolumn(cols), cols=cols';end
            % Get the complete table directory
            tbl=obj.fmt.getTablesDirectory(cols);
            atm=zeros(tbl.NrOfRows,1);
            % Find the active tables
            for i=1:cType.ResultId.SUMMARY_RESULTS
                rid=getResults(obj.results,i);
                if ~isempty(rid) && isValid(rid)
                    list=rid.ListOfTables;
                    idx=cellfun(@(x) getTableId(obj.fmt,x),list);
                    atm(idx)=true;
                end
            end
            % Create the requested table
            rows=find(atm);
            data=tbl.Data(rows,:);
            rowNames=tbl.RowNames(rows);
            colNames=tbl.ColNames;
            props=tbl.getProperties;
            res=cTableData(data,rowNames,colNames,props);
        end

        function res=getTableInfo(obj,name)
        %getTableInfo - Get the properties of a table
        %   Syntax:
        %     res = obj.getTableInfo
        %   Input Arguments:
        %     name - Name of the table
        %   Output Arguments:
        %     res - struct with the properties of the table
            if nargout>0
                res=getTableInfo(obj.fmt,name);
            else
                getTableInfo(obj.fmt,name);
            end
        end

        %%%
        % Results Set methods
        %%%
        function tbl=getTable(obj,name)
        %getTable - Get a table called name, if its available
        %   Syntax:
        %     tbl = obj.getTable(name)
        %   Input Arguments:
        %     name - name of the table
        %   Output Arguments:
        %     tbl - cTable object
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
        %showResults - View an individual table
        %   Syntax:
        %     obj.showResults(table,option)
        %   Input Arguments:
        %     name - Name of the table
        %     option - Table view option
        %       cType.TableView.CONSOLE 
        %       cType.TableView.GUI
        %       cType.TableView.HTML (default)
        %
        %   See also ShowResults
        %
            % print all results tables
            if nargin==1
                res=getResultInfo(obj);
                printResults(res);
                return
            end
            % show an individual table of the model
            if ~ischar(name)
                obj.printWarning(cMessages.InvalidArgument)
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
        %showGraph - Show a graph table. 
        %   Find the resultId asociated to the table
        %   and call cResultInfo.showGraph
        %
        %   Syntax:
        %     obj.showGraph(graph,options)
        %   Input Arguments:
        %     graph - name of the table
        %     options - graph options
        %
        % See also cResultInfo.showGraph, ShowGraph
        %
            if nargin == 1
                graph=obj.DefaultGraph;
            end
            res=obj.getResultTable(graph);
            if res.status
                showGraph(res,graph);
            else
                printLogger(res);
            end
        end

        %%%
        %  Specific result presentation methods
        %%%
        function showSummary(obj,name,varargin)
        %showSummary - Show Summary tables
        %   Syntax:
        %     res = obj.showSummary(name,options)
        %   Input Arguments:
        %     name - name of the summary table
        %      if no name is provided all summary tables are shown in console
        %     options - options to show results
        %
        % See also cResultInfo.showResults, ShowResults
        %
            res=obj.summaryResults;
            if isempty(res)
                return
            end
            if nargin==1
                printResults(res)
            else
                showResults(res,name,varargin{:})
            end
        end

        function showDataModel(obj,name,varargin)
        %showDataModel - Show Data Model tables
        %   Syntax:
        %     res = obj.showDataModel(name,options)
        %   Input Arguments:
        %     name - name of the data model tables
        %      if no name is provided all data model tables are shown in console
        %   options - options to show results
        %
        %   See also cResultSet.showResults, ShowResults
        %
            res=obj.DataModel;
            if nargin==1
                printResults(res)
            else
                showResults(res,name,varargin{:})
            end
        end

        function showTablesDirectory(obj,varargin)
        %showTablesDirectory - Show the list of available tables
        %   Syntax:
        %     obj.showTablesDirectory(options)
        %   Input Arguments:
        %     options - show table options
            tbl=obj.getTablesDirectory;
            showTable(tbl,varargin{:})
        end
        
        %%%
        % Save Results methods
        %%%
        function log=saveSummary(obj,filename)
        %saveSummary - Save the summary tables into a filename
        %   The following file types are available: XLSX,CSV,TXT,TEX,HTML,MAT
        %
        %   Syntax:
        %     log = saveSummary(filename)
        %   Input Arguments:
        %     filename - Name of the file
        %   Output Arguments:
        %     log - cMessageLogger object containing the status and error messages
        %
            log=cMessageLogger();
            if nargin~=2
                log.printError(cMessages.InvalidArgument);
                return
            end       
            msr=obj.summaryResults;
            if isempty(msr)
                return
            end
            log=saveResults(msr,filename);
        end
    
        function log=saveDataModel(obj,filename)
        %saveDataModel - Save the data model in a file
        %   The following file types are available: JSON,XML,XLSX,CSV,MAT
        %
        %   Syntax:
        %     log = obj.saveDataModel(filename)
        %   Input Arguments:
        %     filename - Name of the file
        %   Output Arguments:
        %     log - cMessageLogger object containing the status and error messages
        %
            log=cMessageLogger();
            if nargin~=2
                log.printError(cMessages.InvalidArgument);
                return
            end
            log=saveDataModel(obj.DataModel,filename);
        end

        function log=saveDiagramFP(obj,filename)
        %saveDiagramFP - Save the Adjacency matrix of the Diagram FP in a file
        %   The following file types are available: XLSX,CSV,MAT
        %
        %   Syntax:
        %     log = saveDiagramFP(filename)
        %    Input Arguments:
        %     filename - Name of the file
        %    Output Arguments:
        %     log - cMessageLogger object containing the status and error messages
        %
            log=cMessageLogger();
            if nargin~=2
                log.printError(cMessages.InvalidArgument);
                return
            end
            % Save tables
            res=obj.diagramFP;
            if ~isValid(res)
                printLogger(res)
                return
            end
            log=saveResults(res,filename);
        end

        function log=saveProductiveDiagram(obj,filename)
        %saveProductiveDiagram - Save the productive diagram adjacency tables into a file
        %   The following file types are available: XLSX,CSV,MAT
        %
        %   Syntax:
        %     log = saveProductiveDiagram(filename)
        %   Input Arguments:
        %     filename - Name of the file
        %   Output Arguments:
        %     log - cMessageLogger object containing the status and error messages
        %
            log=cMessageLogger();
            if nargin~=2
                log.printError(cMessages.InvalidArgument);
                return
            end
            % Save fat,pat and fpat tables
            res=obj.productiveDiagram;
            if ~isValid(res)
                res.printLogger;
                return
            end
            log=saveResults(res,filename);
        end
                 
        %%%
        % Waste Analysis methods
        %%%
        function wasteAllocation(obj)
        %wasteAllocation - Show waste information in console
        %   Syntax:
        %     obj.wasteAllocation
        %
            res=obj.wasteAnalysis;
            printTable(res.Tables.wd)
            printTable(res.Tables.wa)
        end

        function log=setWasteType(obj,wtype)
        %setWasteType - Set the waste type allocation method for Active Waste
        %   Syntax: 
        %     log = setWasteType(wtype)
        %   Input Arguments:
        %     wtype - waste allocation type
        %   Output Arguments:
        %     log - cMessageLogger with the status and messages of operation
        %   See also cType.WasteAllocation
        %
            log=cMessageLogger();
            if nargin~=2
               log.printError(cMessages.InvalidArgument);
               return
            end  
            wt=obj.fp1.WasteTable;
            if wt.setType(obj.ActiveWaste,wtype)
                obj.printDebugInfo(cMessages.SetAllocationType,obj.ActiveWaste,wtype);
            else
                log.printError(cMessages.InvalidWasteType,wtype,obj.ActiveWaste);
                return
            end
            wlog=obj.fp1.updateWasteOperators;
            if ~wlog.status
                printLogger(wlog);
                return
            end
            obj.setThermoeconomicAnalysis;
            obj.setSummaryTables;
            if obj.isDiagnosis
                obj.setThermoeconomicDiagnosis;
            end
        end

        function log=setWasteValues(obj,val)
        %setWasteValues - Set the waste table values
        %   Syntax:
        %     log = obj.setWasteValues(val)
        %   Input Arguments:
        %    val - vector containing the waste allocation values for processes
        %   Output Arguments:
        %     log - cMessageLogger with the status and messages of operation
        %
            log=cMessageLogger();
            if nargin~=2
               log.printError(cMessages.InvalidArgument);
               return
            end  
            wt=obj.fp1.WasteTable;
            if wt.setValues(obj.ActiveWaste,val)
                obj.printDebugInfo(cMessages.SetWasteValues,obj.ActiveWaste);
            else
                log.printError(cMessages.NegativeWasteAllocation,obj.ActiveWaste,val);
                return
            end
            wlog=obj.fp1.updateWasteOperators;
            if ~wlog.status
                printLogger(wlog);
                return
            end
            obj.setThermoeconomicAnalysis;
            obj.setSummaryTables;
            if obj.isDiagnosis
                obj.setThermoeconomicDiagnosis;
            end
        end
   
        function log=setWasteRecycled(obj,val)
        %setWasteRecycled - Set the waste recycling ratios
        %   Syntax:
        %     log = obj.setWasteRecycled(val)
        %   Input Arguments:
        %     val - Recycling ratio of the active waste
        %   Output Arguments:
        %     log - cMessageLogger with the status and messages of operation
        %
            log=cMessageLogger();
            if nargin~=2
               log.printError(cMessages.InvalidArgument);
               return
            end 
            wt=obj.fp1.WasteTable;
            if wt.setRecycleRatio(obj.ActiveWaste,val)
                obj.printDebugInfo(cMessages.SetRecycleRatio,obj.ActiveWaste)
            else
                log.printError(cMessages.InvalidRecycling,val,obj.ActiveWaste);
                return 
            end
            wlog=obj.fp1.updateWasteOperators;
            if ~wlog.status
                printLogger(wlog);
                return
            end
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
        %setFlowResources - Set the resource cost of the flows
        %   Syntax:
        %     res = setFlowResources(c0)
        %   Input Arguments:
        %     c0 - array containing the resources cost of flows
        %   Output Arguments:
        %   res - cResourceCost object with the new values
        %
            res=cMessageLogger();
            if ~obj.isGeneralCost
                res.printError(cMessages.NoGeneralizedCost);
				return
            end
            log=setFlowResource(obj.rsd,c0);
            if log.status
                obj.setThermoeconomicAnalysis;
                obj.setSummaryTables;
                res=obj.rsc;
            else
                printLogger(log);
                res.printError(cMessages.InvalidResourceValues);
            end
        end

        function res=setProcessResource(obj,Z)
        %setProcessResource - Set the resource cost of the processes
        %   Syntax:
        %     res =obj.setProcessResource(Z)
        %   Input Agument:
        %     Z - array containing the processes cost
        %   Output Argument:
        %     res - cResourceCost object
        %
            res=cMessageLogger();
            if ~obj.isGeneralCost
                res.printWarning(cMessages.NoGeneralizedCost);
                return
            end
            log=setProcessResource(obj.rsd,Z);
            if log.status
                obj.setThermoeconomicAnalysis;
                obj.setSummaryTables;
                res=obj.rsc;
            else
                printLogger(log);
                res.printWarning(cMessages.InvalidProcessValues);
            end
        end

        function res=addResourceData(obj,sample,c0,varargin)
        %addExergyData - Set exergy data values to actual state
        %   Syntax:
        %     log=obj.setExergyData(values)
        %   Input Arguments:
        %     sample - new sample name to add
        %     c0 - array | struct with the unit cost of the resource flows
        %     Z -  array | struct with the cost associated to processes
        %   Output Arguments:
        %     log - cMessageLogger object with the status and messages of operation
        %
            log=cMessageLogger();
            if nargin<3
                obj.printWarning(cMessages.InvalidArgument);
                return
            end
            ds=obj.DataModel.ResourceData;
            % Check state is no reference 
            if ~cParseStream.checkName(sample) || existsKey(ds,sample)
                log.messageLog(cType.WARNING,cMessages.InvalidSampleName);
                return
            end
            % Set resource data for sample
            data=obj.DataModel;
            res=data.addResourceData(sample,c0,varargin{:});
            if ~res.status
                printLogger(res);
                return
            end
            obj.setResourceSample(sample);
        end
        
        function res=getResourceData(obj,sample)
        %getResourceData - Get the resource data cost values of sample
        %   Syntax:
        %     res = obj.getResourceData(sample)
        %   Input Argument:
        %     sample - Name of the resource sample
        %   Output Argument:
        %     res - cResourceData object 
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
        %getExergyData - Get cExergyData object of a state
        %   Syntax: 
        %     res = obj.getExergyData(state)
        %   Input Arguments:
        %     state - State name. 
        %       If missing, actual state is used
        %   Output Arguments
        %     res - cExergyData object
            if nargin==1
                state=obj.State;
            end
            res=getExergyData(obj.DataModel,state);
        end

        function res=setExergyData(obj,values)
        %setExergyData - Set exergy data values to actual state
        %   Syntax:
        %     log = obj.setExergyData(values)
        %   Input Arguments:
        %     values - Array with the exergy values of the flows
        %   Output Arguments:
        %     log - cMessageLogger object with the status and messages of operation
        %
            res=cMessageLogger();
            % Check state is no reference 
            if strcmp(obj.ReferenceState,obj.State)
                res.printWarning(cMessages.NoSetExergyData);
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
            obj.setSummaryTables(cType.RESOURCES);
        end
    

        function res=addExergyData(obj,state,values)
        %addExergyData - Set exergy data values to actual state
        %   Syntax:
        %     log = obj.setExergyData(values)
        %   Input Arguments:
        %     state - new state name to add
        %     values - Array with the exergy values of the flows
        %   Output Arguments:
        %     log - cMessageLogger object with the status and messages of operation
        %
            res=cMessageLogger();
            if nargin<3
                res.printWarning(cMessages.InvalidArgument);
                return
            end
            % Check state doesn't exist
            ds=obj.DataModel.ExergyData;
            if ~cParseStream.checkName(state) || existsKey(ds,state)
                res.printWarning(cMessages.InvalidStateName);
                return
            end
            % Set exergy data for state
            data=obj.DataModel;
            rex=data.addExergyData(state,values);
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
                obj.rstate.addValues(state,res);
            else
                printLogger(res);
                return
            end
            % Set the new current state
            obj.setState(state);
        end

        function log=updateModel(obj)
        %updateDataModel - update the data model if have been changes
        %   Syntax:
        %     log = obj.updateModel
        %   Output Arguments
        %     log - true|false 
        %
            log=updateModel(obj.DataModel);
        end

        %
        %%% Internal Package functions
        function res=getStateId(obj,key)
        %getStateId - Get the State Id given the name.
        %   Internal function use in TaesPanel
        %
        %   Syntax:
        %     id = obj.getStateId(key)
        %   Input Arguments:
        %     key - State name
        %   Output Arguments:
        %     id - State Id number
        %
            res=obj.DataModel.ExergyData.getIndex(key);
        end

        function res=getSampleId(obj,key)
        %getSampleId - Get the Sample Id given the resource sample name
        %   Internal function use in TaesPanel
        %
        %   Syntax:
        %     id = obj.getSampleId(key)
        %   Input Arguments:
        %     key - Resource Sample name
        %   Output Arguments:
        %     id - Resource State Id number
        %
            res=obj.DataModel.ResourceData.getIndex(key);
        end

        function res=getWasteId(obj,key)
        %getWasteId - Get the Waste flow Id
        %   Internal function use in TaesPanel
        %
        %   Syntax:
        %     id = obj.getWasteId(key)
        %   Input Arguments:
        %     key - Waste name
        %   Output Arguments:
        %     id - Waste Id number
        %
            res=obj.wd.getWasteIndex(key);
        end

        function res=getModelResults(obj)
        %getModelResults - Get a cell array of cResultInfo objects of the current state
        %   Internal application use: ViewResults
            res=getModelResults(obj.results);
        end

        function res=getResultState(obj,idx)
        %getResultState - Get the cExergyCost object of each state 
        %   Internal application use: cSummaryResults
        %
        %   Syntax:
        %     res = obj.getResultState(idx)
        %   Input Argument:
        %     idx - State Name index/key
        %   Output Result
        %     res - cExergyCost object
            if nargin==1
                res=obj.fp1;
            else
                res=obj.rstate.getValues(idx);
            end
        end
    end
    %%%%%%
    % Private Methods
    %%%%%%
    methods(Access=private)
        function printDebugInfo(obj,varargin)
        %printDebugInfo - Print info messages if debug mode is activated
            if obj.debug
                obj.printInfo(varargin{:});
            end
        end

        function setStateInfo(obj)
        %setStateInfo - Trigger exergy analysis
            if ~isValid(obj.fp1)
                return
            end
            res=getExergyResults(obj.fmt,obj.fp1);
            if res.status
                obj.setResults(res);
                obj.printDebugInfo(cMessages.SetState,obj.State);
                obj.setDiagramFP;
            end           
        end

        function setThermoeconomicAnalysis(obj)
        %setThermoeconomicAnalysis - Trigger thermoeconomic analysis
            % Read resources
            options=struct('DirectCost',obj.isDirectCost,'GeneralCost',obj.isGeneralCost);
            if obj.isGeneralCost
                obj.rsc=getResourceCost(obj.rsd,obj.fp1);
                options.ResourcesCost=obj.rsc;
            end
            % Get cModelResults info
            if isValid(obj.fp1)
                res=getCostResults(obj.fmt,obj.fp1,options);
                obj.setResults(res);
                obj.printDebugInfo(cMessages.ComputeTA,obj.State);
            else
                obj.fp1.printError(cMessages.NoComputeTA,obj.State)
            end
            obj.setRecyclingResults;
        end

        function setThermoeconomicDiagnosis(obj)
        %setThermoeconomicDiagnosis - Set thermoeconomic diagnosis computation
            id=cType.ResultId.THERMOECONOMIC_DIAGNOSIS;
            if ~obj.isDiagnosis
                obj.clearResults(id);
                obj.printDebugInfo(cMessages.DiagnosisNotActivated);
                return
            end
            % Compute diagnosis analysis
            method=cType.getDiagnosisMethod(obj.DiagnosisMethod);
            sol=cDiagnosis(obj.fp0,obj.fp1,method);
            % get cModelResult object
            if sol.status
                res=getDiagnosisResults(obj.fmt,sol);
                obj.setResults(res);
                obj.printDebugInfo(cMessages.ComputeTD,obj.State);
            else
                sol.printLogger;
                sol.printError(cMessages.NoComputeTD,obj.State);
                obj.clearResults(id);
            end
        end

        function setSummaryResults(obj)
        %setSummaryResults - Set Summary Results
            id=cType.ResultId.SUMMARY_RESULTS;
            if ~obj.isSummaryActive
                obj.clearResults(id)
                return
            end
            option=obj.summaryId;
            sr=cSummaryResults(obj,option);
            if sr.status
                res=getSummaryResults(obj.fmt,sr);
                obj.setResults(res);
                obj.printDebugInfo(cMessages.ComputeSummary,obj.Summary);
            else
                sr.printLogger;
            end
        end

        function setSummaryTables(obj,option)
        %setSummaryTables - Set summary tables
            if ~obj.isSummaryActive
                return
            end
            if nargin==1
                option=obj.summaryId;
            end
            sr=obj.summaryResults.Info;
            sr.setSummaryTables(obj,option);
            if sr.status
                res=getSummaryResults(obj.fmt,sr);
                obj.setResults(res,true);
                obj.printDebugInfo(cMessages.ComputeSummary,obj.Summary);
            else
                 sr.printLogger;
            end
        end

        function setRecyclingResults(obj)
        %setRecyclingResults - Set Recycling Analysis Results
            if ~obj.isWaste
                return
            end
            if obj.Recycling
                if obj.isGeneralCost 
                    ra=cWasteAnalysis(obj.fp1,true,obj.ActiveWaste,obj.rsd);
                else
                    ra=cWasteAnalysis(obj.fp1,true,obj.ActiveWaste);
                end
                obj.printDebugInfo(cMessages.ComputeRecycling,obj.ActiveWaste);
            else
                ra=cWasteAnalysis(obj.fp1,false,obj.ActiveWaste);
            end
            if ra.status
                options=struct('DirectCost',obj.isDirectCost,'GeneralCost',obj.isGeneralCost);
                res=getWasteAnalysisResults(obj.fmt,ra,options);
                obj.setResults(res);
            else
                ra.printLogger;
            end
        end

        function setDiagramFP(obj)
        %setDiagramFP - Set the Diagram FP cResultInfo object
            dfp=cDiagramFP(obj.fp1);
            if dfp.status
                res=getDiagramFP(obj.fmt,dfp);
                obj.setResults(res);
                obj.printDebugInfo(cMessages.ComputeDiagramFP)
            else
                dfp.printLogger;
            end
        end

        function setProductiveStructure(obj)
        %setProductiveStructure - Set the productive structure cResultInfo objects
            ps=obj.DataModel.ProductiveStructure;
            res=getProductiveStructure(obj.fmt,ps);
            obj.setResults(res)
            % set productive diagrams results
            pd=cProductiveDiagram(ps);
            if pd.status
                res=getProductiveDiagram(obj.fmt,pd);
                obj.setResults(res);
                obj.printDebugInfo(cMessages.ComputeProductiveDiagram)
            else
                pd.printLogger;
            end
        end
        %%%
        % Internal set methods
        %%%
        function res=checkState(obj,state)
        %checkState - Ckeck the state information
        %   Input Arguments:
        %     state - state name
        %   Output Arguments:
        %     res - true | false
            res=false;
            if ~obj.DataModel.existState(state)
                obj.printWarning(cMessages.InvalidStateName,state);
                return
            end
            if strcmp(obj.State,state)
                obj.printDebugInfo(cMessages.NoParameterChange);
                return
            end
            tmp=obj.rstate.getValues(state);
            if isValid(tmp)
                obj.fp1=tmp;
                res=true;
            else
                obj.printWarning(cMessages.InvalidStateName,state);
            end
        end

        function triggerStateChange(obj)
        %triggerStateChange - Trigger State Change
            obj.setStateInfo;
            obj.setThermoeconomicAnalysis;
            obj.setThermoeconomicDiagnosis;
            if isSampleSummary(obj)
                obj.setSummaryTables(cType.RESOURCES);
            end
        end

        function res=checkReferenceState(obj,state)
        %checkReferenceState - Check the reference state value
        %   Input Arguments:
        %     state - state name
        %   Output Arguments:
        %     res - true | false
            res=false;
            if ~obj.DataModel.existState(state)
                obj.printWarning(cMessages.InvalidStateName,state);
                return
            end
            if strcmp(obj.ReferenceState,state)
                obj.printDebugInfo(cMessages.InvalidDiagnosisState);
                return
            end
            obj.fp0=obj.rstate.getValues(state);
            res=true;
        end
 
        function res=checkResourceSample(obj,sample)
        %checkResourceSample - Check the resource sample value
        %   Input Arguments:
        %     sample - resource sample name
        %   Output Arguments:
        %     res - true | false
            res=false;
            if ~obj.DataModel.existSample(sample)
                obj.printWarning(cMessages.InvalidResourceName,sample);
                return       
            end
            if isempty(sample) || strcmp(obj.Sample,sample)
                obj.printDebugInfo(cMessages.NoParameterChange);
                return
            end
            % Read resources and check if are valid
            obj.rsd=obj.getResourceData(sample);
            res=isValid(obj.rsd);
        end

        function triggerResourceSampleChange(obj)
        %triggerResourceSampleChange - Trigger ResourceSample parameter change
            if obj.isGeneralCost
                obj.setThermoeconomicAnalysis;
            end
            if isStateSummary(obj)
                obj.setSummaryTables(cType.STATES);
            end
        end
        
        function res=checkCostTables(obj,value)
        %checkCostTables - Check CostTables parameter
        %   Input Arguments:
        %     values - CostTable parameter
        %   Output Arguments:
        %     res - true | false
            res=false;
            pct=cType.getCostTables(value);
            if isempty(pct)
                obj.printWarning(cMessages.InvalidCostTable,value);
                return
            end
            if strcmp(obj.CostTables,value)
                obj.printDebugInfo(cMessages.NoParameterChange);
                return
            end       
            if bitget(pct,cType.RESOURCES) && ~obj.isResourceCost
                obj.printWarning(cMessages.InvalidCostTable,value);
                return
            end
            res=true;
        end 
    
        function triggerCostTablesChange(obj)
        %triggerCostTablesChange - Set cost tables method and trigger thermoeconomic analysis
            obj.setThermoeconomicAnalysis;
        end

        function res=checkDiagnosisMethod(obj,value)
        %checkDiagnosisMethod - Check Diagnosis Method parameter
        %   Input Arguments:
        %     value - diagnosis method parameter
        %   Output Arguments:
        %     res - true | false
            res=false;
            if ~cType.checkDiagnosisMethod(value)
                obj.printWarning(cMessages.InvalidDiagnosisMethod,value);
                return
            end
            if strcmp(obj.DiagnosisMethod,value)
                obj.printDebugInfo(cMessages.NoParameterChange);
                return
            end
            res=true;
        end

        function res=checkActiveWaste(obj,value)
        %checkActiveWaste - Check Active Waste Parameter
        %   Input Arguments:
        %     value - waste flow name
        %   Output Arguments:
        %     res - true | false
            res=false;
            if ~obj.wd.existWaste(value)
                obj.printWarning(cMessages.InvalidWasteKey,value);
                return
            end
            if strcmp(obj.ActiveWaste,value)
                obj.printDebugInfo(cMessages.NoParameterChange);
                return
            end
            res=true;
        end

        function res=checkSummary(obj,value)
        %checkSummary - Ckeck Summary parameter
        %   Input Arguments:
        %     value - summary option
        %   Output Arguments:
        %     res - true | false
            res=false;
            if ~checkSummaryOption(obj,value)
                obj.printDebugInfo(cMessages.InvalidSummaryOption,value);
                return
            end
           if strcmp(obj.Summary,value)
                obj.printDebugInfo(cMessages.NoParameterChange);
                return
            end
            res=true;
        end

        function res=checkSummaryOption(obj,value)
        %checkSummaryOption - Check if if the summary option is valid
        %   Input Arguments:
        %     value - summary option
        %   Output Arguments:
        %     res - true | false       
            res=obj.DataModel.SummaryOptions.checkName(value);
        end

        function res=checkRecycling(obj,value)
        %checkRecycling - Ckeck Recycling parameter
        %   Input Arguments:
        %     value - recycling parameter (true | false)
        %   Output Arguments:
        %     res - true | false
            res=false;
            if ~islogical(value)
                obj.printDebugInfo(cMessages.InvalidArgument);
                return
            end
            if ~obj.isWaste
                obj.printDebugInfo(cMessages.NoWasteModel);
                return
            end
            if obj.Recycling==value
                obj.printDebugInfo(cMessages.NoParameterChange);
                return
            end
            res=true;
        end

        %%%
        % cModelResults methods
        %%%
        function res=getResults(obj,index)
        %getResults - Get the cResultInfo given the resultId
        %   Input Arguments:
        %     index - resultId
        %   Output Arguments:
        %     res - cResultInfo 
            if index<cType.MAX_RESULT_INFO
                res=getResults(obj.results,index);
            else
                res=buildResultInfo(obj);
            end
            if isempty(res)
                obj.printDebugInfo(cMessages.ResultNotAvailable,cType.Results{index});
            end
        end
        
        function res=getResultTable(obj,table)
        %getResultTable - Get the cResultInfo object associated to a table
        %   Input Arguments:
        %     table - table name
        %   Output Arguments:
        %     res - cResultInfo 
            res=cMessageLogger(cType.INVALID);
            if nargin<2 || ~ischar(table), return; end
            tinfo=obj.fmt.getResultId(table);
            if tinfo
                tmp=obj.getResults(tinfo);
                if isempty(tmp)
                    return
                else
                    res=tmp;
                end
            else
                res.messageLog(cType.ERROR,cMessages.TableNotFound,table);
                return
            end
        end

        function res=buildResultInfo(obj)
        %buildResultInfo - Get a cResultInfo object with all tables of the active model
        %   Output Arguments:
        %     res - cResultInfo (cType.ResultId.RESULT_MODEL)
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
        %clearResults - Clear the result info
        %   Input Arguments:
        %     index - ResultId
            clearResults(obj.results,index);
        end

        function setResults(obj,res,varargin)
        %setResults - Set the result info
        %   Input Arguments:
        %     res - ResultId
        %     force - true | false (optional)
        %   See cModelResults.setResults
            setResults(obj.results,res,varargin{:});
        end
    end
end