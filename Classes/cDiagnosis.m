classdef(Sealed) cDiagnosis < cResultId
%cDiagnosis - Thermoeconomic diagnosis of a plant state change.
%   This class compares a reference state (fp0) and an operation state (fp1),
%   both represented by cExergyCost objects sharing the same productive structure.
%   From the variation of the unit consumption matrix (DKP = mKP1 - mKP0) it
%   decomposes the total fuel impact (FuelImpact) into:
%     - Malfunctions (MF): intrinsic degradation of each process efficiency
%     - Disfunctions (DI): induced exergy consumption increases due to malfunctions
%     - Demand variation cost (DCPs): cost attributable to a change in final demand
%     - Waste malfunction cost (MR*): additional cost caused by waste variation
%
%   Two diagnosis methods are supported:
%     WASTE_EXTERNAL  Waste flows are treated as additional system outputs.
%                     Waste variation appears as a separate term (DWr) in the
%                     irreversibility table and is not propagated through cost operators.
%     WASTE_INTERNAL  Waste costs are internalized via the waste allocation table.
%                     External disfunctions (DFex) are computed using the waste
%                     cost operator opR and propagated to all productive processes.
%
%   cDiagnosis properties:
%     NrOfProcesses   - Number of productive processes in the system
%     NrOfWastes      - Number of waste (dissipative) processes
%     FuelImpact      - Total variation of system resource consumption (sum(F1) - sum(F0))
%     TechnicalSaving - Malfunction cost net of demand-variation cost (FuelImpact - DCPs)
%     Method          - Diagnosis method applied (cType.DiagnosisMethod)
%
%   cDiagnosis methods:
%     cDiagnosis                  - Create an instance of the class
%     buildResultInfo             - Build the cResultInfo for thermoeconomic diagnosis
%     getDiagnosisTable           - Get all diagnosis column vectors in a single struct
%     getUnitConsumptionVariation - Get the unit consumption variation vector of processes
%     getUnitCostVariation        - Get the unit cost variation vector of processes
%     getIrreversibilityVariation - Get the irreversibility variation vector of processes
%     getIrreversibilityTable     - Get the irreversibility variation table (DI matrix)
%     getOutputVariation          - Get the system output variation vector
%     getDemandVariation          - Get the final demand variation vector
%     getDemandVariationCost      - Get the cost of the final demand variation per process
%     getWasteVariation           - Get the waste flow variation vector
%     getMalfunction              - Get the process malfunction vector (MF)
%     getMalfunctionTable         - Get the full malfunction table (MF matrix)
%     getMalfunctionCost          - Get the malfunction cost vector (MF*)
%     getWasteMalfunctionCost     - Get the waste malfunction cost vector (MR*)
%     getWasteMalfunctionCostTable - Get the waste malfunction cost table (MR* matrix)
%     getMalfunctionCostTable     - Get the full malfunction cost table (MF* matrix)
%     getInternalDisfunction      - Get the internal disfunction matrix (DFin)
%     getExternalDisfunction      - Get the external disfunction matrix (DFex)
%     getDemandCorrectionCost     - Get the demand correction cost due to unit cost variation
%
%   See also cResultId, cExergyCost, cResultInfo
%
	properties(GetAccess=public, SetAccess=private)
        NrOfProcesses        % (double) Number of productive processes in the system
        NrOfWastes           % (double) Number of waste (dissipative) processes
        FuelImpact           % (double) Total resource consumption variation: sum(F1) - sum(F0)
        TechnicalSaving      % (double) Malfunction cost net of demand-variation cost: FuelImpact - DCPs
        Method               % (cType.DiagnosisMethod) Diagnosis method applied (WASTE_EXTERNAL or WASTE_INTERNAL)
    end

    properties(Access=private)
        dpuk    % (struct) Process unit exergy cost for the operation state (fp1)
        dpuk0   % (struct) Process unit exergy cost for the reference state (fp0)
        DKP     % (double) Unit consumption variation matrix [NxN]: mKP1 - mKP0
        DW0     % (double) System output variation vector [Nx1]: SystemOutput1 - SystemOutput0
        DWt     % (double) Final demand variation vector [Nx1]: FinalDemand1 - FinalDemand0
        DWr     % (double) Waste flow variation vector [Nx1]: DW0 - DWt
	    tMF     % (double) Malfunction table [NxN]: scaleCol(DKP, ProductExergy0)
        vMF     % (double) Process malfunction row vector [1xN]: sum(tMF, 1)
        vDI     % (double) Irreversibility variation row vector [1xN]: I1 - I0
        vMCR    % (double) Waste malfunction cost row vector [1xN]
        DFin    % (double) Internal disfunction matrix [NxN]: opI * tMF(1:N,:)
        DFex    % (double) External disfunction matrix [NxN]: non-zero only for WASTE_INTERNAL
        DF0     % (double) Output variation disfunction vector [Nx1]
        tDI     % (double) Disfunction table [NxN]: DFin + diag(DWr) or DFin + DFex
        tMC     % (double) Malfunction cost table [NxN]: DFin + diag(vMCR) or DFin + tMCR
        tMCR    % (double) Waste malfunction cost matrix [NxN] (MR* table)
        DFT     % (double) Total fuel impact scalar: sum(F1) - sum(F0)
        DCW     % (double) Demand variation cost row vector [1xN]: cP1 .* DWt'
    end
	
	methods
		function obj=cDiagnosis(fp0,fp1,method)
        %cDiagnosis - Create an instance of the cDiagnosis class.
        %   Computes all diagnosis quantities from the unit consumption variation matrix
        %   DKP = mKP1 - mKP0 and the demand variation DWt = FinalDemand1 - FinalDemand0.
        %   Malfunction and disfunction tables, malfunction cost vectors, and waste
        %   malfunction cost tables are built according to the selected diagnosis method.
        %   The constructor fails (obj.status = false) if the two cExergyCost objects
        %   do not share the same productive structure, active-process configuration,
        %   or if both states are thermodynamically identical (DKP = 0).
        %
        %   Syntax:
        %     obj = cDiagnosis(fp0, fp1, method)
        %   Input Arguments:
        %     fp0    - (cExergyCost) Cost model for the reference state
        %     fp1    - (cExergyCost) Cost model for the operation state
        %     method - (cType.DiagnosisMethod) Diagnosis method:
        %                cType.DiagnosisMethod.WASTE_EXTERNAL
        %                cType.DiagnosisMethod.WASTE_INTERNAL (requires fp1.isWaste = true)
        %   Output Arguments:
        %     obj - (cDiagnosis) Constructed object; obj.status is false if initialization fails
        
            % Check Arguments:
            if ~isObject(fp0,'cExergyCost') || ~isObject(fp1,'cExergyCost')
                obj.messageLog(cType.ERROR,cMessages.ExergyCostRequired);
                return
            end
            if (fp0.ps~=fp1.ps)
                obj.messageLog(cType.ERROR,cMessages.InvalidDiagnosisStruct);
                return
            end
            if ~all(fp0.ActiveProcesses==fp1.ActiveProcesses)
                obj.messageLog(cType.ERROR,cMessages.InvalidDiagnosisConf);
                return
            end
            if ~ismember(method,[cType.DiagnosisMethod.WASTE_EXTERNAL,cType.DiagnosisMethod.WASTE_INTERNAL])
                obj.messageLog(cType.ERROR,cMessages.InvalidDiagnosisMethod);
                return
            end
            if (method==cType.DiagnosisMethod.WASTE_INTERNAL) && ~fp1.isWaste
                obj.messageLog(cType.ERROR,cMessages.InvalidDiagnosisMethod);
                return
            end
            % Check if the states are equal
            obj.NrOfProcesses=fp0.NrOfProcesses;
		    obj.NrOfWastes=fp0.NrOfWastes;    
            obj.DKP=zerotol(fp1.pfOperators.mKP-fp0.pfOperators.mKP);
            if all(obj.DKP==0)
                obj.messageLog(cType.ERROR,cMessages.InvalidDiagnosisStruct);
                return
            end
            % Product Variation and Fuel Impact
            obj.DW0=zerotol(fp1.SystemOutput - fp0.SystemOutput);
            obj.DWt=zerotol(fp1.FinalDemand - fp0.FinalDemand);
            obj.DWr=zerotol(obj.DW0-obj.DWt);
            obj.vDI=zerotol(fp1.Irreversibility - fp0.Irreversibility);
            obj.DFT=sum(fp1.Resources-fp0.Resources);
            % Cost Information
            obj.dpuk=fp1.getProcessUnitCost;
            obj.dpuk0=fp0.getProcessUnitCost;
            % Malfunction and Disfunction Matrix
            opI=fp1.pfOperators.opI;
            obj.tMF=scaleCol(obj.DKP,fp0.ProductExergy);
            obj.vMF=sum(obj.tMF);
            obj.DFin=zerotol(opI*obj.tMF(1:end-1,:));
            obj.DCW=obj.dpuk.cP .* obj.DWt';
            N=obj.NrOfProcesses;
            % Calculate variables related to waste variation
            if obj.NrOfWastes>0
                tMR=scaleCol(fp1.pfOperators.mKR-fp0.pfOperators.mKR,fp0.ProductExergy);
                opR=fp1.pfOperators.opR;
                opIR=opI + opI*opR;
                tDR=tMR + opR*tMR + opR*obj.tMF(1:N,:);
                obj.tMCR=scaleRow(tDR,obj.dpuk.cPE);
            else
                obj.tMCR=zeros(N,N);
            end
            % Calculate malfunction cost and disfunction tables depending on the method
            switch method
                case cType.DiagnosisMethod.WASTE_EXTERNAL
                    % WASTE_EXTERNAL method
                    obj.DF0=opI*obj.DW0;
                    obj.vMCR=sum(obj.tMCR,2)';
                    obj.DFex=zeros(N,N);
                    obj.tDI=obj.DFin + diag(obj.DWr);
                    obj.tMC=obj.DFin + diag(obj.vMCR);
                case cType.DiagnosisMethod.WASTE_INTERNAL 
                    % WASTE_INTERNAL method  
                    obj.DF0=(opIR+opR)*obj.DWt;
                    obj.vMCR=sum(obj.tMCR);
                    obj.DFex=tDR + opI*tDR;
                    obj.tDI=obj.DFin + obj.DFex;
                    obj.tMC=obj.DFin + obj.tMCR;
            end 
            % cResultId properties
            obj.Method=method;
            obj.ResultId=cType.ResultId.THERMOECONOMIC_DIAGNOSIS;
            obj.DefaultGraph=cType.Tables.MALFUNCTION_COST;
            obj.ModelName=fp1.ModelName;
            obj.State=fp1.State;
        end

        function res=get.FuelImpact(obj)
        %FuelImpact - Get the total fuel impact of the state change.
        %   Returns the scalar difference in total resource consumption between
        %   the operation state and the reference state: sum(F1) - sum(F0).
        %   A positive value indicates higher fuel consumption in operation.
        %
        %   Syntax:
        %     res = obj.FuelImpact
        %   Output Arguments:
        %     res - (double) Scalar total resource consumption variation [kW or kJ]
            res=0;
            if obj.status
                res=obj.DFT;
            end
        end

        function res=get.TechnicalSaving(obj)
        %TechnicalSaving - Get the malfunction cost net of demand-variation cost.
        %   Subtracts from FuelImpact the portion attributable to the change in
        %   final demand, evaluated at reference unit costs for demand increases
        %   and at operation unit costs for demand decreases.
        %   A positive value means that process degradation (malfunctions) consumed
        %   more resources than the demand variation alone would justify.
        %
        %   Syntax:
        %     res = obj.TechnicalSaving
        %   Output Arguments:
        %     res - (double) Scalar malfunction cost net of demand-variation cost [kW or kJ]
            res=0;
            if obj.status
                cpt = obj.dpuk0.cP .* (obj.DWt>0)' + obj.dpuk.cP .* (obj.DWt<0)';
                res = obj.DFT - cpt * obj.DWt;
            end
        end

        function res=buildResultInfo(obj,fmt)
        %buildResultInfo - Build the cResultInfo object for thermoeconomic diagnosis.
        %   Delegates table construction to the cResultTableBuilder, which packages
        %   all diagnosis tables (malfunction, disfunction, malfunction cost, etc.)
        %   into a cResultInfo container ready for display or export.
        %
        %   Syntax:
        %     res = obj.buildResultInfo(fmt)
        %   Input Arguments:
        %     fmt - (cResultTableBuilder) Table builder and format configuration object
        %   Output Arguments:
        %     res - (cResultInfo) Results container for THERMOECONOMIC_DIAGNOSIS
        %
            res=fmt.getDiagnosisResults(obj);
        end

        function res=getDiagnosisTable(obj)
        %getDiagnosisTable - Get all diagnosis column vectors packed into a struct.
        %   Collects the seven diagnosis vectors that form the columns of the
        %   summary diagnosis table. Each field is a row vector of length N+1,
        %   where the last element is the column total.
        %
        %   Syntax:
        %     res = obj.getDiagnosisTable
        %   Output Arguments:
        %     res - (struct) Diagnosis column vectors:
        %       MF   - Process malfunction (getMalfunction)
        %       DI   - Irreversibility variation (getIrreversibilityVariation)
        %       DR   - Waste flow variation (getWasteVariation)
        %       DPs  - Final demand variation (getDemandVariation)
        %       MFC  - Malfunction cost (getMalfunctionCost)
        %       MRC  - Waste malfunction cost (getWasteMalfunctionCost)
        %       DCPs - Demand variation cost (getDemandVariationCost)
        %
            res.MF=zerotol(obj.getMalfunction);
            res.DI=zerotol(obj.getIrreversibilityVariation);
            res.DR=zerotol(obj.getWasteVariation);
            res.DPs=zerotol(obj.getDemandVariation);
            res.MFC=zerotol(obj.getMalfunctionCost);
            res.MRC=zerotol(obj.getWasteMalfunctionCost);
            res.DCPs=zerotol(obj.getDemandVariationCost);
        end

        function res=getUnitConsumptionVariation(obj)
        %getUnitConsumptionVariation - Get the unit consumption variation vector.
        %   Returns the column sums of DKP, i.e. the net change in unit exergy
        %   consumption for each process between the reference and operation states.
        %   Positive values indicate efficiency degradation.
        %
        %   Syntax:
        %     res = obj.getUnitConsumptionVariation
        %   Output Arguments:
        %     res - (double) Row vector [1xN] of unit consumption variations per process
            res=sum(obj.DKP,1);
        end

        function res=getUnitCostVariation(obj)
        %getUnitCostVariation - Get the unit exergy cost variation of processes.
        %   Returns the difference between operation and reference unit process costs
        %   (cP1 - cP0). A positive value means that the unit cost of the process
        %   product increased between the two states.
        %
        %   Syntax:
        %     res = obj.getUnitCostVariation
        %   Output Arguments:
        %     res - (double) Row vector [1xN] of unit cost variations per process
        %        
            res=obj.dpuk.cP-obj.dpuk0.cP;
        end

        function res=getIrreversibilityVariation(obj)
        %getIrreversibilityVariation - Get the irreversibility variation of processes.
        %   Returns the difference in irreversibility (I1 - I0) for each process,
        %   with the total system variation appended as the last element.
        %
        %   Syntax:
        %     res = obj.getIrreversibilityVariation
        %   Output Arguments:
        %     res - (double) Row vector [1x(N+1)] of irreversibility variations; last element is total
        %    
            res=[obj.vDI,sum(obj.vDI)];
        end

        function res=getOutputVariation(obj)
        %getOutputVariation - Get the system output variation vector.
        %   Returns DW0 = SystemOutput1 - SystemOutput0, the change in exergy
        %   delivered by each process to the plant product (including waste output).
        %   The last element is the total system output variation.
        %
        %   Syntax:
        %     res = obj.getOutputVariation
        %   Output Arguments:
        %     res - (double) Row vector [1x(N+1)] of output variations; last element is total
        % 
            res=[obj.DW0', sum(obj.DW0)];
        end

        function res=getDemandVariation(obj)
        %getDemandVariation - Get the final demand variation vector.
        %   Returns DWt = FinalDemand1 - FinalDemand0, the change in effective
        %   final demand per process. For productive processes this equals
        %   the output variation; for waste processes it is scaled by RecycleRatio.
        %   The last element is the total demand variation.
        %
        %   Syntax:
        %     res = obj.getDemandVariation
        %   Output Arguments:
        %     res - (double) Row vector [1x(N+1)] of demand variations; last element is total
        % 
            res=[obj.DWt', sum(obj.DWt)];
        end

        function res=getWasteVariation(obj)
        %getWasteVariation - Get the waste flow variation vector.
        %   Returns DWr = DW0 - DWt, the portion of the output variation that is
        %   attributable to a change in waste (non-recovered) exergy rather than
        %   to a change in useful final demand.
        %   The last element is the total waste variation.
        %
        %   Syntax:
        %     res = obj.getWasteVariation
        %   Output Arguments:
        %     res - (double) Row vector [1x(N+1)] of waste variations; last element is total
        %
            res=[obj.DWr',sum(obj.DWr)];
        end

        function res=getDemandVariationCost(obj)
        %getDemandVariationCost - Get the cost of the final demand variation per process.
        %   Returns DCW = cP1 .* DWt, the exergy cost associated with the change
        %   in final demand for each process, valued at operation-state unit costs.
        %   The last element is the total demand variation cost.
        %
        %   Syntax:
        %     res = obj.getDemandVariationCost
        %   Output Arguments:
        %     res - (double) Row vector [1x(N+1)] of demand variation costs; last element is total
        % 
            res=[obj.DCW,sum(obj.DCW)];
        end 

        function res=getMalfunction(obj)
        %getMalfunction - Get the process malfunction vector (MF).
        %   Returns the column sums of the malfunction table (tMF), representing
        %   the intrinsic efficiency degradation of each process. A positive value
        %   indicates that the process consumed more fuel for the same product in
        %   the operation state relative to the reference state.
        %   The last element is the total malfunction.
        %
        %   Syntax:
        %     res = obj.getMalfunction
        %   Output Arguments:
        %     res - (double) Row vector [1x(N+1)] of process malfunctions; last element is total
        %         
            aux=obj.vMF;
            res=[aux,sum(aux)];
        end

        function res=getIrreversibilityTable(obj)
        %getIrreversibilityTable - Build the irreversibility variation table.
        %   Assembles the (N+2) x (N+1) matrix used to present the full diagnosis
        %   in tabular form. Rows correspond to processes (disfunctions), the demand
        %   variation row (DF0), and the malfunction row (vMF). Columns correspond
        %   to processes plus the demand variation column (DWt).
        %
        %   Syntax:
        %     res = obj.getIrreversibilityTable
        %   Output Arguments:
        %     res - (double) Matrix [(N+2)x(N+1)] containing the irreversibility variation table
        %
            res=[obj.tDI',obj.DWt;obj.DF0',0;obj.vMF,0];
        end


		function res=getMalfunctionTable(obj)
        %getMalfunctionTable - Get the full malfunction table (MF matrix).
        %   Returns the (N+1) x (N+1) matrix tMF augmented with the system
        %   output variation vector DW0 as the last column. Entry (i,j) of tMF
        %   gives the contribution of the unit consumption variation dkij to
        %   the malfunction of process j.
        %
        %   Syntax:
        %     res = obj.getMalfunctionTable
        %   Output Arguments:
        %     res - (double) Matrix [(N+1)x(N+1)] of malfunction values with output variation column
        % 
            res=[obj.tMF,[obj.DW0;0]];
        end
        
        function res=getMalfunctionCost(obj)
        %getMalfunctionCost - Get the malfunction cost vector (MF*).
        %   Returns the total exergy cost attributable to process malfunctions,
        %   combining internal disfunctions (propagated through opI) and the
        %   direct malfunction of each process: sum(DFin) + vMF.
        %   The last element is the total malfunction cost.
        %
        %   Syntax:
        %     res = obj.getMalfunctionCost
        %   Output Arguments:
        %     res - (double) Row vector [1x(N+1)] of malfunction costs; last element is total
        %       
            aux=zerotol(sum(obj.DFin))+obj.vMF;
			res=[aux,sum(aux)];
        end
        
        function res=getWasteMalfunctionCost(obj)
        %getWasteMalfunctionCost - Get the waste malfunction cost vector (MR*).
        %   Returns the additional exergy cost per process caused by changes in
        %   waste allocation between the two states. For WASTE_EXTERNAL this is
        %   the row sum of tMCR; for WASTE_INTERNAL it is the column sum.
        %   The last element is the total waste malfunction cost.
        %
        %   Syntax:
        %     res = obj.getWasteMalfunctionCost
        %   Output Arguments:
        %     res - (double) Row vector [1x(N+1)] of waste malfunction costs; last element is total
        %     
	        res=[obj.vMCR,sum(obj.vMCR)];
        end

        function res=getWasteMalfunctionCostTable(obj)
        %getWasteMalfunctionCostTable - Get the waste malfunction cost table (MR* matrix).
        %   Returns the full NxN matrix tMCR where entry (i,j) represents the
        %   waste malfunction cost contribution from process i to process j.
        %   This matrix is built as scaleRow(tDR, cPE) where tDR accumulates
        %   the waste unit consumption variations weighted by product exergy.
        %
        %   Syntax:
        %     res = obj.getWasteMalfunctionCostTable
        %   Output Arguments:
        %     res - (double) Matrix [NxN] of waste malfunction cost contributions
        %     
            res=obj.tMCR;
        end

        function res=getMalfunctionCostTable(obj)
        %getMalfunctionCostTable - Get the full malfunction cost table (MF* matrix).
        %   Returns the (N+1) x (N+1) matrix tMC augmented with the demand
        %   variation cost vector DCW as the last column. Entry (i,j) of tMC
        %   gives the cost contribution of the malfunction in process j to
        %   the total fuel consumed by process i.
        %
        %   Syntax:
        %     res = obj.getMalfunctionCostTable
        %   Output Arguments:
        %     res - (double) Matrix [(N+1)x(N+1)] of malfunction costs with demand variation column
        % 
            res=[obj.tMC,obj.DCW';obj.vMF,0];
        end

        function res=getInternalDisfunction(obj)
        %getInternalDisfunction - Get the internal disfunction matrix (DFin).
        %   Returns the transpose of DFin = opI * tMF(1:N,:), where opI is the
        %   irreversibility cost operator of the operation state. Entry (i,j) of
        %   the result gives the induced exergy increase in process i caused by
        %   the malfunction of process j.
        %
        %   Syntax:
        %     res = obj.getInternalDisfunction
        %   Output Arguments:
        %     res - (double) Matrix [NxN] of internal disfunction values (DFin transposed)
        %
            res=obj.DFin';
        end

        function res=getExternalDisfunction(obj)
        %getExternalDisfunction - Get the external disfunction matrix (DFex).
        %   Returns the transpose of DFex, which captures the additional exergy
        %   consumption induced by waste flow variations. For WASTE_EXTERNAL this
        %   is always zero; for WASTE_INTERNAL it is computed from the waste unit
        %   consumption variation matrix (mKR1 - mKR0) propagated via opR and opI.
        %
        %   Syntax:
        %     res = obj.getExternalDisfunction
        %   Output Arguments:
        %     res - (double) Matrix [NxN] of external disfunction values (DFex transposed)
        %
            res=obj.DFex';
        end

        function res=getDemandCorrectionCost(obj)
        %getDemandCorrectionCost - Get the demand correction cost due to unit cost variation.
        %   Returns the additional cost per process arising from delivering a higher
        %   final demand at operation unit costs instead of reference unit costs.
        %   Only demand increases (DWt > 0) are considered; the cost increment is
        %   (cP1 - cP0) .* DWt for those processes.
        %   The last element is the total demand correction cost.
        %
        %   Syntax:
        %     res = obj.getDemandCorrectionCost
        %   Output Arguments:
        %     res - (double) Row vector [1x(N+1)] of demand correction costs; last element is total
        %
            dcpt = (obj.dpuk.cP-obj.dpuk0.cP) .* (obj.DWt>0)';
            val = dcpt .* obj.DWt';
            res=[val,sum(val)];
        end
    end
end