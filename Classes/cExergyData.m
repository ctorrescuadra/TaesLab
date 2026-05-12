% cExergyData   Get and validates the exergy data values for a state of the plant
%   This class made the following tasks:
%    - Check that productive groups exergy are non-negative
%    - Check that processes irreversibility are non-negative
%    - Find active proceses
%    - Build productive graph adjacency table
%    - Check that final products are reacheable from active productive processes
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
		
			% Check arguments
			if ~isObject(ps,'cProductiveStructure')
				obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(ps));
                return
			end
            if ~isstruct(data)
				obj.messageLog(cType.ERROR,cMessages.InvalidExergyDefinition);
				return
            end
			% Check data file content
			if  ~any(isfield(data,{'stateId','exergy'}))
                obj.messageLog(cType.ERROR,cMessages.InvalidExergyDefinition);
				return
			end
			% Check exergy data structure
			obj.State=data.stateId;
			exergy=data.exergy;
			M=length(exergy);
            if ps.NrOfFlows ~= M
                obj.messageLog(cType.ERROR,cMessages.InvalidExergyDataSize,M);
                return
            end
			% Load flow exergy values
            if all(isfield(data.exergy,cType.KEYVAL))
				B=[exergy.value];
			else
                obj.messageLog(cType.ERROR,cMessages.InvalidExergyDefinition);
				return
            end
            N=ps.NrOfProcesses;
			% Calculate exergy of productive groups
			[E,ET]=ps.flows2Streams(B);
            % Check streams are non negative
            ier=find(E<0);		
			if ~isempty(ier)
				for i=ier
					obj.messageLog(cType.ERROR,cMessages.NegativeExergyStream,ps.Streams(i).key,E(i));
				end
			end
			% Compute and check Process Fuel and Product Exergy
            tbl=ps.ProductiveTable;
			eF=E*tbl.AF;
			eP=E*tbl.AP';
			% Compute global plant resources and production 
			Bin=sum(B(ps.ResourceFlows));
			Bout=sum(B(ps.FinalProductFlows));
			vF=[eF(1:end-1),Bin];
			vP=[eP(1:end-1),Bout];
			if zerotol(vF(end)) == 0
				obj.messageLog(cType.ERROR,cMessages.NoResources);
			end
			if zerotol(Bout) == 0
				obj.messageLog(cType.ERROR,cMessages.NoOutputs);
			end
			% Check Irreversibility are non-negative
			vI=zerotol(vF-vP);
            ier=find(vI<0);
			if ~isempty(ier)
				for i=ier
					obj.messageLog(cType.ERROR,cMessages.NegativeIrreversibilty,ps.ProcessKeys{i},vI(i));
				end
			end
            % Check fuel and product are non-null
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
			vK=vDivide(vF,vP);
			vEf=100*vDivide(vP,vF);
			vK(bypass)=1;
			vEf(bypass)=100;
			if ~obj.status, return; end
			% Build Exergy Adjacency Table
			tbl=ps.ProductiveTable;
			tAE=scaleRow(tbl.AE,B);
			tAS=scaleCol(tbl.AS,B);
			tAF=scaleRow(tbl.AF,E);
            tAP=scaleCol(tbl.AP,E);
			% Demand Driven Adjacency Matrices
			mbF=divideCol(tAF,eP);
			mbP=divideCol(tAP,ET);
			mbE=divideCol(tAE,ET);
            mbS=divideCol(tAS,B);
			% Build Productive Graph (logical Fuel-Product process table)
			aP=ps.getProcessTypes(cType.Process.PRODUCTIVE); NP=numel(aP)+1;
			tfp=logicalMatrix(mbP)*transitiveClosure(mbS*mbE)*logicalMatrix(mbF);
			ssr=[tfp(aP,aP),tfp(aP,end);zeros(1,NP)];
			% Check if final products are reacheable from no bypassed productive processses
			sol=xor(dfs(ssr',NP),[bypass(aP),0]);
			if all(sol)
				obj.ps=ps;
				obj.FlowsExergy=B;
				obj.ProcessesExergy=struct('vF',vF,'vP',vP,'vI',vI,'vK',vK,'vEf',vEf);
				obj.StreamsExergy=struct('ET',ET,'E',E);
				obj.AdjacencyTable=struct('AF',tAF,'AP',tAP,'AE',tAE,'AS',tAS);
				obj.AdjacencyMatrix=struct('AF',mbF,'AP',mbP,'AE',mbE,'AS',mbS);
				obj.ActiveProcesses=logical(~bypass);
            else % Find Non SSR process nodes and log error
            	for i=find(~sol)
					idx=aP(i); 
					obj.messageLog(cType.ERROR,cMessages.OutputNotReachedFromNode,ps.ProcessKeys{idx});
            	end
				obj.messageLog(cType.ERROR,cMessages.NoProductiveState,obj.State);
			end
        end
    end
end