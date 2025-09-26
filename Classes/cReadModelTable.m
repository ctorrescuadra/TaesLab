classdef (Abstract) cReadModelTable < cReadModel
%cReadModelTable - Abstract class to read table data model.
%   This class derives cReadModelCSV and cReadmodelXLS
%	
%   See also cReadModel, cReadModelXLS, cReadModelCSV
%
	properties (Access=protected)
		modelTables   % Model Tables
	end

    properties (Access=private)
        ftype   % Flow types
        fkeys   % Flow keys
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
			path=fileparts(mfilename('fullpath'));
			cfgfile=fullfile(path,cType.CFGFILE);
			try		
				config=jsondecode(fileread(cfgfile));
			catch err
				obj.messageLog(cType.ERROR,err.message);
				obj.messageLog(cType.ERROR,cMessages.InvalidConfigFile,cfgfile);
				return
			end
    		res=config.datamodel;
		end

        function res=buildModelData(obj,tm)
        %buildModelData - Build the cModelData from data tables
        %   Input Arguments:
        %     tm - Structure containing the tables
        %   Output Arguments
        %     res - cModelData object
        %
            % Initialize
            res=cMessageLogger();
            sd=struct();
            % Check Model Data
            sd.Format.definitions=tm.Format.getStructData;
            sd.ProductiveStructure=checkProductiveStructure(obj,tm);
            if obj.status
                sd.ExergyStates=checkExergyTable(obj,tm);
                sd.WasteDefinition=checkWasteDefinition(obj,tm);
                sd.ResourcesCost=checkResourcesCost(obj,tm);
                res=cModelData(obj.ModelName,sd);
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
            % Flows table
            ftbl=tm.Flows;
            obj.fkeys=ftbl.Keys;
            if ftbl.status
                res.flows=ftbl.getStructData;
            else
                obj.messageLog(cType.ERROR,cMessages.TableNotFound,'Flows');
                return
            end
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
            ptbl=tm.Processes;
            if ptbl.status
                res.processes=ptbl.getStructData;
            else
                obj.messageLog(cType.ERROR,cMessages.TableNotFound,'Processes');
                return
            end
            % Check Processes types
            cid=find(strcmp(ptbl.Fields,'type'),1);
            if isempty(cid)
                obj.messageLog(cType.ERROR,cMessages.InvalidTable,'Processes');
                return
            end
            types=[ptbl.Data(:,cid)];
            [tst,idx]=cType.checkProcessTypes(types);
            if ~tst
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
            % Check table status
            tbl=tm.Exergy;
            if ~tbl.status
                obj.messageLog(cType.ERROR,cMessages.TableNotFound,'Exergy');
                return
            end
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

        function pswd=checkWasteDefinition(obj,tm)
        %checkWasteDefinition - check WasteDefinition and WasteAllocation tables
        %   Syntax: 
        %     res = obj.checkWasteDefinition(tm)
        %   Input Arguments:
        %     tm - cModelTable structure
        %   Output Arguments:
        %     res - structure array with the waste data 
        %      
            % Check waste tables
            isWasteDefinition=isfield(tm,'WasteDefinition');
            isWasteAllocation=isfield(tm,'WasteAllocation');
            if  isWasteAllocation || isWasteDefinition                
                pswd=obj.WasteData(tm.Flows);
                if isempty(pswd)
                    obj.messageLog(cType.ERROR,cMessages.InvalidTable,'WasteDefinition');
                    return
                end
                wf={pswd.wastes.flow};
                wdef=0;
                % Waste Definition
                if isWasteDefinition
                    tbl=tm.WasteDefinition;
                    wdef=bitset(wdef,1);
                    keys=tbl.Keys;
                    tmp=tbl.getStructData;
                    cid=find(strcmp(tbl.Fields,'type'),1);
                    if isempty(cid)
                        obj.messageLog(cType.ERROR,cMessages.InvalidTable,'WasteDefinition');
                        return
                    end
                    % Check waste types
                    types=[tbl.Data(:,cid)];
                    [tst,idx]=cType.checkWasteTypes(types);
                    if ~tst
                        for i=idx
                            obj.messageLog(cType.ERROR,cMessages.InvalidWasteType,tbl.Keys{i},types{i});
                        end
                    end
                    % Build waste definition data 
                    for i=1:numel(keys)
                        idx=find(strcmp(keys{i},wf),1);
                        if isempty(idx)
                            obj.messageLog(cType.ERROR,cMessages.InvalidWasteKey,keys{i});
                            continue
                        end
                        pswd.wastes(idx).type=tmp(i).type;
                        pswd.wastes(idx).recycle=tmp(i).recycle;
                    end
                end
                % Waste Allocation Table
                if isWasteAllocation
                    tbl=tm.WasteAllocation;
                    % Check Waste Allocation Table
                    keys=tbl.Fields(2:end);
                    processes=tbl.Keys;
                    data=cell2mat(tbl.Data(:,2:end));
                    wdef=bitset(wdef,2);
                    % Build waste allocation data
                    for i=1:numel(keys)
                        idx=find(strcmp(keys{i},wf),1);
                        if isempty(idx)
                            obj.messageLog(cType.ERROR,cMessages.InvalidWasteKey,keys{i});
                            continue
                        end
                        % Fill the waste allocation values
                        try
                            [irow,~,val]=find(data(:,i));
                            nnz=length(irow);
                            if nnz>0
                                tmp=cell(nnz,1);
                                for j=1:nnz
                                    tmp{j}.process=processes{irow(j)};
                                    tmp{j}.value=val(j);
                                end
                                if ~bitget(wdef,1)
                                    pswd.wastes(idx).type='MANUAL';
                                end
                                pswd.wastes(idx).values=cell2mat(tmp');
                            end
                        catch
                            obj.messageLog(cType.ERROR,cMessages.InvalidWasteKey,keys{i});
                            continue
                        end
                    end            
                end
            end
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
            % Get Resources cost definition
            isResourceCost=isfield(tm,'ResourcesCost');
            if isResourceCost
                tbl=tm.ResourcesCost;
                if tbl.status
                    NrOfSamples=tbl.NrOfCols-2;           
                    %Check Types
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
                        for i=ier
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
                    % Buil Resources Cost data
                    res=struct();
                    data=tbl.Data(:,3:end);
                    for i=1:NrOfSamples
                        fvalues=[tbl.Keys(fidx),data(fidx,i)];
                        fs=cell2struct(fvalues,fields,2);
                        res.Samples(i,1).sampleId=samples{i};
                        res.Samples(i,1).flows=fs;
                    end
                    pidx=find(rtype==cType.Resources.PROCESS);
                    if ~isempty(pidx)
                        for i=1:NrOfSamples
                            pvalues=[tbl.Keys(pidx),data(pidx,i)];
                            pr=cell2struct(pvalues,fields,2);
                            res.Samples(i,1).processes=pr;
                        end
                    end
                end
            end
        end
    
        function res=WasteData(obj,tbl)
        %WasteData - Get default waste data info
        %   Syntax:
        %     res = obj.WasteData(tbl)
        %   Input Argument:
        %     tbl - Flows table
        %   Output Argument:
        %     res - struct array containing waste data default info
        %
            res=cType.EMPTY;
            % Search Wastes in Flows Table
            fl=[tbl.Keys];
            rid=find(obj.ftype==cType.Flow.WASTE);
            NR=numel(rid);
            if NR>0           
                wf=[fl(rid)];
                % Build Waste Data Table
                wastes=cell(NR,1);
                for i=1:NR
                    wastes{i}.flow=wf{i};
                    wastes{i}.type='DEFAULT';
                    wastes{i}.recycle=0.0;
                end
                res.wastes=cell2mat(wastes);
            else
                obj.messageLog(cType.ERROR,cMessages.NoWasteFlows);
            end
        end
    end
end