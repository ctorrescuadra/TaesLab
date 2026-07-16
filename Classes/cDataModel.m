classdef cDataModel < cResultSet
%cDataModel - Central validated data hub for a TaesLab thermoeconomic model.
%   cDataModel receives raw model data from a cModelData object, validates
%   every component in a strict sequential pipeline, and constructs the
%   object graph consumed by all calculation algorithms.
%
%   The construction pipeline proceeds in this order:
%     1. cProductiveStructure  - topology of flows and processes
%     2. cResultTableBuilder   - result format configuration
%     3. cExergyData (dataset) - one entry per operating state
%     4. cWasteData            - waste allocation definitions (if present)
%     5. cResourceData (dataset) - one entry per cost sample (if present)
%
%   If any step fails, the object status is set to false and detailed
%   error messages are accessible through the inherited cMessageLogger.
%
%   Because cDataModel inherits from cResultSet, the data-model tables
%   (flows, processes, exergy states, resource costs, waste definitions)
%   can be displayed or exported through the standard ShowResults /
%   SaveResults pipeline without additional work.
%
%   cDataModel Properties:
%     NrOfFlows           - Number of flows in the productive structure
%     NrOfProcesses       - Number of processes in the productive structure
%     NrOfWastes          - Number of waste flows
%     NrOfResources       - Number of resource flows
%     NrOfSystemOutputs   - Number of system output flows
%     NrOfFinalProducts   - Number of final product flows
%     NrOfStates          - Number of exergy states (operating conditions)
%     NrOfSamples         - Number of resource cost samples
%     isWaste             - True if waste allocation data is available
%     isResourceCost      - True if resource cost data is available
%     isDiagnosis         - True if more than one state exists (diagnosis enabled)
%     isSummary           - True if multi-state or multi-sample data exists
%     StateNames          - Cell array of exergy state names
%     SampleNames         - Cell array of resource sample names
%     WasteFlows          - Cell array of waste flow names
%     ProductiveStructure - cProductiveStructure object
%     FormatData          - cResultTableBuilder object (result format config)
%     WasteData           - cWasteData object (waste allocation)
%     ExergyData          - cDataset of cExergyData objects (one per state)
%     ResourceData        - cDataset of cResourceData objects (one per sample)
%     ModelData           - cModelData object (raw validated input data)
%
%   cDataModel Methods:
%     cDataModel         - Construct the data model from a cModelData object
%     existState         - Return the index of a state name, or 0 if absent
%     existSample        - Return the index of a sample name, or 0 if absent
%     getExergyData      - Retrieve the cExergyData object for a state
%     setExergyData      - Replace the exergy values of an existing state
%     addExergyData      - Append a new exergy state to the dataset
%     getResourceData    - Retrieve the cResourceData object for a sample
%     setFlowResource    - Replace flow-resource values for a sample
%     setProcessResource - Replace process-resource values for a sample
%     addResourceData    - Append a new resource cost sample to the dataset
%     getWasteDefinition - Return (or display) the waste allocation data
%     setWasteType       - Change the allocation method for a waste flow
%     setWasteValues     - Change the allocation coefficients for a waste flow
%     setWasteRecycled   - Change the recycling ratio for a waste flow
%     getSummaryOption   - Return the recommended summary option string
%     getTablesDirectory - Return a directory of available result tables
%     getTableInfo       - Return metadata for a named result table
%     getResultInfo      - Return the cResultInfo for the data-model tables
%     showDataModel      - Display data-model tables in the selected interface
%     saveDataModel      - Save the data model to a file
%     create             - (Static) Construct a cDataModel directly from a file
%
%   cDataModel Methods (inherited from cResultSet):
%     ListOfTables     - Return the table names from the result set
%     getTableIndex    - Return the table index from the result set
%     printResults     - Print results to the console
%     showResults      - Display results in the selected interface
%     showTableIndex   - Display the table index in the selected interface
%     exportResults    - Export all result tables to another format
%     saveResults      - Save all result tables to an external file
%     getTable         - Retrieve a result table by name
%     saveTable        - Save a single result table to an external file
%     exportTable      - Export a single result table to another format
%
%   See also cResultSet, cModelData, cProductiveStructure, cExergyData,
%            cResultTableBuilder, cWasteData, cResourceData
%
    properties(GetAccess=public, SetAccess=private)
        NrOfFlows               % Number of flows
        NrOfProcesses           % Number of processes
        NrOfWastes              % Number of waste flows
        NrOfResources           % Number of resource flows
        NrOfFinalProducts       % Number of final products
        NrOfSystemOutputs       % Number of system outputs
        NrOfStates              % Number of exergy data simulations
        NrOfSamples             % Number of resource cost samples
        isWaste                 % Indicate if the model has waste defined
        isResourceCost          % Indicate if the model has resource cost data
        isDiagnosis             % Indicate if the model has information to make diagnosis
        isSummary               % Indicate if the model has information to make summary report
        StateNames              % State names
        SampleNames             % Resource sample names
        WasteFlows              % Waste Flow names
        ProductiveStructure     % cProductiveStructure object
        FormatData              % cResultTableBuilder object
        WasteData               % cWasteData object
        ExergyData              % Dataset of cExergyData
        ResourceData            % Dataset of cResourceData
        SummaryOptions          % cSummaryOptions object
        ModelData               % Model data from cReadModel interface
    end

    properties(Access=private)
        modelInfo               % cResultInfo data model
    end

    methods
        function obj = cDataModel(dm)
        %cDataModel - Construct the data model from a cModelData object
        %   Executes the sequential validation pipeline described in the
        %   class header.  Each step adds its messages to the object log
        %   via addLogger so the full diagnostic trace is preserved.
        %   Construction halts at the first fatal error; the object status
        %   is set to false and no further steps are attempted.
        %
        %   Syntax:
        %     obj = cDataModel(dm)
        %
        %   Input Arguments:
        %     dm  - cModelData object carrying the validated raw model data
        %           (productive structure, exergy states, resource costs,
        %           waste definitions and format configuration).
        %
        %   Output Arguments:
        %     obj - cDataModel object.  Use isValid(obj) to confirm
        %           successful construction before running analyses.
        %
            % Check Data Structure
            if ~isObject(dm,'cModelData')
                obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(dm));
                return
            end
            obj.addLogger(dm);
            obj.ClassId=cType.ClassId.DATA_MODEL;
            obj.isWaste=dm.isWaste;
            obj.isResourceCost=dm.isResource;
            % Check and get Productive Structure
            ps=cProductiveStructure(dm);
            obj.addLogger(ps);
            status=ps.status;
            if status
                obj.ProductiveStructure=ps;
				obj.messageLog(cType.INFO,cMessages.ValidProductiveStructure);
            else
				obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(ps));
                return
            end
            % Check and get Format	
            rfmt=cResultTableBuilder(ps,dm.Format);
            obj.FormatData=rfmt;
            obj.addLogger(rfmt);
            status = rfmt.status & status;
            if rfmt.status
				obj.messageLog(cType.INFO,cMessages.ValidFormatDefinition);
            else
				obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(rfmt));
                return
            end
            % Check Exergy
            list=dm.getStateNames;
            if ~cParseStream.checkListNames(list)
                obj.messageLog(cType.ERROR,cMessages.InvalidStateList);
                return
            end
            tmp=cDataset(list);
            if tmp.status
                obj.ExergyData=tmp;
            else
                obj.addLogger(tmp);
                obj.messageLog(cType.ERROR,cMessages.InvalidStateList);
                return
            end
            snames=obj.StateNames;
            for i=1:obj.NrOfStates
                exs=dm.ExergyStates.States(i);
                rex=cExergyData(ps,exs);
                setValues(obj.ExergyData,i,rex);
                obj.addLogger(rex)
                if rex.status
					obj.messageLog(cType.INFO,cMessages.ValidExergyData,snames{i});
				else
					obj.messageLog(cType.ERROR,cMessages.InvalidExergyData,snames{i});
                end
                status = rex.status & status;
            end
            % Check Waste
            if ps.NrOfWastes > 0
                if obj.isWaste
                    data=dm.WasteDefinition;
                else
                    data=ps.WasteData;
                    obj.messageLog(cType.INFO,cMessages.WasteNotAvailable);
                end
                wd=cWasteData(ps,data);
                status=wd.status & status;
                obj.addLogger(wd);
                if ~wd.status
					obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(wd));
                else
					obj.messageLog(cType.INFO,cMessages.ValidWasteDefinition);	
                end
                obj.WasteData=wd;
                obj.isWaste=true;	
            else
                obj.isWaste=false;
				obj.messageLog(cType.INFO,cMessages.NoWasteModel);
            end
            % Check ResourceCost
            if obj.isResourceCost
                list=dm.getSampleNames;
                if ~cParseStream.checkListNames(list)
                    obj.messageLog(cType.ERROR,cMessages.InvalidSampleList);
                end
                tmp=cDataset(list);
                obj.addLogger(tmp)
                if tmp.status
                    obj.ResourceData=tmp;
                else
                    obj.messageLog(cType.ERROR,cMessages.InvalidSampleList);
                    return
                end
                snames=obj.SampleNames;
                for i=1:obj.NrOfSamples
                    dmr=dm.ResourcesCost.Samples(i);
                    rsc=cResourceData(ps,dmr);
                    obj.addLogger(rsc);
                    if rsc.status
                        setValues(obj.ResourceData,i,rsc);
						obj.messageLog(cType.INFO,cMessages.ValidResourceCost,snames{i});
                    else
						obj.messageLog(cType.ERROR,cMessages.InvalidResourceData,snames{i});
                    end
                    status=rsc.status & status;
                end
            else
               obj.messageLog(cType.INFO,cMessages.ResourceNotAvailable)
            end
            % Set ResultId properties
            obj.status=status;
            if ~obj.status
                return
            end
            obj.SummaryOptions=cSummaryOptions(obj.NrOfStates,obj.NrOfSamples);
            obj.ResultId=cType.ResultId.DATA_MODEL;
            obj.ResultName=cType.Results{obj.ResultId};
            obj.ModelName=dm.ModelName;
            obj.State='DATA_MODEL';
            obj.DefaultGraph=cType.EMPTY_CHAR;
            obj.ModelData=dm;
            obj.buildResultInfo;
        end

    	function res=get.NrOfFlows(obj)
        % Get the number of flows of the system
            res=0;
            if obj.status
                res=obj.ProductiveStructure.NrOfFlows;
            end
        end
    
        function res=get.NrOfProcesses(obj)
        % Get the number of processes of the system
            res=0;
            if obj.status
                    res=obj.ProductiveStructure.NrOfProcesses;
            end
        end
    
        function res=get.NrOfWastes(obj)
        % Get the number of wastes of the system
            res=0;
            if obj.status
                res=obj.ProductiveStructure.NrOfWastes;
            end
        end

        function res=get.NrOfResources(obj)
        % Get the number of resources of the system
            res=0;
            if obj.status
                res=obj.ProductiveStructure.NrOfResources;
            end
        end

        function res=get.NrOfSystemOutputs(obj)
        % Get the number of system outputs
            res=0;
            if obj.status
                res=obj.ProductiveStructure.NrOfSystemOutputs;
            end
        end

        function res=get.NrOfFinalProducts(obj)
        % Get the number of system outputs
            res=0;
            if obj.status
                res=obj.ProductiveStructure.NrOfFinalProducts;
            end
        end

        function res=get.StateNames(obj)
        % Get the name of the states
            res=cType.EMPTY_CELL;
            if obj.status
                res=obj.ExergyData.Keys;
            end
        end

        function res=get.SampleNames(obj)
        % Get the name of the samples
            res=cType.EMPTY_CELL;
            if obj.isResourceCost && obj.status
                res=obj.ResourceData.Keys;
            end
        end
        
        function res=get.NrOfStates(obj)
        % Get the number of states
            res=0;
            if obj.status
                res=numel(obj.StateNames);
            end
        end
    
        function res=get.NrOfSamples(obj)
        % Get the number of resources samples
            res=0;
            if obj.isResourceCost && obj.status
                res=numel(obj.SampleNames);
            end
        end

        function res=get.isDiagnosis(obj)
        % Check if diagnosis data is available
            res = false;
            if obj.status
			    res=(obj.NrOfStates>1);
            end
        end

        function res=get.isSummary(obj)
        % Check if summary data is available
            res = false;
            if obj.status
                res= (obj.NrOfStates>1) || (obj.NrOfSamples>1);
            end
        end

        function res=get.WasteFlows(obj)
        % Get Waste flows names
            res=cType.EMPTY_CELL;
            if obj.isWaste && isValid(obj.WasteData)
                res=obj.WasteData.Names;
            end
        end

        %%%
        % Get Data model information
        %%%
        function res=existState(obj,state)
		%existState - Return the numeric index of a state name, or 0 if absent
        %   Wraps cDataset.getIndex on the ExergyData dataset.  The return
        %   value can be used directly in conditional expressions (0 is
        %   falsy) or as an index into the dataset.
        %
        %   Syntax:
        %     res = obj.existState(state)
        %
        %   Input Arguments:
        %     state - State name string to look up.
        %
        %   Output Arguments:
        %     res   - Positive integer index if the state exists; 0 otherwise.
        %
			res=obj.ExergyData.getIndex(state);
        end

		function res=existSample(obj,sample)
		%existSample - Return the numeric index of a sample name, or 0 if absent
        %   Wraps cDataset.getIndex on the ResourceData dataset.  The return
        %   value can be used directly in conditional expressions (0 is
        %   falsy) or as an index into the dataset.
        %
        %   Syntax:
        %     res = obj.existSample(sample)
        %
        %   Input Arguments:
        %     sample - Resource sample name string to look up.
        %
        %   Output Arguments:
        %     res    - Positive integer index if the sample exists; 0 otherwise.
        %
			res=obj.ResourceData.getIndex(sample);
        end

        %%%
        % Get/Set Exergy methods
        %%%
        function res=getExergyData(obj,state)
        %getExergyData - Retrieve the cExergyData object for a state
        %   Looks up state by key string or numeric index in the ExergyData
        %   dataset and returns the corresponding cExergyData object.
        %   If state is invalid, the dataset returns a cMessageLogger with
        %   status false.
        %
        %   Syntax:
        %     res = obj.getExergyData(state)
        %
        %   Input Arguments:
        %     state - State name string (char) or positive integer index.
        %
        %   Output Arguments:
        %     res   - cExergyData object for the requested state, or a
        %             cMessageLogger with status false if state is invalid.
        %
            res=obj.ExergyData.getValues(state);
        end

        function res=buildExergyData(obj,state,values)
        %buildExergyData - Set the exergy data values of a state
        %   Syntax:
        %     res = obj.setExergyData(state,values)
        %   Input Arguments:
        %     state - state key name or id
        %       char array | number
        %     values - array with the exergy values of the flows
        %   Output:
        %     res - cExergyData object associated to the values
        %
            res=cMessageLogger();
            if nargin<3
                res.messageLog(cType.ERROR,cMessages.InvalidArgument);
                return
            end
            M=length(values);
            if obj.NrOfFlows~=M
                res.messageLog(cType.ERROR,cMessages.InvalidExergyDataSize,M);
                return
            end
            % Build exergy data structure
            exs.stateId=state;
            % Build exergy data structure
            if isstruct(values)
                exs.exergy=values;
            elseif isnumeric(values)
                fields=cType.KEYVAL;
                keys=obj.ProductiveStructure.FlowKeys;
                if iscolumn(values),values=values';end
                tmp=[keys;num2cell(values)];
                exs.exergy=cell2struct(tmp,fields,1);
            else
                res.messageLog(cType.ERROR,cMessages.InvalidExergyData,state);
                return
            end
            % Check and create a cExergyData object
            res=cExergyData(obj.ProductiveStructure,exs);
            if res.status
                res.messageLog(cType.INFO,cMessages.ValidExergyData,state)
            else
                res.messageLog(cType.ERROR,cMessages.InvalidExergyData,state);
            end 
        end

        function log=setExergyData(obj,state,val)
        %setExergyData - Replace the exergy values of an existing state
        %   Builds a new cExergyData object from val (via buildExergyData)
        %   and stores it in the ExergyData dataset at the position
        %   identified by state.  The state must already exist; use
        %   addExergyData to append a new state.
        %
        %   Syntax:
        %     log = obj.setExergyData(state, val)
        %
        %   Input Arguments:
        %     state - Name (char) or numeric index of the state to update.
        %     val   - Numeric array (1 × NrOfFlows) or struct with flow
        %             key-value pairs containing the new exergy values.
        %
        %   Output Arguments:
        %     log   - cMessageLogger with the operation status.  Check
        %             log.status to verify whether the update succeeded.
        %
            log=cMessageLogger();
            ds=obj.ExergyData;
            if ds.existsKey(state)
                exs=obj.buildExergyData(state,val);
                if ~isValid(exs)
                    log.addLogger(exs)
                    log.messageLog(cType.ERROR,cMessages.InvalidExergyData,state);
                    return
                end
                log=ds.setValues(key,exs);
            else
                log.messageLog(cType.ERROR,cMessages.InvalidStateName,state);
            end
        end

        function res=addExergyData(obj,state,val)
        %addExergyData - Append a new exergy state to the dataset
        %   Validates that state is a legal name and does not already exist,
        %   builds the cExergyData object from val, and appends it to the
        %   ExergyData dataset.  Use setExergyData to update an existing state.
        %
        %   Syntax:
        %     res = obj.addExergyData(state, val)
        %
        %   Input Arguments:
        %     state - New state name string.  Must satisfy cParseStream.checkName
        %             and must not already exist in the dataset.
        %     val   - Numeric array (1 × NrOfFlows) or struct with flow
        %             key-value pairs containing the exergy values.
        %
        %   Output Arguments:
        %     res   - The new cExergyData object on success, or a
        %             cMessageLogger with status false if the operation fails.
        %
            res=cMessageLogger();
            ds=obj.ExergyData;
            if cParseStream.checkName(state) && ~ds.existsKey(state)
                res=obj.buildExergyData(state,val);
                if ~isValid(res)
                    res.addLogger(res)
                    return
                end
                ds.addValues(state,res);
            else
                res.messageLog(cType.ERROR,cMessages.StateAlreadyExists,state);
            end
        end

        %%%
        % Get/Set Resource Definition methods
        %%%
        function res=getResourceData(obj,sample)
        %getResourceData - Retrieve the cResourceData object for a sample
        %   Looks up sample by key string or numeric index in the ResourceData
        %   dataset and returns the corresponding cResourceData object.
        %   If sample is invalid, the dataset returns a cMessageLogger with
        %   status false.
        %
        %   Syntax:
        %     res = obj.getResourceData(sample)
        %
        %   Input Arguments:
        %     sample - Sample name string (char) or positive integer index.
        %
        %   Output Arguments:
        %     res    - cResourceData object for the requested sample, or a
        %              cMessageLogger with status false if sample is invalid.
        %
            res=obj.ResourceData.getValues(sample);
        end

        function log=setFlowResource(obj,sample,values)
        %setFlowResource - Replace the flow-resource cost values of a sample
        %   Retrieves the cResourceData object for sample and delegates to
        %   its setFlowResource method.  Any validation errors from the
        %   inner call are forwarded to the returned logger.
        %
        %   Syntax:
        %     log = obj.setFlowResource(sample, values)
        %
        %   Input Arguments:
        %     sample - Sample name string (char) or positive integer index.
        %     values - Array containing the new flow-resource cost values.
        %
        %   Output Arguments:
        %     log    - cMessageLogger with the operation status.  Check
        %              log.status to verify whether the update succeeded.
        %
            log=cMessageLogger();
            rsd=obj.getResourceData(sample);
            if rsd.status
                lrsd=setFlowResource(rsd,values);
                log.addLogger(lrsd);
            else
                log.addLogger(rsd);
            end
        end

        function log=setProcessResource(obj,sample,values)
        %setProcessResource - Replace the process-resource cost values of a sample
        %   Retrieves the cResourceData object for sample and delegates to
        %   its setProcessResource method.  Any validation errors from the
        %   inner call are forwarded to the returned logger.
        %
        %   Syntax:
        %     log = obj.setProcessResource(sample, values)
        %
        %   Input Arguments:
        %     sample - Sample name string (char) or positive integer index.
        %     values - Array containing the new process-resource cost values.
        %
        %   Output Arguments:
        %     log    - cMessageLogger with the operation status.  Check
        %              log.status to verify whether the update succeeded.
        %
            log=cMessageLogger();
            rsd=obj.getResourceData(sample);
            if rsd.status
                lrsd=setProcessResource(rsd,values);
                log.addLogger(lrsd);
            else
                log.addLogger(rsd);
            end
        end

        function res=buildResourceData(obj,sample,rval,pval)
        %buildResourceData - Create a new cResourceData object
        %   Syntax:
        %     res = obj.buildResourceData(sample,rval,pval)
        %   Input Arguments:
        %     sample - name of the resource sample
        %     rval - array | struct with the flow resource values
        %     pval - array | struct with the processes resource values (optional)
        %   Output Arguments:
        %     res - cResourceData object
        %
            res=cMessageLogger();
            if nargin<3
                res.messageLog(cType.ERROR,cMessages.InvalidArgument);
                return
            end
            ps=obj.ProductiveStructure;
            %Build Resource Data structure
            rsd.sampleId=sample;
            if isstruct(rval)
                rsd.flows=rval;
            elseif isnumeric(rval)
                if obj.NrOfFlows~=length(rval)
                    res.messageLog(cType.ERROR,cMessages.InvalidExergyDataSize,M);
                    return
                end
                fields=cType.KEYVAL;
                irsd=ps.ResourceFlows;
                keys=ps.FlowKeys(irsd);
                if iscolumn(rval), rval=rval';end
                vals=rval(irsd);
                tmp=[keys;num2cell(vals)];
                rsd.flows=cell2struct(tmp,fields,1);
            else
                res.messageLog(cType.ERROR,cMessages.InvalidExergyData,state);
                return
            end
            if nargin==4
                if isstruct(pval)
                    rsd.processes=rval;
                elseif isnumeric(pval)
                    if obj.NrOfProcesses~=length(pval)
                        res.printError(cMessages.InvalidExergyDataSize,M);
                        return
                    end
                    fields=cType.KEYVAL;
                    keys=ps.ProcessKeys(1:end-1);
                    if iscolumn(pval), pval=pval';end
                    tmp=[keys;num2cell(pval)];
                    rsd.processes=cell2struct(tmp,fields,1);
                else
                    res.messageLog(cType.ERROR,cMessages.InvalidResourceData,sample);
                    return
                end
            end
            res=cResourceData(ps,rsd);
        end

        function rsd=addResourceData(obj,sample,rval,varargin)
        %addResourceData - Append a new resource cost sample to the dataset
        %   Validates that sample is a legal name and does not already exist,
        %   builds the cResourceData object from rval (and optionally pval),
        %   and appends it to the ResourceData dataset.
        %
        %   Syntax:
        %     rsd = obj.addResourceData(sample, rval)
        %     rsd = obj.addResourceData(sample, rval, pval)
        %
        %   Input Arguments:
        %     sample   - New sample name string.  Must satisfy
        %                cParseStream.checkName and must not already exist.
        %     rval     - Numeric array or struct with flow resource cost values.
        %     pval     - (optional) Numeric array or struct with process
        %                resource cost values.
        %
        %   Output Arguments:
        %     rsd      - The new cResourceData object on success, or a
        %                cMessageLogger with status false if the operation fails.
        %
            if nargin<3
                return
            end
            rsd=cMessageLogger();
            ds=obj.ResourceData;
            if cParseStream.checkName(sample) && ~ds.existsKey(sample)
                rsd=obj.buildResourceData(sample,rval,varargin{:});
                if ~isValid(rsd)
                    rsd.addLogger(rsd)
                    return
                end
                ds.addValues(sample,rsd);
            else
                rsd.messageLog(cType.ERROR,cMessages.SampleAlreadyExists,sample);
            end
        end

        %%%
        % Get/Set Waste Analysis methods
        %%%
        function res=getWasteDefinition(obj)
        %getWasteDefinition - Return (or display) the waste allocation data
        %   When called with an output argument, returns the cWasteData object
        %   directly.  When called with no output argument (interactive use),
        %   displays the waste-definition and waste-allocation tables through
        %   showResults / printTable.
        %
        %   Syntax:
        %     wd  = obj.getWasteDefinition()    % returns cWasteData
        %     obj.getWasteDefinition()           % displays tables in console
        %
        %   Output Arguments:
        %     res - cWasteData object (only when nargout > 0).
        %
            res=obj.WasteData;
            if nargout==0
                tableData=obj.Format.getModelDataProperties;
                wd=tableData(cType.TableDataIndex.WASTE_DEFINITION).name;
                wa=tableData(cType.TableDataIndex.WASTE_ALLOCATION).name;
                showResults(obj.modelInfo,wd);
                tbl=getTable(obj.modelInfo,wa);
                if tbl.status, printTable(tbl); end
            end
        end

        function log=setWasteType(obj,key,wtype)
        %setWasteType - Change the cost-allocation method for a waste flow
        %   Delegates to cWasteData.setType.  The new allocation type must
        %   be a valid cType.WasteAllocation value.
        %
        %   Syntax:
        %     log = obj.setWasteType(key, wtype)
        %
        %   Input Arguments:
        %     key   - Waste flow key string identifying the waste to modify.
        %     wtype - Allocation type string (see cType.WasteAllocation).
        %
        %   Output Arguments:
        %     log   - cTaesLab object with the operation status.  Check
        %             log.status to verify whether the change succeeded.
        %
        %   See also cType.WasteAllocation
        %
            log=cTaesLab();
            if nargin~=3
               log.printError(cMessages.InvalidArgument);
               return
            end
            if ~setType(obj.WasteData,key,wtype)
                log.printError(cMessages.InvalidWasteAllocation,wtype);
            end
        end

        function log=setWasteValues(obj,key,val)
        %setWasteValues - Change the allocation coefficients for a waste flow
        %   Delegates to cWasteData.setValues.  The vector val must have one
        %   entry per productive process.
        %
        %   Syntax:
        %     log = obj.setWasteValues(key, val)
        %
        %   Input Arguments:
        %     key - Waste flow key string identifying the waste to modify.
        %     val - Numeric vector of allocation coefficients, one per process.
        %
        %   Output Arguments:
        %     log - cTaesLab object with the operation status.  Check
        %           log.status to verify whether the change succeeded.
        %
            log=cTaesLab();
            if nargin~=3
               log.printError(cMessages.InvalidArgument);
               return
            end
            if ~setValues(obj.WasteData,key,val)
                log.printError(cMessages.InvalidWasteValues,key);
            end 
        end
   
        function log=setWasteRecycled(obj,key,val)
        %setWasteRecycled - Change the recycling ratio for a waste flow
        %   Delegates to cWasteData.setRecycleRatio.  val must be a scalar
        %   in [0, 1] representing the fraction of the waste that is recycled.
        %
        %   Syntax:
        %     log = obj.setWasteRecycled(key, val)
        %
        %   Input Arguments:
        %     key - Waste flow key string identifying the waste to modify.
        %     val - Scalar recycling ratio in the range [0, 1].
        %
        %   Output Arguments:
        %     log - cTaesLab object with the operation status.  Check
        %           log.status to verify whether the change succeeded.
        %
            log=cTaesLab();
            if nargin~=3
               log.printError(cMessages.InvalidArgument);
               return
            end 
            if ~setRecycleRatio(obj.WasteData,key,val)
                log.printError(cMessages.InvalidRecycling,val,key);
            end
        end

        function log=updateModel(obj)
        %updateModel - Rebuild internal data after setExergy/setResource/setWaste changes
        %   Calls buildModelData to synchronise the cModelData object with
        %   any modified exergy, resource or waste values, then calls
        %   buildResultInfo to regenerate the result tables.
        %   Must be called explicitly after any set* method to ensure the
        %   data model and its presentation tables are consistent.
        %
        %   Syntax:
        %     log = obj.updateModel()
        %
        %   Output Arguments:
        %     log - Logical scalar: true if the model is still valid after
        %           the rebuild, false if an error occurred.
        %
            buildModelData(obj);
            buildResultInfo(obj);
            log=obj.status;
        end

        %%%
        % Get Tables information
        %%%

        %getSummaryOption - Get the default summary option
        %   Depends on the number of states and resource samples
        %   of the data model
        %   Syntax:
        %     obj.getSummaryOption
        %   Output:
        %     res - summary option text
        %       'NONE' | 'STATES' | 'RESOURCES' | 'ALL'
        %
        function res = getSummaryOption(obj)
        %getSummaryOption - Return the recommended summary option string
        %   Selects the appropriate cType.SummaryId key based on whether
        %   the model has multiple states and/or multiple cost samples:
        %     NrOfStates=1,  NrOfSamples=1  ->  'NONE'
        %     NrOfStates>1,  NrOfSamples=1  ->  'STATES'
        %     NrOfStates=1,  NrOfSamples>1  ->  'RESOURCES'
        %     NrOfStates>1,  NrOfSamples>1  ->  'ALL'
        %
        %   Syntax:
        %     res = obj.getSummaryOption()
        %
        %   Output Arguments:
        %     res - 1×1 cell array containing the option string.
        %
            options = fieldnames(cType.SummaryId);
            id = (obj.NrOfStates > 1) + 2 * (obj.NrOfSamples > 1) + 1;
            res = options(id);
        end
        function res=getTablesDirectory(obj,varargin)
        %getTablesDirectory - Get the tables directory
        %   Syntax:
        %     res = obj.getTablesDirectory(options)
        %   Input Arguments:
        %     options - cell array with selected columns properties
        %   Output Arguments:
        %     res - cTable object with the available tables and its properties
        %   See also ListResultTables
        %
            res=getTablesDirectory(obj.FormatData,varargin{:});
            if nargout==0
                printTable(res);
            end
        end

        function res=getTableInfo(obj,name)
        %getTableInfo - Get information about a table
        %   Syntax:
        %     res = obj.getTableInfo(name)
        %   Input Arguments:
        %     name - table name
        %   Output Arguments:
        %     res - struct with table properties
        %
            res=getTableInfo(obj.FormatData,name);
            if nargout==0
                disp(cType.BLANK)
                disp(res);
            end
        end

        %%%
        % ResultSet Methods
        %%%
        function res=getResultInfo(obj)
        %getResultInfo - Get data model result info
        %   Syntax:
        %     res=obj.getResultInfo
        %   Output Arguments:
        %     res - cResultInfo of data model
        % 
            res=obj.modelInfo;
        end

        function showDataModel(obj,varargin)
        %showDataModel - Display data-model tables in the selected interface
        %   Delegates to showResults (inherited from cResultSet).  The
        %   optional arguments control which table is shown and which
        %   interface is used for presentation.
        %
        %   Syntax:
        %     obj.showDataModel()
        %     obj.showDataModel(name)
        %     obj.showDataModel(name, view)
        %
        %   Input Arguments:
        %     name - (optional) Name of the table to display.  When omitted,
        %            all data-model tables are printed to the console.
        %     view - (optional) Display interface selector:
        %              cType.TableView.CONSOLE  (default)
        %              cType.TableView.GUI
        %              cType.TableView.HTML
        %
            showResults(obj,varargin{:})
        end

        function log=saveDataModel(obj,filename)
		%saveDataModel - Save the data model to a file
        %   The output format is determined by the filename extension.
        %   Supported extensions and their formats:
        %     .json  - JSON (model structure)
        %     .xml   - XML  (model structure)
        %     .csv   - CSV  (result tables, one file per table)
        %     .xlsx  - Excel workbook (one sheet per result table)
        %     .txt   - Plain text
        %     .html  - HTML pages
        %     .tex   - LaTeX tables
        %     .mat   - MATLAB binary (full object)
        %
        %   Syntax:
        %     log = obj.saveDataModel(filename)
        %
        %   Input Arguments:
        %     filename - Path to the output file, including the extension.
        %
        %   Output Arguments:
        %     log      - cMessageLogger with the save status and any error
        %                messages.  Check log.status to verify success.
        %
			log=cMessageLogger();
			% Check inputs
            if (nargin<2) || ~isFilename(filename)
                log.messageLog(cType.ERROR,cMessages.InvalidArgument);
            end
			if ~obj.status
				log.messageLog(cType.ERROR,cMessages.InvalidObject,class(obj));
                return
			end
			% Save data model depending of fileType
			[fileType,fileExt]=cType.getFileType(filename);
            switch fileType
				case cType.FileType.JSON
					log=saveAsJSON(obj.ModelData,filename);
                case cType.FileType.XML
                    log=saveAsXML(obj.ModelData,filename);
				case cType.FileType.CSV
                    log=saveAsCSV(obj.modelInfo,filename);
				case cType.FileType.XLSX
                    log=saveAsXLS(obj.modelInfo,filename);
                case cType.FileType.TXT
                    log=saveAsTXT(obj.modelInfo,filename);
                case cType.FileType.HTML
                    log=saveAsHTML(obj.modelInfo,filename);
                case cType.FileType.LaTeX
                    log=saveAsLaTeX(obj.modelInfo,filename);
                case cType.FileType.MAT
					log=exportMAT(obj,filename);
				otherwise
					log.messageLog(cType.ERROR,cMessages.InvalidFileExt, upper(fileExt));
            end
            if log.status
				log.messageLog(cType.INFO,cMessages.InfoFileSaved,obj.ResultName,filename);
            end
        end
    end

    methods(Static)
        function res = create(filename)
        %create - Create a cDataModel object from a file
        %   Syntax:
        %     res = cDataModel.create(filename)
        %   Input Arguments:
        %     filename - name of the file to read
        %   Output Arguments:
        %     res - cDataModel object
        %
        %   Example:
        %     res = cDataModel.create('dataModel.json'); %returns a cDataModel object from a JSON file 
        %
        %   See also cReadModel, ReadDataModel
        %     
            res=cMessageLogger(cType.INVALID);
            %Check input arguments
            if nargin~=1 || isempty(filename) || ~isFilename(filename)
                res.messageLog(cType.ERROR,cMessages.InvalidInputFile,filename);
                return
            end
            % Read the data model depending de file extension
            filename=char(filename);
            [fileType,fileExt]=cType.getFileType(filename);
            switch fileType
                case cType.FileType.JSON
                    rdm=cReadModelJSON(filename);
                case cType.FileType.XML
                    rdm=cReadModelXML(filename);
                case cType.FileType.CSV
                    rdm=cReadModelCSV(filename);
                case cType.FileType.XLSX
                    rdm=cReadModelXLS(filename);
                otherwise
                    res.messageLog(cType.ERROR,cMessages.InvalidFileExt, upper(fileExt));
                    return
            end
            % Check if the model read is correct
                if ~rdm.status
                    res.addLogger(rdm);
                    res.messageLog(cType.ERROR,cMessages.InvalidDataModelFile,filename);
                    return
                end
                res=cDataModel(rdm.ModelData);
            % Set log message
            if res.status
                res.messageLog(cType.INFO,cMessages.ValidDataModel,res.ModelName);
            else
                res.messageLog(cType.ERROR,cMessages.InvalidDataModelFile,filename);
            end
        end
    end

    methods(Access=private)
        function buildResultInfo(obj)
        %buildResultInfo - Get the cResultInfo with the data model tables
        %   Syntax:
        %     obj.buildResultInfo()
        %
            ps=obj.ProductiveStructure;
            p=struct('Name','','Description','');
            tableData=obj.FormatData.getDataModelProperties;
			% Flows Table
            index=cType.TableDataIndex.FLOWS;
            tp=tableData(index);
            sheet=tp.name;
            p.Name=sheet;
            p.Description=tp.descr;
            fNames={ps.Flows.key};
            colNames={tp.fields.name};
            values={ps.Flows.type}';
            tbl=cTableData(values,fNames,colNames,p);
            if tbl.status
                tables.(sheet)=tbl;
            else
                obj.addLogger(tbl);
                obj.messageLog(cType.ERROR,cMessages.TableNotCreated,sheet);
                return
            end
			% Process Table
            index=cType.TableDataIndex.PROCESSES;
            tp=tableData(index);
            sheet=tp.name;
            p.Name=sheet;
            p.Description=tp.descr;
            prc=ps.Processes(1:end-1);
            pNames={prc.key};
            colNames={tp.fields.name};
            values=cell(obj.NrOfProcesses,3);
            values(:,1)={prc.type}';
            values(:,2)={prc.fuel}';
            values(:,3)={prc.product}';
            tbl=cTableData(values,pNames,colNames,p);
            if tbl.status
                tables.(sheet)=tbl;
            else
                obj.addLogger(tbl);
                obj.messageLog(cType.ERROR,cMessages.TableNotCreated,sheet);
                return
            end
            % Exergy Table
            index=cType.TableDataIndex.EXERGY;
            tp=tableData(index);
            sheet=tp.name;
            p.Name=sheet;
            p.Description=tp.descr;
			colNames=['key',obj.StateNames];			
			values=zeros(obj.NrOfFlows,obj.NrOfStates);
            for i=1:obj.NrOfStates
                rex=obj.getExergyData(i);
				values(:,i)=rex.FlowsExergy';
            end
            tbl=cTableData(num2cell(values),fNames,colNames,p);
            if tbl.status
                tables.(sheet)=tbl;
            else
                obj.addLogger(tbl);
                obj.messageLog(cType.ERROR,cMessages.TableNotCreated,sheet);
                return
            end
            % Format Table
            index=cType.TableDataIndex.FORMAT;
            tp=tableData(index);
            sheet=tp.name;
            p.Name=sheet;
            p.Description=tp.descr;
			fmt=obj.ModelData.Format.definitions;
            rowNames={fmt(:).key};
            colNames={tp.fields.name};
            val=struct2cell(fmt)';
			tbl=cTableData(val(:,2:end),rowNames,colNames,p);
            if tbl.status
                tables.(sheet)=tbl;
            else
                obj.addLogger(tbl);
                obj.messageLog(cType.ERROR,cMessages.TableNotCreated,sheet);
                return
            end
            % Resources Cost tables
            index=cType.TableDataIndex.RESOURCES;
            tp=tableData(index);
            sheet=tp.name;
            p.Name=sheet;
            p.Description=tp.descr;
            if obj.isResourceCost
				colNames=[{'key','type'},obj.SampleNames];
				%Flows
                fId=ps.ResourceFlows;
				rNames=fNames(ps.ResourceFlows);
				rTypes=repmat({'FLOW'},numel(rNames),1);
				rval=zeros(numel(fId),obj.NrOfSamples);
                for i=1:obj.NrOfSamples
                    rsc=obj.ResourceData.getValues(i);
					rval(:,i)=rsc.c0(fId)';
                end
				cflow=[rTypes,num2cell(rval)];
				% Processes
				pval=zeros(obj.NrOfProcesses,obj.NrOfSamples);
				pTypes=repmat({'PROCESS'},obj.NrOfProcesses,1);
                for i=1:obj.NrOfSamples
                    rsc=obj.ResourceData.getValues(i);
					pval(:,i)=rsc.Z';		            
                end
				cprocess=[pTypes,num2cell(pval)];
                rowNames=[rNames,pNames];
                values=[cflow;cprocess];
				tbl=cTableData(values,rowNames,colNames,p);
                if tbl.status
                    tables.(sheet)=tbl;
                else
                    obj.addLogger(tbl);
                    obj.messageLog(cType.ERROR,cMessages.TableNotCreated,sheet);
                    return
                end
				tables.(sheet)=tbl;
            end
            % Waste Table
            if (obj.NrOfWastes>0) && obj.isWaste
                wd=obj.WasteData;
                wnames=obj.WasteFlows;
				% Waste Definition
				index=cType.TableDataIndex.WASTEDEF;
                tp=tableData(index);
                sheet=tp.name;
                p.Name=sheet;
                p.Description=tp.descr;
                rowNames=wnames;
                colNames={tp.fields.name};
                values=cell(obj.NrOfWastes,2);
                values(:,1)=wd.Type';
                values(:,2)=num2cell(wd.RecycleRatio)';
				tbl=cTableData(values,rowNames,colNames,p);
                if tbl.status
                    tables.(sheet)=tbl;
                else
                    obj.addLogger(tbl);
                    obj.messageLog(cType.ERROR,cMessages.TableNotCreated,sheet);
                    return
                end
				% Waste Allocation
                jdx=find(wd.TypeId==0);
                idx=any(wd.Values,1);
                if ~isempty(jdx) && any(idx)
                    index=cType.TableDataIndex.WASTEALLOC;
                    tp=tableData(index);
                    sheet=tp.name;
                    p.Name=sheet;
                    p.Description=tp.descr;
                    colNames=['key',wnames(jdx)];
                    rowNames=pNames(idx);
                    values=wd.Values(jdx,idx)';
				    tbl=cTableData(num2cell(values),rowNames,colNames,p);
                    if tbl.status
                        tables.(sheet)=tbl;
                    else
                        obj.addLogger(tbl);
                        obj.messageLog(cType.ERROR,cMessages.TableNotCreated,sheet);
                        return
                    end
                end
            end
            % Create Data Mode Result Info
            res=cResultInfo(obj,tables);
            if isValid(res)
                obj.modelInfo=res;
            else
                obj.addLogger(res);
            end
        end

        function buildModelData(obj)
        %buildModelData - Update the ModelData
        %   Update the cModelData object with the current data of the model
        %   Syntax:
        %     obj.buildModelData()
            % General variables
            ps=obj.ProductiveStructure;
            % Exergy
            ds=obj.ExergyData;
            fields=cType.KEYVAL;
            snames=obj.StateNames;
            st=cell(obj.NrOfStates,1);
            for i=1:obj.NrOfStates
                st{i}.stateId=snames{i};
                exd=ds.getValues(i);
                values=[ps.FlowKeys;num2cell(exd.FlowsExergy)];
                st{i}.exergy=cell2struct(values,fields,1);
            end
            ExergyStates.States=cell2mat(st);
            %Waste Definition
            if obj.isWaste
                keys=ps.ProcessKeys;
                wd=obj.WasteData;
                NR=obj.NrOfWastes;
                pswd=cell(NR,1);
                for i=1:NR
                    pswd{i}.flow=wd.Names{i};
                    pswd{i}.type=wd.Type{i};
                    pswd{i}.recycle=wd.RecycleRatio(i);
                    [~,cols,vals]=find(wd.Values(i,:));
                    nnz=length(vals);
                    if nnz>0
                        tmp=cell(nnz,1);
                        for j=1:nnz
                            tmp{j}.process=keys{cols(j)};
                            tmp{j}.value=vals(j);
                        end
                        pswd{i}.values=cell2mat(tmp);
                    end
                end
                WasteDefinition.wastes=cell2mat(pswd);
            end
            %Resource data
            if obj.isResourceCost
                ds=obj.ResourceData;
                snames=obj.SampleNames;
                rs=cell(obj.NrOfSamples,1);
                for i=1:obj.NrOfSamples
                    rs{i}.sampleId=snames{i};
                    rsd=ds.getValues(i);
                    % Flow Resources
                    idx=rsd.frsc;
                    keys=ps.FlowKeys(idx);
                    vals=num2cell(rsd.c0(idx));            
                    values=[keys;vals];
                    rs{i}.flows=cell2struct(values,fields,1);
                    % Process Resources
                    keys=ps.ProcessKeys(1:end-1);
                    vals=num2cell(rsd.Z);            
                    values=[keys;vals];
                    rs{i}.processes=cell2struct(values,fields,1);
                end
            end
            % Build Model Data
            ResourcesCost.Samples=cell2mat(rs);
            md=struct('ProductiveStructure',obj.ModelData.ProductiveStructure,...
                'Format',obj.ModelData.Format,...
                'ExergyStates',ExergyStates,...
                'WasteDefinition',WasteDefinition,...
                'ResourcesCost',ResourcesCost);
            res=cModelData(obj.ModelName,md);
            if res.status
                obj.ModelData=res;
            else
                obj.addLogger(res);
            end
        end
    end
end