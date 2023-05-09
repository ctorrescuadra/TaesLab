classdef (Sealed) cResultTableBuilder < cReadFormat
% cResultTableBuilder Generates the cModelResults objects for ExIOLab applications.
%   This class provide methods to obtain the cResultInfo of each application
%   Methods:
%       obj=cResultTableBuilder(cfglocal,ps)
%       res=obj.getProductiveStructureResults(ps)
%       res=obj.getExergyResults(pm)
%       res=obj.getWasteResults(wt)
%       res=obj.getExergyCostResults(pm,options)
%       res=obj.getThermoeconomicAnalysisResults(mfp,options)
%       res=obj.getThermoeconomicDiagnosisResults(dgn)
%       res=obj.getDiagramFP(pm)
%       res=obj.getRecyclingAnalysis(ra)
% Methods from cReadFormat:
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
% See also cReadFormat, cResultInfo
%
    properties(Access=private)
        flowKeys     % Flow Key names
        streamKeys   % Stream Key names
        processKeys  % Process Key names
    end
    
    methods
        function obj=cResultTableBuilder(data,ps)
        % Create the cResultTableBuilder associated to a plant (productive structure)
        %  Input:
        %   data - format data struct
        %   ps - productive structure object
            obj=obj@cReadFormat(data);
            if ~isa(ps,'cProductiveStructure') || ~isValid(ps)
				obj.messageLog(cType.ERROR,'No valid Productive Structure provided');
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

        function res=getWasteResults(obj,wt)
            tbl=struct();
            tbl.wd=obj.getWasteDefinition(wt);
            tbl.wa=obj.getWasteAllocation(wt);
            res=cResultInfo(wt,tbl);
        end
        
        function res=getExergyResults(obj,pm)
        % Generate the exergy result tables
        %  Input:
        %   e - cProcessModel object
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
            tbl.tfp=obj.getTableFP(cType.MatrixTable.TABLE_FP,pm.TableFP);
            res=cResultInfo(pm,tbl);
            if res.ResultId~=cType.ResultId.THERMOECONOMIC_STATE
                res.setResultId(cType.ResultId.THERMOECONOMIC_STATE);
            end
        end
        
        function res=getExergyCostResults(obj,ect,options)
        % Generate the exergy cost result tables
        %  Input:
        %   ect - cExergyCost object
        %   options - structure containing the fields
        %       DirectCost - Direct Cost Tables will be obtained
        %       GeneralCost - General Cost Tables will be obtained
        %       ResourceCost - [optional] cReadResources object if
        %       generalized cost is required
        %  Output:
        %   res - cResultInfo object (EXERGY_COST_CALCULATION) with the result tables
        %    Direct Cost Tables:
        %       dfcost: direct exergy cost of flows
        %       dcost: direct exergy cost of processes
        %       udcost: unit direct cost of processes
        %       dfict: direct irreversibility cost table of flows
        %       dict: direct irreversibility cost table of processes
        %    Generalized Cost Tables:
        %       gfcost: generalized exergy cost of flows
        %       gcost: generalizd exergy cost of processes
        %       ugcost: unit generalized cost of processes
        %       gfict: generalized irreversibility cost table of flows
        %       gict:  generalized irreversibility cost table of processes
            tbl=struct();
            if ect.isWaste
                tbl.wa=obj.getWasteAllocation(ect.WasteTable);
            end
            if options.DirectCost
                dfcost=ect.getDirectFlowsCost;
                [dcost,udcost]=ect.getDirectProcessCost(dfcost);
                dfict=ect.getFlowsICT;
                dict=ect.getProcessICT(dfict);
                tbl.dfcost=obj.getFlowCostTable(cType.CellTable.FLOW_EXERGY_COST,dfcost);
                tbl.dcost=obj.getProcessCostTable(cType.CellTable.PROCESS_COST,dcost);
                tbl.udcost=obj.getProcessCostTable(cType.CellTable.PROCESS_UNIT_COST,udcost);
                tbl.dfict=obj.getFlowICTable(cType.MatrixTable.FLOW_ICT,dfict);
                tbl.dict=obj.getProcessICTable(cType.MatrixTable.PROCESS_ICT,dict);
            end
            if options.GeneralCost
                cz=options.ResourcesCost;
                gfcost=ect.getGeneralFlowsCost(cz);
                [gcost,ugcost]=ect.getGeneralProcessCost(gfcost,cz);
                gfict=ect.getFlowsICT(cz);
                gict=ect.getProcessICT(gfict,cz);
                tbl.gfcost=obj.getFlowCostTable(cType.CellTable.FLOW_GENERALIZED_COST,gfcost);
                tbl.gcost=obj.getProcessCostTable(cType.CellTable.PROCESS_GENERALIZED_COST,gcost);
                tbl.ugcost=obj.getProcessCostTable(cType.CellTable.PROCESS_GENERALIZED_UNIT_COST,ugcost);
                tbl.gfict=obj.getFlowICTable(cType.MatrixTable.FLOW_GENERALIZED_ICT,gfict);
                tbl.gict=obj.getProcessICTable(cType.MatrixTable.PROCESS_GENERALIZED_ICT,gict);
            end
            res=cResultInfo(ect,tbl);
        end
            
        function res=getThermoeconomicAnalysisResults(obj,mfp,options)
        % Get a structure containing the tables for Thermoeconomic Analysis function
        %   Input:
        %       pm - ProcessModel object
        %       options - structure containing the fields
        %           DirectCost - Direct Cost Tables will be obtained
        %           GeneralCost - General Cost Tables will be obtained
        %           ResourceCost - [optional] cReadResources object if
        %               generalized cost is required
        %   Output:
        %       res - cResultInfo object (THERMOECONOMIC_ANALYSIS) with the result tables
        %
            tbl=struct();

            if options.DirectCost
                dcost=mfp.getDirectProcessCost;
                udcost=mfp.getDirectProcessUnitCost;
                dfcost=mfp.getDirectFlowsCost(udcost);    
                dcfp=mfp.getCostTableFP;
                dcfpr=mfp.getCostTableFPR;
                dict=mfp.getProcessICT;
                dfict=mfp.getFlowsICT(dict);               
                tbl.dcost=obj.getProcessCostTable(cType.CellTable.PROCESS_COST,dcost);
                tbl.ducost=obj.getProcessCostTable(cType.CellTable.PROCESS_UNIT_COST,udcost);
                tbl.dfcost=obj.getFlowCostTable(cType.CellTable.FLOW_EXERGY_COST,dfcost);
                tbl.dcfp=obj.getTableFP(cType.MatrixTable.COST_TABLE_FP,dcfp);
                tbl.dcfpr=obj.getTableFP(cType.MatrixTable.COST_TABLE_FPR,dcfpr);
                tbl.dict=obj.getProcessICTable(cType.MatrixTable.PROCESS_ICT,dict);
                tbl.dfict=obj.getFlowICTable(cType.MatrixTable.FLOW_ICT,dfict);
                if mfp.isWaste
                    tbl.dcfpr=obj.getTableFP(cType.MatrixTable.COST_TABLE_FPR,dcfpr);
                    tbl.wa=obj.getWasteAllocation(mfp.WasteData);
                end
            end
            if options.GeneralCost
                cz=options.ResourcesCost;
                gcost=mfp.getGeneralProcessCost(cz);
                ugcost=mfp.getGeneralProcessUnitCost(cz);
                gfcost=mfp.getGeneralFlowsCost(ugcost,cz);    
                gcfp=mfp.getCostTableFPR(cz);
                gict=mfp.getProcessICT(cz);
                gfict=mfp.getFlowsICT(gict,cz);   
                tbl.gcost=obj.getProcessCostTable(cType.CellTable.PROCESS_GENERALIZED_COST,gcost);
                tbl.gucost=obj.getProcessCostTable(cType.CellTable.PROCESS_GENERALIZED_UNIT_COST,ugcost);
                tbl.gfcost=obj.getFlowCostTable(cType.CellTable.FLOW_GENERALIZED_COST,gfcost);
                tbl.gict=obj.getProcessICTable(cType.MatrixTable.PROCESS_GENERALIZED_ICT,gict);
                tbl.gfict=obj.getFlowICTable(cType.MatrixTable.FLOW_GENERALIZED_ICT,gfict);
                tbl.gcfp=obj.getTableFP(cType.MatrixTable.GENERALIZED_COST_TABLE,gcfp);
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
            tbl.mf=obj.getMalfunctionTable(dgn.MalfunctionTable);
            tbl.mfc=obj.getMalfunctionCostTable(dgn.MalfunctionCostTable);
            tbl.dit=obj.getIrreversibilityTable(dgn.IrreversibilityTable);
            res=cResultInfo(dgn,tbl);
        end

        function res=getDiagramFP(obj,mfp,option)
        % Get a structure with the FP tables
        %   Input:
        %       mfp - cModelFPR object
        %       option - table to analyze
        %   Output:
        %       res - cResultInfo object (DIAGRAM_FP) with the Diagram FP tables
            res=cStatusLogger();
            if nargin==2 
                option=cType.Tables.TABLE_FP;
            end
            switch option
                case cType.Tables.TABLE_FP
                values=mfp.TableFP;
                tbl.tfp=obj.getTableFP(cType.MatrixTable.TABLE_FP,values);
                tbl.atfp=obj.getAdjacencyTableFP(cType.CellTable.DIAGRAM_FP,values);
                case cType.Tables.COST_TABLE_FP
                values=mfp.getCostTableFP;
                tbl.tfp=obj.getTableFP(cType.MatrixTable.COST_TABLE_FP,values);
                tbl.atfp=obj.getAdjacencyTableFP(cType.CellTable.COST_DIAGRAM_FP,values);
            otherwise
                res.messageLog(cType.ERROR,'Invalid object %s',arg.ResultName);
                return
            end
            res=cResultInfo(mfp,tbl);
            res.setResultId(cType.ResultId.DIAGRAM_FP);
        end

        function res=getRecyclingAnalysisResults(obj,ra,param)
        % Get a structure with the tables of cRecyclingAnalisys function
        %   Input:
        %       ra: cRecyclingAnalysis object
        %   Output:
        %       res - cResultInfo object (RECYCLING_ANALYSIS) with the tables
        %           rad - Recycling Analysis direct cost
        %           rag - Recycling Analysis generalized cost
            colNames=horzcat('Recycle (%)',ra.OutputFlows);
            tmp=int8(100*ra.dValues(:,1));
            rowNames=arrayfun(@(x) sprintf('%6d',x),tmp,'UniformOutput',false);
            if param.DirectCost
                id=cType.MatrixTable.WASTE_RECYCLING_DIRECT;
                data=ra.dValues(:,2:end);
                tbl.rad=obj.createMatrixTable(id,data,rowNames',colNames);
            end
            if param.GeneralCost
                id=cType.MatrixTable.WASTE_RECYCLING_GENERAL;
                data=ra.gValues(:,2:end);
                tbl.rag=obj.createMatrixTable(id,data,rowNames',colNames);
            end
            res=cResultInfo(ra,tbl);
        end

        function res=getProductiveDiagram(obj,ps)
        % Get the productive diagram tables
        %   Input:
        %       ps - Productive Structure
        %   Output:
        %       res - cResultInfo object (PRODUCTIVE_DIAGRAM)    
            id=cType.CellTable.FLOWS_DIAGRAM;
            A=ps.StructuralMatrix;
            nodes=obj.flowKeys;
            tbl.fat=obj.getProductiveTable(id,A,nodes);
            id=cType.CellTable.PRODUCTIVE_DIAGRAM;
            A=ps.ProductiveMatrix;
            nodes=[obj.streamKeys,obj.flowKeys,obj.processKeys(1:end-1)];
            tbl.pat=obj.getProductiveTable(id,A,nodes);
            res=cResultInfo(ps,tbl);      
        end

        function res=getSummaryResults(obj,ms)
        % Get the cResultInfo for Summary Results
        %   Input:
        %       ms - cModelSummary object
        %   Output:
        %       res - cResultInfo object (SUMMARY_RESULTS) with the tables
        %           exergy - Exergy values of the model state
        %           puk - Unit consumptions of processes
        %           dpc - Direct cost of processes
        %           dpuc - Direct unit cost of processes
        %           dfc - Direct cost of flows
        %           dfuc - Direct unit cost of flows
        %           gpc - Generalized cost of processes
        %           gpuc - Generalized unit cost of processes
        %           gfc - Generalized cost of flows
        %           gfuc - Generalized unit cost of flows

            colNames=horzcat('Key',ms.StateNames);
            % Exergy Tables
            id=cType.SummaryId.EXERGY;
            data=ms.ExergyData;
            rowNames=obj.flowKeys;
            tbl.exergy=createSummaryTable(obj,id,data,rowNames,colNames);
            % Unit consumption Table
            id=cType.SummaryId.UNIT_CONSUMPTION;
            data=ms.UnitConsumption;
            rowNames=obj.processKeys(1:end-1);
            tbl.pku=createSummaryTable(obj,id,data,rowNames,colNames);
            % Cost Tables
            N=length(ms.CostValues);
            for id=1:N
                name=cType.SummaryTableIndex{id};
                if bitget(id-1,2)
                    rowNames=obj.flowKeys;
                else
                    rowNames=obj.processKeys(1:end-1);
                end
                data=ms.CostValues{id};
                tbl.(name)=createSummaryTable(obj,id,data,rowNames,colNames);
            end
            % Create cResultInfo object
            res=cResultInfo(ms,tbl);
        end
    end

    methods(Access=private)    
        %-- Productive Structure Tables
        function res=getFlowsTable(obj,ps)
        % Generates a cTableCell with the flows definition
            id=cType.CellTable.FLOW_TABLE;
            rowNames=obj.flowKeys;
            colNames=obj.getTableHeader(id);
            nrows=length(rowNames);
            ncols=length(colNames)-1;
            data=cell(nrows,ncols);
            for i=1:nrows       
                sf=ps.Flows(i).from;
                st=ps.Flows(i).to;
                data{i,1}=obj.streamKeys{sf};
                data{i,2}=obj.streamKeys{st};
                data{i,3}=ps.Flows(i).type;
            end
            res=obj.createCellTable(id,data,rowNames,colNames);
        end     
            
        function res=getStreamsTable(obj,ps)
        % Generates a cTableCell with the streams definition
            id=cType.CellTable.STREAM_TABLE;
            rowNames=obj.streamKeys;
            colNames=obj.getTableHeader(id);
            nrows=length(rowNames);
            ncols=length(colNames)-1;
            data=cell(nrows,ncols);
            for i=1:nrows
                data{i,1}=ps.Streams(i).description;
                data{i,2}=ps.Streams(i).type;
            end
            res=obj.createCellTable(id,data,rowNames,colNames);
        end        
            
        function res=getProcessesTable(obj,ps)
        % Generates a cTableCell with the processes definition
            id=cType.CellTable.PROCESS_TABLE;
            rowNames=obj.processKeys(1:end-1);
            colNames=obj.getTableHeader(id);
            nrows=length(rowNames);
            ncols=length(colNames)-1;
            data=cell(nrows,ncols);
            for i=1:nrows
                data{i,1}=ps.Processes(i).description;
                data{i,2}=ps.Processes(i).fuel;
                data{i,3}=ps.Processes(i).product;
                data{i,4}=ps.Processes(i).type;
            end
            res=obj.createCellTable(id,data,rowNames,colNames);
        end
               
        %-- Exergy Analysis tables
        function res=getFlowExergy(obj,pm)
        % Generates a cTableCell with the exergy flows values
        %  Input:
        %   values - exergy values 
            id=cType.CellTable.FLOW_EXERGY;
            rowNames=obj.flowKeys;
            colNames=obj.getTableHeader(id);
            nrows=length(rowNames);
            ncols=length(colNames)-1;
            values=pm.FlowsExergy;
            edges=pm.ps.FlowStreamEdges;
            data=cell(nrows,ncols);
            for i=1:nrows  
                data{i,1}=obj.streamKeys{edges.from(i)};
				data{i,2}=obj.streamKeys{edges.to(i)};
            end
            data(:,3)=num2cell(values);		
            res=obj.createCellTable(id,data,rowNames,colNames);
        end	    		
            
        function res=getStreamExergy(obj,values)
        % Generates a cTableCell with stream exergy values
        %  Input:
        %   values - exergy values
            id=cType.CellTable.STREAM_EXERGY;
            rowNames=obj.streamKeys;
            colNames=obj.getTableHeader(id);
            nrows=length(rowNames);
            ncols=length(colNames)-1;
            data=cell(nrows,ncols);
            data(:,1)=num2cell(values.E);
            data(:,2)=num2cell(values.ET);
            res=obj.createCellTable(id,data,rowNames,colNames);
        end
            
        function res=getProcessExergy(obj,values)
        % Generates a cTableCell with the process exergy values
        %  Input:
        %   values - exergy values
            id=cType.CellTable.PROCESS_EXERGY;
            rowNames=obj.processKeys;
            colNames=obj.getTableHeader(id);
            nrows=length(rowNames);
            ncols=length(colNames)-1;
            data=cell(nrows,ncols);
            % Processes Values
            data(:,1)=num2cell(values.vF);
            data(:,2)=num2cell(values.vP);
            data(:,3)=num2cell(values.vI);
            data(:,4)=num2cell(values.vK);
            res=obj.createCellTable(id,data,rowNames,colNames);
        end

        function res=getTableFP(obj,id,values)
        % get a cTableMatrix with the Fuel-Product table
        %  Input:
        %   id - table id
        %   values - table FP values
            rowNames=obj.processKeys;
            colNames=horzcat('Key',rowNames);
            res=obj.createMatrixTable(id,values,rowNames,colNames);
        end

        function res=getAdjacencyTableFP(obj,id,mFP)
        % Generate the FP adjacency matrix
        %  Input:
        %   id - Table Id
        %   mFP - Table FP values
            nodes=obj.processKeys;
            [idx,jdx,ival]=find(mFP(1:end-1,1:end-1));
            isource=nodes(idx);
            itarget=nodes(jdx);
            % Build Resources Edges
            [~,jdx,vval]=find(mFP(end,1:end-1));
            vsource=arrayfun(@(x) sprintf('IN%d',x),1:numel(jdx),'UniformOutput',false);
            vtarget=nodes(jdx);
            % Build Output edges
            [idx,~,wval]=find(mFP(1:end-1,end));
            wtarget=arrayfun(@(x) sprintf('OUT%d',x),1:numel(idx),'UniformOutput',false);
            wsource=nodes(idx);
            % Build object
            source=[vsource,isource,wsource];
            target=[vtarget,itarget,wtarget];
            values=[vval';ival;wval];
            data=[source', target', num2cell(values)];
            M=size(values,1);
            rowNames=arrayfun(@(x) sprintf('E%d',x),1:M,'UniformOutput',false);
            colNames=obj.getTableHeader(id);
			res=obj.createCellTable(id,data,rowNames,colNames);
            res.setGraphType(cType.GraphType.DIGRAPH);
		end

        function res=getProductiveTable(obj,id,A,nodes)
        % Get the productive tables
        %   Input:
        %     id - table id (printconfig.json)
        %     A - adjacency matrix
        %     nodes - node names
            [idx,jdx,~]=find(A);
            source=nodes(idx);
            target=nodes(jdx);
            data=[source', target'];
            M=numel(source);
            rowNames=arrayfun(@(x) sprintf('E%d',x),1:M,'UniformOutput',false);
            colNames=obj.getTableHeader(id);
			res=obj.createCellTable(id,data,rowNames,colNames);
            res.setGraphType(cType.GraphType.DIGRAPH);
        end

        function res=getWasteDefinition(obj,wt)
            id=cType.CellTable.WASTE_DEFINITION;
            flw=obj.flowKeys;
            rowNames=flw(wt.Flows);
            colNames=obj.getTableHeader(id);
            nrows=length(rowNames);
            ncols=length(colNames)-1;
            data=cell(nrows,ncols);
            for i=1:wt.NrOfWastes
                data{i,1}=wt.Type{i};
                data{i,2}=100*wt.RecycleRatio(i);
            end
            res=obj.createCellTable(id,data,rowNames,colNames);
        end

        function res=getWasteAllocation(obj,wt)
            res=cStatusLogger();
            id=cType.MatrixTable.WASTE_ALLOCATION;
            flw=obj.flowKeys;
            prc=obj.processKeys;
            colNames=['Key',flw(wt.Flows)];
            tmp=100*[wt.Values';wt.RecycleRatio];
            [idx,~]=find(tmp);idx=unique(idx);
            if ~isempty(idx)
                rowNames=prc(idx);
                values=tmp(idx,:);
                res=obj.createMatrixTable(id,values,rowNames,colNames);
            else
                res.messageLog(cType.WARNING,'No Waste allocation table defined');
            end
        end

        %-- Thermoeconomic Analysis Tables    
        function res=getFlowCostTable(obj,id,fcost)
        % get a cTableCell with the exergy cost of flows
        %  Input:
        %	id - Table id
        %   fcost - flows cost structure values
            rowNames=obj.flowKeys;        
            colNames=obj.getTableHeader(id);
            fieldNames=obj.getFieldNames(id);
            nrows=length(rowNames);
            ncols=length(colNames)-1;
            values=zeros(nrows,ncols);
            for j=2:length(fieldNames)
                values(:,j-1)=fcost.(fieldNames{j});
            end           
            res=obj.createCellTable(id,num2cell(values),rowNames,colNames);
        end
            
        function res=getProcessCostTable(obj,id,cost)
        % get a cTableCell with the exergy cost of processes
        %  Input:
        %   id - table id
        %   cost - process cost structure values
            rowNames=obj.processKeys(1:end-1);
            colNames=obj.getTableHeader(id);
            fieldNames=obj.getFieldNames(id);
            nrows=length(rowNames);
            ncols=length(colNames)-1;
            values=zeros(nrows,ncols);
            for j=2:length(fieldNames)
                values(:,j-1)=cost.(fieldNames{j});
            end
            res=obj.createCellTable(id,num2cell(values),rowNames,colNames);
        end 
        
        function res=getFlowICTable(obj,id,values)
        % get a cTableMatrix with the flows ICT (Irrreversibility Cost Tables)
        %   Input:
        %     id - table id
        %     values - Flow ICT values 
            rowNames=obj.processKeys;
            colNames=horzcat('Key',obj.flowKeys);
            res=obj.createMatrixTable(id,values,rowNames,colNames);
        end
         
        function res=getProcessICTable(obj,id,values)
        % get a cTableMatrix with the  processes ICT
        %  Input:
        %   id - table id
        %   values - Processes ICT values 
            rowNames=obj.processKeys;
            colNames=horzcat('Key',obj.processKeys(1:end-1));
            res=obj.createMatrixTable(id,values,rowNames,colNames);
        end
            
        %-- Diagnosis Tables
        function res=getDiagnosisSummary(obj,dgn)
        % Get a cTableCell with the diagnosis summary
        %  Input:
        %    dgn - diagnosis object
            id=cType.CellTable.DIAGNOSIS;
            rowNames=obj.processKeys;
            colNames=obj.getTableHeader(id);
            nrows=length(rowNames);
            data=cell(nrows,6);     
            data(:,1)=num2cell(dgn.Malfunction);
            data(:,2)=num2cell(dgn.IrreversibilityVariation);
            data(:,3)=num2cell(dgn.OutputVariation);
            data(:,4)=num2cell(dgn.MalfunctionCost);
            data(:,5)=num2cell(dgn.WasteVariationCost);
            data(:,6)=num2cell(dgn.DemandVariationCost);
            res=obj.createCellTable(id,data,rowNames,colNames);
        end
         
        function res=getMalfunctionTable(obj,values)
        % Get a cTableMatrix with the mafunction table values
        %  Input:
        %   values - Malfunction table values
            id=cType.MatrixTable.MALFUNCTION_TABLE;
            rowNames=obj.processKeys;
            colNames=horzcat(' ',rowNames(1:end-1),'DPs');
            res=obj.createMatrixTable(id,values,rowNames,colNames);
        end
            
        function res=getMalfunctionCostTable(obj,values)
        % Get a cTableMatrix with the mafunction cost table values
        %  Input:
        %   values - Malfunction cost table values
            id=cType.MatrixTable.MALFUNCTION_COST_TABLE;
            rowNames=horzcat(obj.processKeys(1:end-1),'MF');
            colNames=horzcat(' ',obj.processKeys(1:end-1),'DCPs');
            res=obj.createMatrixTable(id,values,rowNames,colNames);
        end
            
        function res=getIrreversibilityTable(obj,values)
        % Get a cTableMatrix with the irreversibility table values
        %  Input:
        %   values - Irreversibility table values
            id=cType.MatrixTable.IRREVERSIBILITY_TABLE;
            rowNames=[obj.processKeys,'MF'];
            colNames=horzcat(' ',obj.processKeys(1:end-1),'DPs');
            res=obj.createMatrixTable(id,values,rowNames,colNames);
        end

        function res=createCellTable(obj,id,data,rowNames,colNames)
        % Create a cell table and set parameters from cPrintConfig
            res=cTableCell(data,rowNames,colNames);
            p.key=obj.getTableKey(id);
            p.Description=obj.getTableDescription(id);    
            p.Unit=obj.getTableUnits(id);
            p.Format=obj.getTableFormat(id);
            p.FieldNames=obj.getFieldNames(id);
            p.ShowNumber=obj.showNumber(id);
            res.setProperties(p);
        end
            
        function res=createMatrixTable(obj,id,data,rowNames,colNames)
        % Create a matrix table and set parameters from cPrintConfig
            [rTotal,cTotal]=obj.getMatrixTotal(id);
            res=cTableMatrix(data,rowNames,colNames,rTotal,cTotal);
            p.key=obj.getMatrixKey(id);
            p.Description=obj.getMatrixDescription(id);    
            p.Unit=obj.getMatrixUnit(id);
            p.Format=obj.getMatrixFormat(id);
            p.GraphType=obj.getMatrixGraphType(id);
            p.GraphOptions=obj.getMatrixGraphOptions(id);
            res.setProperties(p);
        end

        function res=createSummaryTable(obj,id,data,rowNames,colNames)
        % Create a summary table (as cTableMatrix and set parameters)
            res=cTableMatrix(data,rowNames,colNames,false,false);
            p.key=obj.getSummaryKey(id);
            p.Description=obj.getSummaryDescription(id);    
            p.Unit=obj.getSummaryUnit(id);
            p.Format=obj.getSummaryFormat(id);
            p.GraphType=cType.GraphType.SUMMARY;
            p.GraphOptions=obj.getSummaryGraphOptions(id);
            res.setProperties(p);
        end
    end
end
