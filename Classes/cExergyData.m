classdef cExergyData < cMessageLogger
%cExergyData - Get and validates the exergy data values for a state of the plant 
%  	Check if these values are coherent with the productive
%  	structure and get the exergy values for flows, streams and processes.
%
%   cExergyData constructor:
% 	  obj = cExergyData(ps, data)
%
%   cExergyData properties:
%     ps			  - Productive Structure
%     State           - Exergy State
%     FlowsExergy     - Exergy of Flows
%     StreamsExergy   - Exergy of Streams
%     ProcessesExergy - Exergy of Processes
%     ActiveProcesses - Active Processes (not bypassed)
%     AdjacencyTable  - Adjacency Table of the productive graph
%	  AdjacencyMatrix - Adjacency Matrix of the productive graph
%
%   See also cDataModel
%
	properties(GetAccess=public,SetAccess=private)
		ps				  % Productive Structure
		State             % Exergy State
        FlowsExergy       % Exergy of Flows
        StreamsExergy     % Exergy of Streams
        ProcessesExergy   % Exergy of Processes
		ActiveProcesses   % Active Processes (not bypassed)
		AdjacencyTable    % Adjacency Table of the productive graph
		AdjacencyMatrix   % Adjacency Matrix of the productive graph
    end
    
	methods
		function obj=cExergyData(ps,data)
		%cExergyData - Class constructor
		%   Syntax:
        %     obj = cExergyData(ps,data)
		%   Input Arguments
		%     ps - cProductiveStructure object
		%     data - ExergyState struct from cModelData containing exergy values
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
            if  all(isfield(data.exergy,{'key','value'}))
				values=data.exergy;
			else
                obj.messageLog(cType.ERROR,cMessages.InvalidExergyDefinition);
				return
            end
			M=length(values);
            if ps.NrOfFlows ~= M
                obj.messageLog(cType.ERROR,cMessages.InvalidExergyDataSize,M);
                return
            end
            N=ps.NrOfProcesses;
			% Check flow keys and get exergy values	
            B=zeros(1,M);
            for i=1:M
				id=ps.getFlowId(values(i).key);
                if ~id
					obj.messageLog(cType.ERROR,cMessages.InvalidFlowKey,values(i).key);
					continue
                end
                if values(i).value < 0
                    obj.messageLog(cType.ERROR,cMessages.NegativeExergyFlow,values(i).key,values(i).value);
				else
					B(id)=values(i).value;
                end
            end
			if ~obj.status, return; end
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
			opE=mbS*mbE+mbF(:,1:end-1)*mbP(1:end-1,:);
			% Validate Productive Graph and log errors if apply
			if isNonSingularMatrix(opE)
				obj.ps=ps;
				obj.FlowsExergy=B;
				obj.ProcessesExergy=struct('vF',vF,'vP',vP,'vI',vI,'vK',vK,'vEf',vEf);
				obj.StreamsExergy=struct('ET',ET,'E',E);
				obj.AdjacencyTable=struct('AF',tAF,'AP',tAP,'AE',tAE,'AS',tAS);
				obj.AdjacencyMatrix=struct('AF',mbF,'AP',mbP,'AE',mbE,'AS',mbS);
				obj.ActiveProcesses= logical(~bypass);
			else % Compute the transitive closure of the processes graph
				E = eye(N+1) | logicalMatrix(mbP) * transitiveClosure(A) * logicalMatrix(mbF);
                s=E(end,:);t=E(:,end);
				% Log non-SSR process nodes
				for i=find(~s)
					if ~bypass(i)
						obj.messageLog(cType.ERROR,cMessages.NodeNotReachedFromSource,ps.ProcessKeys{i});
					end
				end
            	for i=transpose(find(~t))
					if ~bypass(i)
						obj.messageLog(cType.ERROR,cMessages.OutputNotReachedFromNode,ps.ProcessKeys{i});
					end
            	end
				obj.messageLog(cType.ERROR,cMessages.NoProductiveState,obj.State);
			end
        end
    end
end