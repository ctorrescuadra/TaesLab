classdef cResourceCost < cMessageLogger
% cResourceCost computes the resources cost values properties
% for a state of the system
%
% cResourceCost Properties:
% sample  - Resource sample name
% c0      - Unit cost of external resources
% cs0     - Unit cost of external stream
% ce      - Process Resource Unit Costs
% Ce      - Process Resource Cost
% Z       - Cost associated to processes
% zP      - Cost associated to process per unit of Product
% zF      - Cost associated to process per unit of Fuel
%
	properties (GetAccess=public, SetAccess=private)
		sample  % Resource sample name
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
		% Create an instance of the class
		% Syntax:
		%   obj = cResourceCost(rd, exm)
		% Input Argument:
		%	rd - cResourceData object
		%	exm - cExergyModel object with state information
		%
			if ~isObject(rd,'cResourceData')
				rd.messageLog(cType.ERROR,'Invalid resource cost data');
				return
			end
			if ~isObject(exm,'cExergyModel')
				obj.messageLog(cType.ERROR,'No exergy data model');
				return
			end
			% Set Resources properties
			obj.sample=rd.sample;
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
		end
	end	
end	