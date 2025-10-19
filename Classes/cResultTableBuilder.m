classdef (Sealed) cResultTableBuilder < cFormatData
%cResultTableBuilder - Build the cResultInfo objects for the calculation layer
%   This class provide methods to obtain the cResultInfo object of each function application
%   from the calculation layer.
%
%   cResultTableBuilder methods:
%     cResultTableBuilder    - Create and instance of the class
%     getProductiveStructure - Get Productive Structure Results
%     getExergyResults       - Get Exergy Analysis Results
%     getCostResults         - Get Thermoeconomic Analysis Results
%     getDiagnosisResults    - Get Diagnosis Results
%     getDiagramFP           - Get Diagram FP Results 
%     getProductiveDiagram   - Get Productive Diagram Results
%     getSummaryResults      - Get Summary Results
%
%   cResultTableBuilder methods (inherited from cFormatData):
%     getFormat          - Get the format of a variable type
%     getUnit            - Get the units of a variable type
%     getResultId        - Get the ResultId of a table
%     getTableProperties - Get the properties of a cTable
%
%   cResultTableBuilder methods (inherited from cTablesDefinition):
%     getTablesDirectory - Get the a cTableData with the tables index
%     getTableDefinition - Get configurarion properties of a table
%     getTableInfo       - Get table info as a struct
%     getTableId         - Get the TableId of a table
%     getResultIdTables  - Get the tables configuration of a ResultId
%     getCellTables      - Get the Cell tables configuration
%     getMatrixTables    - Get the Matrix tables configuration     
%     getSummaryTables   - Get the Summary tables configuration
%
%   See also cFormatData, cTablesDefinition, cResultInfo
%
    properties(Access=private)
        flowKeys     % Flow Key names
        streamKeys   % Stream Key names
        processKeys  % Process Key names
        flowEdges    % Flow edges (from,to)
    end
    
    methods
        function obj=cResultTableBuilder(ps,data)
        %cResultTableBuilder - Create and instance of the class
        %   Syntax:
        %     obj = cResultTableBuilder(ps,data)
        %   Input Arguments:
        %     ps - cProductiveStructure object
        %     data - cModelData object
        %   Output Arguments:
        %     obj - cResultTableBuilder object
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
        end
        
        function res=getProductiveStructure(obj,ps)
        %getProductiveStructure - Generate the productive structure results
        %   Syntax:
        %     res = obj.getProductiveStructure(ps)
        %   Input Arguments:
        %     ps - cProductiveStructure object
        %   Output Arguments:
        %     res - cResultInfo object (PRODUCTIVE_STRUCTURE) with the result tables:    
        %       flows: plant flows
        %       streams: plant productive groups
        %       processes: plant processes
        %
            tbl=struct();
            tbl.flows=obj.getFlowsTable(ps);
            tbl.streams=obj.getStreamsTable(ps);
            tbl.processes=obj.getProcessesTable(ps);
            res=cResultInfo(ps,tbl);
        end
        
        function res=getExergyResults(obj,pm)
        %getExergyResults -  Generate the exergy results
        %   Syntax:
        %     res = obj.getExergyResults(pm)
        %   Input :
        %     pm - cExergyModel object
        %   Output Arguments:
        %     res - cResultInfo object (THERMOECONOMIC_STATE) with the result tables:
        %       eflows: Exergy values of the flows
        %       estreams: Exergy values of the productive groups
        %       eprocesses: Exergy values of the processes
        %       tfp: Exergy table FP
        %
            tbl=struct();
            tbl.eflows=obj.getFlowExergy(pm.FlowsExergy);
            tbl.estreams=obj.getStreamExergy(pm.StreamsExergy);
            tbl.eprocesses=obj.getTableCell(cType.Tables.PROCESS_EXERGY,pm.ProcessesExergy);
            tbl.tfp=obj.getTableFP(cType.Tables.TABLE_FP,pm.TableFP);
            res=cResultInfo(pm,tbl);
            res.setResultId(cType.ResultId.THERMOECONOMIC_STATE);
            res.setDefaultGraph(cType.Tables.TABLE_FP);
        end
                  
        function res=getCostResults(obj,mfp,options)
        %getCostResults - Get the thermoeconomic analysis result 
        %   Syntax:
        %     res = obj.getCostResults(exc,options)
        %   Input Arguments:
        %     exc - cExergyCost object
        %     options - structure containing the fields:
        %       DirectCost - Direct Cost Tables will be obtained
        %       GeneralCost - General Cost Tables will be obtained
        %       ResourceCost - cResourceData object if generalized cost is required
        %   Output Arguments:
        %     res - cResultInfo object (THERMOECONOMIC_ANALYSIS) with the result tables:
        %      Direct Cost tables:
        %       dfcost: Direct Exergy Cost of flows
        %       dcost: Direct Exergy cost of processes
        %       udcost: Unit Direct Exergy Cost of processes table
        %       dict: Irreversibility Cost Table 
        %       dfict: Flows Irreversibility Cost Table
        %       dcfp: Fuel-Product direct cost table
        %       dcfpr: Fuel-Product direct cost table (includes waste)
        %      Generalized Cost tables:
        %       gcost: Generalized cost of processes 
        %       ugcost: Unit Generalized Cost of processes
        %       gfcost: Generalized Cost of flows
        %       gcfp: Fuel-Product generalized cost table
        %       gict: Irreversibility generalized cost table 
        %       gfict: Flows Irreversibility generalized cost table
        %
            tbl=struct();
            % Direct Cost Tables
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
                tbl.dcfp=obj.getTableFP(cType.Tables.COST_TABLE_FP,dcfp);
                tbl.dict=obj.getProcessICTable(cType.Tables.PROCESS_ICT,dict);
                tbl.dfict=obj.getFlowICTable(cType.Tables.FLOW_ICT,dfict);
                if mfp.isWaste
                    tbl.dcfpr=obj.getTableFP(cType.Tables.COST_TABLE_FPR,dcfpr);
                end
            end
            % Generalized Cost Tables
            if options.GeneralCost
                cz=options.ResourcesCost;
                mfp.setSample(cz.sample);
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
                tbl.gcfp=obj.getTableFP(cType.Tables.GENERAL_COST_TABLE,gcfp);
            end
            res=cResultInfo(mfp,tbl);
        end

        function res=getDiagnosisResults(obj,dgn)
        %getDiagnosisResults - Get the thermoeconomic diagnosis results
        %   Syntax:
        %     res = obj.getDiagnosisResults(dgn)
        %   Input Arguments:
        %     dgn - cDiagnosis object
        %   Output Arguments:
        %     res - cResultInfo object (THERMOECONOMIC_DIAGNOSIS) with the result tables
        %       dgn: Diagnosis Summary
        %       mf: Malfunction Table
        %       mfc: Malfunction cost table
        %       dit: Irreversibiliy Variation table
        %       dft: Total Fuel Impact
        %       tmfc: Total Malfunction Cost
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
        %getWasteAnalysisResults - Get the waste analysis results
        %   Syntax:
        %     res = obj.getWasteAnalysisResults(ra,options)
        %   Input Arguments:
        %     ra: cRecyclingAnalysis object
        %     options - structure containing the fields:
        %       DirectCost - Direct Cost Tables will be obtained
        %       GeneralCost - General Cost Tables will be obtained
        %       ResourceCost - cResourceData object if generalized cost is required
        %   Output Arguments:
        %     res - cResultInfo object (WASTE_ANALYSIS) with the tables:
        %       wd - Waste Definition
        %       wa - Waste Allocation
        %       rad - Recycling Analysis direct cost
        %       rag - Recycling Analysis generalized cost
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
        %getDiagramFP - Get the diagram FP adjacency results
        %   Syntax:
        %     res = obj.getDiagramFP(dfp) 
        %   Input Arguments:
        %     dfp - cDiagramFP object
        %   Output Arguments:
        %     res - cResultInfo object (DIAGRAM_FP) with the diagram FP tables
        %       atfp - FP adjacency table
        %       atcfp - FP cost adjacency table
        %
            % Get FP adjacency tables
            tbl.atfp=obj.getAdjacencyTableFP(cType.Tables.DIGRAPH_FP,dfp.EdgesFP);
            tbl.atcfp=obj.getAdjacencyTableFP(cType.Tables.DIGRAPH_COST_FP,dfp.EdgesCFP);
            tbl.katfp=obj.getAdjacencyTableFP(cType.Tables.KDIGRAPH_FP,dfp.EdgesKFP);
            tbl.katcfp=obj.getAdjacencyTableFP(cType.Tables.KDIGRAPH_COST_FP,dfp.EdgesKCFP);
            tbl.tfp=obj.getTableFP(cType.Tables.TABLE_FP,dfp.TableFP);
            tbl.ktfp=obj.getTableFP(cType.Tables.KTABLE_FP,dfp.TableKFP,dfp.kNames);
            tbl.dcfp=obj.getTableFP(cType.Tables.COST_TABLE_FP,dfp.TableCFP);
            tbl.kdcfp=obj.getTableFP(cType.Tables.KTABLE_COST_FP,dfp.TableKCFP,dfp.kNames);
            tbl.grps=obj.getGroupsTable(cType.Tables.PROCESS_GROUP,dfp.GroupsTable);
            % Build the cResultInfo
            res=cResultInfo(dfp,tbl);
        end

        function res=getProductiveDiagram(obj,pd)
        %getProductiveDiagram - Get the productive diagram tables
        %   Syntax:
        %     res = obj.getProductiveDiagram(pd)
        %   Input Arguments:
        %     pd - cProductiveDiagram object
        %   Output Arguments:
        %     res    - cResultInfo object (PRODUCTIVE_DIAGRAM) with the tables
        %      fat   - Flow diagram adjacency table
        %      fpat  - Flow-Process diagram adjacency table
        %      sfpat - Productive diagram adjacency table
        %      pat   - Process diagram adjacency table
        %      kpat  - Kernel Process diagram adjacency table 
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
        %getSummaryResults - Get the cResultInfo for Summary Results
        %   Syntax:
        %     res = obj.getSummayResults(sr)
        %   Input Arguments:
        %     sr - cSummaryResults object
        %   Output Arguments:
        %     res - cResultInfo object (SUMMARY_RESULTS) with the tables
        %      STATES
        %       exergy - Exergy values of the model state
        %       puk - Unit consumptions of processes
        %       pI - Process irreversibility
        %       dpc - Direct cost of processes
        %       dpuc - Direct unit cost of processes
        %       dfc - Direct cost of flows
        %       dfuc - Direct unit cost of flows
        %       gpc - Generalized cost of processes
        %       gpuc - Generalized unit cost of processes
        %       gfc - Generalized cost of flows
        %       gfuc - Generalized unit cost of flows
        %     RESOURCES
        %       rgpc - Generalized cost of processes
        %       rgpuc - Generalized unit cost of processes
        %       rgfc - Generalized cost of flows
        %       rgfuc - Generalized unit cost of flows 
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
        %     res=obj.getProcessTable(ps)
        %   Input Arguments:
        %     ps - cProductiveStructure
        %   Output Arguments:
        %    res - cTableCell
            [td,tp]=obj.getTableProperties(cType.Tables.PROCESS_TABLE);
            prc=ps.Processes(1:end-1);
            rowNames=obj.getNodeNames(td.node);
            colNames=obj.getTableHeader(td);
            nrows=numel(rowNames);
            ncols=numel(colNames)-1;
            % Fill Columns
            data=cell(nrows,ncols);
            data(:,1)=ps.ProcessDigraph.getComponentNames;
            data(:,2)={prc.fuel};
            data(:,3)={prc.product};
            data(:,4)={prc.type};
            res=cTableCell(data,rowNames,colNames,tp);
        end
               
        %-- Exergy Analysis tables
        function res=getFlowExergy(obj,values)
        %getFlowExergy - Generates a cTableCell with the exergy flows values
        %   Syntax:
        %     res=obj.getProcessTable(ps)
        %   Input Arguments:
        %     pm - cExergyModel object
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
        %     res=obj.getStreamExergy(values)
        %   Input Arguments:
        %     pm - cExergyModel object
        %   Output Arguments:
        %    res - eStreams cTableCell
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
        %   res - cTableCell object
        %   
            [td,tp]=obj.getTableProperties(name);
            data={val.Group}';
            rowNames={val.Name};
            colNames=obj.getTableHeader(td);
            res=cTableCell(data,rowNames,colNames,tp);
        end

        %
        %--- ProductiveDiagram Tables 
        function res=getProductiveTable(obj,pd,name)
        %getProductiveDiagram - Get the productive tables
        %   Syntax:
        %    res=obj.getProductiveTable(pd,name)
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
        %     res = obj.getWasteDefinition
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
        %getWasteAllocation - Get the Waste Allocation Table
        %   Syntax:
        %     res = obj.WasteAllocation(wt)
        %   Input Arguments:
        %     wt - cWasteTable object
        %   Output Arguments:
        %   res - cTableMatrix object
        %
            res=cTaesLab(cType.INVALID);
            [~,tp]=obj.getTableProperties(cType.Tables.WASTE_ALLOCATION);
            flw=obj.flowKeys;
            prc=obj.processKeys;
            colNames=['Key',flw(wt.Flows)];
            tmp=100*[wt.Values';wt.RecycleRatio];
            [idx,~]=find(tmp);idx=unique(idx);
            if ~isempty(idx)
                rowNames=prc(idx);
                values=tmp(idx,:);
                res=cTableMatrix(values,rowNames,colNames,tp);
            end
        end

        %-- Thermoeconomic Analysis Tables    
        function res=getFlowICTable(obj,name,values)
        %getFlowICTable - Get a cTableMatrix with the flows ICT (Irrreversibility Cost Tables)
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
        %getProcessICTable - Get a cTableMatrix with the  processes ICT
        %   Syntax:
        %     res = obj.getProcessICTable(name,values)
        %   Input Arguments:
        %     name - table id
        %     values - Processes ICT values
        %   Output Arguments:
        %     res - cTableMatrix object
        %
            [~,tp]=obj.getTableProperties(name);
            rowNames=obj.processKeys;
            colNames=horzcat('Key',obj.processKeys(1:end-1));
            res=cTableMatrix(values,rowNames,colNames,tp);
        end
            
        %
        %--- Diagnosis tables
        function res=getMalfunctionTable(obj,dgn)
        %getMalfunctionTable - Get a cTableMatrix with the mafunction table values
        %   Syntax:
        %     res = obj.getMalfunctionTable(dgn)
        %   Input Arguments:
        %     dg - cDiagnosis object
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
        %getMalfunctionCostTable - Get a cTableMatrix with the mafunction cost table values
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
        %getTotalMalfunctionCost - Get a cTableMatrix with the total malfunction cost values
        %   Syntax:
        %     res = obj.getTotalMalfunctionCost(dgn)
        %   Input Arguments:
        %     dgn - cDiagnosis object
        %   Output Arguments:
        %     res - cTableMatrix object      
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
        %getFuelImpactSummary - Get a cTableMatrix with the fuel impact values
        %   Syntax:
        %     res=obj.getFuelImpactSummary(dgn)
        %  Input Arguments:
        %     dgn - cDiagnosis object 
        %  Output Arguments:
        %    res - cTableMatrix object
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
        %getTableCell - Get the corresponding cTableCell object of a table dataset
        %   Syntax:
        %     res=obj.getTableCell(name,data)
        %   Input Arguments:
        %     name - name of the table
        %     data - table data structure
        %   Output Arguments:
        %     res - cTableCell object
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
        %getNodeNames - Get the row names of the table using node type
        %   Syntax:
        %     res=obj.getNodeNames(type)
        %   Input Arguments:
        %     type - type of node
        %   Output Arguments:
        %     res - Cell array with the names of the rows
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
