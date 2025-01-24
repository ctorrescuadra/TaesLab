classdef(Sealed) cDiagnosis < cResultId
%cDiagnosis - Make a thermoeconomic diagnosis Analysis
%   It compares two states of the plant given by two cExergyCost objects.
%   Two method could be applied:
%    WASTE_EXTERNAL considers waste as a system output
%    WASTE_INTERNAL internalize the waste cost according waste table allocation
%
%   cDiagnosis constructor:
%     obj = cDiagnosis(fp0,fp1,method)
% 
%   cDiagnosis properties:
%     NrOfProcesses        - Number of processes
%     NrOfWastes           - Number of Wastes
%     FuelImpact           - Fuel Impact
%     TotalMalfunctionCost - Total Malfunction Cost
% 
%   cDiagnosis Methods
%     buildResultInfo             - Build the cResultInfo associated to thermoeconomic diagnosis
%     getUnitConsumptionVariation - Get the unit consumption variation of processes
%     getProcessUnitCostVariation - Get the variation of the unit cost of processes
%     getIrreversibilityVariation - Get the irreversibility variation of processes
%     getIrreversibilityTable     - Get the Irreversity Variation table
%     getOutputVariation          - Get the output variation of processes
%     getDemandVariation          - Get the final production variation
%     getDemandVariationCost      - Get the final production cost variation
%     getWasteVariation           - Get the waste variation of processes
%     getMalfunction              - Get the malfunction of processes
%     getMalfunctionTable         - Get the malfunction table
%     getMalfunctionCost          - Get the malfunction cost of processes
%     getWasteMalfunctionCost     - Get the malfunction cost due to waste variation
%     getMalfunctionCostTable     - Get the malfunction cost table
%     getInternalDisfunction      - Get the internal disfunctions caused by malfunction
%     getExternalDisfunction      - Get the disfunction caused by waste variation
%     getDemandVariationEffectiveCost - Get the real demand variation cost
%     getDemmandCorrectionCost    - Get the correction of real demand variation cost
%
%   See also cExergyCost
%
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
        DR      % Waste variation (internal allocation)
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
        % cDiagnosis - Create an object of this class
        % Syntax:
        %   obj=cDiagnosis(fp0,fp1,method);
        % Input Arguments:
        %   fp0 - cExergyCost object for reference state
        %   fp1 - cExergyCost object for operation state
        %   method - Diagnosis Method used. 
        %     cType.DiagnosisMethod.WASTE_EXTERNAL
        %     cType.DiagnosisMethod.WASTE_INTERNAL
        %
            % Check Arguments
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
                obj.messageLog(cType.ERROR,cMessages.InvalidDiagnosisMethod,method);
                return
            end
            if (method==cType.DiagnosisMethod.WASTE_INTERNAL) && ~fp1.isWaste
                obj.messageLog(cType.ERROR,cMessages.InvalidDiagnosisMethod,method);
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
            % Product Variation
            obj.iwr=fp1.ps.Waste.processes;
            obj.DW0=zerotol(fp1.SystemOutput - fp0.SystemOutput);
            obj.DWt=zerotol(fp1.FinalDemand - fp0.FinalDemand);
            obj.DWr=zerotol(obj.DW0-obj.DWt);
            obj.vDI=zerotol(fp1.Irreversibility - fp0.Irreversibility);
            % Cost Information
            obj.opI=fp1.pfOperators.opI;
            obj.dpuk=fp1.getProcessUnitCost;
            dpuk0=fp0.getProcessUnitCost;
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
            end
            % Fuel Impact and Malfunction Cost
            obj.DWTEC=obj.computeDWTEC(dpuk0.cP,obj.dpuk.cP);
            obj.DFT=sum(fp1.Resources-fp0.Resources);
            obj.A0=obj.DFT - sum(obj.DWTEC);
            obj.Method=method;
            % cResultId properties
            obj.ResultId=cType.ResultId.THERMOECONOMIC_DIAGNOSIS;
            obj.DefaultGraph=cType.Tables.MALFUNCTION_COST;
            obj.ModelName=fp1.ModelName;
            obj.State=fp1.State;
        end

        function res=get.FuelImpact(obj)
        % Get Fuel Impact value
            res=0;
            if obj.status
                res=obj.DFT;
            end
        end

        function res=get.TotalMalfunctionCost(obj)
        % Total Malfunction Cost (Internal and External)
            res=0;
            if obj.status
                res=obj.A0;
            end
        end

        function res=buildResultInfo(obj,fmt)
        % buildResultInfo - Get cResultInfo object for thermoeconomic diagnosis
        % Syntax:
        %   res=obj.buildResultInfo(fmt)
        % Input Arguments:
        %   fmt - cFormatData object
            res=fmt.getDiagnosisResults(obj);
        end

        function res=getDiagnosisTable(obj)
        % getDiagnosisTable - Get Diagnosis Table
        % Syntax:
        %   res=obj.getDiagnosisTable
        % Output Argument
        %   res - struct containing the column values of the diagnosis table
            res.MF=zerotol(obj.getMalfunction);
            res.DI=zerotol(obj.getIrreversibilityVariation);
            res.DR=zerotol(obj.getWasteVariation);
            res.DPs=zerotol(obj.getDemandVariation);
            res.MFC=zerotol(obj.getMalfunctionCost);
            res.MRC=zerotol(obj.getWasteMalfunctionCost);
            res.DCPs=zerotol(obj.getDemandVariationCost);
        end

        function res=getUnitConsumptionVariation(obj)
        % getUnitConsumptionVariation - Get the unit consumption variation
        % Syntax:
        %   res=obj.getUnitConsumptionVariation
        % Output Argument
        %   res - array with the unit consuption variation of each process
            res=sum(obj.DKP,1);
        end

        function res=getProcessUnitCostVariation(obj)
        % getProcessUnitCostVariation - Get the unit process cost variation
        % Syntax:
        %   res=obj.getUnitConsumptionVariation
        % Output Argument
        %   res - array with the unit process cost variation of each process        
            res=obj.DcP;
        end

        function res=getIrreversibilityVariation(obj)
        % getIrreversibilityVariation - Get the unit process cost variation
        % Syntax:
        %   res=obj.getIrreversibilityVariation
        % Output Argument
        %   res - array with irreversibility variation of each process     
            res=[obj.vDI,sum(obj.vDI)];
        end

        function res=getIrreversibilityTable(obj)
        % getIrreversibilityTable - Build the irreversibility table
        % Syntax:
        %   res=obj.getIrreversibilityTable
        % Output Argument
        %   res - matrix containing the values of the irreversibility table  
            res=[[obj.DIT',[obj.DW;0]];[obj.vMF,0]];
        end

        function res=getOutputVariation(obj)
        % Get the system output variation
            res=[obj.DW0', sum(obj.DW0)];
        end

        function res=getDemandVariation(obj)
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

        function res=getDemmandCorrectionCost(obj)
        % Get Demand Correction
            tmp=obj.DCW-obj.DWTEC;
            res=[tmp,sum(tmp)];
        end

        function res=getWasteVariation(obj)
        % Get waste variation
            res=[obj.DR,sum(obj.DR)];
        end
    end

    methods(Access=private)
        function wasteOutputMethod(obj)
        % Compute internal variables with WASTE_EXTERNAL method
            N=obj.NrOfProcesses;
            mf=obj.tMF(1:N,:);
            obj.DW=obj.DW0;
            obj.DCW=obj.dpuk.cPE .* obj.DW0';
            obj.DFin=obj.opI*[mf,obj.DW0];
            obj.DFex=zeros(N,N+1);
            obj.DIT=obj.DFin;
            obj.vMCR=zeros(1,N);
            obj.MFC=obj.tDF;
            obj.DR=obj.DWr';
        end
        
        function wasteInternalMethod(obj,fp0,fp1)
        % Compute internal variables with WASTE_INTERNAL method
            N=obj.NrOfProcesses;
            opR=fp1.pfOperators.opR;
            cP=obj.dpuk.cP;
            cPE=obj.dpuk.cPE;
            obj.DW=obj.DWt;
            obj.DCW=obj.dpuk.cP .* obj.DWt';
            obj.DR=sum(fp1.TableR-fp0.TableR);
            % Prepare internal variables
            mf=obj.tMF(1:N,:);
            mr=full(scaleCol(fp1.pfOperators.mKR-fp0.pfOperators.mKR,fp0.ProductExergy));
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
            cpt = c0 .* (obj.DWt>0)' + c1 .* (obj.DWt<0)';
            res = cpt .* obj.DWt';
        end
	end
end