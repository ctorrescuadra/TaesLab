classdef cExergyModel < cResultId
%cExergyModel - Builds the Flow-Process exergy model for a plant state.
%   Constructs the FP (Fuel-Product) table and all supporting matrices from a
%   validated cExergyData object. Provides the exergy analysis results including
%   process fuel/product/irreversibility, unit consumption, efficiency, and the
%   demand-driven Flow-Process model matrices used by cExergyCost.
%
%   The FP table is built by composing the demand-driven adjacency matrices:
%     TableFP = mP * mL * tgF   (or mP * tgF for IO-type models)
%   where mL = (I - mV)^{-1} is the Leontief inverse of internal flow recirculation.
% 
%   cExergyModel properties:
%     NrOfFlows            - Number of flows in the productive structure
%     NrOfProcesses        - Number of processes (productive + dissipative)
%     NrOfStreams          - Number of productive streams
%     NrOfWastes           - Number of waste (dissipative) processes
%     FlowsExergy          - Exergy vector of all flows [1 x M]
%     ProcessesExergy      - Struct with per-process vF, vP, vI, vK, vEf (includes plant totals at last index)
%     StreamsExergy        - Struct with productive stream exergy E and total ET
%     FlowProcessModel     - Struct with demand-driven matrices: mV, mF, mF0, mP, mL
%     AdjacencyTable       - Exergy-scaled adjacency tables (AF, AP, AE, AS)
%     TableFP              - Full FP table matrix [N+1 x N+1]
%     FuelExergy           - Process fuel exergy vector [1 x N] (excludes plant-total row)
%     ProductExergy        - Process product exergy vector [1 x N]
%     Irreversibility      - Process irreversibility vector [1 x N]
%     UnitConsumption      - Process unit consumption vector [1 x N] (kj = Fj/Pj)
%     Efficiency           - Process exergy efficiency vector [1 x N] (percent)
%     TotalResources       - Scalar total resource exergy entering the plant
%     FinalProducts        - Scalar total final product exergy leaving the plant
%     TotalOutput          - Scalar total output exergy (final products + waste flows)
%     TotalIrreversibility - Scalar total plant irreversibility
%     TotalUnitConsumption - Scalar plant-level unit consumption (TotalResources/FinalProducts)
%     ActiveProcesses      - Logical vector [1 x N]; false for bypassed processes
%
%   cExergyModel methods:
%     cExergyModel            - Create an instance of the class
%     buildResultInfo         - Build the cResultInfo object for EXERGY_ANALYSIS
%     FlowProcessTable        - Get the exergy-scaled Flow-Process table (tV, tF, tP)
%     InternalIrreversibility - Get the total internal irreversibility (sum of process vI)
%     ExternalIrreversibility - Get the total external irreversibility (sum of waste flow exergy)
%
%   See also cExergyData, cExergyCost, cResultId, cResultInfo
%
	properties (GetAccess=public, SetAccess=protected)
		NrOfFlows        	  % (integer) Number of flows in the productive structure
		NrOfProcesses    	  % (integer) Number of processes (productive + dissipative)
		NrOfStreams           % (integer) Number of productive streams
		NrOfWastes       	  % (integer) Number of waste (dissipative) processes
		FlowsExergy      	  % (double) Row vector [1xM] of exergy values for all flows
		ProcessesExergy  	  % (struct) Per-process exergy data: vF, vP, vI, vK, vEf; last element is the plant total
		StreamsExergy    	  % (struct) Productive stream exergy: E (stream exergy), ET (total stream exergy)
		FlowProcessModel      % (struct) Demand-driven Flow-Process matrices: mV (recirculation), mF (fuel side), mF0 (normalized fuel), mP (product side), mL (Leontief inverse)
        AdjacencyTable        % (struct) Exergy-scaled adjacency tables: AF, AP, AE, AS
        TableFP               % (double) Full FP (Fuel-Product) table matrix [N+1 x N+1]
		FuelExergy            % (double) Row vector [1xN] of process fuel exergy (excludes plant-total)
		ProductExergy         % (double) Row vector [1xN] of process product exergy
		Irreversibility       % (double) Row vector [1xN] of process irreversibilities
		UnitConsumption       % (double) Row vector [1xN] of unit consumption values (kj = Fj/Pj)
        Efficiency            % (double) Row vector [1xN] of process exergy efficiencies (percent)
		TotalResources		  % (double) Scalar total resource exergy entering the plant
		FinalProducts         % (double) Scalar total final product exergy leaving the plant
		TotalOutput           % (double) Scalar total output exergy (final products + waste flows)
		TotalIrreversibility  % (double) Scalar total plant irreversibility
		TotalUnitConsumption  % (double) Scalar plant-level unit consumption (= TotalResources / FinalProducts)
        ActiveProcesses       % (logical) Row vector [1xN]; true for active processes, false for bypassed ones
	    ps					  % (cProductiveStructure) Productive structure object used during construction
    end

	methods
		function obj=cExergyModel(exd)
		%cExergyModel - Create an instance of the cExergyModel class.
		%   Validates the input exergy data, builds the demand-driven Flow-Process
		%   matrices, and constructs the FP table. For standard (non-IO) models the
		%   Leontief inverse mL = (I - mV)^{-1} is computed to handle internal flow
		%   recirculation; IO models skip this step (mL = I, mV = 0).
		%
		%   Syntax:
		%     obj = cExergyModel(exd)
		%   Input Arguments:
		%     exd - (cExergyData) Validated exergy data object for the state to analyze
		%   Output Arguments:
		%     obj - (cExergyModel) Constructed object; obj.status is false if exd is invalid
		
			% Validate input type
            if ~isObject(exd,'cExergyData')
				obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(exd));
				return
            end
			% Retrieve pre-computed exergy-scaled adjacency tables and demand-driven matrices
			tbl=exd.AdjacencyTable;
			mat=exd.AdjacencyMatrix;
			% Compose intermediate demand-driven matrices:
			%   mgF = AE * AF  — maps fuel-side flows to process nodes (demand-driven)
			%   tgF = AE * AF  — exergy-scaled version of the same mapping
			%   mgP = AP * AS  — maps process product nodes to output-side flows
			mgF=mat.AE*mat.AF;
			tgF=mat.AE*tbl.AF;
			mgP=mat.AP*mat.AS;
			% Build the FP table and the Leontief inverse mL:
			%   For IO models: no internal recirculation, mV = 0, mL = I
			%   For standard models: mV = AE*AS captures internal recirculation;
			%     mL = (I - mV)^{-1} is the Leontief inverse resolving recirculation loops
			M=exd.ps.NrOfFlows;
			if exd.ps.isModelIO
				mgV=sparse(M,M);
				mL=speye(M);
				mpL=mgP;
				tfp=mgP*tgF;
			else
				mgV=mat.AE*mat.AS;
				mL=speye(M)/(speye(M)-mgV);
				mpL=mgP*mL;
				tfp=mpL*tgF;
			end
			% Build the normalized fuel adjacency matrix mgF0:
			%   Divides each column of tbl.AF by its total process fuel (vF),
			%   giving the fractional fuel contribution of each flow to each process
			vF=sum(tfp,1);
			AF0=divideCol(tbl.AF,vF);
			mgF0=mat.AE*AF0;
			% Store all matrices and copy data from the exergy data object
			obj.FlowProcessModel=struct('mV',mgV,'mF',mgF,'mF0',mgF0,'mP',mgP,'mL',mL,'mpL',mpL);
			obj.TableFP=full(tfp);
            obj.ps=exd.ps;
            obj.NrOfFlows=exd.ps.NrOfFlows;
			obj.NrOfProcesses=exd.ps.NrOfProcesses;
			obj.NrOfStreams=exd.ps.NrOfStreams;
			obj.NrOfWastes=exd.ps.NrOfWastes;
			obj.FlowsExergy=exd.FlowsExergy;			
			obj.ProcessesExergy=exd.ProcessesExergy;
			obj.StreamsExergy=exd.StreamsExergy;
			obj.AdjacencyTable=exd.AdjacencyTable;
            obj.ActiveProcesses=exd.ActiveProcesses;
			obj.DefaultGraph=cType.Tables.TABLE_FP;
			% Set cResultId identification properties
			obj.ResultId=cType.ResultId.THERMOECONOMIC_STATE;
            obj.ModelName=obj.ps.ModelName;
            obj.State=exd.State;
		end		       		
    
		function res=get.FuelExergy(obj)
		% Returns vF(1:N): fuel exergy for each process, excluding the plant-total last element.
			res=cType.EMPTY;
			if obj.status
				res=obj.ProcessesExergy.vF(1:end-1);
			end
		end

		function res=get.ProductExergy(obj)
		% Returns vP(1:N): product exergy for each process, excluding the plant-total last element.
			res=cType.EMPTY;
			if obj.status
				res=obj.ProcessesExergy.vP(1:end-1);
			end
		end

		function res=get.Irreversibility(obj)
		% Returns vI(1:N): irreversibility for each process, excluding the plant-total last element.
			res=cType.EMPTY;
			if obj.status
				res=obj.ProcessesExergy.vI(1:end-1);
			end
		end

		function res=get.UnitConsumption(obj)
		% Returns vK(1:N): unit consumption (kj = Fj/Pj) for each process, excluding the plant-total.
			res=cType.EMPTY;
			if obj.status
				res=obj.ProcessesExergy.vK(1:end-1);	
			end
        end

        function res=get.Efficiency(obj)
		% Returns vEf(1:N): exergy efficiency (percent) for each process, excluding the plant-total.
			res=cType.EMPTY;
			if obj.status
				res=obj.ProcessesExergy.vEf(1:end-1);
			end
        end

		function res=get.TotalResources(obj)
		% Returns vF(end): total resource exergy entering the plant (last element of vF).
			res=cType.EMPTY;
			if obj.status
				res=obj.ProcessesExergy.vF(end);
			end
		end

		function res=get.FinalProducts(obj)
		% Returns vP(end): total final product exergy leaving the plant (last element of vP).
			res=cType.EMPTY;
			if obj.status
				res=obj.ProcessesExergy.vP(end);
			end
		end

		function res=get.TotalUnitConsumption(obj)
		% Returns vK(end): plant-level unit consumption = TotalResources / FinalProducts.
			res=cType.EMPTY;
			if obj.status
				res=obj.ProcessesExergy.vK(end);
			end
		end

		function res=get.TotalIrreversibility(obj)
		% Returns vI(end): total plant irreversibility = TotalResources - TotalOutput.
			res=cType.EMPTY;
			if obj.status
				res=obj.ProcessesExergy.vI(end);
			end
        end

		function res=get.TotalOutput(obj)
		%TotalOutput - Get the total output exergy (final products + waste flows).
		%   Sums the last column of TableFP over all process rows (1:N), which
		%   captures both final product flows and waste flows delivered out of the system.
		%
		%   Syntax:
		%     res = obj.TotalOutput
		%   Output Arguments:
		%     res - (double) Scalar total output exergy
		%
			res=cType.EMPTY;
			if obj.status
				res=sum(obj.TableFP(1:end-1,end));
			end
		end

		function res=InternalIrreversibility(obj)
		%InternalIrreversibility - Get the total internal irreversibility of the plant.
		%   Sums the per-process irreversibility vector (vI(1:N)), which represents
		%   the exergy destruction within the productive and dissipative processes.
		%
		%   Syntax:
		%     res = obj.InternalIrreversibility
		%   Output Arguments:
		%     res - (double) Scalar sum of all process irreversibilities
		%
			res=sum(obj.Irreversibility);
		end

		function res=ExternalIrreversibility(obj)
		%ExternalIrreversibility - Get the total external irreversibility of the plant.
		%   Sums the exergy of all waste flows, which is the exergy discharged to the
		%   environment without being converted to useful product (external losses).
		%
		%   Syntax:
		%     res = obj.ExternalIrreversibility
		%   Output Arguments:
		%     res - (double) Scalar total waste flow exergy (external irreversibility)
		%
			ind=obj.ps.Waste.flows;
			res=sum(obj.FlowsExergy(ind));
        end

        function [res,tbl]=FlowProcessTable(obj)
        %FlowProcessTable - Get the exergy-scaled Flow-Process table.
        %   Constructs three sub-tables from FlowProcessModel and the current exergy values:
        %     tV  - Internal flow recirculation table: scaleCol(mV, B)
        %     tF  - Fuel-side table: scaleCol(mF, [vP, TotalResources])
        %     tP  - Product-side table: scaleCol(mP, B)
        %   When called with two output arguments, a combined matrix [tV tF; tP 0] is also returned.
        %
        %   Syntax:
        %     res = obj.FlowProcessTable
        %     [res, tbl] = obj.FlowProcessTable
        %   Output Arguments:
        %     res - (struct) Sub-tables: tV (recirculation), tF (fuel side), tP (product side)
        %     tbl - (double) Combined matrix [2M x 2(N+1)] in block form [optional]
        %
            a=obj.FlowProcessModel;
            B=obj.FlowsExergy;
            P=[obj.ProductExergy,obj.TotalResources];  % Product exergy plus plant resource total
            N=obj.NrOfProcesses+1;
            res.tV=scaleCol(a.mV,B);  % Internal recirculation: flow→flow exergy table
            res.tF=scaleCol(a.mF,P);  % Fuel side: process-to-flow exergy assignment
            res.tP=scaleCol(a.mP,B);  % Product side: flow-to-process exergy assignment
            if nargout==2
                tbl=[res.tV,res.tF;res.tP,zeros(N,N)];
            end
        end

        function res=buildResultInfo(obj,fmt)
        %buildResultInfo - Build the cResultInfo object for exergy analysis.
		%
		%   Syntax:
		%     res = obj.buildResultInfo(fmt)
		%   Input Arguments:
		%     fmt - (cResultTableBuilder) Table builder object defining the output format
		%   Output Arguments:
		%     res - (cResultInfo) Results container for EXERGY_ANALYSIS
		%
            res=fmt.getExergyResults(obj);
        end
    end
end
