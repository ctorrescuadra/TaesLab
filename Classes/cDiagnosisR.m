classdef cDiagnosisR < cDiagnosis
% cDiagnosisR Extend Thermoeconomic Diagnosis to include waste cost allocation
%   Methods:    
%	    obj=cDiagnosis(fpr0,fpr1)
%       res=obj.MalfunctionCostTable
%       res=obj.DemandVariationCost
%       res=obj.WasteVariationCost
%       res=obj.WasteMalfunctionCost 
%  See also cDiagnosis
%
    properties(Access=private)
        dWs     % Final demand variation
        dCWs    % Cost of final demand variation
        tCMR    % Malfunction cost of waste table
        vCMR    % Malfunction cost of waste vector
	end
    
	methods
		function obj=cDiagnosisR(fpr0,fpr1)
        % Constructor
        %  fpr0: cModelFPR object for reference state
        %  fpr1: cModelFPR object for operation state
            obj=obj@cDiagnosis(fpr0,fpr1);
            if ~obj.isValid
                return
            end            
            if ~fpr0.isWaste || ~fpr1.isWaste
                obj.messageLog(cType.ERROR,'Input Paramenter must contains waste information');
                return
            end
            obj.dWs=fpr1.FinalDemand-fpr0.FinalDemand;
            obj.dCWs=obj.dpuk.cP' .* obj.dWs;
            % Compute waste cost variation
            MR=scaleCol(fpr1.WasteTable.mKR-fpr0.WasteTable.mKR,obj.vP0);
            DR=fpr1.WasteOperators.opR * obj.tMF(1:end-1,1:end-1);
            CMR1=scaleRow(MR,obj.dpuk.cP);
            CMR2=scaleRow(DR,obj.dpuk.cPE);
            obj.tCMR=CMR1+CMR2;
			obj.vCMR=sumCols(obj.tCMR);
		end
        
        function res=MalfunctionCostTable(obj)
        % override getMalfunctionCostTable
            aux=obj.tDF(:,1:end-1)+obj.tCMR;
            res=[[aux,obj.dCWs];[obj.vMF,0]];
        end
        
        function res=WasteVariationCost(obj)
        % override getWasteVariationCostTable
            res=[obj.vCMR,sum(obj.vCMR)];
        end
        
        function res=DemandVariationCost(obj)
        % override getDemandVariationCost
            res=[obj.dCWs',sum(obj.dCWs)];
        end
	end
end
  