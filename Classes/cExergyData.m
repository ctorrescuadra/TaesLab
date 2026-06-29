% cExergyData   Gets and validates the exergy data values for a state of the plant.
%   This class performs the following tasks:
%    - Validate flow exergy values and map them to productive streams
%    - Check that productive stream exergy values are non-negative
%    - Compute fuel, product, irreversibility, unit cost, and efficiency for each process
%    - Check that process irreversibilities are non-negative
%    - Identify bypassed (inactive) processes where both fuel and product are zero
%    - Check that final products are reachable from all active productive processes
%
%   cExergyData Properties:
%       ps              - (cProductiveStructure) Productive Structure object.
%       State           - (string) Name of the exergy state.
%       FlowsExergy     - (double) Vector with the exergy of the flows.
%       StreamsExergy   - (struct) Exergy of the streams.
%       ProcessesExergy - (struct) Exergy of the processes.
%       ActiveProcesses - (logical) Vector indicating active (not bypassed) processes.
%       AdjacencyTable  - (struct) Adjacency Table of the productive graph.
%       AdjacencyMatrix - (struct) Adjacency Matrix of the productive graph.
%
%   cExergyData Methods:
%       cExergyData - Constructs an instance of the cExergyData class.
%
%   See also: cDataModel, cDataset, cProductiveStructure
%
classdef cExergyData < cMessageLogger
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
		% cExergyData   Constructs an instance of the cExergyData class.
		%   This constructor initializes the object by validating the productive
		%   structure and exergy data. It calculates the exergy of flows, streams,
		%   and processes, and checks for consistency.
		%
		%   Syntax:
		%       obj = cExergyData(ps, data)
		%
		%   Input Arguments:
		%       ps   - (cProductiveStructure) A valid productive structure object.
		%       data - (struct) A struct containing the exergy state data, including
		%              'stateId' and 'exergy' values for each flow.
		%
		%   Output Arguments:
		%       obj  - (cExergyData) The constructed cExergyData object. If the
		%              input data is invalid or inconsistent, the object's status
		%              will be set to false.
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
			idx=ps.getProcessTypes(cType.Process.PRODUCTIVE);
			aP=intersect(idx,find(~bypass)); % Indices of active productive processes
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
		%isProductive - Check if the state is thermodynamically productive.
		%	Verifies that every active productive process can reach the plant output
		%	(the sink node) in the stream-level adjacency graph, using a breath-first
		%	search (BFS) starting from the sink. A process that neither feeds into
		%	nor draws from any path to the sink is unreachable and causes an error.
		%	
		%	Input Arguments
		%     m  - (struct) Demand-driven adjacency matrices of the productive graph
		%              (fields: AF, AP, AE, AS)
		%     pp - (integer vector) Indices of active productive processes
		%
		%   Output Arguments
		%     log - (logical) true if all active productive processes reach the output;
		%           false otherwise. Error messages are appended to obj for each
		%           process that does not reach the plant output.
		%
			% Build the stream-level adjacency matrix by composing the process
			% transitions, and the output stream index
			mE=transpose(m.AF(:,1:end-1)*m.AP(1:end-1,:)+m.AS*m.AE);
			tidx=transpose(find(m.AF(:,end)));
			% BFS from the sink node
			v=bfs(mE,tidx);
			% For each active productive process pp(i):
			%   x(i) = 1 if any of its fuel streams is reachable from the sink
			%   y(i) = 1 if any of its product streams is reachable from the sink
			% A process is productive only if both its fuel and product sides connect
			% to a path that leads to the plant output
			x=v*logicalMatrix(m.AF(:,pp));
			y=logicalMatrix(m.AP(pp,:))*v';
			sol= ~(x & y');  % Processes that fail to reach the output
			% Log an error for each active productive process that cannot reach the plant output
			if any(sol) 
            	for i=find(sol)
                    pname=obj.ps.ProcessKeys{pp(i)};
					obj.messageLog(cType.ERROR,cMessages.OutputNotReachedFromNode,pname);
            	end
			end
			log=obj.status;
		end
	end
end