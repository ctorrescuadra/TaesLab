classdef cDataModel < cResultSet
%cDataModel - Create the data model object.
%   It receives the data from the cReadModel interface classes, then validates
%   and dispatch the information to be used by the calculation algorithms.
%
%   cDataModel constructor:
%     obj = cDataModel(dm)
%
%   cDataModel properties:
%     NrOfFlows           - Number of flows
%     NrOfProcesses       - Number of processes
%     NrOfWastes          - Number of waste flows
%     NrOfResources       - Number of resource flows
%     NrOfSystemOutputs   - Number of system outputs
%     NrOfFinalProducts   - Number of final products
%     NrOfStates          - Number of exergy data simulations
%     NrOfSamples         - Number of resource cost samples
%     isWaste             - Indicate if the model has waste defined
%     isResourceCost      - Indicate if the model has resource cost data
%     isDiagnosis         - Indicate if the model has information to make diagnosis
%     isSummary           - Indicate if the model has information to make summary reports
%     StateNames          - State names
%     SampleNames         - Resource sample names
%     WasteFlows          - Waste Flow names
%     ProductiveStructure - cProductiveStructure object
%     FormatData          - cResultTableBuilder object
%     WasteData           - cWasteData object
%     ExergyData          - Dataset of cExergyData
%     ResourceData        - Dataset of cResourceData
%     ModelData           - cModelData object
%
%   cDataModel methods:
%     existState         - Check if a state name exists 
%     existSample        - Check if a sample name exists
%     getExergyData      - Get the cExergyData of a state
%     setExergyData      - Set the exergy values of a state
%     addExergyData      - Add a new exergy state
%     getResourceData    - Get the cResourceData for a specific sample
%     setFlowResource    - Set Flow-resource values of a sample
%     setProcessResource - Set Process-resource values of a sample
%     addResourceData    - Add a new resource sample
%     getWasteDefinition - Get Waste definition info
%     setWasteType       - Modify the type of a waste
%     setWasteValues     - Modify the allocation values of a waste
%     setWasteRecycled   - Modify the recycling ratio of a waste
%     getTablesDirectory - Get the tables directory 
%     getTableInfo       - Get information about a table object
%     getResultInfo      - Get the cResultInfo associated to the data model
%     showDataModel      - Show the data model
%     saveDataModel      - Save the data model
%
%   See also cResultSet, cProductiveStructure, cExergyData, cResultTableBuilder, cWasteData, cResourceData, cModelData
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
        %cDataModel - Creates the cDataModel object
        %   Syntax:
        %     obj = cDataModel(dm)
        %   Input Argument:
        %     dm - cModelData object with the data of the model
        %
            % Check Data Structure
            if ~isObject(dm,'cModelData')
                obj.addLogger(dm)
                obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(dm));
                return
            end
            obj.ClassId=cType.ClassId.DATA_MODEL;
            obj.isResourceCost=dm.isResourceCost;
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
                if dm.isWaste
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
		%existState - Check if state is defined in States
        %   Syntax:
        %     res = obj.existState(state)
        %   Input Argument:
        %     state - state name
        %   Output Argument:
        %     res - true | false
        %
			res=obj.ExergyData.getIndex(state);
        end

		function res=existSample(obj,sample)
		%existSample - Check if sample is defined in ResourceState
        %   Syntax:
        %     res = obj.existState(sample)
        %   Input Argument:
        %     sample - Resource sample name
        %   Output Argument:
        %     res - true | false
        %
			res=obj.ResourceData.getIndex(sample);
        end

        %%%
        % Get/Set Exergy methods
        %%%
        function res=getExergyData(obj,state)
        %getExergyData - Get the exergy data for a state
        %   Syntax:
        %     res = obj.getExergyData(state)
        %   Input Arguments:
        %     state - state key name or id
        %       char array | number
        %   Output Arguments:
        %     res = cExergyData object
        %
            res=obj.ExergyData.getValues(state);
        end

        function res=buildExergyData(obj,state,values)
        %setExergyData - Set the exergy data values of a state
        %   Syntax:
        %     res = obj.setExergyData(state,values)
        %   Input Argument:
        %     state - state key name or id
        %       char array | number
        %     values - array with the exergy values of the flows
        %   Output:
        %     res - cExergyData object associated to the values
        %
            res=cMessageLogger();
            if nargin<3
                res.printError(cMessages.InvalidArgument);
                return
            end
            M=length(values);
            if obj.NrOfFlows~=M
                res.printError(cMessages.InvalidExergyDataSize,M);
                return
            end
            % Build exergy data structure
            exs.stateId=state;
            % Build exergy data structure
            if isstruct(values)
                exs.exergy=values;
            elseif isnumeric(values)
                fields={'key','value'};
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
        %setExergyData - set exergy data to a state
        %   Syntax: 
        %     log = obj.setExergyData(state,val)
        %   Input Argument:
        %     state - state to change 
        %     val - array | struct with exergy values
        %   Output Argument:
        %     log - true | false status of the operation
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
        %setExergyData - add a new  exergy data state
        %   Syntax: 
        %     log = obj.addExergyData(state,val)
        %   Input Argument:
        %     state - state to change 
        %     val - array | struct with exergy values
        %   Output Argument:
        %     log - true | false status of the operation
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
        %getResourceData - Get the resource data for a sample
        %   Syntax:
        %     res = obj.getResourceData(sample)
        %   Input Arguments:
        %     sample - Resource sample name key or id
        %       char array | number
        %   Output Arguments:
        %     res - cResourceData object
        %
            res=obj.ResourceData.getValues(sample);
        end

        function log=setFlowResource(obj,sample,values)
        %setFlowResourceData - Set the flow-resource value of a sample
        %   Syntax:
        %     log = obj.setFlowResourceData(sample,values)
        %   Input Arguments:
        %     sample - Sample key/id
        %     values - Array containing the flow-resource values
        %   Output Argument:
        %     log - cMessageLogger with the operation status and errors
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
        %setProcessResourceData - Set the process-resource value of a sample
        %   Syntax:
        %     log = obj.setProcessResourceData(sample,values)
        %   Input Arguments:
        %     sample - Sample key/id
        %     values - Array containing the process-resource values
        %   Output Argument:
        %     log - cMessageLogger with the operation status and errors
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
        %buildResourceData - create a new cResourceData object
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
                res.printError(cMessages.InvalidArgument);
                return
            end
            ps=obj.ProductiveStructure;
            %Build Resource Data structure
            rsd.sampleId=sample;
            if isstruct(rval)
                rsd.flows=rval;
            elseif isnumeric(rval)
                if obj.NrOfFlows~=length(rval)
                    res.printError(cMessages.InvalidExergyDataSize,M);
                    return
                end
                fields={'key','value'};
                irsd=ps.ResourceFlows;
                keys=ps.FlowKeys(irsd);
                if iscolumn(rval), rval=rval';end
                vals=rval(irsd);
                tmp=[keys;num2cell(vals)];
                rsd.flows=cell2struct(tmp,fields,1);
            else
                res.printError(cMessages.InvalidExergyData,state);
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
                    fields={'key','value'};
                    keys=ps.ProcessKeys(1:end-1);
                    if iscolumn(pval), pval=pval';end
                    tmp=[keys;num2cell(pval)];
                    rsd.processes=cell2struct(tmp,fields,1);
                else
                    res.printError(cMessages.InvalidResourceData,sample);
                    return
                end
            end
            res=cResourceData(ps,rsd);
            if ~res.status
                printLogger(res);
                res.printError(cMessages.InvalidResourceData,sample);
            end
        end

        function rsd=addResourceData(obj,sample,rval,varargin)
        %addResourceData - create a new cResourceData object and add to Resource samples
        %   Syntax:
        %     res = obj.addResourceData(sample,rval,pval)
        %   Input Arguments:
        %     sample - name of the resource sample
        %     rval - array | struct with the flow resource values
        %     pval - array | struct with the processes resource values (optional)
        %   Output Arguments:
        %     log - true | false status of the operaton
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
        %getWasteDefinition - Get Waste Data
        %   Syntax:
        %     obj.getWasteDefinition;
        %     res = obj.getWasteDefinition
        %   Output Arguments:
        %     res - (optional) cWasteData
        %       If no output, it shows waste tables
        %
            res=obj.WasteData;
            if nargout==0
                showResults(obj.modelInfo,cType.TableData.WASTE_DEFINITION);
                tbl=getTable(obj.modelInfo,cType.TableData.WASTE_ALLOCATION);
                if tbl.status, printTable(tbl); end
            end
        end

        function log=setWasteType(obj,key,wtype)
        %setWasteType - Set the waste type allocation method for Active Waste
        %   Syntax: 
        %     log = setWasteType(wtype)
        %   Input Arguments:
        %     key - waste key 
        %     wtype - waste allocation type
        %   Output Arguments:
        %     log - cMessageLogger with the status and messages of operation
        %   See also cType.WasteAllocation
        %
            log=cMessageLogger();
            if nargin~=3
               log.printError(cMessages.InvalidArgument);
               return
            end
            if ~setType(obj.WasteData,key,wtype)
                log.printError(cMessages.InvalidWasteAllocation,wtype);
            end
        end

        function log=setWasteValues(obj,key,val)
        %setWasteValues - Set the waste table values
        %   Syntax:
        %     log = obj.setWasteValues(val)
        %   Input Arguments:
        %     key - waste key 
        %     val - vector containing the waste allocation values for processes
        %   Output Arguments:
        %     log - cMessageLogger with the status and messages of operation
            log=cMessageLogger();
            if nargin~=3
               log.printError(cMessages.InvalidArgument);
               return
            end
            if ~setValues(obj.WasteData,key,val)
                log.printError(cMessages.InvalidWasteValues,key);
            end 
        end
   
        function log=setWasteRecycled(obj,key,val)
        %setWasteRecycled - Set the waste recycling ratios
        %   Syntax:
        %     log = obj.setWasteRecycled(val)
        %   Input Arguments:
        %     key - Waste key
        %     val - Recycling ratio of the active waste
        %   Output Arguments:
        %     log - cMessageLogger with the status and messages of operation
        %
            log=cMessageLogger();
            if nargin~=3
               log.printError(cMessages.InvalidArgument);
               return
            end 
            if ~setRecycleRatio(obj.WasteData,key,val)
                log.printError(cMessages.InvalidRecycling,val,key);
            end
        end

        function log=updateModel(obj)
        %updateDataModel - Update the Data Model if there is changes
        %   Update cModelData and cResultInfo if changes have been made
        %   by setExergy, setResources or setWaste methods
        %   Syntax
        %     log = obj.updataModel
        %   Output
        %     log - true | false status of the update.
        % 
            buildModelData(obj)
            buildResultInfo(obj);
            log=obj.status;
        end

        %%%
        % Get Tables information
        %%%
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
        end

        function res=getTableInfo(obj,name)
        %getTableInfo - Get information about a table
        %   Syntax:
        %     res = obj.getTableInfo(name)
        %   Input Argument:
        %     name - table name
        %   Output Argument:
        %     res - struct with table properties
        %
            res=getTableInfo(obj.FormatData,name);
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
        %showDataModel - View a table in a GUI Table
        %   Syntax:
        %     obj.showDataModel(options)
        %   Input Arguments:
        %     name - [optional] Name of the table
        %       If is missing all tables are shown in the console
        %     options - TableView option
        %       cType.TableView.CONSOLE (default)
        %       cType.TableView.GUI
        %       cType.TableView.HTML
        %
            showResults(obj,varargin{:})
        end

        function log=saveDataModel(obj,filename)
		%SaveDataModel - Save data model depending of filename extension
        %   Valid extension are: txt, csv, html, xlsx, json, xml, mat
        %
        %   Input Arguments:
        %     filename - name of the file including extension.
        %   Output Arguments:
        %     log - cMessageLog including save status and messages
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
			fileType=cType.getFileType(filename);
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
					log.messageLog(cType.ERROR,cMessages.InvalidFileExt,filename);
            end
            if log.status
				log.messageLog(cType.INFO,cMessages.InfoFileSaved,obj.ResultName,filename);
            end
        end
    end

    methods(Access=private)
        function buildResultInfo(obj)
        %buildResultInfo - Get the cResultInfo with the data model tables
            ps=obj.ProductiveStructure;
            p=struct('Name','','Description','');
			% Flows Table
            index=cType.TableDataIndex.FLOWS;
            sheet=cType.TableDataName{index};
            p.Name=sheet;
            p.Description=cType.TableDataDescription{index};
            fNames={ps.Flows.key};
            colNames={'key','type'};
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
            sheet=cType.TableDataName{index};
            p.Name=sheet;
            p.Description=cType.TableDataDescription{index};
            prc=ps.Processes(1:end-1);
            pNames={prc.key};
            colNames={'key','fuel','product','type'};
            values=cell(obj.NrOfProcesses,3);
            values(:,1)={prc.fuel}';
            values(:,2)={prc.product}';
            values(:,3)={prc.type}';
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
            sheet=cType.TableDataName{index};
            p.Name=sheet;
            p.Description=cType.TableDataDescription{index};
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
            sheet=cType.TableDataName{index};
            p.Name=sheet;
            p.Description=cType.TableDataDescription{index};
			fmt=obj.ModelData.Format.definitions;
            rowNames={fmt(:).key};
            val=struct2cell(fmt)';
			tbl=cTableData(val(:,2:end),rowNames,fieldnames(fmt)',p);
            if tbl.status
                tables.(sheet)=tbl;
            else
                obj.addLogger(tbl);
                obj.messageLog(cType.ERROR,cMessages.TableNotCreated,sheet);
                return
            end
            % Resources Cost tables
            index=cType.TableDataIndex.RESOURCES;
            sheet=cType.TableDataName{index};
            p.Name=sheet;
            p.Description=cType.TableDataDescription{index};
            if obj.isResourceCost
				colNames=[{'Key','Type'},obj.SampleNames];
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
                sheet=cType.TableDataName{index};
                p.Name=sheet;
                p.Description=cType.TableDataDescription{index};
                rowNames=wnames;
                colNames={'key','type','recycle'};
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
                if ~isempty(jdx)
                    index=cType.TableDataIndex.WASTEALLOC;
				    sheet=cType.TableDataName{index};
                    p.Name=sheet;
                    p.Description=cType.TableDataDescription{index};
                    [~,idx]=find(wd.Values);idx=unique(idx);
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
            % General variables
            ps=obj.ProductiveStructure;
            % Exergy
            ds=obj.ExergyData;
            fields={'key','value'};
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