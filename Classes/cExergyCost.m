classdef (Sealed) cExergyCost < cExergyModel
%cExergyCost - Calculate the exergy cost of flows and processes.
%   The class that provides the thermoeconomic analysis results of a state of the plant.
% 
%   cExergyCost properties:
%     SystemOutput           - System Output of processes
%     FinalDemand            - Final Demand of processes
%     Resources              - External resources of processes
%     RecirculationFactor    - Recirculation factor of each process
%     fpOperators            - Structure containing FP Operators (mFP, mRP, opCP,opCR)
%     pfOperators            - Structure containing PF Operators (mPF,mKP,mKR,opP,opI,opR)
%     flowOperators          - Flow operators structure (mG, opB, opI, opR)
%     isWaste                - Indicate if system have wastes
%     WasteTable             - cWasteData object
%     TableR                 - Waste Allocation Table
%     RecycleRatio           - Recycle ratio of each waste
%     WasteWeight            - Weight of each waste
%
%   cExergyCost methods:
%     cExergyCost                  - Create an instance of the class
%     buildResultInfo              - Build the cResultInfo object for THERMOECONOMIC_ANALYSIS
%     getSpectralRatio             - Get the spectral ratio of the productive matrix
%     getProcessCost               - Get cost of Processes
%     getProcessUnitCost           - Get unit cost of Processes
%     getFlowsCost                 - Get cost of flows
%     getStreamsCost               - Get cost of productive groups
%     getCostTableFP               - Get cost table FP
%     getDirectCostTableFPR        - Get the direct cost FPR table
%     getGeneralCostTableFPR       - Get the generalized cost FPR table
%     getIrreversibilityCostTables - Get Irreversibility Cost Tables for processes and flows
%     updateWasteOperators         - Update Waste Operator
%  
%   See also cResultId, cExergyModel, cResultInfo, cWasteData, cResourceData
%
	properties(GetAccess=public,SetAccess=private)
        SystemOutput           % System Output of processes
        FinalDemand            % Final Demand of processes
        Resources              % External resources of processes
        SystemUnitCost         % System Unit Consumption
        RecirculationFactor    % Recirculation factor of each process
        WasteWeight            % Weight of each waste
        fpOperators            % Structure containing FP Operators (mFP, mRP, opCP,opCR)
        pfOperators            % Structure containing PF Operators (mPF,mKP,mKR,opP,opI,opR)
        flowOperators          % Flow operators structure (mG, opB, opI, opR)
        isWaste=false          % Indicate if system have wastes
        WasteTable             % cWasteData object
        TableR                 % Waste Allocation Table
        RecycleRatio           % Recycle ratio of each waste
    end
    
    properties(Access=private)
       mpL
    end
    
	methods
		function obj=cExergyCost(exd,wd)
		%cExergyCost - Creates an instance of the class
        %   Syntax:
        %     obj=cExergyCost(exd,wd)
        %   Input Arguments:
		%     exd - cExergyData object
        %     wd - cWasteData object (optional)
        %   Output Arguments:
        %     obj - cExergyCost object
        %
			obj=obj@cExergyModel(exd);
            % Check if the object is valid
            if ~obj.status
                return
            end
            % Set the ResultId property and initialize variables
            obj.ResultId=cType.ResultId.THERMOECONOMIC_ANALYSIS;
			N=obj.NrOfProcesses;
            M=obj.NrOfFlows;
            vK=obj.UnitConsumption;
            vk1=zerotol(vK-1);
            % Get Flow Operators;
			fpm=obj.FlowProcessModel;
            mG=fpm.mF(:,1:N)*fpm.mP(1:N,:)+fpm.mV;
            opB=eye(M)/(eye(M)-mG);
            obj.mpL=fpm.mP(1:N,:)*fpm.mL;
            obj.flowOperators=struct('mG',mG,'opB',zerotol(opB));
            % Get Process Operators
            tfp=obj.TableFP;        
            mPF=divideCol(tfp(:,1:N),obj.FuelExergy);
            mKP=scaleCol(mPF,vK);
            opP=eye(N)/(eye(N)-mKP(1:N,:));
            opI=scaleRow(opP,vk1);
            obj.pfOperators=struct('mPF',mPF,'mKP',mKP,'opP',opP,'opI',opI);
            mFP=divideRow(tfp(1:N,:),obj.ProductExergy);
            opCP=similarResourceOperator(opP,obj.ProductExergy);
            obj.fpOperators=struct('mFP',mFP,'opCP',opCP);
            obj.DefaultGraph=cType.Tables.PROCESS_ICT;
            % Initialize waste operators
            if (nargin==2) && (obj.NrOfWastes>0)
				obj.isWaste=true;
                setWasteTable(obj,wd)
                wlog=obj.updateWasteOperators;
                if ~wlog.status
                    obj.addLogger(wlog);
                    obj.messaggeLogger(cType.ERROR,cMessages.InvalidWasteOperator,obj.State);
                end
            end
		end

        function res=get.SystemOutput(obj)
        % Get the system output exergy values vector
            res=cType.EMPTY;
            if obj.status
                res=obj.TableFP(1:end-1,end);
            end
        end
        
        function res=get.FinalDemand(obj)
        % Get final demand vector of the system 
            res=obj.SystemOutput;
            if obj.status && obj.isWaste
                idx=obj.ps.Waste.processes;
                res(idx)=scaleRow(obj.TableFP(idx,end),obj.RecycleRatio);
            end
        end    
                
        function res=get.Resources(obj)
        % Get the exergy resources vector
            res=cType.EMPTY;
            if obj.status
                res=obj.TableFP(end,1:end-1);
            end
        end

        function res=get.SystemUnitCost(obj)
        %SystemUnitConsumption - Get the total unit consumption of the system 
        %   It take into account waste recycling as final product
        %
        %   Syntax:
        %     res=obj.SystemUnitConsumption
        %   Output Arguments:
        %     res - Total unit consumption value
        %  
            res=cType.EMPTY;
            if obj.status
                res=sum(obj.Resources)/sum(obj.FinalDemand);
            end
        end
                    
        function res=get.RecirculationFactor(obj)
        % Get the recirculation factor of the processes
            res=cType.EMPTY;
            if obj.status
                res=zerotol(diag(obj.fpOperators.opCP)'-1);
            end
        end
    
        function res=get.WasteWeight(obj)
        % Get the waste weight.
            res=cType.EMPTY;
            if obj.isWaste
                opR=obj.fpOperators.opR;
                res=diag(opR.mValues(:,opR.mRows))';
            end
        end
    
        function res=buildResultInfo(obj,fmt,options)
        %buildResultInfo - Get the cResultInfo object for thermoeconomic analysis
        %   Syntax:
        %     res=obj.buildResultInfo(fmt,options)
        %   Input Arguments:
        %     fmt - cResultTableBuilder object
        %     options - structure indicating the table to obtain
        %       DirectCost: get direct cost tables (true | false)
        %       GeneralCost: get generalized cost tables (true | false)
        %
            if nargin==2
                options.DirectCost=true;
                options.GeneralCost=false;
            end
            res=fmt.getCostResults(obj,options);
        end

        function res=getSpectralRatio(obj)
        %getSpectralRatio - Get the spectral ratio of the productive matrix
        %   Syntax:
        %     res=obj.getSpectralRatio
        %   Output Arguments:
        %     res - Spectral Ratio value
        %
            N=obj.NrOfProcesses;
            res=abs(eigs(obj.mFP(:,1:N),1));
        end
   
        function res=getProcessCost(obj,rsc)
		%getProcessCost - Get processes cost values
        %   If resource cost is provided calculate the generalized cost
        %
        %   Syntax:
        %     obj.getProcessCost(rsc)
		%   Input Arguments:
		%     rsc - cResourceData object [optional]
		%   Output Arguments:
		%     res - structure containing cost values (CPE,CPZ,CPR,CP,CF,CR,Z)
        %
            res=struct();
            % Initialize variables
            czoption=(nargin==2);
			N=obj.NrOfProcesses;
			zero=zeros(1,N);
            aux=obj.fpOperators;
			if czoption %Compute generalized cost
                Ce=rsc.Ce;
                res.Z=rsc.Z;
				res.CPE=Ce * aux.opCP;
				res.CPZ=res.Z * aux.opCP;
			else % Compute direct cost
                res.Z=zero;
				Ce=obj.TableFP(end,1:N);
				res.CPE=Ce * aux.opCP;
				res.CPZ=zero;
			end
            % Compute waste costs
			if obj.isWaste
				res.CPR=(res.CPE+res.CPZ) * aux.opR;
				res.CP=res.CPE + res.CPZ + res.CPR;
				res.CR=res.CP * aux.mRP;
			else
				res.CPR=zero;
				res.CP=res.CPE+res.CPZ;
				res.CR=zero;
			end
            % Compute fuel cost
			res.CF= Ce+res.CP*obj.fpOperators.mFP(:,1:end-1);
		end

        function res = getProcessUnitCost(obj,rsc)
    	%getProcessUnitCost - Get Process Unit Cost
        %   If resource cost is provided calculate the generalized cost
        %
        %   Syntax:
        %     obj.getProcessUnitCost(rsc)
		%   Input Arguments:
		%     rsc - cResourceData object [optional]
		%   Output:
		%     res - structure containing cost values (cP,cPE,cPZ,cPR,cF,cR)
        %
            res=struct();
            % Initialize variables
            czoption=(nargin==2);
            N=obj.NrOfProcesses;
            zero=zeros(1,N);
            res.k=obj.UnitConsumption;
            if czoption %Compute generalized cost
                ce= rsc.ce;
                ke=ce .* res.k;
                res.cPE= ke * obj.pfOperators.opP;
                res.cPZ= rsc.zP * obj.pfOperators.opP;
            else % Compute direct cost
                ce=obj.pfOperators.mPF(end,:);
                ke=ce .* res.k;
                res.cPE= ke * obj.pfOperators.opP;
                res.cPZ= zero;
            end
            % Compute waste costs
            if obj.isWaste
                res.cPR=(res.cPE+res.cPZ)*obj.pfOperators.opR;
                res.cP=res.cPE+res.cPZ+res.cPR;
                res.cR=res.cP*obj.pfOperators.mKR;
            else
                res.cPR=zero;
                res.cP=res.cPE+res.cPZ;
                res.cR=zero;
            end
            % Compute fuel cost
            res.cF=ce+res.cP*obj.pfOperators.mPF(1:end-1,1:end);
        end  

        function res=getFlowsCost(obj,rsc)
        %getFlowCost - Get the exergy cost of flows
        %   If resource cost is provided calculate the generalized cost
        %
        %   Syntax:
        %     res=obj.getFlowsCost(rsc)
        %   Input Arguments:
		%     rsc - cResourceData object [optional]
        %   Output
        %   res - cost of flows structure (B,CE,CZ,CR,C,cE,cZ,cR,c)
        %
            res=struct();
            % Initialize variables
            czoption=(nargin==2);
            zero=zeros(1,obj.NrOfFlows);	   
            aux=obj.flowOperators;
            res.B=obj.FlowsExergy;
            fpm=obj.FlowProcessModel;
            [~,frsc,val]=find(fpm.mP(end,:));
            if czoption % Compute generalized cost
                zB = rsc.zP * fpm.mP(1:end-1,:);
                res.cE = rsc.c0(frsc) * aux.opB(frsc,:);
                res.CE = res.cE .* res.B;
                res.cZ = zB * aux.opB;  
                res.CZ = res.cZ .* res.B;
            else % Compute direct cost
                res.cE = val * aux.opB(frsc,:);
                res.CE = res.cE .* res.B;
                res.cZ = zero;
                res.CZ = zero;
            end
            % Compute waste costs
            if obj.isWaste
                res.cR = (res.cE + res.cZ) * aux.opR;
                res.CR = res.cR .* res.B;
                res.c = res.cE + res.cZ + res.cR;
                res.C = res.CE + res.CZ+res.CR;
            else
                res.cR = zero;
                res.CR = zero;
                res.c = res.cE+res.cZ;
                res.C = res.CE+res.CZ;
            end
        end
        
        function res=getStreamsCost(obj,fcost)
        %getStreamsCost - Get the exergy cost of streams
        %   Compute the direct or generalized cost depending on the values of flows cost
        %
        %   Syntax:
        %     res=obj.getStreamsCost(fcost) 
        %   Input Arguments:
		%     fcost - Exergy cost of flows structure
        %   Output
        %     res - cost of flows structure (E,CE,CZ,CR,C,cE,cZ,cR,c)
        %
            res=struct();
            % Check input parameters and initialize variables
            if (nargin~=2) || ~isstruct(fcost) || ~isfield(fcost,'CE')
                obj.messageLog(cType.ERROR,cMessages.InvalidArgument,'fcost');
                return
            end
            zero=zeros(1,obj.NrOfStreams);
            res.E=obj.StreamsExergy.E;
            % Compute costs
            res.CE=obj.ps.flows2Streams(fcost.CE);
            res.cE=vDivide(res.CE,res.E);
            % Compute waste costs
            if obj.isWaste
                res.CR=obj.ps.flows2Streams(fcost.CR);
                res.cR=vDivide(res.CR,res.E);
            else
                res.CR=zero;
                res.cR=zero;
            end
            % Compute generalized costs
            if isfield(fcost,'CZ')
                res.CZ=obj.ps.flows2Streams(fcost.CZ);
                res.cZ=vDivide(res.CZ,res.E);
                res.C=res.CE+res.CR+res.CZ;
                res.c=res.cE+res.cR+res.cZ;
            else
                res.C=res.CE+res.CR;
                res.c=res.cE+res.cR;
            end
        end

        function res = getCostTableFP(obj,ucost)
        %getCostTableFP - Get the FP Cost Table considering only internal irreversibilities
        %   Syntax:
        %     res=getCostTableFP(ucost)
        %   Input Arguments:
        %     ucost - Unit cost of product. If omitted is calculated
        %   Output:
        %     res - matrix containing the Direct Cost FP table values
        %
            if nargin==1
                ucost=obj.getProcessUnitCost;
            end
            aux=[ucost.cPE,1];
            res=scaleRow(obj.TableFP,aux);
        end

        function res = getDirectCostTableFPR(obj,ucost)
        %getDirectCostTableFPR - Get FPR CostTable with direct costs
        %   Syntax:
        %     res = obj.getDirectCostTableFPR(ucost)
        %   Input Arguments:
        %     ucost - Unitary costs of processes. If ommited is calculated
        %   Output: 
        %     res - matrix containing the Direct Cost FPR table values
        %
            if nargin==1
                ucost=obj.getProcessUnitCost;
            end	
            N=obj.NrOfProcesses;
            aux=obj.TableFP(end,:);
            tmp=obj.TableFP(1:N,:);
            if obj.isWaste
                tR=obj.TableR;
                recycle=scaleRow(obj.TableFP(tR.mRows,end),obj.RecycleRatio);
                tmp(tR.mRows,:)=[tR.mValues,recycle];
            end
            res=[scaleRow(tmp,ucost.cP);aux];
        end 
    
        function res = getGeneralCostTableFPR(obj,rsc,ucost)
        %getGeneralCostTableFPR - Get FPR CostTable with generalized costs
        %   Syntax:
        %     res = obj.getGeneralizedCostTableFPR(rsc,ucost)
        %   Input Arguments:
        %     rsc - cResourceData object
        %     ucost - Unitary costs of processes. If ommited is calculated
        %   Output: 
        %     res - matrix containing the Generalized Cost FPR table values
        %
            if nargin<2
                ucost=obj.getProcessUnitCost(rsc);
            end	
            N=obj.NrOfProcesses;
            % Compute resource costs
            Ce= rsc.ce .* obj.ProcessesExergy.vF(1:N);
            aux=[Ce+rsc.Z,0];
            tmp=obj.TableFP(1:N,:);
            % Compute waste costs
            if obj.isWaste
                tR=obj.TableR;
                recycle=scaleRow(obj.TableFP(tR.mRows,end),obj.RecycleRatio);
                tmp(tR.mRows,:)=[tR.mValues,recycle];
            end
            % Get cost table FPR
            res=[scaleRow(tmp,ucost.cP);aux];
        end 

        function [pict,fict]=getIrreversibilityCostTables(obj,rsc)
        %getIrreversibilityCostTable - Get Irreversibility Cost Tables for processes and flows
        %   If resource cost is provided calculate the generalized tables
        %
        %   Syntax:
        %     [pict,fict]=obj.getIrreversibilityCostTables(rsc)
        %   Input Arguments:
        %     rsc - cResourcesCost object [optional]
        %   Output Arguments:
        %     pict - matrix containing the values of the Process ICT table
        %     fict - matrix containing the values of the Flows ICT table
        %
            narginchk(1,2);
            N=obj.NrOfProcesses;
            M=obj.NrOfFlows;
            fpm=obj.FlowProcessModel;
            pf=obj.pfOperators;
            % Compute Process ICT
            if nargin==2
                cn=obj.getMinCost(rsc);
                ict=zerotol(scaleRow(pf.opI,cn));
            else
                cn=ones(1,N);
                ict=zerotol(pf.opI);
            end
            % Add waste cost
            if obj.isWaste
                cin=cn+sum(ict);
                mopCR=scaleRow(pf.opR,cin);
                ict=ict+mopCR;
            end
            pict=[ict;cn];
            if nargout==1
                return
            end
            % Compute Flows ICT 
            if nargin==2
                cm=rsc.c0*fpm.mL+cn*obj.mpL;  
            else
                cm=ones(1,M);
            end
            fict=[ict*obj.mpL;cm];    	
        end

        function [frsc,prsc,idx]=getResourcesCostDistribution(obj,rsd)
        %getResourcesCostDistribution - Get the resource Cost distribution tables
        %   This table decompose the exergy cost due to each resource flows defined
        %   in the cResourceData object.
        %   If resource data is not provided, the exergy of the resource flows is used,
        %   obtaining the exergy cost distribution table. If resource data is provided,
        %   the generalized cost distribution table is obtained.
        %
        %   Syntax:
        %     [res,idx]=obj.getResourcesCostDistribution(rsd)
        %   Input Arguments:
        %     rsd - cResourceData object (optional)
        %   Output Arguments:
        %     res - matrix containing the resource cost distribution values
        %     idx - index of resource flows in the flows list
        %
            narginchk(1,2);
            idx=obj.ps.ResourceFlows;
            opB=obj.flowOperators.opB;
            fpm=obj.FlowProcessModel;
            opP=obj.pfOperators.opP;
            % Direct or Generalized cost
            if nargin==2
                c0=rsd.c0(idx);
            else
                c0=ones(1,length(idx));
            end
            % Calculate flow resource cost distribution table
            frsc=transpose(scaleRow(opB(idx,:),c0));
            % Calculate process resource cost distribution table
            tmp = fpm.mL(idx,:) * fpm.mF(:,1:end-1);
            ce=scaleRow(tmp,c0);
            prsc=transpose(ce*opP);
        end

        function log=updateWasteOperators(obj)
        %updateWasteOperators - Calculate the waste allocation ratios and cost operators.
        %   The waste allocation ratios are calculated according to the waste definition
        %   type. The waste cost operators are also calculated.
        %   The waste allocation ratios are stored in the WasteTable property.
        %   The waste cost operators are stored in the properties TableR, pfOperators, fpOperators and flowOperators.
        %   The recycle ratio is stored in the RecycleRatio property.
        %   The method returns a cMessageLogger object with error messages if any.
        %
        %   Syntax:
        %     obj.updateWasteOperators
        %   Output Arguments:
        %     log - cMessageLogger with error messages
        %
            log=cMessageLogger();
            if ~obj.isWaste
                log.messageLog(cType.ERROR,cMessages.NoWasteModel);
                return
            end
            % Initialize variables
            wt=obj.WasteTable;
            NR=wt.NrOfWastes;
            N=obj.NrOfProcesses;
            M=obj.NrOfFlows;
            aR=wt.Processes;
            aP=setdiff(1:N,aR);
            tmp=zeros(1,N);
            sol=zeros(NR,N);
            % Variables for thermoeconomic model
            tFP=obj.TableFP;
            mKP=obj.pfOperators.mKP;
            opP=obj.pfOperators.opP;
            opI=obj.pfOperators.opI;
            opCP=obj.fpOperators.opCP;
            vP=obj.ProductExergy;
            % Compute direct exergy cost for type 2 allocation
            if (any(wt.TypeId==cType.WasteAllocation.COST))
                cp=obj.computeCostR(aR);
            end
            % Compute Waste table depending on waste definition type
            for i=1:NR
                j=aR(i);
                if ~obj.ActiveProcesses(j)
                    log.messageLog(cType.WARNING,cMessages.ProcessNotActive,obj.ps.ProcessKeys{j});
                    continue
                end 
                key=wt.Names{i};      
                switch wt.TypeId(i)
                    case cType.WasteAllocation.MANUAL
                        tmp=wt.getValues(key);
                        tmp(~obj.ActiveProcesses)=0.0;
                    case cType.WasteAllocation.RESOURCES  
                        tmp(aP)=mKP(end,aP).*opP(aP,j)';
                    case cType.WasteAllocation.COST
                        tmp(aP)=cp(aP).*tFP(aP,j)';
                    case cType.WasteAllocation.EXERGY
                        tmp(aP)=tFP(aP,j)';            
                    case cType.WasteAllocation.IRREVERSIBILITY
                        tmp(aP)=opI(aP,j);
                        case cType.WasteAllocation.HYBRID
                        tmp(aP)=tFP(aP,j)';
                        tmp=tmp/sum(tmp);  
                        tmp(aP)=tmp(aP)+opI(aP,j)';
                    otherwise
                        log.messageLog(cType.ERROR,cMessages.InvalidWasteType,wt.Type{i},key);
                        return
                end
                if isempty(find(tmp,1))				
                    log.messageLog(cType.ERROR,cMessages.NoWasteAllocationValues,key);
                    return
                end
                sol(i,:)=tmp/sum(tmp);
            end
            % Check if waste operator is valid
            sol=scaleRow(sol,1-wt.RecycleRatio);
            mS=sol*opCP(:,aR);
            if ~isNonSingularMatrix(mS)
                log.messageLog(cType.ERROR,cMessages.InvalidWasteOperator,obj.State);
                return
            end
            % Update object values
            wt.updateValues(sol);
            mRP=cSparseRow(aR,sol);
            obj.TableR=scaleRow(mRP,vP);
            obj.fpOperators.mRP=mRP;
            mKR=divideCol(obj.TableR,vP);
            opR=cExergyCost.getOpR(mKR,opP);
            wflows=obj.ps.Waste.flows;
            obj.pfOperators.mKR=mKR;
            obj.pfOperators.opR=opR;
            obj.fpOperators.opR=cExergyCost.getOpR(mRP,opCP);
            obj.flowOperators.opR=cSparseRow(wflows,opR.mValues*obj.mpL,M);
            obj.RecycleRatio=wt.RecycleRatio;
            obj.WasteTable=wt;
        end 
    end
    methods(Static)
        function res=updateOperator(op,opR)
        %updateOperator - Update an operator with the corresponding waste operator
        %   Syntax:
        %     res = cExergyCost.updateOperator(op,opR)
        %   Input:
        %     op - Operator
        %     opR - Waste Operator
        % 
            res=op+op*opR;
        end

        function res=getOpR(mR,opL)
        %getOpR - Get the corresponding waste operator
        %   Syntax:
        %     res = cExergyCost.getOpR(mR,opL)
        %   Input:
        %     mR - Waste allocation matrix
        %     opL - Cost Operator
        %
            tmp=mR.mValues*opL;
            opR=(eye(mR.NR)-tmp(:,mR.mRows))\tmp;
            res=cSparseRow(mR.mRows,opR);
        end
	end

    methods(Access=private)
        function setWasteTable(obj,wd)
        %setWasteTable -Set the Waste Table for the cExergyCost 
        %   Input:
        %     wd - cWasteData object
            if ~obj.isWaste
                obj.messageLog(cType.ERROR,cMessages.NoWasteModel);
                return
            end
            if ~isObject(wd,'cWasteData')
                obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(wd));
                return
            end
            obj.WasteTable=wd;
        end

        function res=getMinCost(obj,rsc)
        %getMinCost - Calculate the minimun cost of the flows
        %   Input:
        %     rsc - cost of external resources
        %   Output:
        %     res - Minimun cost of the flows
            N=obj.NrOfProcesses;
            res=(rsc.ce+rsc.zF)/(eye(N)-obj.pfOperators.mPF(1:N,:));
        end
    
        function cp=computeCostR(obj,aR)
	    %computeCostR - Compute production cost including waste allocation, using table FP info
        %   Input:
        %     aR - array with dissipative processes index
        %   Output:
        %     cp - production cost
		    N=obj.NrOfProcesses;
		    tmp=zeros(N,N);
		    aP=setdiff(1:N,aR);
		    tmp(:,aP)=obj.pfOperators.mKP(1:N,aP);
		    ke=obj.pfOperators.mKP(end,:);
            tmp(aP, aP) = tmp(aP, aP) + diag(sum(obj.fpOperators.mFP(aP,aR),2));
		    cp=ke/(eye(N)-tmp);
        end
    end
end