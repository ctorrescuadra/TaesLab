classdef cResourceCost < cStatusLogger
% cResourceCost computes 
% 	Methods:
% 		obj=cResourceCost(data,exm)

	properties (GetAccess=public, SetAccess=private)
		c0      % Unit cost of external resources
		cs0     % Unit cost of external stream
		ce      % Processes Resources Costs
		Z       % Cost associated to processes
        zP      % Cost associated to process per unit of Product
        zF      % Cost associated to process per unit of Fuel
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
			% Set Flows Properties
			obj.c0=rd.c0;
			obj.cs0=zeros(1,exm.ps.NrOfStreams);
            obj.ce=zeros(1,exm.ps.NrOfProcesses);
			fid=exm.ps.Resources.flows;
			pid=exm.ps.Resources.processes;
			sid=exm.ps.Resources.streams;
			obj.cs0(sid)=obj.c0(fid);
            if isa(exm,'cProcessModel')
				obj.ce=exm.getProcessResourceCost(obj.c0);
			else
				obj.ce(pid)=obj.c0(fid);
            end
			% Set Process Properties
			obj.Z=rd.Z;
			idx=~exm.ActiveProcesses;
			N=exm.NrOfProcesses;
			vP=exm.ProcessesExergy.vP(1:N);
			vF=exm.ProcessesExergy.vF(1:N);
			ztmp=obj.Z;
            ztmp(idx)=0.0;
			obj.zP=vDivide(ztmp,vP);
			obj.zF=vDivide(ztmp,vF);
			obj.status=cType.VALID;
		end
	end	
end	