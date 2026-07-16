classdef (Abstract) cReadModelTable < cReadModel
%cReadModelTable - Abstract base class for tabular-format model readers.
%   Extends cReadModel to handle data model files stored as spreadsheet or
%   delimited-text tables (XLSX, CSV). Each sheet or file is loaded into a
%   cModelTable object and stored in the ModelTables struct. The expected
%   table layout is driven by the configuration in printformat.json.
%
%   The reading pipeline follows three stages:
%     1. Load printformat.json via getDataModelConfig to discover expected
%        tables and their field definitions.
%     2. Import each table into a cModelTable (done by the subclass).
%     3. Call buildModelData to validate tables and assemble a cModelData.
%
%   Concrete derived classes:
%     cReadModelCSV - reads a directory of CSV files
%     cReadModelXLS - reads a multi-sheet XLSX workbook
%
%   cReadModelTable Properties:
%     ModelTables - Struct of cModelTable objects keyed by table name
%
%   cReadModelTable Methods:
%     printModelTables - Display all model tables on the console
%
%   Protected Methods:
%     getDataModelConfig - Load table configuration from printformat.json
%     buildModelData     - Validate tables and assemble a cModelData object
%
%   See also cReadModel, cReadModelXLS, cReadModelCSV, cModelTable
%
	properties (Access=public)
		ModelTables   % Struct of cModelTable objects keyed by table name
	end

    properties (Access=private)
        ftype   % Flow type indices (cType.FlowType values per flow)
        fkeys   % Flow key strings (cell array, set by checkProductiveStructure)
        ptype   % Process type indices (cType.ProcessType values per process)
        pkeys   % Process key strings (cell array, set by checkProductiveStructure)
    end

    methods
        function printModelTables(obj)
        %printModelTables - Display all loaded model tables on the console.
        %   Iterates over every cModelTable stored in ModelTables and calls
        %   printTable on each one.
        %
        %   Syntax:
        %     obj.printModelTables()
        %
            cellfun(@(x) printTable(x), struct2cell(obj.ModelTables));
        end
    end

	methods (Access=protected)
        function res=getDataModelConfig(obj)
        %getDataModelConfig - Load the table layout configuration from printformat.json.
        %   Reads the printformat.json configuration file and returns the
        %   'datamodel' array describing each expected table: its name,
        %   optional flag, and field definitions (name and datatype).
        %   Returns cType.EMPTY and logs an error if the file cannot be read.
        %
        %   Syntax:
        %     res = obj.getDataModelConfig()
        %
        %   Output Arguments:
        %     res - Struct array with one element per expected table.
        %           Each element has fields: name, optional, fields.
        %           Returns cType.EMPTY on failure.
        %
        %   See also cType.CFGFILE, importJSON
        %
            res=cType.EMPTY;
			cfgfile=fullfile(cType.ConfigPath,cType.CFGFILE);
            config=importJSON(obj,cfgfile);
            if isempty(config)
                return
            end
    		res=config.datamodel;
		end

        function res=buildModelData(obj,tm)
        %buildModelData - Validate tables and assemble a cModelData object.
        %   Validates the ProductiveStructure, ExergyStates, WasteDefinition,
        %   and ResourcesCost sections in sequence. Each section check method
        %   logs errors to the caller object. If all mandatory sections pass,
        %   a cModelData is constructed and any accumulated messages are
        %   merged into it. Returns an empty cMessageLogger on failure.
        %
        %   Syntax:
        %     res = obj.buildModelData(tm)
        %
        %   Input Arguments:
        %     tm  - Struct of cModelTable objects keyed by table name,
        %           as populated by the subclass constructor
        %
        %   Output Arguments:
        %     res - cModelData object on success, or cMessageLogger
        %           (invalid) on failure. Check isValid(res).
        %
        %   See also cModelData, cModelTable
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
        %checkProductiveStructure - Validate Flows and Processes tables.
        %   Checks that both the Flows and Processes tables are present and
        %   valid in tm. Validates flow types against cType.FlowType and
        %   process types against cType.ProcessType, logging an error for
        %   each invalid entry. Also caches validated flow keys (fkeys),
        %   flow type indices (ftype), process keys (pkeys), and process
        %   type indices (ptype) for use by downstream check methods.
        %
        %   Syntax:
        %     res = obj.checkProductiveStructure(tm)
        %
        %   Input Arguments:
        %     tm  - Struct of cModelTable objects keyed by table name
        %
        %   Output Arguments:
        %     res - Struct with fields 'flows' and 'processes' (struct arrays
        %           suitable for cModelData), or cType.EMPTY on failure.
        %
        %   See also cType.checkFlowTypes, cType.checkProcessTypes
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
        %checkExergyTable - Validate the Exergy table and build state data.
        %   Checks that the Exergy table is present and that its row keys
        %   match the flow keys cached by checkProductiveStructure. Builds
        %   a struct array of exergy states, one per data column, each with
        %   a stateId and an exergy field array keyed by flow key.
        %
        %   Syntax:
        %     res = obj.checkExergyTable(tm)
        %
        %   Input Arguments:
        %     tm  - Struct of cModelTable objects keyed by table name
        %
        %   Output Arguments:
        %     res - Struct with field 'States' (struct array, one entry per
        %           operating state), or cType.EMPTY on failure.
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
        %checkWasteDefinition - Validate WasteDefinition and WasteAllocation tables.
        %   Returns cType.EMPTY (with an INFO message) when no WASTE flows
        %   are defined in the productive structure. Otherwise builds default
        %   waste entries and overrides them with data from the optional
        %   WasteDefinition and WasteAllocation tables when present.
        %
        %   Syntax:
        %     res = obj.checkWasteDefinition(tm)
        %
        %   Input Arguments:
        %     tm  - Struct of cModelTable objects keyed by table name
        %
        %   Output Arguments:
        %     res - Struct with field 'wastes' (struct array with flow, type,
        %           recycle, and optional values fields), or cType.EMPTY
        %           when no waste flows exist.
        %
        %   See also cType.DEFAULT_WASTE_ALLOCATION, cType.checkWasteTypes
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
        %checkResourcesCost - Validate the ResourcesCost table and build sample data.
        %   Returns cType.EMPTY silently when the ResourcesCost table is
        %   absent (the section is optional). When present, validates resource
        %   types (FLOW / PROCESS) and cross-checks keys against the flow and
        %   process keys cached by checkProductiveStructure. Builds a Samples
        %   struct array, one entry per cost sample column.
        %
        %   Syntax:
        %     res = obj.checkResourcesCost(tm)
        %
        %   Input Arguments:
        %     tm  - Struct of cModelTable objects keyed by table name
        %
        %   Output Arguments:
        %     res - Struct with field 'Samples' (struct array with sampleId,
        %           flows, and optional processes fields), or cType.EMPTY
        %           when the table is absent.
        %
        %   See also cType.checkResourceTypes
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