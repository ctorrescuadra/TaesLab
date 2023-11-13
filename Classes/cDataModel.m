classdef cDataModel < cStatusLogger
% cDataModel is the data dispatcher for the thermoeconomic analysis classes.
% It receives the data from the cReadModel interface classes, then validates
% and organizes the information to be used by the calculation algorithms
%   Methods:
%       res=obj.getExergyData(state)
%       res=obj.getResourceData(sample)
%       res=obj.getStateName(i)
%       res=obj.getStateId(state)
%       res=obj.existState(state)
%       res=obj.getResourceSample(i)
%       res=obj.getSampleId(sample)
%       res=obj.existSample(sample)
%       res=obj.getWasteFlows
%       res=obj.checkCostTables
%       res=obj.getTable(name)
%       obj.setModelName(name)   
%       log=obj.saveDataModel(filename)
%   See also cModelTables, cProductiveStructure, cExergyData, cResultTableBuilder, cWasteData, cResourceData
%
    properties(GetAccess=public, SetAccess=private)
        NrOfFlows               % Number of flows
        NrOfProcesses           % Number of processes
        NrOfWastes              % Number of waste flows
        NrOfStates              % Number of exergy data simulations
        NrOfResourceSamples     % Number of resource cost samples
        States                  % State names
        ResourceSamples         % Resource sample names
        ProductiveStructure     % cProductiveStructure object
        FormatData              % cResultTableBuilder object
        ExergyData              % cell array of cExergyData for each state
        WasteData               % cWasteData object
        ResourceData            % call array of cResourceData for each sample
        isWaste                 % Indicate is the model has waste defined
        isResourceCost          % Indicate is the model has resource cost data
        isDiagnosis             % Indicate is the model has information to made diagnosis
        ModelData               % Model data from cReadModel interface
        ModelTables             % Model tables from cReadModel interface
        ModelFile               % Name of the model filename used by the cReadModel interface
        ModelName               % Name of the model
    end

    methods
        function obj = cDataModel(rdm)
        % Creates the cDataModel object
        %   rdm - cReadModel object with the data model
            % Check Data Structure
            obj=obj@cStatusLogger(cType.VALID);
            if ~isa(rdm,'cReadModel') || ~isValid(rdm)
                obj.messageLog(cType.ERROR,'Invalid data model');
                return
            end
            data=rdm.ModelData;
            obj.isWaste=data.isWaste;
            obj.isResourceCost=data.isResourceCost;
            % Check and get Productive Structure
            ps=cProductiveStructure(data.ProductiveStructure);
            status=ps.status;
            if isValid(ps)
				obj.messageLog(cType.INFO,'Productive Structure is valid');
            else
                obj.addLogger(ps);
				obj.messageLog(cType.ERROR,'Productive Structure is NOT valid. See error log');
				return
            end
            obj.ProductiveStructure=ps;
            % Check and get Format
            format=data.Format.definitions;		
            rfmt=cResultTableBuilder(format,obj.ProductiveStructure);
            status = rfmt.status & status;
            if isValid(rfmt)
				obj.messageLog(cType.INFO,'Format Definition is valid');
            else
                obj.addLogger(rfmt);
				obj.messageLog(cType.ERROR,'Format Definition is NOT valid. See error log');
				return
            end
            obj.FormatData=rfmt;
            % Check Exergy
            obj.States={data.ExergyStates.States(:).stateId};
            obj.ExergyData=cell(1,obj.NrOfStates);
            for i=1:obj.NrOfStates
                rex=cExergyData(data.ExergyStates.States(i),ps);
                status = rex.status & status;
                if isValid(rex)
					obj.messageLog(cType.INFO,'Exergy values [%s] are valid',obj.States{i});
				else
					obj.addLogger(rex)
					obj.messageLog(cType.ERROR,'Exergy values [%s] are NOT valid. See Error Log',obj.States{i});
                end
                obj.ExergyData{i}=rex;
            end
            % Check Waste
            if ps.NrOfWastes > 0
                if obj.isWaste
                    tmp=data.WasteDefinition;
                else
                    tmp=ps.WasteData;
                    obj.messageLog(cType.INFO,'Waste Definition is not available. Default is used');
                end
				wd=cWasteData(tmp,ps);
                status=wd.status & status;
                if ~isValid(wd)
	                obj.addLogger(wd);
					obj.messageLog(cType.ERROR,'Waste Definition is NOT valid. See error log');
                elseif obj.isWaste
					obj.messageLog(cType.INFO,'Waste Definition is valid');			
                end
                obj.WasteData=wd;
            else
				obj.messageLog(cType.INFO,'The plant has NOT waste');
            end
            % Check ResourceCost
            if obj.isResourceCost
                obj.ResourceSamples={data.ResourcesCost.Samples(:).sampleId};
                obj.ResourceData=cell(1,obj.NrOfResourceSamples);
                for i=1:obj.NrOfResourceSamples
                    rsc=cResourceData(data.ResourcesCost.Samples(i),ps);
                    status=rsc.status & status;
                    if isValid(rsc)
						obj.messageLog(cType.INFO,'Resources Cost sample [%s] is valid',obj.ResourceSamples{i});
                        obj.ResourceData{i}=rsc;
                    else
						obj.addLogger(rsc);
						obj.messageLog(cType.ERROR,'Resources Cost sample [%s] is NOT valid. See error log',obj.ResourceSamples{i});
                    end
                end
            else
               obj.messageLog(cType.INFO,'No Resources Cost Data available')
            end
            % Check Data Model
            obj.status=status;
            if ~obj.isValid
                return
            end
            % Set object properties
            obj.ModelData=data;
            obj.ModelFile=rdm.ModelFile;
            obj.ModelName=rdm.ModelName;
            if rdm.isTableModel
                obj.ModelTables=rdm.getTableModel;
            else
                obj.ModelTables=obj.getTableModel;
            end
       end

    	function res=get.NrOfFlows(obj)
        % Return the number of flows of the system
            res=0;
            if obj.isValid
                res=obj.ProductiveStructure.NrOfFlows;
            end
        end
    
        function res=get.NrOfProcesses(obj)
        % Return the number of processes of the system
            res=0;
            if obj.isValid
                    res=obj.ProductiveStructure.NrOfProcesses;
            end
        end
    
        function res=get.NrOfWastes(obj)
        % Return the number of wastes of the system
            res=0;
            if obj.isValid
                res=obj.ProductiveStructure.NrOfWastes;
            end
        end
        function res=get.NrOfStates(obj)
        % get the number of states
            res=0;
            if ~isempty(obj.States)
                res=numel(obj.States);
            end
        end
    
        function res=get.NrOfResourceSamples(obj)
        % get the number of resources samples
            res=0;
            if ~isempty(obj.ResourceSamples) && obj.isResourceCost
                res=numel(obj.ResourceSamples);
            end
        end

        function res=get.isDiagnosis(obj)
        % check if diagnosis data is available
			res=(obj.NrOfStates>1);
		end

        function res=getExergyData(obj,state)
        % get the exergy data for a state
        %   Input:
        %       state - state key name
            res=cStatusLogger(cType.ERROR);
            if nargin==1
                idx=1;
            else
                idx=obj.getStateId(state);
            end
            if isempty(idx)
                res.printError('Invalid state %s',state);
            else
                res=obj.ExergyData{idx};
            end
        end

        function log=setExergyData(obj,state,values)
        % Set the exergy data of the state with values
        % If state not exists a new one is creates
        %   Input:
        %       state - Name of the state
        %       values - array with the exergy values of the flows
            log=cStatusLogger(true);
            M=size(values,2);
            % Validate the number of flows
            if obj.NrOfFlows~=M
                log.printError('Invalid number of exergy values',length(values));
                return
            end
            % Create the exergy data structure
            fields={'key','value'};
            keys=obj.ProductiveStructure.FlowKeys;
            tmp=[keys;num2cell(values)];
            est.stateId=state;
            est.exergy=cell2struct(tmp,fields,1);
            % Check and create a cExergyData object
            rex=cExergyData(est,obj.ProductiveStructure);
            if ~isValid(rex)
                log.printError('Invalid exergy data',length(values));
                printLogger(rex);
                return
            end
            % If state exist the exergy data is replaced by values
            % else a new exergy data state is created
            if obj.existState(state)
                idx=obj.getStateId(state);
                obj.ExergyData{idx}=rex;
            else
                ns=obj.NrOfStates+1;
                obj.States{ns}=state;
                obj.ExergyData{ns}=rex;
                obj.NrOfStates=ns;
            end
        end

        function res=getResourceData(obj,sample)
        % Get the resource data for a sample
            res=cStatus(cType.ERROR);
            if nargin==1
                idx=1;
            else
                idx=obj.getSampleId(sample);
            end
            if isempty(idx)
                res.printError('Invalid resource sample %s',sample);
            else
                res=obj.ResourceData{idx};
            end
        end

        function res=getStateName(obj,ind)
		% Return the state name of the corresponding index
		% Input:
		%  ind - state index to retrieve
			res=obj.States{ind};
		end

		function res=getStateId(obj,state)
		% return index of a state
			res=find(strcmp(obj.States,state));
		end
		
		function res=existState(obj,state)
		% determine if state is defined in States
			res=ismember(state,obj.States);
		end

        function res=getResourceSample(obj,ind)
		% Return the state number of the corresponding index
		% Input:
		%  ind - state index to retrieve
			res=obj.ResourceSamples{ind};
		end
		
		function res=getSampleId(obj,sample)
		% Return the state number of the corresponding index
		% Input:
		%  ind - state index to retrieve
			res=find(strcmp(obj.ResourceSamples,sample));
		end
		
		function res=existSample(obj,sample)
		% Determine if sample is defined in ResourceSamples
			res=ismember(sample,obj.ResourceSamples);
        end

        function res=getWasteFlows(obj)
        % Get a cell array of the waste flows
            res={};
            if ~obj.isWaste
                return;
            end
            ps=obj.ProductiveStructure;
            idx=ps.Waste.flows;
            res={ps.Flows(idx).key};
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

        function setModelName(obj,name)
        % Set the name of the data model
            obj.ModelName=name;
        end

        function res=getTable(obj,name)
        % get the model table
            res=getTable(obj.ModelTables,name);
        end
      
		function log=saveDataModel(obj,filename)
		% Save data model depending of filename extension
			log=cStatusLogger(cType.VALID);
			% Check inputs
			if ~isValid(obj)
				log.messageLog(cType.ERROR,'Invalid data model %s',obj.ModelName);
                return
			end
            if ~cType.checkFileWrite(filename)
				log.messageLog(cType.ERROR,'Invalid file name: %s',filename);
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
                    log=saveAsCSV(obj.ModelTables,filename);
				case cType.FileType.XLSX
                    log=saveAsXLS(obj.ModelTables,filename);
				case cType.FileType.MAT
					log=obj.saveAsMAT(filename);
				otherwise
					log.messageLog(cType.WARNING,'File extension %s is not supported',filename);
			end
			if isValid(log)
				log.messageLog(cType.INFO,'File %s has been saved',filename);
			end
        end
    end
    methods(Access=private)
        function log=saveAsMAT(obj,filename)
        % Save the cDataModel as a MAT file
            log=cStatusLogger(cType.VALID);
            if isOctave
				log.messageLog(cType.ERROR,'Save MAT files is not implemented in Octave');
	            return
            end
			if nargin==1 % Default name
                [~,name]=fileparts(obj.ModelFile);
                filename=strcat(name,cType.FileExt.MAT);
			end
			% Determine fullfile
			path=fileparts(filename);
            if isempty(path)
				fname=fullfile(pwd,filesep,filename);
            end
			obj.ModelFile=fname;
            % Save the object
            try
				save(filename,'obj');
			catch err
                log.messageLog(cType.ERROR,err.message);
                log.messageLog(cType.ERROR,'File %s cannot be written',filename);
            end
        end

        function res=getTableModel(obj)
        % Get the cModelTable with the data model tables
            ps=obj.ProductiveStructure;
			% Flows Table
            idx=cType.TableDataIndex.FLOWS;
            sheet=cType.TableDataName{idx};
            fNames={ps.Flows(:).key};
            colNames={'key','type'};
            values={ps.Flows(:).type}';
            tbl=cTableData(values,fNames,colNames);
			tbl.setDescription(idx);
			tables.(sheet)=tbl;
			% Process Table
            idx=cType.TableDataIndex.PROCESSES;
            sheet=cType.TableDataName{idx};
            pNames={ps.Processes(1:end-1).key};
            colNames={'key','fuel','product','type'};
            values=cell(obj.NrOfProcesses,3);
            values(:,1)={ps.Processes(1:end-1).fuel}';
            values(:,2)={ps.Processes(1:end-1).product}';
            values(:,3)={ps.Processes(1:end-1).type}';
            tbl=cTableData(values,pNames,colNames);
			tbl.setDescription(idx);
			tables.(sheet)=tbl;
            % Exergy Table
            idx=cType.TableDataIndex.EXERGY;
            sheet=cType.TableDataName{idx};
			colNames=['key',obj.States];			
			values=zeros(obj.NrOfFlows,obj.NrOfStates);
            for i=1:obj.NrOfStates
                rex=obj.ExergyData{i};
				values(:,i)=rex.FlowsExergy';
            end
            tbl=cTableData(num2cell(values),fNames,colNames);
			tbl.setDescription(idx);
			tables.(sheet)=tbl;
            % Format Table
            idx=cType.TableDataIndex.FORMAT;
            sheet=cType.TableDataName{idx};
			fmt=obj.ModelData.Format.definitions;
            rowNames={fmt(:).key};
            val=struct2cell(fmt)';
			tbl=cTableData(val(:,2:end),rowNames,fieldnames(fmt)');
			tbl.setDescription(idx);
			tables.(sheet)=tbl;
            % Resources Cost tables
            idx=cType.TableDataIndex.RESOURCES;
            sheet=cType.TableDataName{idx};
            if obj.isResourceCost
				colNames=[{'Key','Type'},obj.ResourceSamples];
				%Flows
                fId=ps.Resources.flows;
				rNames=fNames(ps.Resources.flows);
				rTypes=repmat({'FLOW'},numel(rNames),1);
				rval=zeros(ps.NrOfResources,obj.NrOfResourceSamples);
                for i=1:obj.NrOfResourceSamples
                    rsc=obj.ResourceData{i};
					rval(:,i)=rsc.c0(fId)';
                end
				cflow=[rTypes,num2cell(rval)];
				% Processes
				pval=zeros(obj.NrOfProcesses,obj.NrOfResourceSamples);
				pTypes=repmat({'PROCESS'},obj.NrOfProcesses,1);
                for i=1:obj.NrOfResourceSamples
                    rsc=obj.ResourceData{i};
					pval(:,i)=rsc.Z';		            
                end
				cprocess=[pTypes,num2cell(pval)];
                rowNames=[rNames,pNames];
                values=[cflow;cprocess];
				tbl=cTableData(values,rowNames,colNames);
				tbl.setDescription(idx);
				tables.(sheet)=tbl;
            end
            % Waste Table
            if (obj.NrOfWastes>0) && obj.isWaste
                wd=obj.WasteData;
				% Waste Definition
				index=cType.TableDataIndex.WASTEDEF;
                sheet=cType.TableDataName{index};
                rowNames=wd.Flows;
                colNames={'key','type','recycle'};
                values=cell(obj.NrOfWastes,2);
                values(:,1)=wd.Type';
                values(:,2)=num2cell(wd.RecycleRatio)';
				tbl=cTableData(values,rowNames,colNames);
				tbl.setDescription(index);
				tables.(sheet)=tbl;
				% Waste Allocation
                jdx=find(wd.TypeId==0);
                if ~isempty(jdx)
                    index=cType.TableDataIndex.WASTEALLOC;
				    sheet=cType.TableDataName{index};
                    [~,idx]=find(wd.Values);idx=unique(idx);
                    colNames=['key',wd.Flows(jdx)];
                    rowNames=pNames(idx);
                    values=wd.Values(jdx,idx)';
				    tbl=cTableData(num2cell(values),rowNames,colNames);
				    tbl.setDescription(index);
				    tables.(sheet)=tbl;
                end
            end
		    info=cResultId(cType.ResultId.DATA_MODEL);
            res=cResultInfo(info,tables);
            res.setProperties(obj.ModelName,'DATA_MODEL')
        end
    end
end