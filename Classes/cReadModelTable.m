classdef (Abstract) cReadModelTable < cReadModel
% cReadModelTable Abstract class to read table data model
%   This class derives cReadModelCSV and cReadmodelXLS
%   Methods:
%		res=obj.getTableModel
%	See also cReadModel, cReadModelXLS, cReadModelCSV
%
	properties (Access=protected)
		modelTables
	end
    methods
        function res=getTableModel(obj)
        % get the cResultInfo object with the data model tables
            res=obj.modelTables;
        end
    end

	methods (Access=protected)  
        function res=buildDataModel(obj,tm)
        % Build cDataModel and cProductiveStructure from cModelTable object
        %   Input:
        %   tm - cResultInfo object (DATA_MODEL)
        %   res - DataModel structure
            res=[];
            tmp.name=obj.ModelName;
            % Productive Structure Tables
            ftbl=tm.Flows;
            if isValid(ftbl)
                tmp.flows=ftbl.getStructData;
            else
                obj.messageLog(cType.ERROR,'Table Flows NOT found');
                return
            end
            ptbl=tm.Processes;
            if isValid(ptbl)
                tmp.processes=ptbl.getStructData;
            else
                obj.messageLog(cType.ERROR,'Table Processes NOT found');
                return
            end
            res.ProductiveStructure=tmp;
            % Get Format definition
            tbl=tm.Format;
            if isValid(tbl)  
                if ~tbl.isNumericColumn(1:2)
                    obj.messageLog(cType.ERROR,'Invalid format table');
                end
                res.Format.definitions=tbl.getStructData;
            else
                obj.messageLog(cType.ERROR,'Table Format NOT found');
                return
            end
            % Get Exergy states data
            tbl=tm.Exergy;
            if ~isValid(tbl)
                obj.messageLog(cType.ERROR,'Table Exergy NOT found');
                return
            end
            NrOfStates=tbl.NrOfCols-1;
            if NrOfStates<1
                obj.messageLog(cType.ERROR,'Invalid number of states')
                return
            end
            if ~tbl.isNumericTable
                obj.messageLog(cType.ERROR,'Invalid exergy table');
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
            res.ExergyStates=tmp;
            % Get Waste definition
            isWasteDefinition=isfield(tm,'WasteDefinition');
            isWasteAllocation=isfield(tm,'WasteAllocation');
            if  isWasteAllocation || isWasteDefinition
                pswd=obj.WasteData(tm);
                if isempty(pswd)
                    return
                end
                wf={pswd.wastes.flow};
                wdef=0;
                % Waste Definition
                if isWasteDefinition
                    tbl=tm.WasteDefinition;
                    if (tbl.NrOfCols<2)
                        obj.messageLog(cType.ERROR,'Waste table. Invalid number of columns');
                        return
                    end
                    wdef=bitset(wdef,1);
                    keys=tbl.RowNames;
                    tmp=tbl.getStructData;
                    if ~isfield(tmp,'type')
                        obj.messageLog(cType.ERROR,'Waste table. Type column missing');
                        return
                    end
                    % Build waste definition data 
                    for i=1:numel(keys)
                        idx=find(strcmp(keys{i},wf),1);
                        if isempty(idx)
                            obj.messageLog(cType.ERROR,'Waste table. Invalid waste flow %s',keys{i});
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
                    tbl=tm.WasteAllocation;
                    NR=tbl.NrOfCols-1;
                    % Check Waste Allocation Table
                    if (NR<1) || ~tbl.isNumericTable
                        obj.messageLog(cType.ERROR,'Invalid waste allocation table');
                        return
                    end
                    keys=tbl.ColNames(2:end);
                    processes=tbl.RowNames;
                    wdef=bitset(wdef,2);
                    % Build waste allocation data
                    for i=1:numel(keys)
                        idx=find(strcmp(keys{i},wf),1);
                        if isempty(idx)
                            obj.messageLog(cType.ERROR,'Waste table. Invalid waste flow %s',keys{i});
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
                res.WasteDefinition=pswd;
            end                               
            % Get Resources cost definition
            isResourceCost=isfield(tm,'ResourcesCost');
            if isResourceCost
                tbl=tm.ResourcesCost;
                if isValid(tbl)
                    NrOfSamples=tbl.NrOfCols-2;
                    % Check ResourcesCost Table
                    if (NrOfSamples<1) || ~tbl.isNumericColumn(2:tbl.NrOfCols-1)
                        obj.messageLog(cType.ERROR,'Invalid resource cost definition');
                        return
                    end
            
                    samples=tbl.ColNames(3:end);
                    fields={'key','value'};
                    idx=cellfun(@(x) cType.getResourcesId(x),tbl.Data(:,1));
                    fidx=find(idx==cType.Resources.FLOW);
                    if isempty(fidx)
                        obj.messageLog(cType.ERROR,'No resource flows defined');
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
                    res.ResourcesCost=tmp;
                end
            end
        end
    end
    methods(Access=private)
        function res=WasteData(obj,tm)
        % Get default waste data info
            res=[];
            % Search Wastes in Flows Table
            ft=tm.Flows;
            fl=[ft.RowNames];
            fields=[ft.ColNames(2:end)];
            cid=find(strcmp(fields,'type'),1);
            if isempty(cid)
                obj.messageLog(cType.ERROR,'Invalid flows table. Type column NOT defined');
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