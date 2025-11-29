classdef (Abstract) cReadModelTable < cReadModel
%cReadModelTable - Abstract class to read table data model.
%   It implements the common properties and methods of the model reader
%   based on tables. The data model configuration is stored in the file
%   printconfig.json, located in the Classes folder.
%   The data from tables is stored in cModelTable objects, which are stored
%   in the ModelTables property as a structure. Each table is identified by
%   its name. The model is built from the data stored in these tables.
%   Derived classes: cReadModelCSV and cReadmodelXLS.
%   It is derived from cReadModel.
%
%   cReadModelTable methods:
%     getDataModelConfig - Get data model configuration
%     buildModelData     - Build the cModelData from data tables
%     printModelTables   - Show the model tables on console
%
%   See also cReadModel, cReadModelXLS, cReadModelCSV
%
	properties (Access=public)
		ModelTables   % Model Tables
	end

    properties (Access=private)
        ftype   % Flow types
        fkeys   % Flow keys
        ptype   % Process types
        pkeys   % Processes keys
    end

    methods
        function printModelTables(obj)
        %printModelTables - Show the model tables on console
        %   Syntax:
        %     printModelTables(obj)
        %
            cellfun(@(x) printTable(x),struct2cell(obj.ModelTables));
        end
    end

	methods (Access=protected)
        function res=getDataModelConfig(obj)
        %getDataModelConfig - Get data model configuration
        %   Syntax:
        %     res =obj.getDataModelConf();
        %   Output Arguments:
        %     res - struct array containing the data model configuration
        %
            res=cType.EMPTY;
			cfgfile=fullfile(cType.ClassesPath,cType.CFGFILE);
            config=importJSON(obj,cfgfile);
            if isempty(config)
                return
            end
    		res=config.datamodel;
		end

        function res=buildModelData(obj,tm)
        %buildModelData - Build the cModelData from data tables
        %   Syntax:
        %     res = obj.buildModelData(tm)
        %   Input Arguments:
        %     tm - Structure containing the cModelTable objects
        %   Output Arguments:
        %     res - cModelData object
        %
            res=cMessageLogger();
            % Check input
            if ~isstruct(tm) || isempty(fieldnames(tm))
                obj.messageLog(cType.ERROR,cMessages.InvalidModelTables);
                return
            end
            % Check and build Model Data
            sd=struct();
            sd.Format.definitions=tm.Format.getStructData;
            sd.ProductiveStructure=checkProductiveStructure(obj,tm);
            if obj.status
                sd.ExergyStates=checkExergyTable(obj,tm);
                sd.WasteDefinition=checkWasteDefinition(obj,tm);
                sd.ResourcesCost=checkResourcesCost(obj,tm);
                res=cModelData(obj.ModelName,sd);
                res.addLogger(obj);
            end
        end
    end

    methods(Access=private)
        function res=checkProductiveStructure(obj,tm)
        %checkProductiveStructure - check productive structure tables
        %   Syntax:
        %     res = obj.checkProductiveStructure(tm)
        %   Input Arguments:
        %     tm - cModelTable structure
        %   Output Arguments:
        %     res - structure with the flows and process tables
        %
            res=cType.EMPTY;
            % Flows table
            if ~isfield(tm,'Flows') || ~isValid(tm.Flows)
                obj.messageLog(cType.ERROR,cMessages.TableNotFound,'Flows');
                return
            end
            ftbl=tm.Flows;
            obj.fkeys=ftbl.Keys;
            res.flows=ftbl.getStructData;
            % Check Flows types
            cid=find(strcmp(ftbl.Fields,'type'),1);
            if isempty(cid)
                obj.messageLog(cType.ERROR,cMessages.InvalidTable,'Flows');
                return
            end
            types=[ftbl.Data(:,cid)];
            [tst,idx]=cType.checkFlowTypes(types);
            if tst
                obj.ftype=idx;
            else
                for i=idx    
                    obj.messageLog(cType.ERROR,cMessages.InvalidFlowType,ftbl.Keys{i},types{i});
                end
            end
            % Processes table
            if ~isfield(tm,'Processes') || ~isValid(tm.Processes)
                obj.messageLog(cType.ERROR,cMessages.TableNotFound,'Processes');
                return
            end
            ptbl=tm.Processes;
            obj.pkeys=ptbl.Keys;
            res.processes=ptbl.getStructData;
            % Check Processes types
            cid=find(strcmp(ptbl.Fields,'type'),1);
            if isempty(cid)
                obj.messageLog(cType.ERROR,cMessages.InvalidTable,'Processes');
                return
            end
            types=[ptbl.Data(:,cid)];
            [tst,idx]=cType.checkProcessTypes(types);
            if tst
                obj.ptype=idx;
            else
                for i=idx               
                    obj.messageLog(cType.ERROR,cMessages.InvalidProcessType,ptbl.Keys{i},types{i});
                end
            end
        end

        function res=checkExergyTable(obj,tm)
        %checkExergyData - check Exergy table
        %   Syntax: 
        %     res = obj.checkExergyTable(tm)
        %   Input Arguments:
        %     tm - cModelTable structure
        %   Output Arguments:
        %     res - structure array with the exergy states
        %
            res=cType.EMPTY;
            % Check table status
            if ~isfield(tm,'Exergy') || ~isValid(tm.Exergy)
                obj.messageLog(cType.ERROR,cMessages.TableNotFound,'Exergy');
                return
            end
            tbl=tm.Exergy;
            % Check keys against flow keys
            if ~isequal(tbl.Keys,obj.fkeys)
                obj.messageLog(cType.ERROR,cMessages.InvalidExergyKeys);
                return
            end
            % Build exergy states structure
            NrOfStates=tbl.NrOfCols-1;
            res=struct();
            fields=cType.KEYVAL;
            data=tbl.Data(:,2:end);
            states=tbl.Fields(2:end);
            for i=1:NrOfStates
                st.stateId=states{i};
                values=[tbl.Keys,data(:,i)];
                st.exergy=cell2struct(values,fields,2);
                res.States(i,1)=st;
            end
        end

        function res=checkWasteDefinition(obj,tm)
        %checkWasteDefinition - check WasteDefinition and WasteAllocation tables
        %   Syntax: 
        %     res = obj.checkWasteDefinition(tm)
        %   Input Arguments:
        %     tm - cModelTable structure
        %   Output Arguments:
        %     res - structure array with the waste data 
        %                 
            res=cType.EMPTY;
            % Check if the model has waste flows
            rid=find(obj.ftype==cType.Flow.WASTE);
            if isempty(rid)
                obj.messageLog(cType.INFO,cMessages.NoWasteModel);
                return
            end
            % Get the default waste definition
            wf=obj.fkeys(rid);
            pswd=struct('flow',wf,...
                    'type',cType.DEFAULT_WASTE_ALLOCATION,...
                    'recycle',0.0);
            % Read Waste Definition table
            wdef=0;
            if isfield(tm,'WasteDefinition') && isValid(tm.WasteDefinition)
                tbl=tm.WasteDefinition;
                cid=find(strcmp(tbl.Fields,'type'));
                if isempty(cid)
                    obj.messageLog(cType.ERROR,cMessages.InvalidTable,'WasteDefinition');
                    return
                end
                wdef=bitset(wdef,1);
                keys=tbl.Keys;
                tmp=tbl.getStructData;
                % Check waste types
                types=[tbl.Data(:,cid)];
                [tst,ier]=cType.checkWasteTypes(types);
                if tst
                    for i=1:numel(keys)
                        id=find(strcmp(keys{i},wf));
                        if isempty(id)
                            obj.messageLog(cType.ERROR,cMessages.InvalidWasteKey,keys{i});
                            continue
                        end
                        pswd(id).type=tmp(i).type;
                        pswd(id).recycle=tmp(i).recycle;
                    end
                    wtypes=ier;
                else
                    for i=ier
                        obj.messageLog(cType.ERROR,cMessages.InvalidWasteType,types{i},tbl.Keys{i});
                    end
                end
            end
            % Waste Allocation Table
            if isfield(tm,'WasteAllocation') && isValid(tm.WasteAllocation)
                tbl=tm.WasteAllocation;
                % Check Allocation processes
                processes=tbl.Keys;
                [tst,idx]=ismember(processes,obj.pkeys);
                if ~all(tst) 
                    ier=find(~tst);
                    for i=ier
                        obj.messageLog(cType.ERROR,cMessages.InvalidProcessTableKey,processes{i},tbl.Name);
                    end
                    return
                end
                % Procsses to allocate waste must be productive
                ier=find(obj.ptype(idx)==cType.Process.DISSIPATIVE);
                if ~isempty(ier)
                    for i=ier
                        obj.messageLog(cType.ERROR,cMessages.InvalidAllocationProcess,processes{i});
                    end
                    return
                end
                wkeys=tbl.Fields(2:end);
                data=cell2mat(tbl.Data(:,2:end));
                wdef=bitset(wdef,2);
                % Build waste allocation data
                for j=1:numel(wkeys)
                    idx=find(strcmp(wkeys{j},wf),1);
                    if isempty(idx)
                        obj.messageLog(cType.ERROR,cMessages.InvalidWasteKey,wkeys{j});
                        continue
                    end
                    % Fill the waste allocation values
                    try
                        [irow,~,val]=find(data(:,j));
                        nnz=length(irow);
                        if nnz>0
                            tmp=cell(1,nnz);
                            for k=1:nnz
                                tmp{k}.process=processes{irow(k)};
                                tmp{k}.value=val(k);
                            end
                            if ~bitget(wdef,1)
                                pswd(idx).type='MANUAL';
                            end
                            pswd(idx).values=cell2mat(tmp);
                        end
                    catch
                        obj.messageLog(cType.ERROR,cMessages.InvalidWasteKey,keys{j});
                        continue
                    end
                end
            elseif bitget(wdef,1) && ~all(wtypes)
                obj.messageLog(cType.ERROR,cMessages.InvalidManualAllocation);
            end
            res.wastes=pswd;
        end
        
        function res=checkResourcesCost(obj,tm)
        %checkResourcesCost - Check resources cost table
        %   Syntax: 
        %     res = obj.checkResourcesCost(tm)
        %   Input Arguments:
        %     tm - cModelTable structure
        %   Output Arguments:
        %     res - structure array with the resource cost data
        %     
            res=cType.EMPTY;
            if ~isfield(tm,'ResourcesCost') || ~isValid(tm.ResourcesCost)
                return
            end
            tbl=tm.ResourcesCost;
            NrOfSamples=tbl.NrOfCols-2;           
            %Check Table
            if NrOfSamples<1
                obj.messageLog(cType.ERROR,cMessages.InvalidTable,'ResourceCost');
                return
            end
            cid=find(strcmp(tbl.Fields,'type'),1);
            if isempty(cid)
                obj.messageLog(cType.ERROR,cMessages.InvalidTable,'ResourceCost');
                return
            end
            types=tbl.Data(:,cid);
            [tst,idx]=cType.checkResourceTypes(types);
            if tst
                rtype=idx;
            else
                for i=idx
                    obj.messageLog(cType.ERROR,cMessages.InvalidResourcesType,tbl.Keys{i},types{i});
                end
            end
            % Check if there is resources flows
            samples=tbl.Fields(3:end);
            fields=cType.KEYVAL;
            fidx=find(rtype==cType.Resources.FLOW);
            if isempty(fidx)
                obj.messageLog(cType.ERROR,cMessages.InvalidTable,'ResourcesCost');
                return
            end
            % Check resource flows keys
            flows=tbl.Keys(fidx);
            tf=ismember(flows,obj.fkeys);
            if ~all(tf)
                ier=find(~tf);
                for i=ier
                    obj.messageLog(cType.ERROR,cMessages.InvalidFlowTableKey,flows{i},tbl.Name);
                end
            end
            % Buil Flow Resources Cost data
            res=struct();
            data=tbl.Data(:,3:end);
            for i=1:NrOfSamples
                fvalues=[tbl.Keys(fidx),data(fidx,i)];
                fs=cell2struct(fvalues,fields,2);
                res.Samples(i,1).sampleId=samples{i};
                res.Samples(i,1).flows=fs;
            end
            % Process Resources
            pidx=find(rtype==cType.Resources.PROCESS);
            if ~isempty(pidx)
            % Check Table Keys
                processes=tbl.Keys(pidx);
                tf=ismember(processes,obj.pkeys);
                if ~all(tf)
                    ier=find(~tf);
                    for i=ier
                        obj.messageLog(cType.ERROR,cMessages.InvalidProcessTableKey,processes{i},tbl.Name);
                    end
                end
                % get sample values
                for i=1:NrOfSamples
                    pvalues=[tbl.Keys(pidx),data(pidx,i)];
                    pr=cell2struct(pvalues,fields,2);
                    res.Samples(i,1).processes=pr;
                end
            end
        end
    end
end