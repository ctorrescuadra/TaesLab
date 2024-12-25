classdef (Sealed) cExergyCost < cExergyModel
% cExergyCost calculates exergy cost of flows and processes.
%   It is the class that provides the thermoeconomic analysis results
%
% cExergyCost constructor:
%   obj = cExergyCost(exd,wd)
% 
% cExergyCost properties:
%   SystemOutput           - System Output of processes
%   FinalDemand            - Final Demand of processes
%   Resources              - External resources of processes
%   SystemUnitConsumption  - Total unit consumption of the system
%   RecirculationFactor    - Recirculation factor of each process
%   fpOperators            - Structure containing FP Operators (mFP, mRP, opCP,opCR)
%   pfOperators            - Structure containing PF Operators (mPF,mKP,mKR,opP,opI,opR)
%   FlowOperators          - Flow operators structure (mG, opB, opI, opR)
%   isWaste                - Indicate if system have wastes
%   WasteTable             - cWasteData object
%   TableR                 - R-Table (waste allocation)
%   RecycleRatio           - Recycle ratio of each waste
%   WasteWeight            - Weight of each waste
%
% cExergyCost methods:
%   buildResultInfo        - Build the cResultInfo object for thermoeconomic analysis
%   getProcessCost         - Get cost of Processes
%   getProcessUnitCost     - Get unit cost of Processes
%   getFlowsCost           - Get cost of flows
%   getStremasCost         - Get cost of streams
%   getCostTableFP         - Get cost table FP
%   getDirectCostTableFPR  - Get the direct cost FPR table
%   getGeneralCostTableFPR - Get the generalized cost FPR table
%   getProcessICT          - Get Irreversibility Cost Table for processes
%   getFlowsICT            - Get Irreversibility Cost table for flows
%   updateWasteOperator    - Update Waste Operator
%  
% See also cExergyModel
%
	properties(GetAccess=public,SetAccess=private)
        SystemOutput           % System Output of processes
        FinalDemand            % Final Demand of processes
        Resources              % External resources of processes
        SystemUnitConsumption  % Total unit consumption of the system
        RecirculationFactor    % Recirculation factor of each process
        WasteWeight            % Weight of each waste
        fpOperators            % Structure containing FP Operators (mFP, mRP, opCP,opCR)
        pfOperators            % Structure containing PF Operators (mPF,mKP,mKR,opP,opI,opR)
        FlowOperators          % Flow operators structure (mG, opB, opI, opR)
        isWaste=false          % Indicate if system have wastes
        WasteTable             % cWasteData object
        TableR                 % Table R (waste allocation)
        RecycleRatio           % Recycle ratio of each waste
    end
    properties(Access=private)
       opBP
    end
    
	methods
		function obj=cExergyCost(exd,wd)
		% Creates an instance of the class
        % Syntax:
        %   obj=cExergyCost(exd,wd)
        % Input Arguments:
		%   exd - cExergyData object
        %   wd - cWasteData object (optional)
        % Output Arguments Arguments:
        %  obj - cExergyCost object
        %
			obj=obj@cExergyModel(exd);
            obj.ResultId=cType.ResultId.THERMOECONOMIC_ANALYSIS;
            M=obj.NrOfFlows;
			N=obj.NrOfProcesses;
            vK=obj.UnitConsumption;
            vk1=zerotol(vK-1);
            % Get Flow Operators;
			fpt=obj.FlowProcessTable;
            mG=fpt.mF(:,1:N)*fpt.mP(1:N,:)+fpt.mV;
            opB=eye(M)/(eye(M)-mG);
            obj.opBP=fpt.mP(1:N,:)*opB;
            opBI=scaleRow(obj.opBP,vk1);
            obj.FlowOperators=struct('mG',mG,'opB',opB,'opI',opBI);
            % Get Process Operators
            tfp=obj.TableFP;        
            mPF=divideCol(tfp(:,1:N),obj.FuelExergy);
            mKP=scaleCol(mPF,vK);
            opP=zerotol(eye(N)+fpt.mP(1:N,:)*opB*fpt.mF(:,1:N));
            opI=scaleRow(opP,vk1);
            obj.pfOperators=struct('mPF',mPF,'mKP',mKP,'opP',opP,'opI',opI);
            mFP=divideRow(tfp(1:N,:),obj.ProductExergy);
            opCP=cExergyCost.similarMatrix(opP,obj.ProductExergy);
            obj.fpOperators=struct('mFP',mFP,'opCP',opCP);
            obj.DefaultGraph=cType.Tables.PROCESS_ICT;
            % Initialize waste operators
            if (nargin==2) && (obj.NrOfWastes>0)
				obj.isWaste=true;
                setWasteTable(obj,wd)
                obj.updateWasteOperators;
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
    
        function res=get.SystemUnitConsumption(obj)
        % Get the total unit consumtion of the sistem
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
        % Get the cResultInfo object for thermoeconomic analysis
        % Syntax:
        %   res=obj.buildResultInfo(fmt,options)
        % Input Arguments:
        %   fmt - cResultTableBuilder object
        %   options - structure indicating the table to obtain
        %     DirectCost: get direct cost tables (true | false)
        %     GeneralCost: get generalized cost tables (true | false)
            if nargin==2
                options.DirectCost=true;
                options.GeneralCost=false;
            end
            res=fmt.getCostResults(obj,options);
        end
   
        function res=getProcessCost(obj,rsc)
		% Get processes cost values
        %   If resource cost is provided calculate the generalized cost
        % Syntax:
        %   obj.getProcessCost(rsc)
		% Input Arguments:
		%   rsc - cResourceCost object [optional]
		% Output Arguments:
		%   res - structure containing cost values (CPE,CPZ,CPR,CP,CF,CR,Z)
        %
			czoption=(nargin==2);
            res=struct();
			N=obj.NrOfProcesses;
			zero=zeros(1,N);
            aux=obj.fpOperators;
			if czoption
                Ce=rsc.Ce;
                res.Z=rsc.Z;
				res.CPE=Ce * aux.opCP;
				res.CPZ=res.Z * aux.opCP;
			else
				Ce=obj.TableFP(end,1:N);
				res.CPE=Ce * aux.opCP;
				res.CPZ=zero;
			end
			if obj.isWaste
				res.CPR=(res.CPE+res.CPZ) * aux.opR;
				res.CP=res.CPE + res.CPZ + res.CPR;
				res.CR=res.CP * aux.mRP;
			else
				res.CPR=zero;
				res.CP=res.CPE+res.CPZ;
				res.CR=zero;
			end
			res.CF= Ce+res.CP*obj.fpOperators.mFP(:,1:end-1);
		end

        function res = getProcessUnitCost(obj,rsc)
    	% Get Process Unit Cost
        %   If resource cost is provided calculate the generalized cost
        % Syntax:
        %   obj.getProcessUnitCost(rsc)
		% Input Arguments:
		%   rsc - cResourceCost object [optional]
		% Output:
		%   res - structure containing cost values (cP,cPE,cPZ,cPR,cF,cR)
        %
            res=struct();
            czoption=(nargin==2);
            N=obj.NrOfProcesses;
            zero=zeros(1,N);
            res.k=obj.UnitConsumption;
            if czoption
                ce= rsc.ce;
                ke=ce .* res.k;
                res.cPE= ke * obj.pfOperators.opP;
                res.cPZ= rsc.zP * obj.pfOperators.opP;
            else
                ce=obj.pfOperators.mPF(end,:);
                ke=ce .* res.k;
                res.cPE= ke * obj.pfOperators.opP;
                res.cPZ= zero;
            end
            if obj.isWaste
                res.cPR=(res.cPE+res.cPZ)*obj.pfOperators.opR;
                res.cP=res.cPE+res.cPZ+res.cPR;
                res.cR=res.cP*obj.pfOperators.mKR;
            else
                res.cPR=zero;
                res.cP=res.cPE+res.cPZ;
                res.cR=zero;
            end
            res.cF=ce+res.cP*obj.pfOperators.mPF(1:end-1,1:end);
        end  

        function res=getFlowsCost(obj,rsc)
        % Get the exergy cost of flows
        %   If resource cost is provided calculate the generalized cost
        % Syntax:
        %   res=obj.getFlowsCost(rsc)
        % Input Arguments:
		%   rsc - cResourceCost object [optional]
        % Output
        %   res - cost of flows structure (B,CE,CZ,CR,C,cE,cZ,cR,c)
            czoption=(nargin==2);
            res=struct();
            zero=zeros(1,obj.NrOfFlows);	   
            aux=obj.FlowOperators;
            tbl=obj.FlowProcessTable;
            res.B=obj.FlowsExergy;
            if czoption
                res.cE=rsc.c0 * aux.opB;
                res.CE=res.cE .* res.B;
                res.cZ=rsc.zP * tbl.mP(1:end-1,:)*aux.opB;  
                res.CZ=res.cZ .* res.B;
            else
                res.cE=tbl.mP(end,:) * aux.opB;
                res.CE=res.cE .* res.B;
                res.cZ=zero;
                res.CZ=zero;
            end
            if obj.isWaste
                res.cR=(res.cE+res.cZ)*aux.opR;
                res.CR=res.cR .* res.B;
                res.c=res.cE+res.cZ+res.cR;
                res.C=res.CE+res.CZ+res.CR;
            else
                res.cR=zero;
                res.CR=zero;
                res.c=res.cE+res.cZ;
                res.C=res.CE+res.CZ;
            end
        end
        
        function res=getStreamsCost(obj,fcost)
        % Get the exergy cost of streams
        %   Compute the direct or generalized cost
        %   depending on the values of flows cost
        % Syntax:
        %   res=obj.getStreamsCost(fcost)
        % Input Arguments:
		%   fcost - Exergy cost of flows structure
        % Output
        %   res - cost of flows structure (E,CE,CZ,CR,C,cE,cZ,cR,c)
        %
            res=struct();
            zero=zeros(1,obj.NrOfStreams);
            res.E=obj.StreamsExergy.E;
            res.CE=obj.ps.flows2Streams(fcost.CE);
            res.cE=vDivide(res.CE,res.E);
            if obj.isWaste
                res.CR=obj.ps.flows2Streams(fcost.CR);
                res.cR=vDivide(res.CR,res.E);
            else
                res.CR=zero;
                res.cR=zero;
            end
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
        % Get the FP Cost Table considering only internal irreversibilities
        % Syntax:
        %   res=getCostTableFP(ucost)
        % Input Arguments:
        %   ucost - Unit cost of product. If omitted is calculated
        % Output:
        %   res - Direct Cost FP table values

            if nargin==1
                ucost=obj.getProcessUnitCost;
            end
            aux=[ucost.cPE,1];
            res=scaleRow(obj.TableFP,aux);
        end

        function res = getDirectCostTableFPR(obj,ucost)
        % Get FPR CostTable with direct costs
        % Syntax:
        %   res = obj.getDirectCostTableFPR(ucost)
        % Input Arguments:
        %   ucost - Unitary costs of processes. If ommited is calculated
        % Output: 
        %   res - Direct Cost FPR table values
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
        % Get FPR CostTable with generalized costs
        % Syntax:
        %   res = obj.getGeneralizedCostTableFPR(rsc,ucost)
        % Input Arguments:
        %   rsc - cResourceCost object
        %   ucost - Unitary costs of processes. If ommited is calculated
        % Output: 
        %   res - Generalized Cost FPR table values
        %
            if nargin<2
                ucost=obj.getProcessUnitCost(rsc);
            end	
            N=obj.NrOfProcesses;
            Ce= rsc.ce .* obj.ProcessesExergy.vF(1:N);
            aux=[Ce+rsc.Z,0];
            tmp=obj.TableFP(1:N,:);
            if obj.isWaste
                tR=obj.TableR;
                recycle=scaleRow(obj.TableFP(tR.mRows,end),obj.RecycleRatio);
                tmp(tR.mRows,:)=[tR.mValues,recycle];
            end
            res=[scaleRow(tmp,ucost.cP);aux];
        end 

        function res=getProcessICT(obj,rsc)
        % Get Process Irreversibility Cost Table
        %   If resource cost is provided calculate the generalized table
        % Syntax:
        %   res=obj.getProcessICT(rsc)
        % Input Arguments:
        %   rsc - cResourcesCost object [optional]
        % Output Arguments:
        %   res - Process ICT table
        %
            narginchk(1,2);
            N=obj.NrOfProcesses;
            if nargin==2
                cp0=obj.getMinCost(rsc);
                ict=zerotol([scaleRow(obj.pfOperators.opI,cp0);cp0]);
            else
                cp0=obj.getMinCost;
                ict=zerotol([obj.pfOperators.opI;cp0]);
            end
            if obj.isWaste
                mopCR=scaleRow(obj.pfOperators.opR,sum(ict));
                res=[ict(1:N,:)+mopCR;ict(end,:)];
            else
                res=ict;
            end		
        end

        function res=getFlowsICT(obj,rsc)
        % Get the irreversibility-cost table of flows
        %   If resource cost is provided calculate the generalized table
        % Syntax:
        %   res=obj.getFlowsICT(rsc)
        % Input Arguments:
        %   rsc - cResourceCost object [optional]
        % Output Arguments:
        %   res - irreversivility cost table for flows
            narginchk(1,2);
            N=obj.NrOfProcesses;
            M=obj.NrOfFlows;
            tbl=obj.FlowProcessTable;
            aux=obj.FlowOperators;
            if nargin==1
                cn=ones(1,N);
                cm=ones(1,M);
            else
                cn=obj.getMinCost(rsc);
                cm=(rsc.c0+cn*tbl.mP(1:end-1,:))*tbl.mL;
            end
            fict=scaleRow(aux.opI,cn);
            if obj.isWaste
                values=aux.opR.mValues;
                aR=aux.opR.mRows;
                cpe=sum(fict);
                cmR=scaleRow(values,cpe(aR));
                wprocess=obj.ps.Waste.processes; 
                rict=cSparseRow(wprocess,cmR,N);
                res=[fict+rict;cm];
            else
                res=[fict;cm];
            end
        end

        function updateWasteOperators(obj)
        % Calculate the waste allocation ratios and cost operators.
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
            vP=obj.ProductExergy;
            % Compute direct exergy cost for type 2 allocation
            if (any(wt.TypeId==cType.WasteAllocation.COST))
                cp=obj.computeCostR(aR);
            end
            % Compute Waste table depending on waste definition type
            for i=1:NR
                j=aR(i); 
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
                        obj.messageLog(cType.ERROR,cMessages.InvalidWasteType,wt.Type{i},key);
                        return
                end
                if isempty(find(tmp,1))				
                    obj.messageLog(cType.ERROR,cMessages.WasteAllocation,key);
                    return
                end
                sol(i,:)=tmp/sum(tmp);
            end
            % Create Waste Tables object
            sol=scaleRow(sol,1-wt.RecycleRatio);
            wt.updateValues(sol);
            mRP=cSparseRow(aR,sol);
            obj.TableR=scaleRow(mRP,vP);
            obj.fpOperators.mRP=mRP;
            mKR=divideCol(obj.TableR,vP);
            mSKR=(eye(NR)-mKR.mValues*opP(:,aR))\mKR.mValues;
            obj.pfOperators.mKR=mKR;
            obj.pfOperators.opR=cSparseRow(aR,mSKR*opP);
            obj.fpOperators.opR=cExergyCost.similarMatrix(obj.pfOperators.opR,vP);
            wflows=obj.ps.Waste.flows;
            obj.FlowOperators.opR=cSparseRow(wflows,mSKR*obj.opBP,M);
            obj.RecycleRatio=wt.RecycleRatio;
            obj.WasteTable=wt;
        end 
    end   
    
    methods(Static)
        function res=similarMatrix(A,x)
        % Calculate the similar matrix B=inv(x)*A*x
        % Input:
        %   A: Matrix
        %   x: vector
            tmp=scaleCol(A,x);
            res=divideRow(tmp,x);
        end

        function res=updateOperator(op,opR)
        % Update an operator with the corresponding waste operator
        % Input:
        %   op - Operator
        %   opR - Waste Operator
            res=op+op*opR;
        end
    end
    methods(Access=private)
        function setWasteTable(obj,wd)
        % Set the Waste Table for the cExergyCost 
        %  Input:
        %   wd - cWasteData object
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
        % Calculate the minimun cost of the flows
        %  Input:
        %   rsc - [optional] cost of external resources
            N=obj.NrOfProcesses;
            if nargin==2
                res=(rsc.ce+rsc.zF)/(eye(N)-obj.pfOperators.mPF(1:N,:));
            else
                res=ones(1,N);
            end
        end
    
        function cp=computeCostR(obj,aR)
	    % Compute production cost including waste allocation, using table FP info
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