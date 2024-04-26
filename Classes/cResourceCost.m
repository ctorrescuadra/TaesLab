classdef cResourceCost < cStatusLogger
% cResourceCost computes 
% 	Methods:
% 		obj=cResourceCost(data,exm)

	properties (GetAccess=public, SetAccess=private)
		c0      % Unit cost of external resources
		cs0     % Unit cost of external stream
		ce      % Process Resource Unit Costs
        Ce      % Process Resource Cost
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
				rd.messageLog(cType.ERROR,'Invalid resource cost data');
				return
			end
			if ~isa(exm,'cExergyModel') || ~exm.isValid
				obj.messageLog(cType.ERROR,'No exergy data model');
				return
			end
			% Set Resources properties
			obj.c0=rd.c0;
			obj.cs0=rd.c0*exm.StreamProcessTable.mS';
			% Process Resources Cost
			tbl=exm.FlowProcessTable;
			obj.ce=obj.c0 * tbl.mL * tbl.mF0(:,1:end-1);
			obj.Ce=obj.ce .* exm.FuelExergy;
			% Set Process Properties
            idx=~exm.ActiveProcesses;
			obj.Z=rd.Z;
	        obj.Z(idx)=0.0;
			obj.zP=vDivide(obj.Z,exm.ProductExergy);
			obj.zF=vDivide(obj.Z,exm.FuelExergy);
			obj.status=cType.VALID;
		end
	end	
end	