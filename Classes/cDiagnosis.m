classdef cDiagnosis < cResultId
% cDiagnosis make Thermoeconomic Diagnosis Analysis
%   It compares two states of the plant given by two cModelFPR objects
%   cDiagnosis methods and properties
%   Methods:
%	    obj=cDiagnosis(fp0,fp1,method)
%
	properties(GetAccess=public, SetAccess=protected)
        NrOfProcesses % Number of processes
        NrOfWastes % Number of Wastes
        DW0  % System output variation
        DWt  % Final demand variation
        DFT  % Fuel Impact
        DKP  % Unit Cost Variation Matrix
		tMF  % Malfunction table
        vMF  % Process Malfunction
		tDF  % Disfunction table
        tMR  % Waste Malfunction Matrix
        tDR  % Waste Diafunction Matrix
        tMCR % Waste Malfunction Cost Table
        vMCR % Waste Malfunction Cost
        dCW0 % Direct Cost of Output Variation
        A0   % Technical saving
    end
	
	methods
		function obj=cDiagnosis(fp0,fp1,method)
        % Diagnosis Constructor
        %  fp0: cModelFPR object for reference state
        %  fp1: cModelFPR object for operation state
        %  method: Diagnosis Method used. 
        %   cType.DiagnosisMethod.WASTE_OUTPUT
        %   cType.DiagnosisMethod.WASTE_INTERNAL   
            obj=obj@cResultId(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
            if ~isa(fp0,'cModelFPR') || ~isa(fp1,'cModelFPR')
                obj.messageLog(cType.ERROR,'Input parameters are not cModelFPR objects');
                return
            end
            if (fp0.ps~=fp1.ps)
                obj.messageLog(cType.ERROR,'Compare not equal productive structures');
                return
            end
            if ~all(fp0.ActiveProcesses==fp1.ActiveProcesses)
                obj.messageLog(cType.ERROR,'Compare two diferent plant configurations is not possible');
                return
            end
            if ~ismember(method,[cType.DiagnosisMethod.WASTE_OUTPUT,cType.DiagnosisMethod.WASTE_INTERNAL])
                obj.messageLog(cType.ERROR,'Invalid Diagnosis method');
                return
            end
            if (method==cType.DiagnosisMethod.WASTE_INTERNAL) && ~fp1.isWaste
                obj.messageLog(cType.ERROR,'Diagnosis Method requires waste information');
                return
            end
            % Check if the states are equal
            obj.DKP=zerotol(fp1.pfOperators.mKP-fp0.pfOperators.mKP);
            if all(obj.DKP==0)
                obj.messageLog(cType.ERROR,'Reference and Operation states are the same');
                return
            end
            % Preparing the model
            opI=fp1.pfOperators.opI;
            dpuk=fp1.getDirectProcessUnitCost;
            cP=dpuk.cP;
            cPIN=dpuk.cPE;     
            obj.DW0=fp1.SystemOutput - fp0.SystemOutput;
            obj.DWt=fp1.FinalDemand - fp0.FinalDemand;
            dcpt=cP * obj.DWt;
            obj.DFT=sum(fp1.Resources-fp0.Resources);
            obj.A0=obj.DFT - dcpt;
            obj.tMF=[scaleCol(obj.DKP,fp0.ProductExergy),[obj.DW0;0]];
            obj.vMF=sum(obj.tMF(:,1:end-1));
            obj.tDF=zerotol(opI*obj.tMF(1:end-1,:));
            N=fp0.NrOfProcesses;
            switch method
                case cType.DiagnosisMethod.WASTE_OUTPUT
                    obj.dCW0=cPIN .* obj.DW0';
                    obj.tMCR=zeros(N,N);
                case cType.DiagnosisMethod.WASTE_INTERNAL
                    opR=fp1.WasteOperators.opR;
                    obj.dCW0= cP .* obj.DWt;
                    obj.tMR=scaleCol(fp1.WasteTable.mKR-fp0.WasteTable.mKR,fp0.ProductExergy);
                    obj.tDR=opR * obj.tMF(1:end-1,1:end-1);
                    obj.tMCR=obj.computeWasteMalfunctionCost(cPIN,cP);
            end
            obj.NrOfProcesses=fp0.NrOfProcesses;
		    obj.NrOfWastes=fp0.NrOfWastes;    
            obj.status=cType.VALID;
        end
        
        function res=getIrreversibilityTable(obj)
        % Build the irreversibility table
            res=[[obj.tDF',[obj.DW0;0]];[obj.vMF,0]];
        end
        
		function res=getMalfunctionTable(obj)
        % get Malfunction table
            res=obj.tMF;
        end
		
		function res=getFuelImpact(obj)
        % get Fuel Impact value
            res=obj.DFT;
        end

        function res=getTotalMalfunctionCost(obj)
        % Total Malfunction Cost (Internal and External)
            res=obj.A0;
        end
        
        function res=getIrreversibilityVariation(obj)
        % Get the irreversibility vatiation vector
        	vDI=sum(obj.tDF,2)' +obj.vMF;
            res=[vDI,sum(vDI)];
        end
        
        function res=getMalfunction(obj)
        % Get the malfunction vector
            aux=obj.vMF;
            res=[aux,sum(aux)];
        end
        
        function res=getMalfunctionCost(obj)
        % Get the malfunction cost vector
            aux=zerotol(sum(obj.tDF(:,1:end-1)))+obj.vMF;
			res=[aux,sum(aux)];
        end
        
        function res=getOutputVariation(obj)
        % Get the system output variation
            res=[obj.DW0', sum(obj.DW0)];
        end

        function res=getUnitConsumptionVariation(obj)
        % Get the unit consumption variation
            res=sum(obj.DKP,1);
        end
        
        function res=getDemandVariationCost(obj)
        % get the output cost variation
            res=[obj.dCW0,sum(obj.dCW0)];
        end 

        function res=getWasteVariationCost(obj)
        % Default method for Waste Variation Cost
	        res=[obj.vMCR,sum(obj.vMCR)];
        end

        function res=getMalfunctionCostTable(obj)
        % Build the malfunction cost table
            aux=obj.tDF(:,1:end-1)+obj.tMCR;
            res=[[aux,obj.dCW0'];[obj.vMF,0]];
        end
    end

    methods(Access=protected)
        function res=computeWasteMalfunctionCost(obj,cPIN,cP)
            CMR1=scaleRow(obj.tMR,cP);
            CMR2=scaleRow(obj.tDR,cPIN);
            res=CMR1+CMR2;
        end
	end
end