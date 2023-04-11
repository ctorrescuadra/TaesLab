classdef cDiagnosis < cResultId
% cDiagnosis make Thermoeconomic Diagnosis Analysis
%   It compares two states of the plant given by two cModelFPR objects
%   cDiagnosis methods and properties
%   Methods:
%	    obj=cDiagnosis(fpr0,fpr1)
%       res=obj.MalfunctionCostTable
%       res=obj.DemandVariationCost
%       res=obj.WasteVariationCost
%
	properties(GetAccess=public, SetAccess=private)
        NrOfProcesses               % Number of Processes
        NrOfWastes                  % Number of Wastes
        IrreversibilityTable        % Irreversibility Table
        MalfunctionTable            % Malfunction table
        FuelImpact                  % Fuel Impact
        IrreversibilityVariation    % Irreversibility Variation
        Malfunction                 % Processes Malfunction
        MalfunctionCost             % Processes Malfunction cost
        OutputVariation             % Output Variation
        UnitConsumptionVariation    % Unit Consumptions Variation
    end

    properties(Access=protected)
		tMF  % Malfunction table
        vMF  % Malfunction vector
		tDF  % Disfunction table
        dW0  % System output variation
        dCW0 % System output cost Variation
        dFT  % Resources variation
        dpuk % Unit cost of products
        vP0  % Production Reference State
		vDI  % Irreversibility Variation
		vMFC % Malfunction Cost
        dKP  % Unit Cost Variation Matrix
	end
	
	methods
		function obj=cDiagnosis(fp0,fp1)
        % Diagnosis Constructor
        %  fp0: cModelFPR object for reference state
        %  fp1: cModelFPR object for operation state
            obj=obj@cResultId(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
            if ~isa(fp0,'cModelFPR') && ~isa(fp1,'cModelFPR')
                obj.messageLog(cType.ERROR,'Input parameters are not cModelFPR objects');
                return
            end
            if (fp0.ps~=fp1.ps)
                obj.messageLog(cType.ERROR,'Compare not equal productive structures');
                return
            end
            if ~all(fp0.ActiveProcesses==fp1.ActiveProcesses)
                obj.messageLog(cType.ERROR,'Compare two diferent plant configurations not possible');
                return
            end
            % Check if the states are equal
            obj.dKP=zerotol(fp1.pfOperators.mKP-fp0.pfOperators.mKP);
            if all(obj.dKP==0)
                obj.messageLog(cType.ERROR,'Reference and Operation states are the same');
                return
            end
            % Prepare the model
		    obj.NrOfProcesses=fp0.NrOfProcesses;
		    obj.NrOfWastes=fp0.NrOfWastes;
            N=obj.NrOfProcesses;
            opI=fp1.pfOperators.opI;
            obj.vP0=fp0.ProcessesExergy.vP(1:N);
            obj.dpuk=fp1.getDirectProcessUnitCost;
            obj.dW0=fp1.SystemOutput - fp0.SystemOutput;
            obj.dCW0=obj.dpuk.cPE' .* obj.dW0;
            obj.dFT=sum(fp1.Resources-fp0.Resources);
            obj.tMF=[scaleCol(obj.dKP,obj.vP0),[obj.dW0;0]];
            obj.vMF=zerotol(sum(obj.tMF(:,1:end-1)));
            obj.tDF=zerotol(opI*obj.tMF(1:end-1,:));
			obj.vDI=zerotol(sum(obj.tDF,2)')+obj.vMF;
			obj.vMFC=zerotol(sum(obj.tDF(:,1:end-1)))+obj.vMF;
            obj.status=cType.VALID;
		end
        
        function res=get.IrreversibilityTable(obj)
        % Build the irreversibility table
            res=[[obj.tDF',[obj.dW0;0]];[obj.vMF,0]];
        end
        
		function res=get.MalfunctionTable(obj)
        % get Malfunction table
            res=obj.tMF;
        end
		
		function res=get.FuelImpact(obj)
        % get Fuel Impact value
            res=obj.dFT;
        end
        
        function res=get.IrreversibilityVariation(obj)
        % Get the irreversibility vatiation vector
            res=[obj.vDI,sum(obj.vDI)];
        end
        
        function res=get.Malfunction(obj)
        % Get the malfunction vector
            res=[obj.vMF,sum(obj.vMF)];
        end
        
        function res=get.MalfunctionCost(obj)
        % Get the malfunction cost vector 
			res=[obj.vMFC,sum(obj.vMFC)];
        end
        
        function res=get.OutputVariation(obj)
        % Get the system output variation
            res=[obj.dW0', sum(obj.dW0)];
        end

        function res=get.UnitConsumptionVariation(obj)
        % Get the unit consumption variation
            res=sum(obj.dKP,1);
        end
        
        function res=MalfunctionCostTable(obj)
        % Build the malfunction cost table
            res=[[obj.tDF(:,1:end-1),obj.dCW0];[obj.vMF,0]];
        end
        
        function res=DemandVariationCost(obj)
        % get the output cost variation
            res=obj.dCW0';
            res=[res,sum(res)];
        end 

        function res=WasteVariationCost(obj)
        % Default method for Waste Variation Cost
	        res=zeros(1,obj.NrOfProcesses+1);
        end
	end
end