classdef cDataModel < cResultSet
% cDataModel - is the data dispatcher for the thermoeconomic analysis classes.
%   It receives the data from the cReadModel interface classes, then validates
%   and organizes the information to be used by the calculation algorithms.
%
% cDataModel properties:
%   NrOfFlows           - Number of flows
%   NrOfProcesses       - Number of processes
%   NrOfWastes          - Number of waste flows
%   NrOfStates          - Number of exergy data simulations
%   NrOfSamples         - Number of resource cost samples
%   isWaste             - Indicate is the model has waste defined
%   isResourceCost      - Indicate is the model has resource cost data
%   isDiagnosis         - Indicate is the model has information to make diagnosis
%   StateNames          - State names
%   SampleNames         - Resource sample names
%   WasteFlows          - Waste Flow names
%   ProductiveStructure - cProductiveStructure object
%   FormatData          - cResultTableBuilder object
%   WasteData           - cWasteData object
%   ExergyData          - Dataset of cExergyData
%   ResourceData        - Dataset of cResourceData
%   ModelData           - cModelData object
%   ModelName           - Name of the model
%   ResultId            - ResultId (cType.ResultId.DATA_MODEL)
%
% cDataModel methods:
%   getExergyData      - Get the cExergyData of a state
%   setExergyData      - Set the exergy values of a state
%   getResourceData    - Get the cResourceData for a specific sample
%   existState         - Check if a state name exists 
%   existSample        - Check if a sample name exists
%   getTablesDirectory - Get the tables directory 
%   getTableInfo       - Get information about a table object
%   getResultInfo      - Get the cResultInfo associated to the data model
%   showDataModel      - Show the data model
%   saveDataModel      - Save the data model
%
%   See also cResultSet, cProductiveStructure, cExergyData, cResultTableBuilder, cWasteData, cResourceData
%
    properties(GetAccess=public, SetAccess=private)
        NrOfFlows               % Number of flows
        NrOfProcesses           % Number of processes
        NrOfWastes              % Number of waste flows
        NrOfStates              % Number of exergy data simulations
        NrOfSamples             % Number of resource cost samples
        isWaste                 % Indicate is the model has waste defined
        isResourceCost          % Indicate is the model has resource cost data
        isDiagnosis             % Indicate is the model has information to made diagnosis
        StateNames              % State names
        SampleNames             % Resource sample names
        WasteFlows              % Waste Flow names
        ProductiveStructure     % cProductiveStructure object
        FormatData              % cResultTableBuilder object
        WasteData               % cWasteData object
        ExergyData              % Dataset of cExergyData
        ResourceData            % Dataset of cResourceData
        ModelData               % Model data from cReadModel interface
    end

    properties(Access=private)
        modelInfo               % cResultInfo data model
    end

    methods
        function obj = cDataModel(dm)
        % Creates the cDataModel object
        % Syntax:
        %   obj = cDataModel(dm)
        % Input Argument:
        %   dm - cModelData object with the data of the model
        %
            % Check Data Structure
            obj=obj@cResultSet(cType.ClassId.DATA_MODEL);
            if ~isObject(dm,'cModelData')
                obj.messageLog(cType.ERROR,'Invalid data model');
                return
            end
            obj.isResourceCost=dm.isResourceCost;
            % Check and get Productive Structure
            ps=cProductiveStructure(dm);
            status=ps.status;
            if status
                obj.ProductiveStructure=ps;
				obj.messageLog(cType.INFO,'Productive Structure is valid');
            else
                obj.addLogger(ps);
				obj.messageLog(cType.ERROR,'Productive Structure is NOT valid. See error log');
                return
            end
            % Check and get Format	
            rfmt=cResultTableBuilder(ps,dm.Format);
            obj.FormatData=rfmt;
            status = rfmt.status & status;
            if rfmt.status
				obj.messageLog(cType.INFO,'Format Definition is valid');
            else
                obj.addLogger(rfmt);
				obj.messageLog(cType.ERROR,'Format Definition is NOT valid. See error log');
                return
            end
            % Check Exergy
            list=dm.getStateNames;
            tmp=cDataset(list);
            if tmp.status
                obj.StateNames=list;
                obj.ExergyData=tmp;
            else
                obj.messageLog(cType.ERROR,'Invalid states list');
                return
            end
            for i=1:obj.NrOfStates
                exs=dm.getExergyState(i);
                rex=cExergyData(ps,exs);
                status = rex.status & status;
                if rex.status
					obj.messageLog(cType.INFO,'Exergy values [%s] are valid',obj.StateNames{i});
				else
					obj.addLogger(rex)
					obj.messageLog(cType.ERROR,'Exergy values [%s] are NOT valid. See Error Log',obj.StateNames{i});
                end
                setValues(obj.ExergyData,i,rex);
            end
            % Check Waste
            if ps.NrOfWastes > 0
                if dm.isWaste
                    data=dm.WasteDefinition;
                else
                    data=ps.wasteDefinition;
                    obj.messageLog(cType.INFO,'Waste Definition is not available. Default is used');
                end
                wd=cWasteData(ps,data);
                status=wd.status & status;
                obj.addLogger(wd);
                if ~wd.status
					obj.messageLog(cType.ERROR,'Waste Definition is NOT valid. See error log');
                else
					obj.messageLog(cType.INFO,'Waste Definition is valid');	
                end
                obj.WasteData=wd;
                obj.isWaste=true;	
            else
                obj.isWaste=false;
				obj.messageLog(cType.INFO,'The plant has NOT waste');
            end
            % Check ResourceCost
            if obj.isResourceCost
                list=dm.getSampleNames;
                tmp=cDataset(list);
                if tmp.status
                    obj.SampleNames=list;
                    obj.ResourceData=tmp;
                else
                    obj.messageLog(cType.ERROR,'Invalid resource samples list');
                    return
                end
                for i=1:obj.NrOfSamples
                    dmr=dm.getResourceSample(i);
                    rsc=cResourceData(ps,dmr);
                    status=rsc.status & status;
                    if rsc.status
						obj.messageLog(cType.INFO,'Resources Cost sample [%s] is valid',obj.SampleNames{i});
                        obj.ResourceData.setValues(i,rsc);
                    else
						obj.addLogger(rsc);
						obj.messageLog(cType.ERROR,'Resources Cost sample [%s] is NOT valid. See error log',obj.SampleNames{i});
                    end
                end
            else
               obj.messageLog(cType.INFO,'No Resources Cost Data available')
            end
            % Set ResultId properties
            obj.status=status;
            if ~obj.status
                return
            end
            obj.ResultId=cType.ResultId.DATA_MODEL;
            obj.ResultName=cType.Results{obj.ResultId};
            obj.ModelName=dm.ModelName;
            obj.State='DATA_MODEL';
            obj.DefaultGraph=cType.EMPTY_CHAR;
            obj.ModelData=dm;
            % Get the Model Info
            res=getTableModel(obj);
            if ~res.status
                obj.addLogger(res);
            else
                obj.modelInfo=res;
            end          
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
        function res=get.NrOfStates(obj)
        % get the number of states
            res=0;
            if obj.status
                res=numel(obj.StateNames);
            end
        end
    
        function res=get.NrOfSamples(obj)
        % Get the number of resources samples
            res=0;
            if obj.status
                res=numel(obj.SampleNames);
            end
        end

        function res=get.isDiagnosis(obj)
        % Check if diagnosis data is available
			res=(obj.NrOfStates>1);
        end

        function res=get.WasteFlows(obj)
            res=cType.EMPTY_CELL;
            if obj.isWaste && isValid(obj.WasteData)
                res=obj.WasteData.Names;
            end
        end
        %%%
        % Get Data model information
        %%%
        function res=getExergyData(obj,state)
        % Get the exergy data for a state
        % Syntax:
        %   res = obj.getExergyData(state)
        % Input Arguments:
        %   state - state key name or id
        %     char array | number
        % Output Arguments:
        %   res = cExergyData object
        %
            res=obj.ExergyData.getValues(state);
            if ~res.status
                res.printError('Invalid state %s',state);
            end
        end

        function res=setExergyData(obj,state,values)
        % Set the exergy data values of a state
        % Syntax:
        %   res = obj.setExergyData(state,values)
        % Input Argument:
        %   state - state key name or id
        %     char array | number
        %   values - array with the exergy values of the flows
        % Output:
        %   res - cExergyData object associated to the values
        %
            res=cMessageLogger();
            M=size(values,2);
            % Validate the number of flows
            if obj.NrOfFlows~=M
                res.printError('Invalid number of exergy values',length(values));
                return
            end
            % Validate state
            idx=obj.ExergyData.getIndex(state);
            if ~idx
                res.printError('State %s does not exists',state);
                return
            end
            % Build exergy data structure
            fields={'key','value'};
            keys=obj.ProductiveStructure.FlowKeys;
            tmp=[keys;num2cell(values)];
            % Retrieve exergy state object and set value
            exs.stateId=state;
            exs.exergy=cell2struct(tmp,fields,1);
            % Check and create a cExergyData object
            res=cExergyData(obj.ProductiveStructure,exs);
            if res.status
                obj.ExergyData.setValues(idx,res);
            else
                res.printError('Invalid exergy data');
                printLogger(res);
            end 
        end

        function res=getResourceData(obj,sample)
        % Get the resource data for a sample
        % Syntax:
        %   res = obj.getResourceData(sample)
        % Input Arguments:
        %   sample - Resource sample name key or id
        %     char array | number
        % Output Arguments:
        %   res - cResourceData object
        %
            res=obj.ResourceData.getValues(sample);
            if ~res.status
                res.printError('Invalid state %s',sample);
            end
        end
		
		function res=existState(obj,state)
		% Check if state is defined in States
        % Syntax:
        %   res = obj.existState(state)
        % Input Argument:
        %   state - state name
        % Output Argument:
        %   res - true | false
        %
			res=obj.ExergyData.getIndex(state);
        end

		function res=existSample(obj,sample)
		% Check if sample is defined in ResourceState
        % Syntax:
        %   res = obj.existState(sample)
        % Input Argument:
        %   sample - Resource sample name
        % Output Argument:
        %   res - true | false
        %
			res=obj.ResourceData.getIndex(sample);
        end

        function res=getTablesDirectory(obj,varargin)
        % Get the tables directory
        % Syntax:
        %   res = obj.getTablesDirectory(options)
        % Input Arguments:
        %   options - cell array with selected columns properties
        % Output Arguments:
        %   res - cTable object with the available tables and its properties
        % See also ListResultTables
        %
            res=getTablesDirectory(obj.FormatData,varargin{:});
        end

        function res=getTableInfo(obj,name)
        % Get information about a table
        % Syntax:
        %   res = obj.getTableInfo(name)
        % Input Argument:
        %   name - table name
        % Output Argument:
        %   res - struct with table properties
        %
            res=getTableInfo(obj.FormatData,name);
        end

        %%%
        % ResultSet Methods
        %%%
        function res=getResultInfo(obj)
        % Get data model result info
        % Syntax:
        %   res=obj.getResultInfo
        % Output Arguments:
        %   res - cResultInfo of data model
        % 
            res=obj.modelInfo;
        end

        function showDataModel(obj,varargin)
        % View a table in a GUI Table
        % Syntax:
        %   obj.showDataModel(options)
        % Input Arguments:
        %   name - [optional] Name of the table
        %     If is missing all tables are shown in the console
        %   options - TableView option
        %     cType.TableView.CONSOLE (default)
        %     cType.TableView.GUI
        %     cType.TableView.HTML
        %
            showResults(obj,varargin{:})
        end

        function log=saveDataModel(obj,filename)
		% Save data model depending of filename extension
        %   Valid extension are: txt, csv, html, xlsx, json, xml, mat
        % Input Arguments:
        %   filename - name of the file including extension.
        % Output Arguments:
        %   log - cMessageLog including save status and messages
        %
			log=cMessageLogger();
			% Check inputs
            if (nargin<2) || ~isFilename(filename)
                log.messageLog(cType.ERROR,'Invalid arguments');
            end
			if ~obj.status
				log.messageLog(cType.ERROR,'Invalid data model %s',obj.ModelName);
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
					log.messageLog(cType.ERROR,'File extension %s is not supported',filename);
            end
            if log.status
				log.messageLog(cType.INFO,'File %s has been saved',filename);
            end
        end
    end

    methods(Access=private)
        function res=getTableModel(obj)
        % Get the cResultInfo with the data model tables
            res=cMessageLogger(cType.INVALID);
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
                res.addLogger(tbl);
                res.messageLog(cType.ERROR,'Error creating table: %s',sheet);
                return
            end
			% Process Table
            index=cType.TableDataIndex.PROCESSES;
            sheet=cType.TableDataName{index};
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
                res.addLogger(tbl);
                res.messageLog(cType.ERROR,'Error creating table: %s',sheet);
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
                res.addLogger(tbl);
                res.messageLog(cType.ERROR,'Error creating table: %s',sheet);
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
                res.addLogger(tbl);
                res.messageLog(cType.ERROR,'Error creating table: %s',sheet);
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
                fId=ps.Resources.flows;
				rNames=fNames(ps.Resources.flows);
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
                    res.addLogger(tbl);
                    res.messageLog(cType.ERROR,'Error creating table: %s',sheet);
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
                    res.addLogger(tbl);
                    res.messageLog(cType.ERROR,'Error creating table: %s',sheet);
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
                        res.addLogger(tbl);
                        res.messageLog(cType.ERROR,'Error creating table: %s',sheet);
                        return
                    end
                end
            end
            res=cResultInfo(obj,tables);
        end
    end
end