classdef (Abstract) cReadModelTable < cReadModel
% cReadModelTable Abstract class to read table data model
%   This class derives cReadModelCSV and cReadmodelXLS
%   Methods:
%		res=obj.buildDataModel(tm)
%		res=obj.getTableModel
%	Methods inhereted from cReadModel
%		res=obj.getStateName(id)
%		res=obj.getStateId(name)
%   	res=obj.existState()
%   	res=obj.getResourceSample(id)
%   	res=obj.getSampleId(sample)
%		res=obj.existSample(sample)
%	    res=obj.getWasteFlows;
%		res=obj.checkModel;
%   	log=obj.saveAsMAT(filename)
%   	log=obj.saveDataModel(filename)
%   	res=obj.readExergy(state)
%   	res=obj.readResources(sample)
%   	res=obj.readWaste
%   	res=obj.readFormat
%	See also cReadModel, cReadModelXLS, cReadModelCSV
%
	properties (Access=protected)
		Tables
	end
    methods
        function res=getTableModel(obj)
        % get the cModelTables object with the data model tables
            res=obj.Tables;
        end
    end

	methods (Access=protected)  
        function buildDataModel(obj,tm)
        % Build cDataModel and cProductiveStructure from cModelTable object
        %   Input:
        %   tm - cModelTables object
            obj.status=cType.VALID;
            tmp=struct();
            % Productive Structure Tables
            ftbl=getTable(tm,cType.InputTables.FLOWS);
            if isValid(ftbl)
                tmp.flows=ftbl.getStructData;
            else
                obj.messageLog(cType.ERROR,'Table %s NOT found',cType.InputTables.FLOWS);
                return
            end
            ptbl=getTable(tm,cType.InputTables.PROCESSES);
            if isValid(ptbl)
                tmp.processes=ptbl.getStructData;
            else
                obj.messageLog(cType.ERROR,'Table %s NOT found',cType.InputTables.PROCESSES);
                return
            end
            % Get Productive Structure
            ps=cProductiveStructure(tmp);
            if ~isValid(ps)
                obj.addLogger(ps);
                return
            end
            dm.ProductiveStructure=tmp;
            obj.status=ps.status;
            % Get Exergy states data
            tbl=getTable(tm,cType.InputTables.EXERGY);
            if ~isValid(tbl)
                obj.messageLog(cType.ERROR,'Table %s NOT found',cType.InputTables.EXERGY);
                return
            end
            NrOfStates=tbl.NrOfCols-1;
            if NrOfStates<1
                obj.messageLog(cType.ERROR,'Invalid number of states')
                return
            end
            if ~isNumCellArray(tbl.Data)
                obj.messageLog(cType.ERROR,'Invalid Exergy table');
                return
            end
            tmp=struct();
            fields={'key','value'};
            states=tbl.ColNames(2:end);
            for i=1:NrOfStates
                st.stateId=states{i};
                values=[tbl.RowNames',tbl.Data(:,i)];
                st.exergy=cell2struct(values,fields,2);
                tmp.States(i,1)=st;
            end
            dm.ExergyStates=tmp;
            % Get Waste definition
            isWasteDefinition=existTable(tm,cType.InputTables.WASTEDEF);
            isWasteAllocation=existTable(tm,cType.InputTables.WASTEALLOC);
            pswd=obj.WasteData; %Get default waste data
            if ~isempty(pswd)
                pswd=ps.WasteData;
                wf={pswd.wastes.flow};
                wdef=0;
                % Waste Definition
                if isWasteDefinition
                    tbl=getTable(tm,cType.InputTables.WASTEDEF);
                    if (tbl.NrOfCols<2)
                        obj.messageLog(cType.ERROR,'Waste Table. Invalid number of columns');
                        return
                    end
                    wdef=bitset(wdef,1);
                    keys=tbl.RowNames;
                    tmp=tbl.getStructData;
                    if ~isfield(tmp,'type')
                        obj.messageLog(cType.ERROR,'Waste Table. Type column missing');
                        return
                    end
                    % Build waste definition data 
                    for i=1:numel(keys)
                        idx=find(strcmp(keys{i},wf),1);
                        if isempty(idx)
                            obj.messageLog(cType.ERROR,'Waste Table. Invalid waste flow %s',keys{i});
                            continue
                        end
                        pswd.wastes(idx).type=tmp(i).type;
                        if isfield(tmp,'recycle') && isnumeric(tmp(i).recycle)
                            pswd.wastes(idx).recycle=tmp(i).recycle;
                        end
                    end
                end
                % Waste Allocation Table
                if isWasteAllocation
                    tbl=getTable(tm,cType.InputTables.WASTEALLOC);
                    NR=tbl.NrOfCols-1;
                    % Check Waste Allocation Table
                    if NR<1
                        obj.messageLog(cType.ERROR,'Invalid Waste Allocation table');
                        return
                    end
                    if ~isNumCellArray(tbl.Data)
                        obj.messageLog(cType.ERROR,'Invalid WasteAllocation table');
                    end
                    keys=tbl.ColNames(2:end);
                    processes=tbl.RowNames;
                    wdef=bitset(wdef,2);
                    % Build waste allocation data
                    for i=1:numel(keys)
                        idx=find(strcmp(keys{i},wf),1);
                        if isempty(idx)
                            obj.messageLog(cType.ERROR,'Waste Table. Invalid waste flow %s',keys{i});
                            continue
                        end
                        try
                            wt=cell2mat(tbl.Data(:,i));
                            [irow,~,val]=find(wt);
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
                            obj.messageLog(cType.ERROR,'Invalid waste allocation values for %s',keys{i});
                            return
                        end
                    end            
                end
                dm.WasteDefinition=pswd;
            end        
            % Get Format definition
            if existTable(tm,cType.InputTables.FORMAT)
                tbl=getTable(tm,cType.InputTables.FORMAT);
                if ~isNumCellArray(tbl.Data(:,1:2))
                    obj.messageLog(cType.ERROR,'Invalid Format table');
                end
                dm.Format.definitions=tbl.getStructData;
            end                        
            % Get Resources cost definition
            if existTable(tm,cType.InputTables.RESOURCES)
                tbl=getTable(tm,cType.InputTables.RESOURCES);
                NrOfSamples=tbl.NrOfCols-2;
                % Check ResourcesCost Table
                if NrOfSamples<1
                    obj.messageLog(cType.WARNING,'Invalid Resources Cost Definition');
                    return
                end
                if ~isNumCellArray(tbl.Data(:,2:end))
                    obj.messageLog(cType.ERROR,'Invalid Resources Cost Definition');
                end
                samples=tbl.ColNames(3:end);
                fields={'key','value'};
                idx=cellfun(@(x) cType.getResourcesId(x),tbl.Data(:,1));
                fidx=find(idx==cType.Resources.FLOW);
                if isempty(fidx)
                    obj.messageLog(cType.WARNING,'No Resources flows cost defined');
                    return
                end
                % Buil Resources Cost data
                tmp=struct();
                for i=1:NrOfSamples
                    fvalues=[tbl.RowNames(fidx)',tbl.Data(fidx,i+1)];
                    fs=cell2struct(fvalues,fields,2);
                    tmp.Samples(i,1).sampleId=samples{i};
                    tmp.Samples(i,1).flows=fs;
                end
                pidx=find(idx==cType.Resources.PROCESS);
                if ~isempty(pidx)
                    for i=1:NrOfSamples
                        pvalues=[tbl.RowNames(pidx)',tbl.Data(pidx,i+1)];
                        pr=cell2struct(pvalues,fields,2);
                        tmp.Samples(i,1).processes=pr;
                    end
                end
                dm.ResourcesCost=tmp;
            end
            % Add ModelData and ProductiveStructure to the object
            if obj.isValid
                obj.ModelData=cModelData(dm);
                obj.ProductiveStructure=ps;
            end
        end
    end
    methods(Access=private)
        function res=WasteData(obj)
        % Get default waste data info
            res=[];
            % Search Wastes in Flows Table
            tm=obj.getTableModel;
            ft=tm.Tables.Flows;
            fl=[ft.RowNames];
            fields=[ft.ColNames(2:end)];
            cid=find(strcmp(fields,'type'),1);
            if isempty(cid)
                obj.messageLog(cType.ERROR,'Invalid Flows Table. Type Column NOT defined');
                return
            end
            types=[ft.Data(:,cid)];
            rid=find(strcmp(types,'WASTE'));
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
            end
        end
    end
end