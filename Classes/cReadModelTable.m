classdef (Abstract) cReadModelTable < cReadModel
%cReadModelTable - Abstract class to read table data model.
%   This class derives cReadModelCSV and cReadmodelXLS
%   
%   cReadModelTable Methods:
%     getModelTable    - Get the tables of the data model
%     buildModelTables - Build the cModelData object
%	
% See also cReadModel, cReadModelXLS, cReadModelCSV
%
	properties (Access=public)
		modelTables
	end

    properties (Access=public)
        ftype
    end

    methods
        function res=getModelTables(obj)
        % Get the tables of the data model
            res=obj.modelTables;
        end
    end

	methods (Access=protected)
        function res=loadDataModelConfig(obj)
		% load default configuration filename
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
        % Build the cModelData from data tables
        % Input Arguments:
        %   tm - Structure containing the tables
        % Output Arguments
        %   res - cModelData object
        %
            res=cMessageLogger();
            sd=struct();
            tmp.name=obj.ModelName;
            % Flows table
            ftbl=tm.Flows;
            fkeys=ftbl.Keys;
            if ftbl.status
                tmp.flows=ftbl.getStructData;
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
            [tst,obj.ftype]=cType.checkFlowTypes(types);
            if ~tst
                obj.messageLog(cType.ERROR,cMessages.InvalidTable,'Flows');
                return
            end
            % Processes table
            ptbl=tm.Processes;
            if ptbl.status
                tmp.processes=ptbl.getStructData;
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
            if ~cType.checkProcessTypes(types)               
                obj.messageLog(cType.ERROR,cMessages.InvalidTable,'Processes');
                return
            end         
            sd.ProductiveStructure=tmp;
            % Get Format definition
            tbl=tm.Format;
            sd.Format.definitions=tbl.getStructData;
            % Get Exergy states data
            tbl=tm.Exergy;
            if ~tbl.status
                obj.messageLog(cType.ERROR,cMessages.TableNotFound,'Exergy');
                return
            end
            if ~isequal(tbl.Keys,fkeys)
                obj.messageLog(cType.ERROR,'Invalid Exergy Keys');
                return
            end
            NrOfStates=tbl.NrOfCols-1;
            tmp=struct();
            fields={'key','value'};
            data=tbl.Data(:,2:end);
            states=tbl.Fields(2:end);
            for i=1:NrOfStates
                st.stateId=states{i};
                values=[tbl.Keys,data(:,i)];
                st.exergy=cell2struct(values,fields,2);
                tmp.States(i,1)=st;
            end
            sd.ExergyStates=tmp;
            % Get Waste definition
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
                    cid=find(strcmp(ftbl.Fields,'type'),1);
                    if isempty(cid)
                        obj.messageLog(cType.ERROR,cMessages.InvalidTable,'WasteDefinition');
                        return
                    end
                    types=[tbl.Data(:,cid)];
                    if ~cType.checkWasteTypes(types)
                        obj.messageLog(cType.ERROR,cMessages.InvalidTable,'WasteDefinition');
                        return
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
                            return
                        end
                    end            
                end
                sd.WasteDefinition=pswd;
            end                               
            % Get Resources cost definition
            isResourceCost=isfield(tm,'ResourcesCost');
            if isResourceCost
                tbl=tm.ResourcesCost;
                if tbl.status
                    NrOfSamples=tbl.NrOfCols-2;           
                    %Check Types
                    cid=find(strcmp(tbl.Fields,'type'),1);
                    if isempty(cid)
                        obj.messageLog(cType.ERROR,cMessages.InvalidTable,'WasteDefinition');
                        return
                    end
                    types=tbl.Data(:,cid);
                    [tst,rtype]=cType.checkResourceTypes(types);
                    if ~tst
                        obj.messageLog(cType.ERROR,cMessages.InvalidTable,'ResourcesCost');
                        return
                    end
                    % Check if there is resources flows
                    samples=tbl.Fields(3:end);
                    fields={'key','value'};
                    fidx=find(rtype==cType.Resources.FLOW);
                    if isempty(fidx)
                        obj.messageLog(cType.ERROR,cMessages.InvalidTable,'ResourcesCost');
                        return
                    end
                    % Buil Resources Cost data
                    tmp=struct();
                    data=tbl.Data(:,3:end);
                    for i=1:NrOfSamples
                        fvalues=[tbl.Keys(fidx),data(fidx,i)];
                        fs=cell2struct(fvalues,fields,2);
                        tmp.Samples(i,1).sampleId=samples{i};
                        tmp.Samples(i,1).flows=fs;
                    end
                    pidx=find(rtype==cType.Resources.PROCESS);
                    if ~isempty(pidx)
                        for i=1:NrOfSamples
                            pvalues=[tbl.Keys(pidx),data(pidx,i)];
                            pr=cell2struct(pvalues,fields,2);
                            tmp.Samples(i,1).processes=pr;
                        end
                    end
                    sd.ResourcesCost=tmp;
                end
            end
            res=cModelData(obj.ModelName,sd);
        end
    end
    methods(Access=private)
        function res=WasteData(obj,tbl)
        % Get default waste data info
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