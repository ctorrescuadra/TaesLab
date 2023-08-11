classdef cDiagnosis < cResultId
% cDiagnosis make Thermoeconomic Diagnosis Analysis
%   It compares two states of the plant given by two cModelFPR objects.
%   Two method could be applied:
%   WASTE_OUTPUT considers waste as a system output
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
%
	properties(GetAccess=public, SetAccess=private)
        NrOfProcesses        % Number of processes
        NrOfWastes           % Number of Wastes
        FuelImpact           % Fuel Impact
        TotalMalfunctionCost % Total Malfunction Cost
    end
    properties(Access=private)
        opI     % Irreversibility operator
        DKP     % Unit Cost Variation Matrix
        DW0     % System output variation
        DWt     % Final demand variation
        DcP     % Unit Cost Variation     
	    tMF     % Malfunction Matrix
        tDF     % Disfunction Matrix
        tDF0    % External Disfunction Matrix     
        tMCR    % Waste Malfuction Cost
        vMF     % Process Malfunction
        vDI     % Irreversibility Variation
        DFT     % Fuel Impact
        DCW     % Cost of Output Variation
        DW      % Output Variation
        DIT     % Irreversibilty Table
        MFC     % Malfunction Cost Table
        A0      % Technical Saving
        dpuk    % direct Unit exergy cost (operation)
        dpuk0   % direct Unit exergy cost (reference)
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
            if ~ismember(method,[cType.DiagnosisMethod.WASTE_OUTPUT,cType.DiagnosisMethod.WASTE_INTERNAL])
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
            obj.vDI=fp1.Irreversibility - fp0.Irreversibility;
            obj.DW0=fp1.SystemOutput - fp0.SystemOutput;
            obj.DWt=fp1.FinalDemand - fp0.FinalDemand;
            % Cost Information
            obj.opI=fp1.pfOperators.opI;
            obj.dpuk=fp1.getDirectProcessUnitCost;
            obj.dpuk0=fp0.getDirectProcessUnitCost;
            obj.DcP=obj.dpuk.cP-obj.dpuk0.cP;
            % Malfunction and Disfunction Matrix
            obj.tMF=[scaleCol(obj.DKP,fp0.ProductExergy),[obj.DW0;0]];
            obj.vMF=sum(obj.tMF(:,1:end-1));
            obj.tDF=zerotol(obj.opI*obj.tMF(1:end-1,:));
            iw0=fp1.ps.SystemOutput.processes;
            obj.tDF0=scaleCol(obj.opI(:,iw0),obj.DW0(iw0));
            % Calculate the malfunction cost according to the chosen method
            switch method
                case cType.DiagnosisMethod.WASTE_OUTPUT
                    obj.wasteOutputMethod;
                case cType.DiagnosisMethod.WASTE_INTERNAL
                    obj.wasteInternalMethod(fp0,fp1);
                otherwise
                    obj.messageLog(cType.ERROR,'Invalid Diagnosis method');
                    return
            end
            % Fuel Impact and Malfunction Cost
            dcpt=obj.computeDCPT(obj.dpuk0.cP,obj.dpuk.cP);
            obj.DFT=sum(fp1.Resources-fp0.Resources);
            obj.A0=obj.DFT - dcpt;
            % Object Status Information
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
            res=obj.tMF;
        end
        
        function res=getMalfunctionCost(obj)
        % Get the malfunction cost vector
            aux=zerotol(sum(obj.tDF(:,1:end-1)))+obj.vMF;
			res=[aux,sum(aux)];
        end
        
        function res=getWasteMalfunctionCost(obj)
        % Default method for Waste Variation Cost
            aux=sum(obj.tMCR);
	        res=[aux,sum(aux)];
        end

        function res=getMalfunctionCostTable(obj)
        % Build the malfunction cost table
            res=[[obj.MFC,obj.DCW'];[obj.vMF,0]];
        end

        function res=getExternalDisfunction(obj)
        % Get the external disfunction table
            rsum=sum(obj.tDF0,2);
            csum=sum(obj.tDF0,1);
            tsum=sum(csum);
            res=[obj.tDF0,rsum;[csum,tsum]];
        end
    end

    methods(Access=protected)
        function wasteOutputMethod(obj)
        % Compute internal variables with WASTE_OUTPUT method
            N=obj.NrOfProcesses;
            obj.DCW=obj.dpuk.cPE .* obj.DW0';
            obj.DW=obj.DW0;
            obj.MFC=obj.tDF(:,1:N);
            obj.DIT=obj.tDF;
            obj.tMCR=zeros(N,N);
        end
        
        function wasteInternalMethod(obj,fp0,fp1)
        % Compute internal variables with WASTE_INTERNAL method
            N=obj.NrOfProcesses;
            opR=fp1.WasteOperators.opR;
            iwr=fp1.ps.Waste.processes;
            cP=obj.dpuk.cP;
            cPE=obj.dpuk.cPE;
            % Compute Waste Malfunction Cost
            tMR=scaleCol(fp1.WasteTable.mKR-fp0.WasteTable.mKR,fp0.ProductExergy);
            tDR=opR * obj.tMF(1:N,1:N);
            obj.tMCR=scaleRow(tMR,cP)+scaleRow(tDR,cPE);
            % Compute waste variation
            res1=tMR+tDR+opR*tMR;
            res2=opR*obj.DWt;
            DWr=[full(res1),full(res2)];
            % Compute variables for tables
            obj.MFC=obj.tDF(:,1:N)+obj.tMCR;
            obj.DCW=cP .* obj.DWt';
            obj.DW=obj.DWt;
            obj.DIT=obj.tDF;
            % Update DIT matrix
            obj.DIT(:,end)=obj.opI*obj.DWt;
            DFr=scaleCol(obj.opI(:,iwr),obj.DW0(iwr));
            obj.DIT(:,iwr)=obj.DIT(:,iwr)+DFr;
            obj.DIT=obj.DIT+DWr;
        end

        function res=computeDCPT(obj,c0,c1)
        % Compute the cost of the final product variation (alternate version)
        % If the variation is positive takes the reference cost
        % If the variation is negative takes the actual cost
            cpt=c0 .* (obj.DWt>0)' + c1 .* (obj.DWt<0)';
            res= cpt * obj.DWt;
        end
	end
end