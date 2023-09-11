classdef cDiagnosis < cResultId
% cDiagnosis make Thermoeconomic Diagnosis Analysis
%   It compares two states of the plant given by two cModelFPR objects.
%   Two method could be applied:
%   WASTE_EXTERNAL considers waste as a system output
%   WASTE_INTERNAL internalize the waste cost according waste table allocation
%   Methods:
%	    obj=cDiagnosis(fp0,fp1,method)
%       obj.FuelImpact
%       obj.TotalMalfunctionCost
%       obj.getUnitConsumptionVariation
%       obj.getIrreversibilityVariation
%       obj.getIrreversibilityTable
%       obj.getOutputVariation
%       obj.getDemandVariationCost
%       obj.getUnitProductCostVariation
%       obj.getMalfunction
%       obj.getMalfunctionTable
%       obj.getMalfunctionCost
%       obj.getWasteMalfunctionCost
%       obj.getMalfunctionCostTable
%       obj.getInternalDisfunction
%       obj.getExternalDisfunction
%       obj.getDemandVariationEffectiveCost
	properties(GetAccess=public, SetAccess=private)
        NrOfProcesses        % Number of processes
        NrOfWastes           % Number of Wastes
        FuelImpact           % Fuel Impact
        TotalMalfunctionCost % Total Malfunction Cost
        Method               % Diagnosis Method
    end
    properties(Access=private)
        iwr     % Waste index
        dpuk    % Direct Unit exergy cost (operation)
        opI     % Irreversibility operator
        DKP     % Unit Cost Variation Matrix
        DW0     % System output variation
        DWt     % Final demand variation
        DWr     % Waste variation
        DcP     % Unit Cost Variation     
	    tMF     % Malfunction Matrix
        tDF     % Disfunction Matrix
        vMF     % Process Malfunction
        vDI     % Irreversibility Variation
        vMCR    % Waste Malfuction Cost
        DFin    % Internal disfunction matrix
        DFex    % External disfunction matrix
        DFT     % Fuel Impact
        DCW     % Cost of Output Variation
        DW      % Output Variation
        DIT     % Irreversibilty Table
        MFC     % Malfunction Cost Table
        A0      % Technical Saving
        DWTEC   % Efective cost variation of final products
    end
	
	methods
		function obj=cDiagnosis(fp0,fp1,method)
        % Diagnosis Constructor
        %  fp0: cModelFPR object for reference state
        %  fp1: cModelFPR object for operation state
        %  method: Diagnosis Method used. 
        %   cType.DiagnosisMethod.WASTE_EXTERNAL
        %   cType.DiagnosisMethod.WASTE_INTERNAL   
            obj=obj@cResultId(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
            % Check Arguments
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
            if ~ismember(method,[cType.DiagnosisMethod.WASTE_EXTERNAL,cType.DiagnosisMethod.WASTE_INTERNAL])
                obj.messageLog(cType.ERROR,'Invalid Diagnosis method');
                return
            end
            if (method==cType.DiagnosisMethod.WASTE_INTERNAL) && ~fp1.isWaste
                obj.messageLog(cType.ERROR,'Diagnosis Method requires waste information');
                return
            end
            % Check if the states are equal
            obj.NrOfProcesses=fp0.NrOfProcesses;
		    obj.NrOfWastes=fp0.NrOfWastes;    
            obj.DKP=zerotol(fp1.pfOperators.mKP-fp0.pfOperators.mKP);
            if all(obj.DKP==0)
                obj.messageLog(cType.ERROR,'Reference and Operation states are the same');
                return
            end
            % Product Variation
            obj.iwr=fp1.ps.Waste.processes;
            obj.DW0=fp1.SystemOutput - fp0.SystemOutput;
            obj.DWt=fp1.FinalDemand - fp0.FinalDemand;
            obj.DWr=obj.DW0-obj.DWt;
            obj.vDI=(fp1.Irreversibility - fp0.Irreversibility) + obj.DWr';
            % Cost Information
            obj.opI=fp1.pfOperators.opI;
            obj.dpuk=fp1.getDirectProcessUnitCost;
            dpuk0=fp0.getDirectProcessUnitCost;
            obj.DcP=obj.dpuk.cP-dpuk0.cP;
            % Malfunction and Disfunction Matrix
            obj.tMF=scaleCol(obj.DKP,fp0.ProductExergy);
            obj.vMF=sum(obj.tMF);
            obj.tDF=zerotol(obj.opI*obj.tMF(1:end-1,:));
            % Calculate the malfunction cost according to the chosen method
            switch method
                case cType.DiagnosisMethod.WASTE_EXTERNAL
                    obj.wasteOutputMethod;
                case cType.DiagnosisMethod.WASTE_INTERNAL
                    obj.wasteInternalMethod(fp0,fp1);
                otherwise
                    obj.messageLog(cType.ERROR,'Invalid Diagnosis method');
                    return
            end
            % Fuel Impact and Malfunction Cost
            obj.DWTEC=obj.computeDWTEC(dpuk0.cP,obj.dpuk.cP);
            obj.DFT=sum(fp1.Resources-fp0.Resources);
            obj.A0=obj.DFT - sum(obj.DWTEC);
            % Object Status Information
            obj.Method=method;
            obj.status=cType.VALID;
        end

        function res=get.FuelImpact(obj)
        % Get Fuel Impact value
            res=obj.DFT;
        end

        function res=get.TotalMalfunctionCost(obj)
        % Total Malfunction Cost (Internal and External)
            res=obj.A0;
        end

        function res=getUnitConsumptionVariation(obj)
        % Get the unit consumption variation
            res=sum(obj.DKP,1);
        end

        function res=getProcessUnitCostVariation(obj)
            res=obj.DcP;
        end

        function res=getIrreversibilityVariation(obj)
        % Get the irreversibility vatiation vector
            res=[obj.vDI,sum(obj.vDI)];
        end

        function res=getIrreversibilityTable(obj)
        % Build the irreversibility table
            res=[[obj.DIT',[obj.DW;0]];[obj.vMF,0]];
        end

        function res=getOutputVariation(obj)
        % Get the system output variation
            res=[obj.DW0', sum(obj.DW0)];
        end

        function res=getDemandVariation(obj)
        % Get the system demand variation
            res=[obj.DWt', sum(obj.DWt)];
        end
            
        function res=getDemandVariationCost(obj)
        % get the output cost variation
            res=[obj.DCW,sum(obj.DCW)];
        end 

        function res=getMalfunction(obj)
        % Get the malfunction vector
            aux=obj.vMF;
            res=[aux,sum(aux)];
        end

		function res=getMalfunctionTable(obj)
        % get Malfunction table
            res=[obj.tMF,[obj.DW0;0]];
        end
        
        function res=getMalfunctionCost(obj)
        % Get the malfunction cost vector
            aux=zerotol(sum(obj.tDF))+obj.vMF;
			res=[aux,sum(aux)];
        end
        
        function res=getWasteMalfunctionCost(obj)
        % Default method for Waste Variation Cost
	        res=[obj.vMCR,sum(obj.vMCR)];
        end

        function res=getMalfunctionCostTable(obj)
        % Build the malfunction cost table
            res=[[obj.MFC,obj.DCW'];[obj.vMF,0]];
        end

        function res=getInternalDisfunction(obj)
        % Get internal disfunction matrix
            res=obj.DFin';
        end

        function res=getExternalDisfunction(obj)
        % Get waste disfunction matrix
            res=obj.DFex';
        end

        function res=getDemandVariationEffectiveCost(obj)
        % Get Demand Variation effective cost.
            res=[obj.DWTEC,sum(obj.DWTEC)];
        end

    end

    methods(Access=protected)
        function wasteOutputMethod(obj)
        % Compute internal variables with WASTE_EXTERNAL method
            N=obj.NrOfProcesses;
            idx=obj.iwr;
            mdwr=sparse(idx,idx,obj.DWr(idx),N,N+1);
            mf=obj.tMF(1:N,:);
            obj.DW=obj.DWt;
            obj.DCW=obj.dpuk.cPE .* obj.DW0';
            obj.DFin=obj.opI*[mf,obj.DWt];
            obj.DFex=zeros(N,N+1);
            dfr=obj.opI*mdwr;
            obj.DIT=obj.DFin+dfr+mdwr;
            obj.vMCR=zeros(1,N);
            obj.MFC=obj.tDF;
        end
        
        function wasteInternalMethod(obj,fp0,fp1)
        % Compute internal variables with WASTE_INTERNAL method
            N=obj.NrOfProcesses;
            opR=fp1.WasteOperators.opR;
            cP=obj.dpuk.cP;
            cPE=obj.dpuk.cPE;
            obj.DW=obj.DWt;
            obj.DCW=obj.dpuk.cP .* obj.DWt';
            % Prepare internal variables
            mf=obj.tMF(1:N,:);
            mr=full(scaleCol(fp1.WasteTable.mKR-fp0.WasteTable.mKR,fp0.ProductExergy));
            dr=opR*mf;
            mfr=[mf+mr,obj.DWt];
            % Compute Malfunction Cost
            tMCR=scaleRow(mr,cP)+scaleRow(dr,cPE);
            obj.vMCR=sum(tMCR);
            obj.MFC=obj.tDF+tMCR;
            % Compute waste variation
            mdwr=[mr,zeros(N,1)]+opR*mfr;
            % Compute Irreversibility table
            obj.DFin=obj.opI*([mf,obj.DWt]);
            obj.DFex=obj.opI*mdwr;
            obj.DIT=obj.DFin+obj.DFex+mdwr;
        end

        function res=computeDWTEC(obj,c0,c1)
        % Compute the cost of the final product variation (alternate version)
        % If the variation is positive takes the reference cost
        % If the variation is negative takes the actual cost
            cpt=c0 .* (obj.DWt>0)' + c1 .* (obj.DWt<0)';
            res= cpt .* obj.DWt';
        end
	end
end