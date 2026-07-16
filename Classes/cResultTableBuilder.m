classdef (Sealed) cResultTableBuilder < cFormatData
%cResultTableBuilder - Assemble cResultInfo objects from calculation-layer outputs.
%   cResultTableBuilder sits at the top of the format hierarchy:
%
%     cTablesDefinition  (table registry from printformat.json)
%          ↓
%     cFormatData        (model-specific format/unit overrides)
%          ↓
%     cResultTableBuilder (structural keys + one builder per analysis type)
%
%   The constructor stores the flow, stream, process and resource key arrays
%   from a cProductiveStructure object.  These keys are reused by every
%   private helper method as the row and column names of result tables.
%
%   Each public method accepts the computation object produced by one
%   analysis type in the calculation layer and returns a fully populated
%   cResultInfo containing the corresponding cTableCell / cTableMatrix
%   objects, ready for display or export.
%
%   cResultTableBuilder Methods:
%     cResultTableBuilder    - Construct from a cProductiveStructure and format data
%     getProductiveStructure - Build the productive structure cResultInfo
%     getExergyResults       - Build the exergy analysis cResultInfo
%     getCostResults         - Build the thermoeconomic analysis cResultInfo
%     getDiagnosisResults    - Build the thermoeconomic diagnosis cResultInfo
%     getWasteAnalysisResults - Build the waste analysis cResultInfo
%     getDiagramFP           - Build the FP diagram cResultInfo
%     getProductiveDiagram   - Build the productive diagram cResultInfo
%     getSummaryResults      - Build the summary results cResultInfo
%
%   cResultTableBuilder Methods (inherited from cFormatData):
%     getFormat          - Return the C-like format string for a variable type
%     getUnit            - Return the unit label for a variable type
%     getResultId        - Return the ResultId associated with a table name
%     getTableProperties - Return the definition and/or properties of a table
%
%   cResultTableBuilder Methods (inherited from cTablesDefinition):
%     getTablesDirectory     - Return a cTableData listing all registered tables
%     getTableDefinition     - Return the raw config struct for a named table
%     getTableInfo           - Return a summary-info struct for a named table
%     getTableId             - Return the dictionary index of a table name
%     getResultIdTables      - Return the table names for a given ResultId
%     getDataModelProperties - Return the data-model table configuration(s)
%     getCellTables          - Return cell-table configuration struct(s)
%     getMatrixTables        - Return matrix-table configuration struct(s)
%     getSummaryTables       - Return summary-table configuration struct(s)
%
%   See also cFormatData, cTablesDefinition, cResultInfo
%
    properties(Access=private)
        flowKeys     % Flow Key names
        streamKeys   % Stream Key names
        processKeys  % Process Key names
        resourceKeys % Resource Key names
        flowEdges    % Flow edges (from,to)
    end
    
    methods
        function obj=cResultTableBuilder(ps,data)
        %cResultTableBuilder - Construct from a cProductiveStructure and format data
        %   Calls the cFormatData constructor to set up the table registry
        %   and apply the model format overrides, then stores the structural
        %   key arrays from ps as private properties for reuse by all
        %   table-building helpers (row names, column names, edge lookups).
        %   Construction fails if cFormatData construction fails or if ps is
        %   not a valid cProductiveStructure object.
        %
        %   Syntax:
        %     obj = cResultTableBuilder(ps, data)
        %
        %   Input Arguments:
        %     ps   - cProductiveStructure object providing flow, stream,
        %            process and resource key arrays and flow-edge data.
        %     data - Format struct from cModelData (passed to cFormatData).
        %
        %   Output Arguments:
        %     obj  - cResultTableBuilder object.  Use isValid(obj) to confirm
        %            successful construction before calling build methods.
        %
            obj=obj@cFormatData(data);
            % Check input object
            if ~obj.status
                obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(obj));
                return
            end
            if ~isObject(ps,'cProductiveStructure')
				obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(ps));
                return
            end
            % Set private properties
            obj.flowKeys=ps.FlowKeys;
            obj.streamKeys=ps.StreamKeys;
            obj.processKeys=ps.ProcessKeys;
            obj.flowEdges=ps.FlowEdges;
            obj.resourceKeys=ps.getResourceNames;
        end
        
        function res=getProductiveStructure(obj,ps)
        %getProductiveStructure - Build the productive structure cResultInfo
        %   Constructs three tables describing the plant topology and returns
        %   them packaged in a cResultInfo object.
        %
        %   Syntax:
        %     res = obj.getProductiveStructure(ps)
        %
        %   Input Arguments:
        %     ps  - cProductiveStructure object.
        %
        %   Output Arguments:
        %     res - cResultInfo (PRODUCTIVE_STRUCTURE) containing:
        %             flows     - Flow definitions (key, from-process, to-process, type)
        %             streams   - Stream/productive-group definitions
        %             processes - Process definitions (key, fuel, product, type)
        %
            tbl=struct();
            tbl.flows=obj.getFlowsTable(ps);
            tbl.streams=obj.getStreamsTable(ps);
            tbl.processes=obj.getProcessesTable(ps);
            res=cResultInfo(ps,tbl);
        end
        
        function res=getExergyResults(obj,pm)
        %getExergyResults - Build the exergy analysis cResultInfo
        %   Constructs tables for the exergy values of flows, streams and
        %   processes, plus the active Fuel-Product (FP) table.
        %
        %   Syntax:
        %     res = obj.getExergyResults(pm)
        %
        %   Input Arguments:
        %     pm  - cExergyModel object.
        %
        %   Output Arguments:
        %     res - cResultInfo (THERMOECONOMIC_STATE) containing:
        %             eflows    - Exergy values of all flows
        %             estreams  - Exergy values of the productive groups
        %             eprocesses - Exergy values of the processes
        %             tfp       - Active Fuel-Product exergy table
        %
            tbl=struct();
            tbl.eflows=obj.getFlowExergy(pm.FlowsExergy);
            tbl.estreams=obj.getStreamExergy(pm.StreamsExergy);
            tbl.eprocesses=obj.getTableCell(cType.Tables.PROCESS_EXERGY,pm.ProcessesExergy);
            % Build Active TableFP
            idx=[pm.ActiveProcesses,true];
            tbl.tfp=obj.getTableFP(cType.Tables.TABLE_FP,pm.TableFP(idx,idx),obj.processKeys(idx));
            res=cResultInfo(pm,tbl);
            res.setResultId(cType.ResultId.THERMOECONOMIC_STATE);
            res.setDefaultGraph(cType.Tables.TABLE_FP);
        end
                  
        function res=getCostResults(obj,mfp,options)
        %getCostResults - Build the thermoeconomic analysis cResultInfo
        %   Constructs direct and/or generalised cost tables depending on
        %   the flags in options.  Resource-cost distribution tables are
        %   added automatically when more than one resource flow exists.
        %
        %   Syntax:
        %     res = obj.getCostResults(mfp, options)
        %
        %   Input Arguments:
        %     mfp     - cExergyCost object carrying the cost calculation results.
        %     options - Struct with the following fields:
        %                 DirectCost    - logical; build direct cost tables
        %                 GeneralCost   - logical; build generalised cost tables
        %                 ResourcesCost - cResourceData object required when
        %                                 GeneralCost is true
        %
        %   Output Arguments:
        %     res - cResultInfo (THERMOECONOMIC_ANALYSIS) containing a subset
        %           of the following tables, depending on the options flags:
        %
        %           Direct cost tables (options.DirectCost = true):
        %             dcost  - Direct exergy cost of processes
        %             ducost - Unit direct exergy cost of processes
        %             dfcost - Direct exergy cost of flows
        %             dscost - Direct exergy cost of streams
        %             dcfp   - Fuel-Product direct cost table
        %             dcfpr  - Fuel-Product direct cost table (with waste)
        %             dict   - Process irreversibility cost table
        %             dfict  - Flow irreversibility cost table
        %             dfrsc  - Flow resource-cost distribution (multi-resource)
        %             dprsc  - Process resource-cost distribution (multi-resource)
        %
        %           Generalised cost tables (options.GeneralCost = true):
        %             gcost  - Generalised cost of processes
        %             gucost - Unit generalised cost of processes
        %             gfcost - Generalised cost of flows
        %             gscost - Generalised cost of streams
        %             gcfp   - Fuel-Product generalised cost table
        %             gict   - Process irreversibility generalised cost table
        %             gfict  - Flow irreversibility generalised cost table
        %             gfrsc  - Flow resource-cost distribution (multi-resource)
        %             gprsc  - Process resource-cost distribution (multi-resource)
        %
            tbl=struct();
            % Direct Cost Tables
            idx=[mfp.ActiveProcesses,true];
            pnames=obj.processKeys(idx);
            if options.DirectCost
                dcost=mfp.getProcessCost;
                ducost=mfp.getProcessUnitCost;
                dfcost=mfp.getFlowsCost;
                dscost=mfp.getStreamsCost(dfcost);
                dcfp=mfp.getCostTableFP(ducost);  
                dcfpr=mfp.getDirectCostTableFPR(ducost);
                [dict,dfict]=mfp.getIrreversibilityCostTables;            
                tbl.dcost=obj.getTableCell(cType.Tables.PROCESS_COST,dcost);
                tbl.ducost=obj.getTableCell(cType.Tables.PROCESS_UNIT_COST,ducost);
                tbl.dfcost=obj.getTableCell(cType.Tables.FLOW_EXERGY_COST,dfcost);
                tbl.dscost=obj.getTableCell(cType.Tables.STREAM_EXERGY_COST,dscost);
                tbl.dcfp=obj.getTableFP(cType.Tables.COST_TABLE_FP,dcfp(idx,idx),pnames);
                tbl.dict=obj.getProcessICTable(cType.Tables.PROCESS_ICT,dict);
                tbl.dfict=obj.getFlowICTable(cType.Tables.FLOW_ICT,dfict);
                if mfp.isWaste
                    tbl.dcfpr=obj.getTableFP(cType.Tables.COST_TABLE_FPR,dcfpr(idx,idx),pnames);
                end
                if length(mfp.ps.ResourceFlows)>1
                    [dfrsc,dprsc]=mfp.getResourcesCostDistribution;
                    tbl.dfrsc=obj.getFlowRCDTable(cType.Tables.FLOW_RESOURCE_COST,dfrsc');
                    tbl.dprsc=obj.getProcessRCDTable(cType.Tables.PROCESS_RESOURCE_COST,dprsc');
                end
            end
            % Generalized Cost Tables
            if options.GeneralCost
                cz=options.ResourcesCost;
                mfp.setSample(cz.Sample);
                gcost=mfp.getProcessCost(cz);
                gucost=mfp.getProcessUnitCost(cz);
                gfcost=mfp.getFlowsCost(cz);
                gscost=mfp.getStreamsCost(gfcost);   
                gcfp=mfp.getGeneralCostTableFPR(cz,gucost);
                [gict,gfict]=mfp.getIrreversibilityCostTables(cz);   
                tbl.gcost=obj.getTableCell(cType.Tables.PROCESS_GENERAL_COST,gcost);
                tbl.gucost=obj.getTableCell(cType.Tables.PROCESS_GENERAL_UNIT_COST,gucost);
                tbl.gfcost=obj.getTableCell(cType.Tables.FLOW_GENERAL_COST,gfcost);
                tbl.gscost=obj.getTableCell(cType.Tables.STREAM_GENERAL_COST,gscost);
                tbl.gict=obj.getProcessICTable(cType.Tables.PROCESS_GENERAL_ICT,gict);
                tbl.gfict=obj.getFlowICTable(cType.Tables.FLOW_GENERAL_ICT,gfict);
                tbl.gcfp=obj.getTableFP(cType.Tables.GENERAL_COST_TABLE,gcfp(idx,idx),pnames);
                if length(mfp.ps.ResourceFlows)>1
                    [gfrsc,gprsc]=mfp.getResourcesCostDistribution(cz);
                    tbl.gfrsc=obj.getFlowRCDTable(cType.Tables.FLOW_RESOURCE_GENERAL_COST,gfrsc');
                    tbl.gprsc=obj.getProcessRCDTable(cType.Tables.PROCESS_RESOURCE_GENERAL_COST,gprsc');
                end
            end
            res=cResultInfo(mfp,tbl);
        end

        function res=getDiagnosisResults(obj,dgn)
        %getDiagnosisResults - Build the thermoeconomic diagnosis cResultInfo
        %   Constructs the malfunction, malfunction-cost, irreversibility,
        %   total-malfunction-cost and fuel-impact tables from a cDiagnosis
        %   object.
        %
        %   Syntax:
        %     res = obj.getDiagnosisResults(dgn)
        %
        %   Input Arguments:
        %     dgn - cDiagnosis object.
        %
        %   Output Arguments:
        %     res - cResultInfo (THERMOECONOMIC_DIAGNOSIS) containing:
        %             dgn  - Diagnosis summary table
        %             mf   - Malfunction table
        %             mfc  - Malfunction cost table
        %             dit  - Irreversibility variation table
        %             tmfc - Total malfunction cost table
        %             dft  - Fuel impact summary table
        %
            tbl.dgn=obj.getTableCell(cType.Tables.DIAGNOSIS,dgn.getDiagnosisTable);
            tbl.mf=obj.getMalfunctionTable(dgn);
            tbl.mfc=obj.getMalfunctionCostTable(dgn);
            tbl.dit=obj.getIrreversibilityTable(dgn);
            tbl.tmfc=obj.getTotalMalfunctionCost(dgn);
            tbl.dft=obj.getFuelImpactSummary(dgn);
            res=cResultInfo(dgn,tbl);
        end

        function res=getWasteAnalysisResults(obj,ra,param)
        %getWasteAnalysisResults - Build the waste analysis cResultInfo
        %   Constructs waste-definition, waste-allocation and (optionally)
        %   recycling-analysis tables.  Recycling tables are added only when
        %   ra.Recycling is true and the corresponding cost flag is set.
        %
        %   Syntax:
        %     res = obj.getWasteAnalysisResults(ra, param)
        %
        %   Input Arguments:
        %     ra    - cWasteAnalysis object carrying the analysis results.
        %     param - Struct with the following fields:
        %               DirectCost  - logical; build direct recycling table
        %               GeneralCost - logical; build generalised recycling table
        %
        %   Output Arguments:
        %     res - cResultInfo (WASTE_ANALYSIS) containing:
        %             wd  - Waste definition table
        %             wa  - Waste allocation table
        %             rad - Recycling analysis direct cost table (if DirectCost)
        %             rag - Recycling analysis generalised cost table (if GeneralCost)
        %
            tbl=struct();
            % Get Waste Definition and Allocation tables
            tbl.wd=obj.getWasteDefinition(ra.wasteTable);
            tbl.wa=obj.getWasteAllocation(ra.wasteTable);
            % Get Recycling analysis tables
            if ra.Recycling
                colNames=horzcat('Recycle (%)',ra.OutputFlows);
                tmp=int8(100*ra.dValues(:,1));
                rowNames=arrayfun(@(x) sprintf('%6d',x),tmp,'UniformOutput',false);
                if param.DirectCost
                    [~,tp]=obj.getTableProperties(cType.Tables.WASTE_RECYCLING_DIRECT);
                    data=ra.dValues(:,2:end);
                    tbl.rad=cTableMatrix(data,rowNames',colNames,tp);
                end
                if param.GeneralCost
                    [~,tp]=obj.getTableProperties(cType.Tables.WASTE_RECYCLING_GENERAL);
                    data=ra.gValues(:,2:end);
                    tbl.rag=cTableMatrix(data,rowNames',colNames,tp);
                end
            end
            % Build the cResultInfo Object
            res=cResultInfo(ra,tbl);
        end

        function res=getDiagramFP(obj,dfp)
        %getDiagramFP - Build the FP diagram cResultInfo
        %   Constructs adjacency tables and FP matrix tables from a
        %   cDiagramFP object for both the exergy and cost FP graphs,
        %   in both full and kernel (k-) forms.
        %
        %   Syntax:
        %     res = obj.getDiagramFP(dfp)
        %
        %   Input Arguments:
        %     dfp - cDiagramFP object.
        %
        %   Output Arguments:
        %     res - cResultInfo (DIAGRAM_FP) containing:
        %             atfp   - FP exergy adjacency table
        %             atcfp  - FP cost adjacency table
        %             katfp  - Kernel FP exergy adjacency table
        %             katcfp - Kernel FP cost adjacency table
        %             tfp    - FP exergy matrix table
        %             ktfp   - Kernel FP exergy matrix table
        %             dcfp   - FP direct cost matrix table
        %             kdcfp  - Kernel FP direct cost matrix table
        %             grps   - Process groups table
        %
            % Get FP adjacency tables
            tbl.atfp=obj.getAdjacencyTableFP(cType.Tables.DIGRAPH_FP,dfp.EdgesFP);
            tbl.atcfp=obj.getAdjacencyTableFP(cType.Tables.DIGRAPH_COST_FP,dfp.EdgesCFP);
            tbl.katfp=obj.getAdjacencyTableFP(cType.Tables.KDIGRAPH_FP,dfp.EdgesKFP);
            tbl.katcfp=obj.getAdjacencyTableFP(cType.Tables.KDIGRAPH_COST_FP,dfp.EdgesKCFP);
            tbl.tfp=obj.getTableFP(cType.Tables.TABLE_FP,dfp.TableFP,dfp.Names);
            tbl.ktfp=obj.getTableFP(cType.Tables.KTABLE_FP,dfp.TableKFP,dfp.kNames);
            tbl.dcfp=obj.getTableFP(cType.Tables.COST_TABLE_FP,dfp.TableCFP,dfp.Names);
            tbl.kdcfp=obj.getTableFP(cType.Tables.KTABLE_COST_FP,dfp.TableKCFP,dfp.kNames);
            tbl.grps=obj.getGroupsTable(cType.Tables.PROCESS_GROUP,dfp);
            % Build the cResultInfo
            res=cResultInfo(dfp,tbl);
        end

        function res=getProductiveDiagram(obj,pd)
        %getProductiveDiagram - Build the productive diagram cResultInfo
        %   Retrieves all table names registered under PRODUCTIVE_DIAGRAM
        %   and constructs an adjacency table for each one by calling
        %   getProductiveTable in a loop.
        %
        %   Syntax:
        %     res = obj.getProductiveDiagram(pd)
        %
        %   Input Arguments:
        %     pd  - cProductiveDiagram object.
        %
        %   Output Arguments:
        %     res - cResultInfo (PRODUCTIVE_DIAGRAM) containing:
        %             fat   - Flow diagram adjacency table
        %             fpat  - Flow-Process diagram adjacency table
        %             sfpat - Productive diagram adjacency table
        %             pat   - Process diagram adjacency table
        %             kpat  - Kernel process diagram adjacency table
        %
            tbl=struct();
            tnames=obj.getResultIdTables(cType.ResultId.PRODUCTIVE_DIAGRAM);
            for i=1:length(tnames)
                name=tnames{i};             
                tbl.(name)=obj.getProductiveTable(pd,name);
            end
            res=cResultInfo(pd,tbl);
        end

        function res=getSummaryResults(obj,sr)
        %getSummaryResults - Build the summary results cResultInfo
        %   Iterates over the datasets stored in the cSummaryResults object
        %   and builds one cTableMatrix per dataset using the corresponding
        %   summary-table properties.
        %
        %   Syntax:
        %     res = obj.getSummaryResults(sr)
        %
        %   Input Arguments:
        %     sr  - cSummaryResults object.
        %
        %   Output Arguments:
        %     res - cResultInfo (SUMMARY_RESULTS) containing a subset of:
        %
        %           State-comparison tables:
        %             exergy - Exergy values per state
        %             puk    - Process unit consumptions per state
        %             pI     - Process irreversibilities per state
        %             dpc    - Direct cost of processes per state
        %             dpuc   - Direct unit cost of processes per state
        %             dfc    - Direct cost of flows per state
        %             dfuc   - Direct unit cost of flows per state
        %             gpc    - Generalised cost of processes per state
        %             gpuc   - Generalised unit cost of processes per state
        %             gfc    - Generalised cost of flows per state
        %             gfuc   - Generalised unit cost of flows per state
        %
        %           Resource-sample comparison tables:
        %             rgpc   - Generalised cost of processes per sample
        %             rgpuc  - Generalised unit cost of processes per sample
        %             rgfc   - Generalised cost of flows per sample
        %             rgfuc  - Generalised unit cost of flows per sample
        %
            tables=struct();
            for i=1:sr.NrOfTables
                ds=sr.getValues(i);
                tbl=ds.Name;
                rowNames=obj.getNodeNames(ds.Node);
                colNames=['key',sr.getSummaryColumns(ds.Type)];
                data=ds.Values;
                tp=obj.getSummaryTableProperties(ds.TableDefinition);
                tables.(tbl)=cTableMatrix(data,rowNames,colNames,tp);
            end
            res=cResultInfo(sr,tables);
        end
    end

    methods(Access=private)    
        %--- Productive Structure Tables
        function res=getFlowsTable(obj,ps)
        %getFlowsTable - Generates a cTableCell with the flows definition
        %   Syntax:
        %     res=obj.getFlowsTable(ps)
        %   Input Arguments:
        %     ps - cProductiveStructure
        %   Output Arguments:
        %     res - cTableCell object
        %
            [td,tp]=obj.getTableProperties(cType.Tables.FLOW_TABLE);
            rowNames=obj.flowKeys;
            colNames=obj.getTableHeader(td);
            nrows=numel(rowNames);
            ncols=numel(colNames)-1;
            % Fill columns
            data=cell(nrows,ncols);
            data(:,1)={obj.flowEdges.from};
            data(:,2)={obj.flowEdges.to};
            data(:,3)={ps.Flows.type};
            res=cTableCell(data,rowNames,colNames,tp);
        end     
            
        function res=getStreamsTable(obj,ps)
        %getStreamsTable - Generates a cTableCell with the streams definition
        %   Syntax:
        %     res=obj.getStreamsTable(ps)
        %   Input Arguments:
        %     ps - cProductiveStructure
        %   Output Arguments:
        %     res - cTableCell object
        %
            [td,tp]=obj.getTableProperties(cType.Tables.STREAM_TABLE);
            rowNames=obj.streamKeys;
            colNames=obj.getTableHeader(td);
            nrows=numel(rowNames);
            ncols=numel(colNames)-1;
            % Fill Columns
            data=cell(nrows,ncols);
            data(:,1)={ps.Streams.definition};
            data(:,2)={ps.Streams.type};
            res=cTableCell(data,rowNames,colNames,tp);
        end        
            
        function res=getProcessesTable(obj,ps)
        %getProcessesTable - Generates a cTableCell with the processes definition
        %   Syntax:
        %     res = obj.getProcessesTable(ps)
        %   Input Arguments:
        %     ps - cProductiveStructure object
        %   Output Arguments:
        %     res - cTableCell object
        %
            [td,tp]=obj.getTableProperties(cType.Tables.PROCESS_TABLE);
            prc=ps.Processes(1:end-1);
            rowNames=obj.getNodeNames(td.node);
            colNames=obj.getTableHeader(td);
            nrows=numel(rowNames);
            ncols=numel(colNames)-1;
            % Fill Columns
            data=cell(nrows,ncols);
            data(:,1)=obj.processKeys(1:end-1);
            data(:,2)={prc.fuel};
            data(:,3)={prc.product};
            data(:,4)={prc.type};
            res=cTableCell(data,rowNames,colNames,tp);
        end
               
        %-- Exergy Analysis tables
        function res=getFlowExergy(obj,values)
        %getFlowExergy - Generates a cTableCell with the exergy flows values
        %   Syntax:
        %     res = obj.getFlowExergy(values)
        %   Input Arguments:
        %     values - flow exergy values array
        %   Output Arguments:
        %     res - cTableCell object
        %
            [td,tp]=obj.getTableProperties(cType.Tables.FLOW_EXERGY);
            rowNames=obj.flowKeys;
            colNames=obj.getTableHeader(td);
            nrows=numel(rowNames);
            ncols=numel(colNames)-1;
            % Fill Columns
            data=cell(nrows,ncols);
            data(:,1)={obj.flowEdges.from};
            data(:,2)={obj.flowEdges.to};
            data(:,3)=num2cell(values);		
            res=cTableCell(data,rowNames,colNames,tp);
        end	    		
            
        function res=getStreamExergy(obj,values)
        %getStreamExergy - Generates a cTableCell with stream exergy values
        %   Syntax:
        %     res = obj.getStreamExergy(values)
        %   Input Arguments:
        %     values - stream exergy values struct (fields E, ET)
        %   Output Arguments:
        %     res - cTableCell object
        %
            [td,tp]=obj.getTableProperties(cType.Tables.STREAM_EXERGY);
            rowNames=obj.streamKeys;
            colNames=obj.getTableHeader(td);
            nrows=numel(rowNames);
            ncols=numel(colNames)-1;
            % Fill Columns
            data=cell(nrows,ncols);
            data(:,1)=num2cell(values.E);
            data(:,2)=num2cell(values.ET);
            res=cTableCell(data,rowNames,colNames,tp);
        end

        function res=getTableFP(obj,name,values,rows)
        %getTableFP - Get a cTableMatrix with the Fuel-Product table
        %   Syntax:
        %     res = obj.getTableFP(name,values,rows)
        %   Input Arguments:
        %     name   - Table name
        %     values - Table FP values
        %     rows   - Row names (optional)
        %   Output Arguments:
        %     res - cTableMatrix object
        %
            if nargin==3
                rowNames=obj.processKeys;
            else
                rowNames=rows;
            end
            [~,tp]=obj.getTableProperties(name);
            colNames=horzcat('Key',rowNames);
            res=cTableMatrix(values,rowNames,colNames,tp);
        end

        %
        %--- DiagramFP tables
        function res=getAdjacencyTableFP(obj,name,val)
        %getAdjacencyTableFP - Generate the FP adjacency tables
        %   Syntax:
        %     res = obj.getAdjacencyTableFP(name,val)
        %   Input Arguments:
        %     name - Table name
        %     val - Adjacency Table FP
        %   Output Arguments:
        %     res - cTableCell object
        %
            [td,tp]=obj.getTableProperties(name);
            M=size(val,1);
            rowNames=arrayfun(@(x) sprintf('E%d',x),1:M,'UniformOutput',false);
            colNames=obj.getTableHeader(td);
            data=struct2cell(val)';
			res=cTableCell(data,rowNames,colNames,tp);
		end

        function res=getGroupsTable(obj,name,val)
        %getGroupsTable - Generate the Process Groups tables
        %   Syntax:
        %     res = obj.getGroupsTable(name,val)
        %   Input Arguments:
        %     name - Table name
        %     val - Group Table (Name,Group) struct
        %   Output Arguments:
        %     res - cTableCell object
        %
            [~,tp]=obj.getTableProperties(name);
            data(:,1)={val.GroupsTable.Group};
            data(:,2)=num2cell(val.NodeWeight');
            rowNames={val.GroupsTable.Name};
            colNames={'Node','Group','Weight'};
            res=cTableCell(data,rowNames,colNames,tp);
        end

        %
        %--- ProductiveDiagram Tables 
        function res=getProductiveTable(obj,pd,name)
        %getProductiveTable - Get the productive diagram adjacency tables
        %   Syntax:
        %     res = obj.getProductiveTable(pd,name)
        %   Input Arguments:
        %     pd   - cProductiveDiagram object
        %     name - name of the table
        %   Output Arguments:
        %     res - cTableCell object
        %
            [td,tp]=obj.getTableProperties(name);
            val=pd.getEdgesTable(name);
            M=size(val,1);
            rowNames=arrayfun(@(x) sprintf('E%d',x),1:M,'UniformOutput',false);
            colNames=obj.getTableHeader(td);
            data=struct2cell(val)';
			res=cTableCell(data(:,1:2),rowNames,colNames,tp);
        end

        %
        %-- Waste and Recycling tables
        function res=getWasteDefinition(obj,wt)
        %getWasteDefinition - Get the Waste Definition Table
        %   Syntax:
        %     res = obj.getWasteDefinition(wt)
        %   Input Arguments:
        %     wt - cWasteTable object
        %   Output Arguments:
        %     res - cTableCell object
        %
            [td,tp]=obj.getTableProperties(cType.Tables.WASTE_DEFINITION);
            flw=obj.flowKeys;
            rowNames=flw(wt.Flows);
            colNames=obj.getTableHeader(td);
            nrows=length(rowNames);
            ncols=numel(colNames)-1;
            % Fill columns
            data=cell(nrows,ncols);
            data(:,1)=wt.Type;
            data(:,2)=num2cell(100*wt.RecycleRatio);
            res=cTableCell(data,rowNames,colNames,tp);
        end

        function res=getWasteAllocation(obj,wt)
        %getWasteAllocation - Build a cTableMatrix for the waste allocation table
        %   Syntax:
        %     res = obj.getWasteAllocation(wt)
        %   Input Arguments:
        %     wt  - cWasteTable object.
        %   Output Arguments:
        %     res - cTableMatrix object.
        %
            [~,tp]=obj.getTableProperties(cType.Tables.WASTE_ALLOCATION);
            flw=obj.flowKeys;
            prc=obj.processKeys;
            colNames=['Key',flw(wt.Flows)];
            tmp=100*[wt.Values';wt.RecycleRatio];
            idx=any(zerotol(tmp),2);
            rowNames=prc(idx);
            values=tmp(idx,:);
            res=cTableMatrix(values,rowNames,colNames,tp);
        end

        %-- Thermoeconomic Analysis Tables    
        function res=getFlowICTable(obj,name,values)
        %getFlowICTable - Get a cTableMatrix with the flows ICT (Irreversibility Cost Tables)
        %   Syntax:
        %     res = obj.getFlowICTable(name,values)
        %   Input Arguments:
        %     name - table name
        %     values - Flow ICT values
        %   Output Arguments:
        %     res - cTableMatrix object
        %
            [~,tp]=obj.getTableProperties(name);
            rowNames=obj.processKeys;
            colNames=horzcat('Key',obj.flowKeys);
            res=cTableMatrix(values,rowNames,colNames,tp);
        end
         
        function res=getProcessICTable(obj,name,values)
        %getProcessICTable - Build a cTableMatrix for the process irreversibility cost table
        %   Syntax:
        %     res = obj.getProcessICTable(name, values)
        %   Input Arguments:
        %     name   - Table name string (cType.Tables value).
        %     values - Process ICT numeric matrix.
        %   Output Arguments:
        %     res - cTableMatrix object.
        %
            [~,tp]=obj.getTableProperties(name);
            rowNames=obj.processKeys;
            colNames=horzcat('Key',obj.processKeys(1:end-1));
            res=cTableMatrix(values,rowNames,colNames,tp);
        end
        
        function res=getFlowRCDTable(obj,name,values)
        %getFlowRCDTable - Get a cTableMatrix with the flows RCD (Resource Cost Distribution) values
        %   Syntax:
        %     res = obj.getFlowRCDTable(name,values)
        %   Input Arguments:
        %     name - table name
        %     values - flow RCD values matrix
        %   Output Arguments:
        %     res - cTableMatrix object
        %
            [~,tp]=obj.getTableProperties(name);
            rowNames=obj.flowKeys;
            colNames=horzcat('Key',obj.resourceKeys);
            res=cTableMatrix(values,rowNames,colNames,tp);
        end

        function res=getProcessRCDTable(obj,name,values)
        %getProcessRCDTable - Get a cTableMatrix with the processes RCD (Resource Cost Distribution) values
        %   Syntax:
        %     res = obj.getProcessRCDTable(name,values)
        %   Input Arguments:
        %     name - table name
        %     values - Process RCD values
        %   Output Arguments:
        %     res - cTableMatrix object
        %
            [~,tp]=obj.getTableProperties(name);
            rowNames=obj.processKeys(1:end-1);
            colNames=horzcat('Key',obj.resourceKeys);
            res=cTableMatrix(values,rowNames,colNames,tp);
        end

        %--- Diagnosis tables
        function res=getMalfunctionTable(obj,dgn)
        %getMalfunctionTable - Get a cTableMatrix with the malfunction table values
        %   Syntax:
        %     res = obj.getMalfunctionTable(dgn)
        %   Input Arguments:
        %     dgn - cDiagnosis object
        %   Output Arguments:
        %     res - cTableMatrix object
        %
            [~,tp]=obj.getTableProperties(cType.Tables.MALFUNCTION);
            rowNames=obj.processKeys;
            DPs=[cType.Symbols.delta,'Ps'];
            values=dgn.getMalfunctionTable;
            colNames=horzcat('key',rowNames(1:end-1),DPs);
            res=cTableMatrix(values,rowNames,colNames,tp);
        end
            
        function res=getMalfunctionCostTable(obj,dgn)
        %getMalfunctionCostTable - Get a cTableMatrix with the malfunction cost table values
        %   Syntax:
        %     res = obj.getMalfunctionCostTable(dgn)
        %   Input Arguments:
        %     dgn - cDiagnosis object
        %   Output Arguments:
        %     res - cTableMatrix object
        %
            [~,tp]=obj.getTableProperties(cType.Tables.MALFUNCTION_COST);
            rowNames=horzcat(obj.processKeys(1:end-1),'MF');
            values=dgn.getMalfunctionCostTable;
            DPt=[cType.Symbols.delta,'Pt*'];
            colNames=horzcat('key',obj.processKeys(1:end-1),DPt);
            res=cTableMatrix(values,rowNames,colNames,tp);
        end
            
        function res=getIrreversibilityTable(obj,dgn)
        %getIrreversibilityTable - Get a cTableMatrix with the irreversibility table values
        %   Syntax:
        %     res = obj.getIrreversibilityTable(dgn)
        %   Input Arguments:
        %     dgn - cDiagnosis object
        %   Output Arguments:
        %     res - cTableMatrix object
        %
            [~,tp]=obj.getTableProperties(cType.Tables.IRREVERSIBILITY_VARIATION);
            rowNames=[obj.processKeys,'MF'];
            DPt=[cType.Symbols.delta,'Pt'];
            colNames=horzcat('key',obj.processKeys(1:end-1),DPt);
            values=dgn.getIrreversibilityTable;
            res=cTableMatrix(values,rowNames,colNames,tp);
        end

        function res=getTotalMalfunctionCost(obj,dgn)
        %getTotalMalfunctionCost - Build a cTableMatrix for the total malfunction cost
        %   Assembles a three-column table with malfunction cost (MF*),
        %   waste malfunction cost (MR*), and demand correction cost (MPt*)
        %   for each process.
        %
        %   Syntax:
        %     res = obj.getTotalMalfunctionCost(dgn)
        %
        %   Input Arguments:
        %     dgn - cDiagnosis object.
        %
        %   Output Arguments:
        %     res - cTableMatrix object.
        %
            M=3;
            N=dgn.NrOfProcesses+1;
            [~,tp]=obj.getTableProperties(cType.Tables.TOTAL_MALFUNCTION_COST);
            % Set values
            values=zeros(N,M);
            values(:,1)=dgn.getMalfunctionCost';
            values(:,2)=dgn.getWasteMalfunctionCost';
            values(:,3)=dgn.getDemandCorrectionCost';
              % Set row and col names
            rowNames=obj.processKeys;
            colNames={'key','MF*','MR*','MPt*'};
            res=cTableMatrix(values,rowNames,colNames,tp);
        end

        function res=getFuelImpactSummary(obj,dgn)
        %getFuelImpactSummary - Build a cTableMatrix for the fuel impact summary
        %   Assembles a three-column table with irreversibility variation
        %   (ΔI), waste variation (ΔR), and demand variation (ΔPt) for
        %   each process.
        %
        %   Syntax:
        %     res = obj.getFuelImpactSummary(dgn)
        %
        %   Input Arguments:
        %     dgn - cDiagnosis object.
        %
        %   Output Arguments:
        %     res - cTableMatrix object.
        %
            M=3;
            N=dgn.NrOfProcesses+1;
            [~,tp]=obj.getTableProperties(cType.Tables.FUEL_IMPACT);
            % Set Values
            values=zeros(N,M);
            values(:,1)=dgn.getIrreversibilityVariation';
            values(:,2)=dgn.getWasteVariation';
            values(:,3)=dgn.getDemandVariation';
            % Set row and col names
            rowNames=obj.processKeys;
            DI=[cType.Symbols.delta,'I'];
            DR=[cType.Symbols.delta,'R'];
            DPs=[cType.Symbols.delta,'Pt'];
            colNames={'key',DI,DR,DPs};
            res=cTableMatrix(values,rowNames,colNames,tp);
        end

        function res=getTableCell(obj,name,data)
        %getTableCell - Build a cTableCell from a named table definition and a data struct
        %   Resolves the table definition (row names, column headers, format)
        %   and fills the cell array from the struct fields listed in the
        %   definition, then constructs the cTableCell object.
        %
        %   Syntax:
        %     res = obj.getTableCell(name, data)
        %
        %   Input Arguments:
        %     name - Table name string (cType.Tables value).
        %     data - Struct whose fields match the column field names defined
        %            in the table configuration (one numeric vector per field).
        %
        %   Output Arguments:
        %     res  - cTableCell object.
        %
            [td,tp]=obj.getTableProperties(name);
            rowNames=obj.getNodeNames(td.node);
            colNames=obj.getTableHeader(td);
            fieldNames={td.fields.name};
            nrows=length(rowNames);
            ncols=numel(colNames)-1;
            values=zeros(nrows,ncols);
            for j=2:td.columns,values(:,j-1)=data.(fieldNames{j}); end
            res=cTableCell(num2cell(values),rowNames,colNames,tp);
        end

        function res=getNodeNames(obj,type)
        %getNodeNames - Return the row-name array for a given node type
        %   Maps a cType.NodeType value to the corresponding private key
        %   array (flowKeys, streamKeys, processKeys) so that every table
        %   builder uses the same row-name source without duplicating the
        %   switch logic.
        %
        %   Syntax:
        %     res = obj.getNodeNames(type)
        %
        %   Input Arguments:
        %     type - Node type selector (cType.NodeType value):
        %              FLOW    → flowKeys
        %              STREAM  → streamKeys
        %              PROCESS → processKeys(1:end-1)  (excludes environment)
        %              ENV     → processKeys           (includes environment)
        %
        %   Output Arguments:
        %     res  - Cell array of key strings, or cType.EMPTY_CELL if type
        %            does not match any of the above cases.
        %
            res=cType.EMPTY_CELL;
            switch type
                case cType.NodeType.FLOW
                    res=obj.flowKeys;
                case cType.NodeType.STREAM
                    res=obj.streamKeys;
                case cType.NodeType.PROCESS
                    res=obj.processKeys(1:end-1);
                case cType.NodeType.ENV
                    res=obj.processKeys;
            end
        end
    end
end
