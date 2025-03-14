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
%     NrOfProcesses   - Number of processes
%     NrOfWastes      - Number of Wastes
%     FuelImpact      - Fuel Impact
%     TechnicalSaving - Total Malfunction Cost
% 
%   cDiagnosis Methods
%     buildResultInfo             - Build the cResultInfo associated to thermoeconomic diagnosis
%     getDiagnosisTable           - Get the summary diagnosis results
%     getUnitConsumptionVariation - Get the unit consumption variation of processes
%     getUnitCostVariation        - Get the variation of the unit cost of processes
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
%     getDemmandCorrectionCost    - Get the correction of real demand variation cost
%
%   See also cExergyCost
%
	properties(GetAccess=public, SetAccess=private)
        NrOfProcesses        % Number of processes
        NrOfWastes           % Number of Wastes
        FuelImpact           % Fuel Impact
        TechnicalSaving      % Total Malfunction Cost
        Method               % Diagnosis Method
    end
    properties(Access=private)
        dpuk    % Direct Unit exergy cost (operation)
        dpuk0   % Direct Unit exergy cost (reference) 
        DKP     % Unit Consuption Variation Matrix       
        DW0     % System output variation
        DWt     % Final demand variation
        DWr     % Waste variation
	    tMF     % Malfunction Matrix
        vMF     % Process Malfunction
        vDI     % Irreversibility Variation
        vMCR    % Waste Malfuction Cost
        DFin    % Internal disfunction matrix
        DFex    % External disfunction matrix
        DF0     % Output variation disfunction
        tDI     % Disfunction table
        tMC     % Malfunction Cost table
        DFT     % Fuel Impact
        DCW     % Cost of Output Variation
    end
	
	methods
		function obj=cDiagnosis(fp0,fp1,method)
        %cDiagnosis - Create an object of the class
        %   Syntax:
        %     obj=cDiagnosis(fp0,fp1,method);
        %   Input Arguments:
        %     fp0 - cExergyCost object for reference state
        %     fp1 - cExergyCost object for operation state
        %     method - Diagnosis Method used. 
        %       cType.DiagnosisMethod.WASTE_EXTERNAL
        %       cType.DiagnosisMethod.WASTE_INTERNAL
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
            % Calculate the malfunction cost and disfunction tables according to the chosen method
            N=obj.NrOfProcesses;
            if obj.NrOfWastes>0 % Waste depending parameter
                tMR=full(scaleCol(fp1.pfOperators.mKR-fp0.pfOperators.mKR,fp0.ProductExergy));
                mfr=obj.tMF(1:N,:)+tMR;
                opR=fp1.pfOperators.opR;
                opIR=opI + opI*opR;
                mdwr=tMR + opR*mfr;
                tMCR=scaleRow(mdwr,obj.dpuk.cPE);
            else
                tMCR=zeros(N,N);
            end
            switch method
                case cType.DiagnosisMethod.WASTE_EXTERNAL
                    % WASTE_EXTERNAL method
                    obj.DF0=opI*obj.DW0;
                    obj.vMCR=sum(tMCR,2)';
                    obj.DFex=zeros(N,N);
                    obj.tDI=obj.DFin + diag(obj.DWr);
                    obj.tMC=obj.DFin + diag(obj.vMCR);
                case cType.DiagnosisMethod.WASTE_INTERNAL 
                    % WASTE_EXTERNAL method  
                    obj.DF0=(opIR+opR)*obj.DWt;
                    obj.vMCR=sum(tMCR);
                    obj.DFex=mdwr + opI*mdwr;
                    obj.tDI=obj.DFin + obj.DFex;
                    obj.tMC=obj.DFin + tMCR;
            end 
            % cResultId properties
            obj.Method=method;
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

        function res=get.TechnicalSaving(obj)
        % Total Malfunction Cost (Internal and External)
            res=0;
            if obj.status
                cpt = obj.dpuk0.cP .* (obj.DWt>0)' + obj.dpuk.cP .* (obj.DWt<0)';
                res = obj.DFT - cpt * obj.DWt;
            end
        end

        function res=buildResultInfo(obj,fmt)
        %buildResultInfo - Get cResultInfo object for thermoeconomic diagnosis
        %   Syntax:
        %     res=obj.buildResultInfo(fmt)
        %   Input Arguments:
        %     fmt - cFormatData object
        %   Ouput Arguments:
        %     res - cResultInfo (cType.ResultInfo.THERMOECONOMIC_DIAGNOSIS)
            res=fmt.getDiagnosisResults(obj);
        end

        function [res]=getDiagnosisTable(obj)
        %getDiagnosisTable - Get Diagnosis Table
        %   Syntax:
        %     res=obj.getDiagnosisTable
        %   Output Argument
        %     res - struct containing the column values of the diagnosis table
        %     tbl - cell array with the diagnosis table values
            res.MF=zerotol(obj.getMalfunction);
            res.DI=zerotol(obj.getIrreversibilityVariation);
            res.DR=zerotol(obj.getWasteVariation);
            res.DPs=zerotol(obj.getDemandVariation);
            res.MFC=zerotol(obj.getMalfunctionCost);
            res.MRC=zerotol(obj.getWasteMalfunctionCost);
            res.DCPs=zerotol(obj.getDemandVariationCost);
        end

        function res=getUnitConsumptionVariation(obj)
        %getUnitConsumptionVariation - Get the unit consumption variation
        %   Syntax:
        %     res=obj.getUnitConsumptionVariation
        %   Output Argument
        %     res - array with the unit consuption variation of each process
            res=sum(obj.DKP,1);
        end

        function res=getUnitCostVariation(obj)
        %getUnitCostVariation - Get the unit process cost variation
        %   Syntax:
        %     res=obj.getUnitCostVariation
        %   Output Argument
        %     res - array with the unit process cost variation of each process        
        res=obj.dpuk.cP-obj.dpuk0.cP;
        end

        function res=getIrreversibilityVariation(obj)
        %getIrreversibilityVariation - Get the unit process cost variation
        %   Syntax:
        %     res=obj.getIrreversibilityVariation
        %   Output Argument
        %     res - array with irreversibility variation of each process     
            res=[obj.vDI,sum(obj.vDI)];
        end

        function res=getOutputVariation(obj)
        %getOutputVariation - Get the system output variation
        %   Syntax:
        %     res=obj.getOutputVariation
        %   Output Argument
        %     res - Array containing the values of the system output variation  
        % 
            res=[obj.DW0', sum(obj.DW0)];
        end

        function res=getDemandVariation(obj)
        %getDemandVariation - Get the system demand variation
        %   Syntax:
        %     res=obj.getDemandVariation
        %   Output Argument
        %     res - Array containing the values of the system demand variation  
        % 
            res=[obj.DWt', sum(obj.DWt)];
        end

        function res=getWasteVariation(obj)
        %getWasteVariation - Get waste variation
            res=[obj.DWr',sum(obj.DWr)];
        end

        function res=getDemandVariationCost(obj)
        %getDemandVariationCost - Get the system demand variation cost
        %   Syntax:
        %     res=obj.getDemandVariationCost
        %   Output Argument
        %     res - Array containing the values of the system demand variation cost
        % 
            res=[obj.DCW,sum(obj.DCW)];
        end 

        function res=getMalfunction(obj)
        %getMalfunction - Get the malfunction vector
        %   Syntax:
        %     res=obj.getMalfunction
        %   Output Argument
        %     res - Array containing the values of the processes malfunctions
        %         
            aux=obj.vMF;
            res=[aux,sum(aux)];
        end

        function res=getIrreversibilityTable(obj)
        %getIrreversibilityTable - Build the irreversibility table
        %   Syntax:
        %     res=obj.getIrreversibilityTable
        %   Output Argument
        %     res - matrix containing the values of the irreversibility table  
        %
            res=[obj.tDI',obj.DWt;obj.DF0',0;obj.vMF,0];
        end


		function res=getMalfunctionTable(obj)
        %getMalfunctionTable - Get the Malfunction table
        %   Syntax:
        %     res=obj.getMalfunctionTable
        %   Output Argument
        %     res - Matrix containing the values of the Malfunction Table
        % 
            res=[obj.tMF,[obj.DW0;0]];
        end
        
        function res=getMalfunctionCost(obj)
        %getMalfunctionCost - Get the malfunction cost vector (MF*)
        %   Syntax:
        %     res=obj.getMalfunctionCoat
        %   Output Argument
        %     res - Array containing the values of the processes cost malfunctions
        %       
            aux=zerotol(sum(obj.DFin))+obj.vMF;
			res=[aux,sum(aux)];
        end
        
        function res=getWasteMalfunctionCost(obj)
        %getWasteMalfunctionCost - Get the waste cost variation (MR*)
        %   Syntax:
        %     res=obj.getWasteMalfunctionCoat
        %   Output Argument
        %     res - Array containing the values of the waste variation cost
        %     
	        res=[obj.vMCR,sum(obj.vMCR)];
        end

        function res=getMalfunctionCostTable(obj)
        %getMalfunctionCostTable - Get the malfunction cost table
        %   Syntax:
        %     res=obj.getMalfunctionCostTable
        %   Output Argument
        %     res - Matrix containing the values of the Malfunction Cost Table
        % 
            res=[obj.tMC,obj.DCW';obj.vMF,0];
        end

        function res=getInternalDisfunction(obj)
        %getInternalDisfunction - Get the internal disfunction matrix
        %   Syntax:
        %     res=obj.getInternalDisfunction
        %   Output Argument
        %     res - Matrix containing the values of the internal disfunction values
        %
            res=obj.DFin';
        end

        function res=getExternalDisfunction(obj)
        %getExternalDisfunction - Get the external disfunction matrix
        %   Syntax:
        %     res=obj.getInternalDisfunction
        %   Output Argument
        %     res - Matrix containing the values of the internal disfunction values
        %
            res=obj.DFex';
        end

        function res=getDemandCorrectionCost(obj)
        %getDemandCorrection - Get Demand Variation effective cost.
        %   Syntax:
        %     res=obj.getDemandVariationEffectiveCost
        %   Output Argument
        %     res - Array containing the values of demand variation effective cost
        %
            dcpt = (obj.dpuk.cP-obj.dpuk0.cP) .* (obj.DWt>0)';
            val = dcpt .* obj.DWt';
            res=[val,sum(val)];
        end
    end
end