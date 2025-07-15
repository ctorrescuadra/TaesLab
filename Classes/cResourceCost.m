classdef cResourceCost < cMessageLogger
%cResourceCost - Compute the resource cost properties for a state.
%
%   cResourceCost constructor
%     obj = cResourceCost(rsd, exm)
%
%   cResourceCost properties:
%     sample  - Resource sample name
%     c0      - Unit cost of external resources
%     ce      - Process Resource Unit Costs
%     Ce      - Process Resource Cost
%     Z       - Cost associated to processes
%     zP      - Cost associated to process per unit of Product
%     zF      - Cost associated to process per unit of Fuel
%
	properties (GetAccess=public, SetAccess=private)
		sample  % Resource sample name
		c0      % Unit cost of external resources
		ce      % Process Resource Unit Costs
        Ce      % Process Resource Cost
		Z       % Cost associated to processes
        zP      % Cost associated to process per unit of Product
        zF      % Cost associated to process per unit of Fuel
	end

	methods		
		function obj=cResourceCost(rsd,exm)
		%cResourceCost - Create an instance of the class
		%   Syntax:
		%     obj = cResourceCost(rsd, exm)
		%   Input Argument:
		%	  rsd - cResourceData object
		%	  exm - cExergyModel object with state information
		%
			if ~isObject(rsd,'cResourceData')
				rsd.messageLog(cType.ERROR,cMessages.InvalidObject,class(rsd));
				return
			end
			if ~isObject(exm,'cExergyModel')
				obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(exm));
				return
			end
			% Set Resources properties
			idx=rsd.frsc;
			obj.sample=rsd.Sample;
			obj.c0=rsd.c0;
			% Process Resources Cost
			fpm=exm.FlowProcessModel;
			obj.ce = obj.c0(idx) * fpm.mL(idx,:) * fpm.mF0(:,1:end-1);
			obj.Ce = obj.ce .* exm.FuelExergy;
			% Set Process Properties
            idx = ~exm.ActiveProcesses;
			obj.Z = rsd.Z;
	        obj.Z(idx) = 0.0;
			obj.zP = vDivide(obj.Z,exm.ProductExergy);
			obj.zF = vDivide(obj.Z,exm.FuelExergy);
		end
	end	
end	