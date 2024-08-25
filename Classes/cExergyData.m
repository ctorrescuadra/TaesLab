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
            if ~isstruct(data)
				obj.messageLog(cType.ERROR,'Invalid exergy data provided');
				return
            end
            if ~isa(ps,'cProductiveStructure') || ~isValid(ps)
				obj.messageLog(cType.ERROR,'No Productive Structure provided');
                return
            end
 
			% Check data file content
			if  ~any(isfield(data,{'stateId','exergy'}))
                obj.messageLog(cType.ERROR,'Invalid data. Fields Missing');
				return
			end
			% Check exergy data structure
			obj.State=data.stateId;
            if  all(isfield(data.exergy,{'key','value'}))
				values=data.exergy;
			else
                obj.messageLog(cType.ERROR,'Wrong exergy values data. Fields Missing');
				return
            end
			M=length(values);
            if ps.NrOfFlows ~= M
                obj.messageLog(cType.ERROR,'NrOfFlows %d is not conformant with productive structure %d',ps.NrOfFlows,M);
                return
            end
            NS=ps.NrOfStreams;
            N=ps.NrOfProcesses;
			% Check flows' keys	and get exergy values	
            B=zeros(1,M);
            for i=1:M
				id=ps.getFlowId(values(i).key);
                if cType.isEmpty(id)
					obj.messageLog(cType.ERROR,'Exergy index %s not found',values(i).key);
					continue
                end
                if values(i).value < 0
                    obj.messageLog(cType.ERROR,'Exergy of flow %s is negative %f',values(i).key,values(i).value);
				else
					B(id)=values(i).value;
                end
            end
			if ~obj.isValid
				return
			end
			% Check exergy values and compute exergy of processes and streams
			tbl=ps.AdjacencyMatrix;
            BE=B*tbl.AE;
			BS=B*tbl.AS';
            fstreams=ps.getFuelStreams;
            pstreams=ps.getProductStreams;
			ET=zeros(1,NS);
			ET(fstreams)=BE(fstreams);
			ET(pstreams)=BS(pstreams);
			E=zeros(1,NS);
			E(fstreams)=zerotol(BE(fstreams)-BS(fstreams));
			E(pstreams)=zerotol(BS(pstreams)-BE(pstreams));
            % Check streams are non negative
            ier=find(E<0);		
			if ~isempty(ier)
				for i=ier
					obj.messageLog(cType.ERROR,'Exergy of stream %s is negative %f',ps.Streams(i).key,E(i));
				end
			end
			% Compute and check Process Fuel and Product Exergy
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
					obj.messageLog(cType.ERROR,'Irreversibility of process %s is negative %f',ps.ProcessKeys{i},vI(i));
				end
			end
            % Check fuel and product are non-null
			bypass=false(1,N);
            ier=find(~vP);
            if ~isempty(ier)
				for i=ier
					if vF(i)>0
						obj.messageLog(cType.ERROR,'Product of process %s is zero',ps.ProcessKeys{i});
					else
						bypass(i)=true;
						obj.messageLog(cType.INFO,'Process %s is not Active',ps.ProcessKeys{i});
					end
				end
            end
			vK=vDivide(vF,vP);
			vEf=vDivide(vP,vF);
			vK(bypass)=1;
			vEf(bypass)=1;
            % Assign values object class
			obj.ps=ps;
			obj.FlowsExergy=B;
			obj.ProcessesExergy=struct('vF',vF,'vP',vP,'vI',vI,'vK',vK,'vEf',vEf);
			obj.StreamsExergy=struct('ET',ET,'E',E);
			obj.ActiveProcesses= uint8(~bypass);
        end
    end
end