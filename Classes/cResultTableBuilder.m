classdef (Sealed) cResultTableBuilder < cFormatData
% cResultTableBuilder generates the cResultInfo objects for the calculation layer
%   This class provide methods to obtain the cResultInfo of each function application
%   Methods:
%       obj=cResultTableBuilder(cfglocal,ps)
%       res=obj.getProductiveStructureResults(ps)
%       res=obj.getExergyResults(pm)
%       res=obj.getThermoeconomicAnalysisResults(mfp,options)
%       res=obj.getThermoeconomicDiagnosisResults(dgn)
%       res=obj.getDiagramFP(pm)
%       res=obj.getRecyclingAnalysis(ra)
% Methods from cFormatData:
%	    res=obj.getFormat(id)
%	    res=obj.getUnit(id)
%	    res=obj.getTableDescription(id)
%       res=obj.getMatrixDescription(id)
%	    res=obj.getTableHeader(id)
%	    res=obj.getNumColumns(id)
%	    res=obj.getFieldNames(id)
%	    res=obj.getTableFormat(id)
%	    res=obj.getMatrixFormat(id)
%	    res=obj.getTableUnits(id)
%	    res=obj.getMatrixUnit(id)
%	    res=obj.getMatrixName(id)
%	    [row,col]=obj.getMatrixTotal(id)
%       res=obj.PrintConfig;
% See also cFormatData, cResultInfo
%
    properties(Access=private)
        flowKeys     % Flow Key names
        streamKeys   % Stream Key names
        processKeys  % Process Key names
    end
    
    methods
        function obj=cResultTableBuilder(dm,ps)
        % Create the cResultTableBuilder associated to a plant (productive structure)
        %  Input:
        %   data - cModelData object
        %   ps - cProductiveStructure object
            obj=obj@cFormatData(dm);
            if ~isValid(obj)
                obj.messageLog(cType.ERROR,'Invalid Format Data');
                return
            end

            if ~isa(ps,'cProductiveStructure') || ~isValid(ps)
				obj.messageLog(cType.ERROR,'Invalid Productive Structure');
                return
            end
            obj.flowKeys=ps.FlowKeys;
            obj.streamKeys=ps.StreamKeys;
            obj.processKeys=ps.ProcessKeys;
        end
        
        function res=getProductiveStructureResults(obj,ps)
        % Generate the productive structure tables
        %  Input:
        %   ps - cProductiveStructure object
        %  Output:
        %   res - cResultInfo object (PRODUCTIVE_STRUCTURE) with the result tables:    
        %     flows: plant flows
        %     streams: plant productive groups
        %     processes: plant processes
            tbl=struct();
            tbl.flows=obj.getFlowsTable(ps);
            tbl.streams=obj.getStreamsTable(ps);
            tbl.processes=obj.getProcessesTable(ps);
            res=cResultInfo(ps,tbl);
        end
        
        function res=getExergyResults(obj,pm)
        % Generate the exergy result tables
        %  Input:
        %   pm - cExergyModel object
        %  Output:
        %   res - cResultInfo object (THERMOECONOMIC_STATE) with the result tables:
        %     eflows: Exergy values of the flows
        %     estreams: Exergy values of the productive groups
        %     eprocesses: Exergy values of the processes
        %     tfp: Exergy table FP
            tbl=struct();
            tbl.eflows=obj.getFlowExergy(pm);
            tbl.estreams=obj.getStreamExergy(pm.StreamsExergy);
            tbl.eprocesses=obj.getProcessExergy(pm.ProcessesExergy);
            tbl.tfp=obj.getTableFP(cType.Tables.TABLE_FP,pm.TableFP);
            res=cResultInfo(pm,tbl);
            res.setResultId(cType.ResultId.THERMOECONOMIC_STATE);
        end
                  
        function res=getThermoeconomicAnalysisResults(obj,mfp,options)
        % Get a structure containing the tables for Thermoeconomic Analysis function
        %   Input:
        %       pm - ProcessModel object
        %       options - structure containing the fields
        %           DirectCost - Direct Cost Tables will be obtained
        %           GeneralCost - General Cost Tables will be obtained
        %           ResourceCost - [optional] cResourceData object if
        %               generalized cost is required
        %   Output:
        %       res - cResultInfo object (THERMOECONOMIC_ANALYSIS) with the result tables
        %
            tbl=struct();
            if options.DirectCost
                dcost=mfp.getProcessCost;
                ducost=mfp.getProcessUnitCost;
                dfcost=mfp.getFlowsCost;
                dscost=mfp.getStreamsCost;
                dcfp=mfp.getCostTableFP(ducost);  
                dcfpr=mfp.getDirectCostTableFPR(ducost);
                dict=mfp.getProcessICT;
                dfict=mfp.getFlowsICT;               
                tbl.dcost=obj.getProcessCostTable(cType.Tables.PROCESS_COST,dcost);
                tbl.ducost=obj.getProcessCostTable(cType.Tables.PROCESS_UNIT_COST,ducost);
                tbl.dfcost=obj.getFlowCostTable(cType.Tables.FLOW_EXERGY_COST,dfcost);
                tbl.dscost=obj.getStreamCostTable(cType.Tables.STREAM_EXERGY_COST,dscost);
                tbl.dcfp=obj.getTableFP(cType.Tables.COST_TABLE_FP,dcfp);
                tbl.dict=obj.getProcessICTable(cType.Tables.PROCESS_ICT,dict);
                tbl.dfict=obj.getFlowICTable(cType.Tables.FLOW_ICT,dfict);
                if mfp.isWaste
                    tbl.dcfpr=obj.getTableFP(cType.Tables.COST_TABLE_FPR,dcfpr);
                end
            end
            if options.GeneralCost
                cz=options.ResourcesCost;
                gcost=mfp.getProcessCost(cz);
                gucost=mfp.getProcessUnitCost(cz);
                gfcost=mfp.getFlowsCost(cz);
                gscost=mfp.getStreamsCost(cz);   
                gcfp=mfp.getGeneralCostTableFPR(cz,gucost);
                gict=mfp.getProcessICT(cz);
                gfict=mfp.getFlowsICT(cz);   
                tbl.gcost=obj.getProcessCostTable(cType.Tables.PROCESS_GENERAL_COST,gcost);
                tbl.gucost=obj.getProcessCostTable(cType.Tables.PROCESS_GENERAL_UNIT_COST,gucost);
                tbl.gfcost=obj.getFlowCostTable(cType.Tables.FLOW_GENERAL_COST,gfcost);
                tbl.gscost=obj.getStreamCostTable(cType.Tables.STREAM_GENERAL_COST,gscost);
                tbl.gict=obj.getProcessICTable(cType.Tables.PROCESS_GENERAL_ICT,gict);
                tbl.gfict=obj.getFlowICTable(cType.Tables.FLOW_GENERAL_ICT,gfict);
                tbl.gcfp=obj.getTableFP(cType.Tables.GENERAL_COST_TABLE,gcfp);
            end
            res=cResultInfo(mfp,tbl);
        end

        function res=getDiagnosisResults(obj,dgn)
        % Get a structure with the tables for ThermoeconomicDiagnosis function
        %   Input:
        %       dgn - cDiagnosis object
        %   Output:
        %       res - cResultInfo object (THERMOECONOMIC_DIAGNOSIS) with the result tables
        %           dgn: Diagnosis Summary
        %           mf: Malfunction Table
        %           mfc: Malfunction cost table
        %           dit: Irreversibiliy Variation table
            tbl.dgn=obj.getDiagnosisSummary(dgn);
            tbl.mf=obj.getMalfunctionTable(dgn.getMalfunctionTable);
            tbl.mfc=obj.getMalfunctionCostTable(dgn.getMalfunctionCostTable,dgn.Method);
            tbl.dit=obj.getIrreversibilityTable(dgn.getIrreversibilityTable);
            tbl.tmfc=obj.getTotalMalfunctionCost(dgn);
            tbl.dft=obj.getFuelImpactSummary(dgn);
            res=cResultInfo(dgn,tbl);
        end

        function res=getWasteAnalysisResults(obj,ra,param)
        % Get a structure with the tables of cRecyclingAnalisys function
        %   Input:
        %       ra: cRecyclingAnalysis object
        %       param: struct containing the fields (DirectCost,GeneralCost)
        %   Output:
        %       res - cResultInfo object (WASTE_ANALYSIS) with the tables
        %            wd - Waste Definition
        %            wa - Waste Allocation
        %           rad - Recycling Analysis direct cost
        %           rag - Recycling Analysis generalized cost
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
        % Get a structure with the FP tables
        %   Input:
        %       dfp - cDiagramFP object
        %   Output:
        %       res - cResultInfo object (DIAGRAM_FP) with the Diagram FP tables
        %
            % Get FP adjacency tables
            tbl.atfp=obj.getAdjacencyTableFP(cType.Tables.DIAGRAM_FP,dfp.EdgesFP);
            tbl.atcfp=obj.getAdjacencyTableFP(cType.Tables.COST_DIAGRAM_FP,dfp.EdgesCFP);
            % Build the cResultInfo
            res=cResultInfo(dfp,tbl);
        end

        function res=getProductiveDiagram(obj,pd)
        % Get the productive diagram tables
        %   Input:
        %       pd - Productive Diagram
        %   Output:
        %       res - cResultInfo object (PRODUCTIVE_DIAGRAM)
        %   
            % Flows Diagram
            id=cType.Tables.FLOWS_DIAGRAM;                 
            tbl.fat=obj.getProductiveTable(id,pd.EdgesFAT);
            % Flow-Process Diagram
            id=cType.Tables.FLOW_PROCESS_DIAGRAM;
            tbl.fpat=obj.getProductiveTable(id,pd.EdgesFPAT);
            % Productive (SPF) Diagram
            id=cType.Tables.PRODUCTIVE_DIAGRAM;
            tbl.pat=obj.getProductiveTable(id,pd.EdgesPAT);
            res=cResultInfo(pd,tbl);
        end

        function res=getSummaryResults(obj,ms)
        % Get the cResultInfo for Summary Results
        %   Input:
        %       ms - cModelSummary object
        %   Output:
        %       res - cResultInfo object (SUMMARY_RESULTS) with the tables
        %           exergy - Exergy values of the model state
        %           puk - Unit consumptions of processes
        %           pI - Process irreversibility
        %           dpc - Direct cost of processes
        %           dpuc - Direct unit cost of processes
        %           dfc - Direct cost of flows
        %           dfuc - Direct unit cost of flows
        %           gpc - Generalized cost of processes
        %           gpuc - Generalized unit cost of processes
        %           gfc - Generalized cost of flows
        %           gfuc - Generalized unit cost of flows
        %
            colNames=horzcat('Key',ms.StateNames);
            % Exergy Tables
            data=ms.ExergyData;
            rowNames=obj.flowKeys;
            tp=obj.getSummaryTableProperties(cType.Tables.SUMMARY_EXERGY);
            tbl.exergy=obj.createSummaryTable(tp,data,rowNames,colNames);
            % Unit consumption Table
            tp=obj.getSummaryTableProperties(cType.Tables.SUMMARY_UNIT_CONSUMPTION);
            data=ms.UnitConsumption;
            rowNames=obj.processKeys;
            tbl.pku=createSummaryTable(obj,tp,data,rowNames,colNames);
            % Irreversibility Table
            tp=obj.getSummaryTableProperties(cType.Tables.SUMMARY_IRREVERSIBILITY);
            data=ms.Irreversibility;
            rowNames=obj.processKeys;
            tbl.pI=obj.createSummaryTable(tp,data,rowNames,colNames);
            % Cost Tables
            N=length(ms.CostValues);
            for id=1:N
                name=cType.SummaryTableIndex{id};
                tp=obj.getSummaryTableProperties(name);
                switch tp.node
                    case cType.NodeType.FLOW
                        rowNames=obj.flowKeys;
                    case cType.NodeType.PROCESS
                        rowNames=obj.processKeys(1:end-1);
                end
                data=ms.CostValues{id};
                tbl.(name)=createSummaryTable(obj,tp,data,rowNames,colNames);
            end
            % Create cResultInfo object
            res=cResultInfo(ms,tbl);
        end
    end

    methods(Access=private)    
        %-- Productive Structure Tables
        function res=getFlowsTable(obj,ps)
        % Generates a cTableCell with the flows definition
            tp=obj.getCellTableProperties(cType.Tables.FLOW_TABLE);
            rowNames=obj.flowKeys;
            colNames=obj.getTableHeader(tp);
            nrows=length(rowNames);
            ncols=tp.columns-1;
            data=cell(nrows,ncols);
            for i=1:nrows       
                sf=ps.Flows(i).from;
                st=ps.Flows(i).to;
                data{i,1}=obj.streamKeys{sf};
                data{i,2}=obj.streamKeys{st};
                data{i,3}=ps.Flows(i).type;
            end
            res=obj.createCellTable(tp,data,rowNames,colNames);
        end     
            
        function res=getStreamsTable(obj,ps)
        % Generates a cTableCell with the streams definition
            tp=obj.getCellTableProperties(cType.Tables.STREAM_TABLE);
            rowNames=obj.streamKeys;
            colNames=obj.getTableHeader(tp);
            nrows=length(rowNames);
            ncols=tp.columns-1;
            data=cell(nrows,ncols);
            for i=1:nrows
                data{i,1}=ps.Streams(i).definition;
                data{i,2}=ps.Streams(i).type;
            end
            res=obj.createCellTable(tp,data,rowNames,colNames);
        end        
            
        function res=getProcessesTable(obj,ps)
        % Generates a cTableCell with the processes definition
            tp=obj.getCellTableProperties(cType.Tables.PROCESS_TABLE);
            rowNames=obj.processKeys(1:end-1);
            colNames=obj.getTableHeader(tp);
            nrows=length(rowNames);
            ncols=tp.columns-1;
            data=cell(nrows,ncols);
            for i=1:nrows
                data{i,1}=ps.Processes(i).fuel;
                data{i,2}=ps.Processes(i).product;
                data{i,3}=ps.Processes(i).type;
            end
            res=obj.createCellTable(tp,data,rowNames,colNames);
        end
               
        %-- Exergy Analysis tables
        function res=getFlowExergy(obj,pm)
        % Generates a cTableCell with the exergy flows values
        %  Input:
        %   values - exergy values 
            tp=obj.getCellTableProperties(cType.Tables.FLOW_EXERGY);
            rowNames=obj.flowKeys;
            colNames=obj.getTableHeader(tp);
            nrows=length(rowNames);
            ncols=tp.columns-1;
            values=pm.FlowsExergy;
            edges=pm.ps.FlowStreamEdges;
            data=cell(nrows,ncols);
            for i=1:nrows  
                data{i,1}=obj.streamKeys{edges.from(i)};
				data{i,2}=obj.streamKeys{edges.to(i)};
            end
            data(:,3)=num2cell(values);		
            res=obj.createCellTable(tp,data,rowNames,colNames);
        end	    		
            
        function res=getStreamExergy(obj,values)
        % Generates a cTableCell with stream exergy values
        %  Input:
        %   values - exergy values
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
            
        function res=getProcessExergy(obj,values)
        % Generates a cTableCell with the process exergy values
        %  Input:
        %   values - exergy values
            tp=obj.getCellTableProperties(cType.Tables.PROCESS_EXERGY);
            rowNames=obj.processKeys;
            colNames=obj.getTableHeader(tp);
            nrows=length(rowNames);
            ncols=tp.columns-1;
            data=cell(nrows,ncols);
            % Processes Values
            data(:,1)=num2cell(values.vF);
            data(:,2)=num2cell(values.vP);
            data(:,3)=num2cell(values.vI);
            data(:,4)=num2cell(values.vK);
            data(:,5)=num2cell(100*values.vEf);
            res=obj.createCellTable(tp,data,rowNames,colNames);
        end

        function res=getTableFP(obj,id,values)
        % get a cTableMatrix with the Fuel-Product table
        %  Input:
        %   id - table id
        %   values - table FP values
            tp=obj.getMatrixTableProperties(id);
            rowNames=obj.processKeys;
            colNames=horzcat('Key',rowNames);
            res=obj.createMatrixTable(tp,values,rowNames,colNames);
        end

        function res=getAdjacencyTableFP(obj,id,data)
        % Generate the FP adjacency matrix
        %  Input:
        %   id - Table Id
        %   mFP - Table FP values
            tp=obj.getCellTableProperties(id);
            M=size(data,1);
            rowNames=arrayfun(@(x) sprintf('E%d',x),1:M,'UniformOutput',false);
            colNames=obj.getTableHeader(tp);
			res=obj.createCellTable(tp,data,rowNames,colNames);
		end

        function res=getProductiveTable(obj,id,data)
        % Get the productive tables
        %   Input:
        %     id - table id (printconfig.json)
        %     A - adjacency matrix
        %     nodes - node names
            tp=obj.getCellTableProperties(id);
            M=size(data,1);
            rowNames=arrayfun(@(x) sprintf('E%d',x),1:M,'UniformOutput',false);
            colNames=obj.getTableHeader(tp);
			res=obj.createCellTable(tp,data,rowNames,colNames);
        end

        function res=getWasteDefinition(obj,wt)
            tp=obj.getCellTableProperties(cType.Tables.WASTE_DEFINITION);
            flw=obj.flowKeys;
            rowNames=flw(wt.Flows);
            colNames=obj.getTableHeader(tp);
            nrows=length(rowNames);
            ncols=tp.columns-1;
            data=cell(nrows,ncols);
            for i=1:wt.NrOfWastes
                data{i,1}=wt.Type{i};
                data{i,2}=100*wt.RecycleRatio(i);
            end
            res=obj.createCellTable(tp,data,rowNames,colNames);
        end

        function res=getWasteAllocation(obj,wt)
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
                res=cStatus(cType.ERROR);
            end
        end

        %-- Thermoeconomic Analysis Tables    
        function res=getFlowCostTable(obj,id,fcost)
        % get a cTableCell with the exergy cost of flows
        %  Input:
        %	id - Table id
        %   fcost - flows cost structure values
            tp=obj.getCellTableProperties(id);
            rowNames=obj.flowKeys;        
            colNames=obj.getTableHeader(tp);
            fieldNames={tp.fields.name};
            nrows=length(rowNames);
            ncols=tp.columns-1;
            values=zeros(nrows,ncols);
            for j=2:length(fieldNames)
                values(:,j-1)=fcost.(fieldNames{j});
            end           
            res=obj.createCellTable(tp,num2cell(zerotol(values)),rowNames,colNames);
        end
            
        function res=getProcessCostTable(obj,id,cost)
        % get a cTableCell with the exergy cost of processes
        %  Input:
        %   id - table id
        %   cost - process cost structure values
            tp=obj.getCellTableProperties(id);
            rowNames=obj.processKeys(1:end-1);
            colNames=obj.getTableHeader(tp);
            fieldNames={tp.fields.name};
            nrows=length(rowNames);
            ncols=tp.columns-1;
            values=zeros(nrows,ncols);
            for j=2:length(fieldNames)
                values(:,j-1)=cost.(fieldNames{j});
            end
            res=obj.createCellTable(tp,num2cell(zerotol(values)),rowNames,colNames);
        end

        function res=getStreamCostTable(obj,id,scost)
        % get a cTableCell with the exergy cost of streams
        %  Input:
        %	id - Table id
        %   fcost - flows cost structure values
            tp=obj.getCellTableProperties(id);
            rowNames=obj.streamKeys;        
            colNames=obj.getTableHeader(tp);
            fieldNames={tp.fields.name};
            nrows=length(rowNames);
            ncols=tp.columns-1;
            values=zeros(nrows,ncols);
            for j=2:length(fieldNames)
                values(:,j-1)=scost.(fieldNames{j});
            end           
            res=obj.createCellTable(tp,num2cell(zerotol(values)),rowNames,colNames);
        end
   
        function res=getFlowICTable(obj,id,values)
        % get a cTableMatrix with the flows ICT (Irrreversibility Cost Tables)
        %   Input:
        %     id - table id
        %     values - Flow ICT values
            tp=obj.getMatrixTableProperties(id);
            rowNames=obj.processKeys;
            colNames=horzcat('Key',obj.flowKeys);
            res=obj.createMatrixTable(tp,values,rowNames,colNames);
        end
         
        function res=getProcessICTable(obj,id,values)
        % get a cTableMatrix with the  processes ICT
        %  Input:
        %   id - table id
        %   values - Processes ICT values
            tp=obj.getMatrixTableProperties(id);
            rowNames=obj.processKeys;
            colNames=horzcat('Key',obj.processKeys(1:end-1));
            res=obj.createMatrixTable(tp,values,rowNames,colNames);
        end
            
        %-- Diagnosis Tables
        function res=getDiagnosisSummary(obj,dgn)
        % Get a cTableCell with the diagnosis summary
        %  Input:
        %    dgn - diagnosis object
            tp=obj.getCellTableProperties(cType.Tables.DIAGNOSIS);
            rowNames=obj.processKeys;
            colNames=obj.getTableHeader(tp);
            nrows=length(rowNames);
            data=cell(nrows,7);     
            data(:,1)=num2cell(zerotol(dgn.getMalfunction));
            data(:,2)=num2cell(zerotol(dgn.getIrreversibilityVariation));
            data(:,3)=num2cell(zerotol(dgn.getWasteVariation));
            data(:,4)=num2cell(zerotol(dgn.getDemandVariation));
            data(:,5)=num2cell(zerotol(dgn.getMalfunctionCost));
            data(:,6)=num2cell(zerotol(dgn.getWasteMalfunctionCost));
            data(:,7)=num2cell(zerotol(dgn.getDemandVariationCost));
            res=obj.createCellTable(tp,data,rowNames,colNames);
        end
         
        function res=getMalfunctionTable(obj,values)
        % Get a cTableMatrix with the mafunction table values
        %  Input:
        %   values - Malfunction table values
            tp=obj.getMatrixTableProperties(cType.Tables.MALFUNCTION);
            rowNames=obj.processKeys;
            DPt=[cType.Symbols.delta,'Ps'];
            colNames=horzcat('key',rowNames(1:end-1),DPt);
            res=obj.createMatrixTable(tp,values,rowNames,colNames);
        end
            
        function res=getMalfunctionCostTable(obj,values,method)
        % Get a cTableMatrix with the mafunction cost table values
        %  Input:
        %   values - Malfunction cost table values
            tp=obj.getMatrixTableProperties(cType.Tables.MALFUNCTION_COST);
            rowNames=horzcat(obj.processKeys(1:end-1),'MF');
            if method==cType.DiagnosisMethod.WASTE_INTERNAL
                DPt=[cType.Symbols.delta,'Pt*'];
            else
                DPt=[cType.Symbols.delta,'Ps*'];
            end
            colNames=horzcat('key',obj.processKeys(1:end-1),DPt);
            res=obj.createMatrixTable(tp,values,rowNames,colNames);
        end
            
        function res=getIrreversibilityTable(obj,values)
        % Get a cTableMatrix with the irreversibility table values
        %  Input:
        %   values - Irreversibility table values
            tp=obj.getMatrixTableProperties(cType.Tables.IRREVERSIBILITY_VARIATION);
            rowNames=[obj.processKeys,'MF'];
            DPt=[cType.Symbols.delta,'Pt'];
            colNames=horzcat('key',obj.processKeys(1:end-1),DPt);
            res=obj.createMatrixTable(tp,values,rowNames,colNames);
        end

        function res=getTotalMalfunctionCost(obj,dgn)
            M=3;
            N=dgn.NrOfProcesses+1;
            values=zeros(N,M);
            values(:,1)=dgn.getMalfunctionCost';
            values(:,2)=dgn.getWasteMalfunctionCost';
            values(:,3)=dgn.getDemmandCorrectionCost';
            tp=obj.getMatrixTableProperties(cType.Tables.TOTAL_MALFUNCTION_COST);
            rowNames=[obj.processKeys(1:end)];
            colNames={'key','MF*','MR*','MPt*'};
            res=obj.createMatrixTable(tp,values,rowNames,colNames);
        end

        function res=getFuelImpactSummary(obj,dgn)
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
            DPs=[cType.Symbols.delta,'Ps'];
            colNames={'key',DI,DR,DPs};
            res=obj.createMatrixTable(tp,values,rowNames,colNames);
        end

        function res=createCellTable(obj,props,data,rowNames,colNames)
        % Set parameters from cPrintConfig and create cTableCell
            p.key=props.key;
            p.Description=props.description;   
            p.Unit=obj.getTableUnits(props);
            p.Format=obj.getTableFormat(props);
            p.FieldNames={props.fields.name};
            p.ShowNumber=props.number;
            p.GraphType=props.graph;
            res=cTableCell.create(data,rowNames,colNames,p);
        end
            
        function res=createMatrixTable(obj,props,data,rowNames,colNames)
        % Set parameters from cPrintConfig and create cTableMatrix
            p.key=props.key;
            p.Description=props.header;    
            p.Unit=obj.getUnit(props.type);
            p.Format=obj.getFormat(props.type);
            p.GraphType=props.graph;
            p.GraphOptions=props.options;
            p.rowTotal=props.rowTotal;
            p.colTotal=props.colTotal;
            res=cTableMatrix.create(data,rowNames,colNames,p);
        end

        function res=createSummaryTable(obj,props,data,rowNames,colNames)
        % Create a summary table (as cTableMatrix)
            p.key=props.key;
            p.Description=props.header;    
            p.Unit=obj.getUnit(props.type);
            p.Format=obj.getFormat(props.type);
            p.GraphType=props.graph;
            p.GraphOptions=props.options;
            p.rowTotal=false;
            p.colTotal=false;
            res=cTableMatrix.create(data,rowNames,colNames,p);
        end
    end
end
