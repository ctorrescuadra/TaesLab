classdef cProcessModel < cExergyModel
% cProcessModel build the Table FP
% 	It builts the FP table and the auxiliary matrices
%	to compute the cost of flows and process resources.	
%	Methods:
%		obj=cProcessModel(rex)
%		res=obj.getProcessResourceCost(c0)
%		res=obj.flowsUnitCost(cp,c0)
% See also cExergyModel, cModelFPR
%
    properties (GetAccess=public, SetAccess=private)
        TableFP     % Table FP
    end
	properties(Access=private)
        mgP, mgF, mL
	end
	methods
		function obj=cProcessModel(rex)
		% Algorithm constructor for the Table FP
		%   rex: cExergyData object
			obj=obj@cExergyModel(rex);
			tbl=obj.FlowProcessTable;
			obj.mgP=divideCol(tbl.tP,obj.FlowsExergy);
			obj.mgF=divideCol(tbl.tF(:,1:end-1),obj.FuelExergy);
			mgV=divideCol(tbl.tV,obj.FlowsExergy);
			if obj.ps.isModelIO
				obj.mL=eye(obj.NrOfFlows);
			else
				obj.mL=zerotol(inv(eye(obj.NrOfFlows)-mgV));
			end
            obj.TableFP=full(obj.mgP*obj.mL*tbl.tF);
		end
		function res=getProcessResourceCost(obj,c0)			
		% Get the Processes Resources cost given the unit cost of resource flows
		% Use the matrices of Table FP building
		%  	Input:
		%   	c0 - External resources costs of flows
		%	Output:
		%	   res - Process resources cost (ce)
			res=c0*obj.mL*obj.mgF;
		end
	end

	methods(Access=protected)
		function res=flowsUnitCost(obj,cp,c0)
		% Compute the flows unit cost given the product cost
		% Use the matrices of Table FP building
		%	Input: 
		%		cp - unit cost of product
		%		c0 - unit cost of resource flows (optional)
		%	Output:
		%	   res - unit cost of flows
			aux=cp*obj.mgP(1:end-1,:);
			if nargin==3
				aux=aux+c0;
			end
			res=aux*obj.mL;
		end
    end
end
