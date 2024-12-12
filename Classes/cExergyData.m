classdef cExergyData < cMessageLogger
% cExergyData gets and validates the exergy data values for a state of the plant 
%  	Check if these values are coherent with the productive
%  	structure and get the exergy values for flows, streams and processes.
% Methods:
% 	obj=cExergyData(ps, data)
%
	properties(GetAccess=public,SetAccess=private)
		ps				  % Productive Structure
		State             % Exergy State
        FlowsExergy       % Exergy of Flows
        StreamsExergy     % Exergy of Streams
        ProcessesExergy   % Exergy of Processes
		ActiveProcesses   % Active Processes (not bypassed)
    end
    
	methods
		function obj=cExergyData(ps,data)
		% Class constructor
        %  dm - cExergyState object
		%  ps - cProductiveStructure object
			% Check arguments
			if ~isObject(ps,'cProductiveStructure')
				obj.messageLog(cType.ERROR,cMessages.InvalidProductiveStructure);
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
			if ~obj.status
				return
			end
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
            tbl=ps.AdjacencyMatrix;
			vF=E*tbl.AF;
			vP=E*tbl.AP';
			% Calculate total system values
			vF(end)=sum(B(ps.Resources.flows));
			vP(end)=sum(B(ps.FinalProducts.flows));
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
            % Assign values object class
			obj.ps=ps;
			obj.FlowsExergy=B;
			obj.ProcessesExergy=struct('vF',vF,'vP',vP,'vI',vI,'vK',vK,'vEf',vEf);
			obj.StreamsExergy=struct('ET',ET,'E',E);
			obj.ActiveProcesses= uint8(~bypass);
        end
    end
end