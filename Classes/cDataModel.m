classdef cDataModel < cResultSet
% cDataModel is the data dispatcher for the thermoeconomic analysis classes.
% It receives the data from the cReadModel interface classes, then validates
% and organizes the information to be used by the calculation algorithms
%   Methods:
%       res=obj.getExergyData(state)
%       log=obj.setExergyData(state,values)
%       res=obj.getResourceData(sample)
%       res=obj.existState(state)
%       res=obj.existSample(sample)
%       res=obj.checkCostTables
%       res=obj.getTablesDirectory(columns)
%       res=obj.getTableInfo(name)
%       log=obj.saveDataModel(filename)
%   ResultSet methods
%       res=obj.getResultInfo
%       obj.printResults
%       obj.showResults(name,options)
%       res=obj.getTable(name,options)
%       res=obj.getTableIndex(options)
%       obj.showTableIndex(options)
%       log=obj.saveTable(name,filename)
%       res=obj.exportTable(name,options)
%       
%   See also cResultSet, cProductiveStructure, cExergyData, cResultTableBuilder, cWasteData, cResourceData
%
    properties(GetAccess=public, SetAccess=private)
        NrOfFlows               % Number of flows
        NrOfProcesses           % Number of processes
        NrOfWastes              % Number of waste flows
        NrOfStates              % Number of exergy data simulations
        NrOfSamples     % Number of resource cost samples
        isWaste                 % Indicate is the model has waste defined
        isResourceCost          % Indicate is the model has resource cost data
        isDiagnosis             % Indicate is the model has information to made diagnosis
        StateNames              % State names
        SampleNames             % Resource sample names
        WasteFlows              % Waste Flow names
        ProductiveStructure     % cProductiveStructure object
        FormatData              % cResultTableBuilder object
        ExergyData              % cell array of cExergyData for each state
        WasteData               % cWasteData object
        ResourceData            % call array of cResourceData for each sample
        ModelData               % Model data from cReadModel interface
        ModelInfo               % cResultInfo data model tables from cReadModel interface
        ModelFile               % Name of the model filename used by the cReadModel interface
        ModelName               % Name of the model
        ResultId                % ResultId
        ResultName              % Result Name (cResultId)
        State                   % State Name (cResultId)
        DefaultGraph            % Default Graph (cResultId)
    end

    methods
        function obj = cDataModel(rdm)
        % Creates the cDataModel object
        %   rdm - cReadModel object with the data model
            % Check Data Structure
            obj=obj@cResultSet(cType.ClassId.DATA_MODEL);
            if ~isa(rdm,'cReadModel') || ~isValid(rdm)
                obj.messageLog(cType.ERROR,'Invalid data model');
                return
            end
            dm=rdm.ModelData;
            obj.isResourceCost=dm.isResourceCost;
            % Check and get Productive Structure
            ps=cProductiveStructure(dm);
 
            status=ps.status;
            if isValid(ps)
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
            if isValid(rfmt)
				obj.messageLog(cType.INFO,'Format Definition is valid');
            else
                obj.addLogger(rfmt);
				obj.messageLog(cType.ERROR,'Format Definition is NOT valid. See error log');
                return
            end
            % Check Exergy
            list=dm.getStateNames;
            tmp=cDataset(list);
            if isValid(tmp)
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
                if isValid(rex)
					obj.messageLog(cType.INFO,'Exergy values [%s] are valid',obj.StateNames{i});
				else
					obj.addLogger(rex)
					obj.messageLog(cType.ERROR,'Exergy values [%s] are NOT valid. See Error Log',obj.StateNames{i});
                end
                obj.ExergyData.setValues(i,rex);
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
                if ~isValid(wd)
					obj.messageLog(cType.ERROR,'Waste Definition is NOT valid. See error log');
                else
					obj.messageLog(cType.INFO,'Waste Definition is valid');	
                end
                obj.WasteData=wd;
                obj.isWaste=true;	
            else
				obj.messageLog(cType.INFO,'The plant has NOT waste');
            end
            % Check ResourceCost
            if obj.isResourceCost
                list=dm.getSampleNames;
                tmp=cDataset(list);
                if isValid(tmp)
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
                    if isValid(rsc)
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
            % Set object properties
            obj.ModelData=dm;
            obj.ModelFile=rdm.ModelFile;
            % Set ResultId properties
            obj.ResultId=cType.ResultId.DATA_MODEL;
            obj.ResultName=cType.Results{obj.ResultId};
            obj.ModelName=rdm.ModelName;
            obj.State='DATA_MODEL';
            obj.DefaultGraph='';
            % Check Data Model
            obj.status=status;
            if ~obj.isValid
                return
            end
            % Get the cResultInfo object
            if obj.isValid
                if rdm.isTableModel
                    obj.ModelInfo=rdm.getTableModel;
                else
                    obj.ModelInfo=obj.getTableModel;
                end
            end
        end

    	function res=get.NrOfFlows(obj)
        % Get the number of flows of the system
            res=0;
            if obj.isValid
                res=obj.ProductiveStructure.NrOfFlows;
            end
        end
    
        function res=get.NrOfProcesses(obj)
        % Get the number of processes of the system
            res=0;
            if obj.isValid
                    res=obj.ProductiveStructure.NrOfProcesses;
            end
        end
    
        function res=get.NrOfWastes(obj)
        % Get the number of wastes of the system
            res=0;
            if obj.isValid
                res=obj.ProductiveStructure.NrOfWastes;
            end
        end
        function res=get.NrOfStates(obj)
        % get the number of states
            res=0;
            if obj.isValid
                res=numel(obj.StateNames);
            end
        end
    
        function res=get.NrOfSamples(obj)
        % Get the number of resources samples
            res=0;
            if obj.isValid
                res=numel(obj.SampleNames);
            end
        end

        function res=get.isDiagnosis(obj)
        % Check if diagnosis data is available
			res=(obj.NrOfStates>1);
        end

        function res=get.WasteFlows(obj)
            res={};
            if obj.isWaste && isValid(obj.WasteData)
                res=obj.WasteData.Names;
            end
        end
        %%%
        % Get Data model information
        %%%
        function res=getExergyData(obj,state)
        % get the exergy data for a state
        %   Input:
        %       state - state key name
            res=obj.ExergyData.getValues(state);
            if ~isValid(res)
                res.printError('Invalid state %s',state);
            end
        end

        function log=setExergyData(obj,state,values)
        % Set the exergy data of the state with values
        % If state not exists a new one is creates
        %   Input:
        %       state - Name of the state
        %       values - array with the exergy values of the flows
            log=cStatus();
            M=size(values,2);
            % Validate the number of flows
            if obj.NrOfFlows~=M
                log.printError('Invalid number of exergy values',length(values));
                return
            end
            % Validate state
            idx=obj.ExergyData.getIndex(state);
            if ~idx
                log.printError('State %s does not exists',state);
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
            rex=cExergyData(obj.ProductiveStructure,exs);
            if isValid(rex)
                obj.ExergyData.setValues(idx,rex);
            else
                log.printError('Invalid exergy data');
                printLogger(rex);
            end 
        end

        function res=getResourceData(obj,sample)
        % Get the resource data for a sample
            res=obj.ResourceData.getValues(sample);
            if ~isValid(res)
                res.printError('Invalid state %s',sample);
            end
        end
		
		function res=existState(obj,state)
		% determine if state is defined in States
			res=obj.ExergyData.getIndex(state);
        end

		function res=existSample(obj,sample)
		% Determine if sample is defined in ResourceSamples
			res=obj.ResourceData.getIndex(sample);
        end
 
        function res=checkCostTables(obj,value)
        % Check if the CostTables parameter is valid
            res=false;
            pct=cType.getCostTables(value);
            if cType.isEmpty(pct)
                return
            end
            if bitget(pct,cType.GENERALIZED) && ~obj.isResourceCost
                return
            end
            res=true;
        end

        function res=getTablesDirectory(obj,varargin)
        % Get the tables directory
        %   Input
        %     options - cell array with selected columns
        %
            res=getTablesDirectory(obj.FormatData,varargin{:});
        end

        function res=getTableInfo(obj,name)
            res=getTableInfo(obj.FormatData,name);
        end

        %%%
        % ResultSet Methods
        %%%
        function res=getResultInfo(obj)
        % Get data model result info
            res=obj.ModelInfo;
        end

        function showDataModel(obj,varargin)
        % View a table in a GUI Table
        %   Input:
        %       name - [optional] Name of the table
        %           If is missing all tables are shown in the console
        %       options - TableView option
        %           cType.TableView.CONSOLE
        %           cType.TableView.GUI
        %           cType.TableView.HTML (default)
        %
            showResults(obj,varargin{:})
        end

        function log=saveDataModel(obj,filename)
		% Save data model depending of filename extension
        %   Valid extension are: txt, csv, html, xlsx, json, xml, mat
        %   Input:
        %       filename - name of the file including extension.
        %    
			log=cStatusLogger(cType.VALID);
			% Check inputs
            if (nargin<2) || ~isFilename(filename)
                log.messageLog(cType.ERROR,'Invalid arguments');
            end
			if ~isValid(obj)
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
                    log=saveAsCSV(obj.ModelInfo,filename);
				case cType.FileType.XLSX
                    log=saveAsXLS(obj.ModelInfo,filename);
                case cType.FileType.TXT
                    log=saveAsTXT(obj.ModelInfo,filename);
                case cType.FileType.HTML
                    log=saveAsHTML(obj.ModelInfo,filename);
                case cType.FileType.LaTeX
                    log=saveAsLaTeX(obj.ModelInfo,filename);
                case cType.FileType.MAT
					log=exportMAT(obj,filename);
				otherwise
					log.messageLog(cType.ERROR,'File extension %s is not supported',filename);
            end
            if isValid(log)
				log.messageLog(cType.INFO,'File %s has been saved',filename);
            end
        end
    end

    methods(Access=private)
        function res=getTableModel(obj)
        % Get the cModelTable with the data model tables
            ps=obj.ProductiveStructure;
			% Flows Table
            index=cType.TableDataIndex.FLOWS;
            sheet=cType.TableDataName{index};
            fNames={ps.Flows.key};
            colNames={'key','type'};
            values={ps.Flows.type}';
            tbl=cTableData(values,fNames,colNames);
            tbl.setProperties(sheet,cType.TableDataDescription{index})
			tables.(sheet)=tbl;
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
            tbl=cTableData(values,pNames,colNames);
            tbl.setProperties(sheet,cType.TableDataDescription{index})
			tables.(sheet)=tbl;
            % Exergy Table
            index=cType.TableDataIndex.EXERGY;
            sheet=cType.TableDataName{index};
			colNames=['key',obj.StateNames];			
			values=zeros(obj.NrOfFlows,obj.NrOfStates);
            for i=1:obj.NrOfStates
                rex=obj.getExergyData(i);
				values(:,i)=rex.FlowsExergy';
            end
            tbl=cTableData(num2cell(values),fNames,colNames);
            tbl.setProperties(sheet,cType.TableDataDescription{index})
			tables.(sheet)=tbl;
            % Format Table
            index=cType.TableDataIndex.FORMAT;
            sheet=cType.TableDataName{index};
			fmt=obj.ModelData.Format.definitions;
            rowNames={fmt(:).key};
            val=struct2cell(fmt)';
			tbl=cTableData(val(:,2:end),rowNames,fieldnames(fmt)');
            tbl.setProperties(sheet,cType.TableDataDescription{index})
			tables.(sheet)=tbl;
            % Resources Cost tables
            index=cType.TableDataIndex.RESOURCES;
            sheet=cType.TableDataName{index};
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
				tbl=cTableData(values,rowNames,colNames);
                tbl.setProperties(sheet,cType.TableDataDescription{index})
				tables.(sheet)=tbl;
            end
            % Waste Table
            if (obj.NrOfWastes>0) && obj.isWaste
                wd=obj.WasteData;
                wnames=obj.WasteFlows;
				% Waste Definition
				index=cType.TableDataIndex.WASTEDEF;
                sheet=cType.TableDataName{index};
                rowNames=wnames;
                colNames={'key','type','recycle'};
                values=cell(obj.NrOfWastes,2);
                values(:,1)=wd.Type';
                values(:,2)=num2cell(wd.RecycleRatio)';
				tbl=cTableData(values,rowNames,colNames);
                tbl.setProperties(sheet,cType.TableDataDescription{index})
				tables.(sheet)=tbl;
				% Waste Allocation
                jdx=find(wd.TypeId==0);
                if ~isempty(jdx)
                    index=cType.TableDataIndex.WASTEALLOC;
				    sheet=cType.TableDataName{index};
                    [~,idx]=find(wd.Values);idx=unique(idx);
                    colNames=['key',wnames(jdx)];
                    rowNames=pNames(idx);
                    values=wd.Values(jdx,idx)';
				    tbl=cTableData(num2cell(values),rowNames,colNames);
                    tbl.setProperties(sheet,cType.TableDataDescription{index})
				    tables.(sheet)=tbl;
                end
            end
            res=cResultInfo(obj,tables);
            res.setProperties(obj.ModelName,'DATA_MODEL')
        end
    end
end