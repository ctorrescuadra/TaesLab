classdef cResourceCost < cStatusLogger
% cResourceData gets and validates the external cost resources of a system
% 	Methods:
% 		obj=cResourceCost(data,exm)
%		obj.setFlowResources(c0)
%   	obj.setProcessResources(Z)
%		obj.setResourcesFlowValue(key,value)
%		obj.getResourceIndex(key)
	properties (GetAccess=public, SetAccess=private)
		c0      % Unit cost of external resources
		cs0     % Unit cost of external stream
		ce      % Processes Resources Costs
		Z       % Cost associated to processes
        zP      % Cost associated to process per unit of Product
        zF      % Cost associated to process per unit of Fuel
	end

	properties (Access=private)
		exm     % cExergyModel object
	end
    
	methods		
		function obj=cResourceCost(rd,exm)
		% Set the resources cost values for a given state exm
		%	Input:
		%	 exm - cExergyModel object with state information
			if ~isa(rd,'cResourceData') || ~rd.isValid
				rd.messageLog(cType.ERROR,'Invalid Resource data provided');
				return
			end
			if ~isa(exm,'cExergyModel') || ~exm.isValid
				obj.messageLog(cType.ERROR,'No exergy data model');
				return
			end
			obj.exm=exm;
			obj.cs0=zeros(1,exm.ps.NrOfStreams);
            obj.ce=zeros(1,exm.ps.NrOfProcesses);
			obj.setFlowResources(rd.c0);
			obj.setProcessResources(rd.Z);
            obj.status=cType.VALID;
		end

		function res=setProcessResources(obj,Z)
		% Set the Resources cost of processes
        %  Input:
        %   Z [optional] - Resources cost processes values
			res=false;
			if length(Z) == obj.exm.NrOfProcesses
				obj.Z=Z;
			else
				obj.messageLog(cType.WARNING,'Invalid Processes Resources size',length(Z));
				return
			end
			if ~isempty(find(Z<0,1))
				obj.messageLog(cType.WARNING,'Values of flows resources must be non-negatives');
                return
			end
			idx=~obj.exm.ActiveProcesses;
			N=obj.exm.NrOfProcesses;
			vP=obj.exm.ProcessesExergy.vP(1:N);
			vF=obj.exm.ProcessesExergy.vF(1:N);
			ztmp=obj.Z;
            ztmp(idx)=0.0;
			obj.zP=vDivide(ztmp,vP);
			obj.zF=vDivide(ztmp,vF);
            res=true;
		end

		function res=setFlowResources(obj,c0)
        % Set the Resources unit cost of flows
        %  Input:
        %   c0 [optional] - Resources cost flows values
			res=false;
			if length(c0) == obj.exm.NrOfFlows
				obj.c0=c0;
			else
				obj.messageLog(cType.WARNING,'Invalid Flows Resources size',length(c0));
				return
				end
			if ~isempty(find(c0<0,1))
				obj.messageLog(cType.WARNING,'Values of flows resources must be non-negatives');
                return
			end
			fid=obj.exm.ps.Resources.flows;
			pid=obj.exm.ps.Resources.processes;
			sid=obj.exm.ps.Resources.streams;
			obj.cs0(sid)=obj.c0(fid);
            if isa(obj.exm,'cProcessModel')
				obj.ce=obj.exm.getProcessResourceCost(obj.c0);
			else
				obj.ce(pid)=obj.c0(fid);
            end
            res=true;
        end

		function res=setResourcesFlowValue(obj,key,value)
		% Set the value of a resource
		%	key - key of the resource
		%	value - cost of the resource
			res=false;
			id=obj.getResourceIndex(key);
			if ~cType.isEmpty(id)
				obj.c0(id)=value;
				res=obj.setFlowResources(obj.c0);
			end			
		end

		function id=getResourceIndex(obj,key)
		%  Get the index of resource key
		%	key - key of the resource
			id=obj.exm.ps.getFlowId(key);
			if ~cType.isEmpty(id)
				rf=obj.exm.ps.Resources.flows;
				if isempty(find(rf==id,1))
					id=cType.EMPTY;
				end
			end
		end
	end	
end	