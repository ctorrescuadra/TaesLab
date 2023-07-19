classdef cDiagnosisG < cDiagnosis
% cDiagnosisG computes the Generalized Malfunction Cost
%   Methods:
%	    obj=cDiagnosisG(fp0,fp1,method,rsd)
%
    properties(GetAccess=public,SetAccess=private)
        gCW0   % Production General Cost Variation
        DC0    % Generalized Fuel Impact
        gDF    % Generalized Disfunction Matrix
        vgMF   % Generalized Malfunction vector
        gCMR   % Generalized Waste malfunction Cost
        dcZ    % Amortization cost
        gA0    % Generalized Technical Saving
	end
	
	methods
		function obj=cDiagnosisG(fp0,fp1,method,rsd)
        % Diagnosis Constructor
        %  fp0: cModelFPR object for reference state
        %  fp1: cModelFPR object for operation state
            obj=obj@cDiagnosis(fp0,fp1,method);
            if ~isValid(obj)
                 obj.messageLog(cType.ERROR,'Input Diagnosis analysis'); 
                 obj.printLogger;
                 return
            end
            if  ~isa(rsd,'cResourceData')
                obj.messageLog(cType.ERROR,'Input parameter is not cResourceData objects');
                return
            end
            % Compute Cost
            rsc0=cResourceCost(rsd,fp0);
            rsc1=cResourceCost(rsd,fp1);
            % Compute unit costs
            cp0=fp1.getMinCost(rsc1);
            gpuk=fp1.getGeneralProcessUnitCost(rsc1);
            cPIN=gpuk.cPE+gpuk.cPZ;
            cP=gpuk.cP;
            % Compute Generalizad Fuel Impact
            obj.DC0=sum(rsc1.c0 .* fp1.FlowsExergy - rsc0.c0 .* fp0.FlowsExergy);
            % Compute generalized Malfunction
            % Processes Amortization Cost
            obj.dcZ=(rsc1.zP-rsc0.zP) .* fp0.ProductExergy;
            % Compute Generalized Fuel Impact
            obj.DC0=rsc1.c0 * fp1.FlowsExergy' - rsc0.c0 * fp0.FlowsExergy';
            gcpt=gpuk.cP * obj.DWt;
            obj.gA0=obj.DC0 - sum(obj.dcZ) - gcpt;
            % Compute generalized Malfunction
            mF=obj.tMF(1:end-1,1:end-1);
            mF0=obj.tMF(end,1:end-1);
            dce=rsc1.ce .* mF0;
            gMF=scaleRow(mF,cp0);
            obj.vgMF=dce + sum(gMF);
            % Calculate Generalized Disfunction
            obj.gDF=scaleRow(obj.tDF(:,1:end-1),cp0);
            % method depending variables
            switch method
                case cType.DiagnosisMethod.WASTE_OUTPUT
                    obj.gCMR=zeros(obj.NrOfProcesses,obj.NrOfProcesses);
                    obj.gCW0=cPIN .* obj.DW0';
                case cType.DiagnosisMethod.WASTE_INTERNAL
                    obj.gCMR=obj.computeWasteMalfunctionCost(cPIN,cP);
                    obj.gCW0=gpuk.cP .* obj.DWt';
            end
        end

        function res=getAmortizationCost(obj)
        % Get amortization cost
            res=[obj.dcZ,sum(obj.dcZ)];
        end

        function res=getProductionGeneralCostVariation(obj)
        % Get General Cost Variation of final Prducts
            res=[obj.dGCW0,sum(obj.dGCW0)];
        end

        function res=getGeneralFuelImpact(obj)
        % Generalized fuel impact
            res=obj.dGC0;
        end

        function res=getGeneralizedMalfunctionCost(obj)
        % Total Malfunction Cost (Internal and External)
            res=obj.gA0;
        end

        function res=getInternalMalfunctionCost(obj)
        % Internal Malfunction Cost
            aux=sum(obj.gDF)+obj.vgMF;
            res=[aux,sum(aux)];
        end

        function res=getExternalMalfunctionCost(obj)
        % External (waste) Malfunction cost
            aux=sum(obj.gCMR);
            res=[aux,sum(aux)];
        end

        function res=getGeneralMalfunctionCostTable(obj)
        % General Malfunction Cost Table
            aux=obj.gDF+obj.gCMR;
            res=[[aux,obj.gCW0'];[obj.vgMF,0]];
        end
    end
end