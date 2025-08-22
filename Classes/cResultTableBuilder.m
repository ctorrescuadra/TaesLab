classdef (Sealed) cResultTableBuilder < cFormatData
%cResultTableBuilder - Build the cResultInfo objects for the calculation layer
%   This class provide methods to obtain the cResultInfo object of each function application
%
%   cResultTableBuilder constructor:
%     obj = cResultTableBuilder(ps,data) 
%
%   cResultTableBuilder methods:
%     getProductiveStructure - Get Productive Structure Results
%     getExergyResults       - Get Exergy Analysis Results
%     getCostResults         - Get Thermoeconomic Analysis Results
%     getDiagnosisResults    - Get Diagnosis Results
%     getDiagramFP           - Get Diagram FP Results 
%     getProductiveDiagram   - Get Productive Diagram Results
%     getSummaryResults      - Get Summary Results
%
%   See also cFormatData, cResultInfo
%
    properties(Access=private)
        flowKeys     % Flow Key names
        streamKeys   % Stream Key names
        processKeys  % Process Key names
        flowEdges    % Flow edges
    end
    
    methods
        function obj=cResultTableBuilder(ps,data)
        %cResultTableBuilder - Create and instance of the class
        %   Syntax:
        %     obj = cResultTableBuilder(ps,data)
        %   Input:
        %     ps - cProductiveStructure object
        %     data - cModelData object
        %  
            obj=obj@cFormatData(data);
            if ~obj.status
                obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(obj));
                return
            end

            if ~isObject(ps,'cProductiveStructure')
				obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(ps));
                return
            end
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
        %   Output:
        %     res - cResultInfo object (THERMOECONOMIC_STATE) with the result tables:
        %       eflows: Exergy values of the flows
        %       estreams: Exergy values of the productive groups
        %       eprocesses: Exergy values of the processes
        %       tfp: Exergy table FP
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
        % Get the thermoeconomic analysis result 
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
        %   Input Argument:
        %     dgn - cDiagnosis object
        %   Output Argument:
        %     res - cResultInfo object (THERMOECONOMIC_DIAGNOSIS) with the result tables
        %       dgn: Diagnosis Summary
        %       mf: Malfunction Table
        %       mfc: Malfunction cost table
        %       dit: Irreversibiliy Variation table
        %       dft: Total Fuel Impact
        %       tmfc: Total Malfunction Cost
            tbl.dgn=obj.getSummaryDiagnosis(dgn);
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
                    tp=obj.getMatrixTableProperties(cType.Tables.WASTE_RECYCLING_DIRECT);
                    data=ra.dValues(:,2:end);
                    tbl.rad=obj.createMatrixTable(tp,data,rowNames',colNames);
                end
                if param.GeneralCost
                    tp=obj.getMatrixTableProperties(cType.Tables.WASTE_RECYCLING_GENERAL);
                    data=ra.gValues(:,2:end);
                    tbl.rag=obj.createMatrixTable(tp,data,rowNames',colNames);
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
            tbl.atfp=obj.getAdjacencyTableFP(cType.Tables.DIAGRAM_FP,dfp.EdgesFP);
            tbl.atcfp=obj.getAdjacencyTableFP(cType.Tables.COST_DIAGRAM_FP,dfp.EdgesCFP);
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
        %     res - cResultInfo object (PRODUCTIVE_DIAGRAM) with the tables
        %       fat  - Flow diagram adjacency table
        %       fpat - Flow-Process diagram adjacency table
        %       pat  - Process diagram adjacency table
        %       sfpat - Productive diagram adjacency table
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
        %   Syntax
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
            tables=struct();
            for i=1:sr.NrOfTables
                tmp=sr.getValues(i);
                tbl=tmp.Name;
                rowNames=sr.getRowNames(tbl);
                colNames=['key',sr.getColNames(tbl)];
                data=tmp.Values;
                tp=obj.getTableProperties(tbl);
                tables.(tbl)=createSummaryTable(obj,tp,data,rowNames,colNames);
            end
            res=cResultInfo(sr,tables);
        end

        function res=getTableFP(obj,name,values,names)
        % Get a cTableMatrix with the Fuel-Product table
        %  Input:
        %   name   - Table name
        %   values - Table FP values
        %  Output:
        %   res - cTableMatrix object
        %
            if nargin==3
                rowNames=obj.processKeys;
            else
                rowNames=names;
            end
            tp=obj.getMatrixTableProperties(name);
            colNames=horzcat('Key',rowNames);
            res=obj.createMatrixTable(tp,values,rowNames,colNames);
        end
    end

    methods(Access=private)    
        %-- Productive Structure Tables
        function res=getFlowsTable(obj,ps)
        % Generates a cTableCell with the flows definition
        % Input:
        %   ps - cProductiveStructure
        % Output:
        %   res - flows cTableCell
            tp=obj.getCellTableProperties(cType.Tables.FLOW_TABLE);
            rowNames=obj.flowKeys;
            colNames=obj.getTableHeader(tp);
            nrows=length(rowNames);
            ncols=tp.columns-1;
            data=cell(nrows,ncols);
            % Fill columns
            data(:,1)={obj.flowEdges.from};
            data(:,2)={obj.flowEdges.to};
            data(:,3)={ps.Flows.type};
            res=obj.createCellTable(tp,data,rowNames,colNames);
        end     
            
        function res=getStreamsTable(obj,ps)
        % Generates a cTableCell with the streams definition
        % Input:
        %   ps - cProductiveStructure
        % Output:
        %   res - streams cTableCell
            tp=obj.getCellTableProperties(cType.Tables.STREAM_TABLE);
            rowNames=obj.streamKeys;
            colNames=obj.getTableHeader(tp);
            nrows=length(rowNames);
            ncols=tp.columns-1;
            data=cell(nrows,ncols);
            data(:,1)={ps.Streams.definition};
            data(:,2)={ps.Streams.type};
            res=obj.createCellTable(tp,data,rowNames,colNames);
        end        
            
        function res=getProcessesTable(obj,ps)
        % Generates a cTableCell with the processes definition
        % Input:
        %   ps - cProductiveStructure
        % Output:
        %   res - processes cTableCell
            tp=obj.getCellTableProperties(cType.Tables.PROCESS_TABLE);
            prc=ps.Processes(1:end-1);
            rowNames=obj.processKeys(1:end-1);
            colNames=obj.getTableHeader(tp);
            nrows=length(rowNames);
            ncols=tp.columns-1;
            data=cell(nrows,ncols);
            data(:,1)={prc.fuel};
            data(:,2)={prc.product};
            data(:,3)={prc.type};
            res=obj.createCellTable(tp,data,rowNames,colNames);
        end
               
        %-- Exergy Analysis tables
        function res=getFlowExergy(obj,values)
        % Generates a cTableCell with the exergy flows values
        % Input:
        %   pm - cExergyModel object
        % Output:
        %   res - eflows cTableCell
            tp=obj.getCellTableProperties(cType.Tables.FLOW_EXERGY);
            rowNames=obj.flowKeys;
            colNames=obj.getTableHeader(tp);
            nrows=length(rowNames);
            ncols=tp.columns-1;
            data=cell(nrows,ncols);
            data(:,1)={obj.flowEdges.from};
            data(:,2)={obj.flowEdges.to};
            data(:,3)=num2cell(values);		
            res=obj.createCellTable(tp,data,rowNames,colNames);
        end	    		
            
        function res=getStreamExergy(obj,values)
        % Generates a cTableCell with stream exergy values
        % Input:
        %   pm - cExergyModel object
        % Output:
        %   res - eStreams cTableCell
            tp=obj.getCellTableProperties(cType.Tables.STREAM_EXERGY);
            rowNames=obj.streamKeys;
            colNames=obj.getTableHeader(tp);
            nrows=length(rowNames);
            ncols=tp.columns-1;
            data=cell(nrows,ncols);
            data(:,1)=num2cell(values.E);
            data(:,2)=num2cell(values.ET);
            res=obj.createCellTable(tp,data,rowNames,colNames);
        end

        function res=getAdjacencyTableFP(obj,name,val)
        % Generate the FP adjacency matrix
        %  Input:
        %   name - Table name
        %   val - Adjacency Table FP 
        %  Output:
        %   res - cTableCell object
        %   
            tp=obj.getCellTableProperties(name);
            M=size(val,1);
            rowNames=arrayfun(@(x) sprintf('E%d',x),1:M,'UniformOutput',false);
            colNames=obj.getTableHeader(tp);
            data=struct2cell(val)';
			res=obj.createCellTable(tp,data,rowNames,colNames);
		end

        function res=getProductiveTable(obj,pd,name)
        % Get the productive tables
        %  Input:
        %   pd   - cProductiveDiagram object
        %   name - name of the table
        %  Output:
        %   res - cTableCell object
        %
            tp=obj.getCellTableProperties(name);
            val=pd.getEdgeTable(name);
            M=size(val,1);
            rowNames=arrayfun(@(x) sprintf('E%d',x),1:M,'UniformOutput',false);
            colNames=obj.getTableHeader(tp);
            data=struct2cell(val)';
			res=obj.createCellTable(tp,data,rowNames,colNames);
        end

        function res=getWasteDefinition(obj,wt)
        % Get the Waste Definition Table
        %  Input:
        %   wt - cWasteTable object
        %  Output:
        %   res - cTableCell wd
        %
            tp=obj.getCellTableProperties(cType.Tables.WASTE_DEFINITION);
            flw=obj.flowKeys;
            rowNames=flw(wt.Flows);
            colNames=obj.getTableHeader(tp);
            nrows=length(rowNames);
            ncols=tp.columns-1;
            data=cell(nrows,ncols);
            data(:,1)=wt.Type;
            data(:,2)=num2cell(100*wt.RecycleRatio);
            res=obj.createCellTable(tp,data,rowNames,colNames);
        end

        function res=getWasteAllocation(obj,wt)
        % Get the Waste Allocation Table
        %  Input:
        %   wt - cWasteTable object
        %  Output:
        %   res - cTableMatrix wa
            tp=obj.getMatrixTableProperties(cType.Tables.WASTE_ALLOCATION);
            flw=obj.flowKeys;
            prc=obj.processKeys;
            colNames=['Key',flw(wt.Flows)];
            tmp=100*[wt.Values';wt.RecycleRatio];
            [idx,~]=find(tmp);idx=unique(idx);
            if ~isempty(idx)
                rowNames=prc(idx);
                values=tmp(idx,:);
                res=obj.createMatrixTable(tp,values,rowNames,colNames);
            else
                res=cMessageLogger(cType.INVALID);
            end
        end

        %-- Thermoeconomic Analysis Tables    
        function res=getFlowICTable(obj,name,values)
        % Get a cTableMatrix with the flows ICT (Irrreversibility Cost Tables)
        % Input:
        %  name - table name
        %  values - Flow ICT values
        % Output:
        %  res - cTableMatrix object
            tp=obj.getMatrixTableProperties(name);
            rowNames=obj.processKeys;
            colNames=horzcat('Key',obj.flowKeys);
            res=obj.createMatrixTable(tp,values,rowNames,colNames);
        end
         
        function res=getProcessICTable(obj,name,values)
        % Get a cTableMatrix with the  processes ICT
        % Input:
        %  name - table id
        %  values - Processes ICT values
        % Output:
        %  res - cTableMatrix
            tp=obj.getMatrixTableProperties(name);
            rowNames=obj.processKeys;
            colNames=horzcat('Key',obj.processKeys(1:end-1));
            res=obj.createMatrixTable(tp,values,rowNames,colNames);
        end
            
        %-- Diagnosis Tables
        function res=getSummaryDiagnosis(obj,dgn)
        % Get the Summary Diagnosis Tables
        % Input:
        %   dgn - cDiagnosis object
        % Output:
        %   res - Summary Diagnosis cTable
            res=obj.getTableCell(cType.Tables.DIAGNOSIS,dgn.getDiagnosisTable);
        end

        function res=getMalfunctionTable(obj,dgn)
        % Get a cTableMatrix with the mafunction table values
        % Input:
        %  values - Malfunction table values
        % Output:
        %  res - cTableMatrix object
            tp=obj.getMatrixTableProperties(cType.Tables.MALFUNCTION);
            rowNames=obj.processKeys;
            DPs=[cType.Symbols.delta,'Ps'];
            values=dgn.getMalfunctionTable;
            colNames=horzcat('key',rowNames(1:end-1),DPs);
            res=obj.createMatrixTable(tp,values,rowNames,colNames);
        end
            
        function res=getMalfunctionCostTable(obj,dgn)
        % Get a cTableMatrix with the mafunction cost table values
        % Input:
        %  values - Malfunction cost table values
        % Output:
        %  res - cTableMatrix object
            tp=obj.getMatrixTableProperties(cType.Tables.MALFUNCTION_COST);
            rowNames=horzcat(obj.processKeys(1:end-1),'MF');
            values=dgn.getMalfunctionCostTable;
            DPt=[cType.Symbols.delta,'Pt*'];
            colNames=horzcat('key',obj.processKeys(1:end-1),DPt);
            res=obj.createMatrixTable(tp,values,rowNames,colNames);
        end
            
        function res=getIrreversibilityTable(obj,dgn)
        % Get a cTableMatrix with the irreversibility table values
        % Input:
        %  values - Irreversibility table values
        % Output:
        %  res - cTableMatrix object
            tp=obj.getMatrixTableProperties(cType.Tables.IRREVERSIBILITY_VARIATION);
            rowNames=[obj.processKeys,'MF'];
            DPt=[cType.Symbols.delta,'Pt'];
            colNames=horzcat('key',obj.processKeys(1:end-1),DPt);
            values=dgn.getIrreversibilityTable;
            res=obj.createMatrixTable(tp,values,rowNames,colNames);
        end

        function res=getTotalMalfunctionCost(obj,dgn)
        % Get a cTableMatrix with the total malfunction cost values
        %  Input:
        %   dgn - cDiagnosis object
        % Output:
        %  res - cTableMatrix object      
            M=3;
            N=dgn.NrOfProcesses+1;
            values=zeros(N,M);
            values(:,1)=dgn.getMalfunctionCost';
            values(:,2)=dgn.getWasteMalfunctionCost';
            values(:,3)=dgn.getDemandCorrectionCost';
            tp=obj.getMatrixTableProperties(cType.Tables.TOTAL_MALFUNCTION_COST);
            rowNames=[obj.processKeys(1:end)];
            colNames={'key','MF*','MR*','MPt*'};
            res=obj.createMatrixTable(tp,values,rowNames,colNames);
        end

        function res=getFuelImpactSummary(obj,dgn)
        % Get a cTableMatrix with the fuel impact values
        %  Input:
        %   dgn - cDiagnosis object 
        % Output:
        %  res - cTableMatrix object    
            M=3;
            N=dgn.NrOfProcesses+1;
            values=zeros(N,M);
            values(:,1)=dgn.getIrreversibilityVariation';
            values(:,2)=dgn.getWasteVariation';
            values(:,3)=dgn.getDemandVariation';
            tp=obj.getMatrixTableProperties(cType.Tables.FUEL_IMPACT);
            rowNames=[obj.processKeys(1:end)];
            DI=[cType.Symbols.delta,'I'];
            DR=[cType.Symbols.delta,'R'];
            DPs=[cType.Symbols.delta,'Pt'];
            colNames={'key',DI,DR,DPs};
            res=obj.createMatrixTable(tp,values,rowNames,colNames);
        end

        function res=getNodeNames(obj,type)
        % Get the row names of the table
        % Input:
        %   type - type of node
        % Output:
        %   res - Cell array with the names of row names
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

        function res=getTableCell(obj,name,data)
        % Get the corresponding cTableCell object
        % Input:
        %   name - name of the table
        %   data - table data structure
            tp=obj.getCellTableProperties(name);
            rowNames=obj.getNodeNames(tp.node);
            colNames=obj.getTableHeader(tp);
            fieldNames={tp.fields.name};
            nrows=length(rowNames);
            ncols=tp.columns-1;
            values=zeros(nrows,ncols);
            for j=2:tp.columns,values(:,j-1)=data.(fieldNames{j}); end
            res=obj.createCellTable(tp,num2cell(values),rowNames,colNames);
        end

        function res=createCellTable(obj,props,data,rowNames,colNames)
        % Set parameters from cPrintConfig and create cTableCell
        % Input:
        %  props - Cell Table properties structure
        %  data  - Cell Values
        %  rowNames - Names of the rows
        %  colNames - Names of the columns
        % Output:
        %  res - cTableCell object
            p.Name=props.key;
            p.Description=props.description;   
            p.Unit=obj.getTableUnits(props);
            p.Format=obj.getTableFormat(props);
            p.FieldNames={props.fields.name};
            p.ShowNumber=props.number;
            p.GraphType=props.graph;
            p.NodeType=props.node;
            p.Resources=props.rsc;
            res=cTableCell(data,rowNames,colNames,p);
        end
            
        function res=createMatrixTable(obj,props,data,rowNames,colNames)
        % Set parameters from cPrintConfig and create cTableMatrix
        % Input:
        %  props - Matrix Table properties structure
        %  data  - Table Values
        %  rowNames - Names of the rows
        %  colNames - Names of the columns
        % Output:
        %  res - cTableCell object

            p.Name=props.key;
            p.Description=props.header;    
            p.Unit=obj.getUnit(props.type);
            p.Format=obj.getFormat(props.type);
            p.GraphType=props.graph;
            p.GraphOptions=props.options;
            p.Resources=props.rsc;
            p.SummaryType=cType.SummaryId.NONE;
            p.rowTotal=props.rowTotal;
            p.colTotal=props.colTotal;
            res=cTableMatrix(data,rowNames,colNames,p);
        end

        function res=createSummaryTable(obj,props,data,rowNames,colNames)
        % Create a summary table (as cTableMatrix)
        %  Input:
        %   props - Summary Table properties structure
        %   data  - Table Values
        %   rowNames - Names of the rows
        %   colNames - Names of the columns
            p.Name=props.key;
            p.Description=props.header;    
            p.Unit=obj.getUnit(props.type);
            p.Format=obj.getFormat(props.type);
            p.GraphType=props.graph;
            p.GraphOptions=props.options;
            p.Resources=props.rsc;
            p.SummaryType=props.table;
            p.rowTotal=false;
            p.colTotal=false;
            res=cTableMatrix(data,rowNames,colNames,p);
        end
    end
end
