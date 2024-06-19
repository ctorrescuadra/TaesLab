classdef cDataModel < cResultSet
% cDataModel is the data dispatcher for the thermoeconomic analysis classes.
% It receives the data from the cReadModel interface classes, then validates
% and organizes the information to be used by the calculation algorithms
%   Methods:
%       res=obj.getExergyData(state)
%       log=obj.setExergyData(state,values)
%       res=obj.getResourceData(sample)
%       res=obj.getStateNames(i)
%       res=obj.getStateId(state)
%       res=obj.existState(state)
%       res=obj.getSampleNames(i)
%       res=obj.getSampleId(sample)
%       res=obj.existSample(sample)
%       res=obj.getWasteFlows
%       res=obj.getWasteNames
%       res=obj.checkCostTables
%       res=obj.getResultInfo
%       obj.printResults
%       obj.showResults(name,options)
%       res=obj.getTable(name,options)
%       res=obj.getTableIndex(options)
%       obj.showTableIndex(options)
%       obj.saveResults(filename)
%       obj.saveTable(name,filename)
%       obj.showDataModel(name,option)
%       log=obj.saveDataModel(filename)
%       res=obj.getTablesDirectory;
%       obj.showTablesDirectory(option)  
%       log=obj.saveTablesDirectory(filename)
%       
%   See also cResultSet, cProductiveStructure, cExergyData, cResultTableBuilder, cWasteData, cResourceData
%
    properties(GetAccess=public, SetAccess=private)
        NrOfFlows               % Number of flows
        NrOfProcesses           % Number of processes
        NrOfWastes              % Number of waste flows
        NrOfStates              % Number of exergy data simulations
        NrOfResourceSamples     % Number of resource cost samples
        States                  % States list
        ResourceSamples         % Resource samples list
        ProductiveStructure     % cProductiveStructure object
        FormatData              % cResultTableBuilder object
        ExergyData              % cell array of cExergyData for each state
        WasteData               % cWasteData object
        ResourceData            % call array of cResourceData for each sample
        isWaste                 % Indicate is the model has waste defined
        isResourceCost          % Indicate is the model has resource cost data
        isDiagnosis             % Indicate is the model has information to made diagnosis
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
            obj.ProductiveStructure=ps;
            status=ps.status;
            if isValid(ps)
				obj.messageLog(cType.INFO,'Productive Structure is valid');
            else
                obj.addLogger(ps);
				obj.messageLog(cType.ERROR,'Productive Structure is NOT valid. See error log');
                return
            end
            % Check and get Format	
            rfmt=cResultTableBuilder(dm,ps);
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
            list={dm.ExergyStates.States(:).stateId};
            tmp=cSetList(list);
            if isValid(tmp)
                obj.States=tmp;
            else
                obj.messageLog(cType.ERROR,'Invalid states list');
                return
            end
            obj.ExergyData=cell(1,obj.NrOfStates);
            for i=1:obj.NrOfStates
                rex=cExergyData(dm,ps,i);
                status = rex.status & status;
                if isValid(rex)
					obj.messageLog(cType.INFO,'Exergy values [%s] are valid',obj.getStateNames(i));
				else
					obj.addLogger(rex)
					obj.messageLog(cType.ERROR,'Exergy values [%s] are NOT valid. See Error Log',obj.getStateNames(i));
                end
                obj.ExergyData{i}=rex;
            end
            % Check Waste
            if ps.NrOfWastes > 0
                wd=cWasteData(dm,ps);
                status=wd.status & status;
                obj.addLogger(wd);
                if ~isValid(wd)
					obj.messageLog(cType.ERROR,'Waste Definition is NOT valid. See error log');
                elseif dm.isWaste
					obj.messageLog(cType.INFO,'Waste Definition is valid');	
                end
                obj.WasteData=wd;
                obj.isWaste=true;	
            else
				obj.messageLog(cType.INFO,'The plant has NOT waste');
            end
            % Check ResourceCost
            if obj.isResourceCost
                list={dm.ResourcesCost.Samples(:).sampleId};
                tmp=cSetList(list);
                if isValid(tmp)
                    obj.ResourceSamples=tmp;
                else
                    obj.messageLog(cType.ERROR,'Invalid resource samples list');
                    return
                end
                obj.ResourceData=cell(1,obj.NrOfResourceSamples);
                for i=1:obj.NrOfResourceSamples
                    rsc=cResourceData(dm,ps,i);
                    status=rsc.status & status;
                    if isValid(rsc)
						obj.messageLog(cType.INFO,'Resources Cost sample [%s] is valid',obj.getSampleNames(i));
                        obj.ResourceData{i}=rsc;
                    else
						obj.addLogger(rsc);
						obj.messageLog(cType.ERROR,'Resources Cost sample [%s] is NOT valid. See error log',obj.getSampleNames(i));
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
            if isValid(obj.States)
                res=numel(obj.States);
            end
        end
    
        function res=get.NrOfResourceSamples(obj)
        % Get the number of resources samples
            res=0;
            if ~isempty(obj.ResourceSamples) && obj.isResourceCost
                res=numel(obj.ResourceSamples);
            end
        end

        function res=get.isDiagnosis(obj)
        % Check if diagnosis data is available
			res=(obj.NrOfStates>1);
        end
        
        %%%
        % Get Data model information
        %%%
        function res=getExergyData(obj,state)
        % get the exergy data for a state
        %   Input:
        %       state - state key name
            res=cStatus();
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
            log=cStatus();
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
                obj.States.setValue(ns,state);
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

        function res=getStateNames(obj,varargin)
		% Return the state name of the corresponding index
		% Input:
		%  ind - state index to retrieve
			res=obj.States.Values(varargin{:});
		end

		function res=getStateId(obj,state)
		% return index of a state
			res=obj.States.getIndex(state);
		end
		
		function res=existState(obj,state)
		% determine if state is defined in States
			res=obj.States.existValue(state);
        end

        function res=getSampleNames(obj,varargin)
		% Return the state number of the corresponding index
		% Input:
		%  ind - state index to retrieve
			res=obj.ResourceSamples.Values(varargin{:});
		end
		
		function res=getSampleId(obj,sample)
		% Return the state number of the corresponding index
		% Input:
		%  ind - state index to retrieve
			res=obj.ResourceSamples.getIndex(sample);
		end
		
		function res=existSample(obj,sample)
		% Determine if sample is defined in ResourceSamples
			res=obj.ResourceSamples.existValue(sample);
        end
 
        function res=getWasteNames(obj,varargin)
            res=obj.WasteData.Flows.Values(varargin{:});
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

        %%%
        % Gat data model tables
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
            if nargin<2
                log.messageLog(cType.ERROR,'Invalid number of arguments');
            end
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

        %%%
        % Tables Directory functions
        %%%
        function res=getTablesDirectory(obj,varargin)
        % Get the Tables directory object
        %   Input:
        %       options - VarMode options.
        %           cType.VarMode.NONE (default) as cTable
        %           cType.VarMode.CELL as cell array
        %           cType.VarMode.STRUCT as struct array
        %           cType.VarMode.TABLE as Matlab table
        %
            res=getTablesDirectory(obj.FormatData,varargin{:});
        end

        function showTablesDirectory(obj,varargin)
        % View the Tables directory
        %   Input:
        %       options - TableView option
        %
            showTablesDirectory(obj.FormatData,varargin{:});
        end

        function saveTablesDirectory(obj,filename)
        % Save Tables directory in a file depending the extension
        %   Valid extension are: txt, csv, html, xlsx, json, xml, mat
        %   Input:
        %       filename - name of the file including extension.
        %    
            saveTablesDirectory(obj.FormatData,filename);
        end
    end

    methods(Access=private)
        function res=getTableModel(obj)
        % Get the cModelTable with the data model tables
            ps=obj.ProductiveStructure;
			% Flows Table
            index=cType.TableDataIndex.FLOWS;
            sheet=cType.TableDataName{index};
            fNames={ps.Flows(:).key};
            colNames={'key','type'};
            values={ps.Flows(:).type}';
            tbl=cTableData(values,fNames,colNames);
            tbl.setProperties(sheet,cType.TableDataDescription{index})
			tables.(sheet)=tbl;
			% Process Table
            index=cType.TableDataIndex.PROCESSES;
            sheet=cType.TableDataName{index};
            pNames={ps.Processes(1:end-1).key};
            colNames={'key','fuel','product','type'};
            values=cell(obj.NrOfProcesses,3);
            values(:,1)={ps.Processes(1:end-1).fuel}';
            values(:,2)={ps.Processes(1:end-1).product}';
            values(:,3)={ps.Processes(1:end-1).type}';
            tbl=cTableData(values,pNames,colNames);
            tbl.setProperties(sheet,cType.TableDataDescription{index})
			tables.(sheet)=tbl;
            % Exergy Table
            index=cType.TableDataIndex.EXERGY;
            sheet=cType.TableDataName{index};
			colNames=['key',obj.getStateNames];			
			values=zeros(obj.NrOfFlows,obj.NrOfStates);
            for i=1:obj.NrOfStates
                rex=obj.ExergyData{i};
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
				colNames=[{'Key','Type'},obj.getSampleNames];
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
                tbl.setProperties(sheet,cType.TableDataDescription{index})
				tables.(sheet)=tbl;
            end
            % Waste Table
            if (obj.NrOfWastes>0) && obj.isWaste
                wd=obj.WasteData;
                wnames=obj.getWasteNames;
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