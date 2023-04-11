classdef cProcessModel < cExergyModel
% cProcessModel computes the Table FP
%	Methods:
%		obj=cStreamProcessModel(rex)
% 	Methods inherited form cExergyModel
%		res=obj.getStreamProcessTable
%		res=obj.getFlowProcessTable
%   	res=obj.getStreamsCost
% See also cExergyModel
%
    properties (GetAccess=public, SetAccess=private)
        TableFP     % Table FP
    end
	properties(Access=protected)
        mgP, mgF, mL
	end
	methods
		function obj=cProcessModel(rex)
		% Algorithm constructor
		%   rex: cReadExergy object
			obj=obj@cExergyModel(rex);
			tbl=obj.getFlowProcessTable;
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
    end
end
