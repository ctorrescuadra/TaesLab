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
    properties(GetAccess=public,SetAccess=private)
        tMR     % Waste Variation table
        tDR     % Waste Disfunction table
	end
    
	methods
		function obj=cDiagnosisR(fp0,fp1)
        % Constructor
        %  fpr0: cModelFPR object for reference state
        %  fpr1: cModelFPR object for operation state
            obj=obj@cDiagnosis(fp0,fp1);
            if ~obj.isValid
                return
            end            
            if ~fp0.isWaste || ~fp1.isWaste
                obj.messageLog(cType.ERROR,'Input Paramenter must contains waste information');
                return
            end
            opR=fp1.WasteOperators.opR;
            cP=obj.dpuk.cP;
            cPIN=obj.dpuk.cPE;
            obj.dCW0= cP .* (fp1.FinalDemand-fp0.FinalDemand)';
            % Compute waste cost variation
            obj.tMR=scaleCol(fp1.WasteTable.mKR-fp0.WasteTable.mKR,obj.vP0);
            obj.tDR=opR * obj.tMF(1:end-1,1:end-1);
            obj.tMCR=obj.computeWasteMalfunctionCost(cPIN,cP);
			obj.vMCR=sumCols(obj.tMCR);
		end
    end   
end
  