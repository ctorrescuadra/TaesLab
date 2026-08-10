classdef cExergyData < cMessageLogger
%cExergyData - Validate exergy data and build the productive graph for a plant state.
%   Validates flow exergy values provided in a state data struct against the
%   productive structure, then computes all thermodynamic quantities required
%   for thermoeconomic analysis:
%     - Maps flow exergy values to productive streams
%     - Checks non-negativity of stream and process irreversibilities
%     - Computes fuel, product, irreversibility, unit exergy cost, and efficiency
%     - Identifies bypassed (inactive) processes
%     - Verifies that all active productive processes can reach the plant output
%
%   The object is invalid (isValid returns false) if any check fails.
%
%   cExergyData properties:
%     ps              - cProductiveStructure object for the productive structure
%     State           - Name of the exergy state being analysed
%     FlowsExergy     - (1 x NrOfFlows double) Per-flow exergy values
%     StreamsExergy   - Struct with stream net exergy (E) and total exergy (ET)
%     ProcessesExergy - Struct with per-process vF, vP, vI, vK, and vEf vectors
%     ActiveProcesses - (1 x NrOfProcesses logical) true for non-bypassed processes
%     AdjacencyTable  - Struct of exergy-weighted adjacency tables (AF, AP, AE, AS)
%     AdjacencyMatrix - Struct of demand-driven adjacency matrices (AF, AP, AE, AS)
%
%   cExergyData methods:
%     cExergyData - Construct an instance of this class
%
%   See also cProductiveStructure, cDataModel, cMessageLogger
%
	properties(GetAccess=public,SetAccess=private)
		ps				  % (cProductiveStructure) Productive Structure object associated with the exergy data.
		State             % (string) Name of the exergy state being analyzed.
        FlowsExergy       % (double) Vector containing the exergy values of each flow.
        StreamsExergy     % (struct) Struct with the exergy of productive streams (`E`) and total exergy of streams (`ET`).
        ProcessesExergy   % (struct) Struct with the exergy of fuels (`vF`), products (`vP`), irreversibilities (`vI`), unit exergy costs (`vK`), and efficiencies (`vEf`) for each process.
		ActiveProcesses   % (logical) Logical vector indicating which processes are active (true) or bypassed (false).
		AdjacencyTable    % (struct) Struct containing the exergy-based adjacency tables (AF, AP, AE, AS).
		AdjacencyMatrix   % (struct) Struct containing the exergy-based adjacency matrices (AF, AP, AE, AS) for demand-driven calculations.
    end
    
	methods
		function obj=cExergyData(ps,data)
		%cExergyData - Construct an instance of this class
		%   Validates the productive structure and exergy state data, builds all
		%   thermodynamic quantities (streams, processes, adjacency tables), and
		%   verifies productive graph connectivity. The object is invalid if any
		%   check fails.
		%
		%   Syntax:
		%     obj = cExergyData(ps, data)
		%
		%   Input Arguments:
		%     ps   - cProductiveStructure object with a valid productive structure
		%     data - (struct) Exergy state data with required fields:
		%              stateId - name of the exergy state (char)
		%              exergy  - (1 x NrOfFlows struct array) per-flow exergy
		%                        entries with key and value fields
		%
		%   Output Arguments:
		%     obj  - cExergyData object; check isValid(obj) before use
		%
		
			% Validate input argument types
			if ~isObject(ps,'cProductiveStructure')
				obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(ps));
                return
			end
            if ~isstruct(data)
				obj.messageLog(cType.ERROR,cMessages.InvalidExergyDefinition);
				return
            end
			% Verify required fields are present in the data struct
			if  ~any(isfield(data,{'stateId','exergy'}))
                obj.messageLog(cType.ERROR,cMessages.InvalidExergyDefinition);
				return
			end
			% Store state identifier and verify the number of flow entries matches the productive structure
			obj.State=data.stateId;
			exergy=data.exergy;
			M=length(exergy);
            if ps.NrOfFlows ~= M
                obj.messageLog(cType.ERROR,cMessages.InvalidExergyDataSize,M);
                return
            end
			% Extract flow exergy values into vector B (one entry per flow)
            if all(isfield(data.exergy,cType.KEYVAL))
				B=[exergy.value];
			else
                obj.messageLog(cType.ERROR,cMessages.InvalidExergyDefinition);
				return
            end
            N=ps.NrOfProcesses;
			% Aggregate flow exergies into productive streams:
			%   E  - exergy of each stream (fuel/product groups)
			%   ET - total exergy entering/leaving each stream node
			[E,ET]=ps.flows2Streams(B);
            % Validate that all stream exergy values are non-negative
            ier=find(E<0);		
			if ~isempty(ier)
				for i=ier
					obj.messageLog(cType.ERROR,cMessages.NegativeExergyStream,ps.Streams(i).key,E(i));
				end
			end
			% Compute process-level fuel (eF) and product (eP) exergy using
			% the structural adjacency tables AF (fuel side) and AP (product side)
            tbl=ps.ProductiveTable;
			eF=E*tbl.AF;
			eP=E*tbl.AP';
			% Append plant-level totals: total resource input (Bin) and final output (Bout)
			Bin=sum(B(ps.ResourceFlows));
			Bout=sum(B(ps.FinalProductFlows));
			vF=[eF(1:end-1),Bin];  % Fuel exergy vector, last entry is global plant fuel
			vP=[eP(1:end-1),Bout]; % Product exergy vector, last entry is global plant product
			if zerotol(vF(end)) == 0
				obj.messageLog(cType.ERROR,cMessages.NoResources);
			end
			if zerotol(Bout) == 0
				obj.messageLog(cType.ERROR,cMessages.NoOutputs);
			end
			% Compute irreversibilities (vI = vF - vP); apply zero tolerance to suppress rounding noise
			vI=zerotol(vF-vP);
            ier=find(vI<0);
			if ~isempty(ier)
				for i=ier
					obj.messageLog(cType.ERROR,cMessages.NegativeIrreversibilty,ps.ProcessKeys{i},vI(i));
				end
			end
            % Identify bypassed processes (vP = 0):
			%   If vF > 0 but vP = 0, the process has fuel but no product — error.
			%   If both vF = 0 and vP = 0, the process is inactive (bypassed) — informational.
			bypass=false(1,N);
            ier=find(~vP);
            if ~isempty(ier)
				for i=ier
					if vF(i)>0
						obj.messageLog(cType.ERROR,cMessages.ZeroProduct,ps.ProcessKeys{i});
					else
						bypass(i)=true;
						obj.messageLog(cType.INFO,cMessages.ProcessNotActive,ps.ProcessKeys{i});
					end
				end
            end
			% Compute unit exergy cost (vK = vF/vP) and efficiency (vEf = vP/vF);
			% bypassed processes are assigned neutral values (k=1, ef=100%)
			vK=vDivide(vF,vP);
			vEf=100*vDivide(vP,vF);
			vK(bypass)=1;
			vEf(bypass)=100;
			if ~obj.status, return; end
			% Build exergy-scaled adjacency tables by weighting structural tables
			% with the corresponding flow (B) or stream (E) exergy values
			tAE=scaleRow(tbl.AE,B);
			tAS=scaleCol(tbl.AS,B);
			tAF=scaleRow(tbl.AF,E);
            tAP=scaleCol(tbl.AP,E);
			% Build demand-driven (normalized) adjacency matrices by dividing each
			% column by the corresponding process product or stream total exergy.
			mbF=divideCol(tAF,eP);
			mbP=divideCol(tAP,ET);
			mbE=divideCol(tAE,ET);
            mbS=divideCol(tAS,B);
			mA=struct('AF',mbF,'AP',mbP,'AE',mbE,'AS',mbS);
			% Verify that every active productive process can reach the plant output
			obj.ps=ps;
			aP=ps.ProductiveProcesses & ~bypass; % Indices of active productive processes
			if obj.isProductive(mA,aP)
				obj.FlowsExergy=B;
				obj.ProcessesExergy=struct('vF',vF,'vP',vP,'vI',vI,'vK',vK,'vEf',vEf);
				obj.StreamsExergy=struct('ET',ET,'E',E);
				obj.AdjacencyTable=struct('AF',tAF,'AP',tAP,'AE',tAE,'AS',tAS);
				obj.AdjacencyMatrix=mA;
				obj.ActiveProcesses=logical(~bypass);
			else
				obj.messageLog(cType.ERROR,cMessages.NoProductiveState,obj.State);
			end
        end
    end

	methods(Access=private)
		function log=isProductive(obj,m,pp)
		%isProductive - Check if the state is productive
		%   Verifies that every active productive process can reach the plant
		%   output (sink node) in the stream-level adjacency graph, using a
		%   breadth-first search (BFS) starting from the sink. A process that
		%   neither feeds into nor draws from any path to the sink is
		%   unreachable and an error is logged for it.
		%
		%   Input Arguments:
		%     m  - (struct) Demand-driven adjacency matrices with fields:
		%            AF, AP, AE, AS
		%     pp - (integer array) Indices of active productive processes
		%
		%   Output Arguments:
		%     log - (logical) true if all active productive processes reach the
		%           plant output; false if any process is unreachable
		%
			% Build the process-stream adjacency matrix 
			N = obj.ps.NrOfProcesses+1;
			NS = obj.ps.NrOfStreams+1;
			tmp = logicalMatrix([m.AS*m.AE, m.AF; m.AP, zeros(N,N)]);
			% Check if isequal to the reference stream-process matrix
			% then the state is productive
			spm = obj.ps.getStreamProcessMatrix;
			if isequal(spm,tmp)
				log = true;
				return
			end
			% BFS from the sink node
			mA = transpose(tmp(1:end-1,1:end-1)); 
			out = transpose(full(tmp(1:end-1,end)));
			v = cDigraphAnalysis.bfs(mA,out);
			% Log productive nodes does not reach sink
			fail = ~v(NS:end) & pp;
            for i = find(fail)
                pname=obj.ps.ProcessKeys{i};
				obj.messageLog(cType.ERROR,cMessages.OutputNotReachedFromNode,pname);
            end
			log=obj.status;
		end
	end
end