classdef (Sealed) cExergyCost < cExergyModel
% cFlowExergyCost Calculates exergy cost of flows and processes, using Flow-Process approach
% 	Methods:
%		obj=cFlowExergyCost(rex,wd)
%		obj.updateWasteOperators;
%       res=obj.getProcessCost(rsc)
%       res=obj.getUnitProcessCost(rsc)
%   	res=obj.getFlowCost(rsc)
%       res=obj.getStreamCost(rsc)
%		res=obj.getProcessICT(rsc)               
%	    res=obj.getFlowICT(rsc)
%       res=obj.getCostTableFP(ucost)
%       res=obj.getCostTableFPR(rsc,ucost)
% See also cExergyModel
	properties(GetAccess=public,SetAccess=private)
        SystemOutput           % System Output of processes
        FinalDemand            % Final Demand of processes
        Resources              % External resources of processes
        SystemUnitConsumption  % Total unit consumption of the system
        RecirculationFactor    % Recirculation factor of each process
        WasteWeight            % Weight of each waste
        fpOperators            % Structure containing FP Operators (mFP, mRP, opCP,opCR)
        pfOperators            % Structure containing PF Operators (mPF,mKP,mKR,opP,opI,opR)
        StreamOperators        % Stream operators structure (mG, opE, opI, opR)  
        FlowOperators          % Flow operators structure (mG, opB, opI, opR)
        isWaste                % Indicate if system have wastes
        WasteTable             % cWasteData object
        TableR                 % Table R (waste allocation)
        RecycleRatio           % Recycle ratio of each waste
	end

	properties (Access=private)
        opEP, opBP
	end

	methods
		function obj=cExergyCost(rex,wd)
		% Creates the cFlowProcessModel object
		%   rex - cExergyData object
        %   wd - cWasteData object
			obj=obj@cExergyModel(rex);
            obj.ResultId=cType.ResultId.THERMOECONOMIC_ANALYSIS;
            M=obj.NrOfFlows;
			N=obj.NrOfProcesses;
            NS=obj.NrOfStreams;
            vK=obj.UnitConsumption;
            vk1=zerotol(vK-1);
            % Get Stream Operators
            spt=obj.StreamProcessTable;
            mH=spt.mF(:,1:N)*spt.mP(1:N,:)+spt.mS*spt.mE;
            opE=eye(NS)/(eye(NS)-mH);
            obj.opEP=spt.mP(1:N,:)*opE;
            opEI=scaleRow(obj.opEP,vk1);
            obj.StreamOperators=struct('mH',mH,'opE',opE,'opI',opEI);
            % Get Flow Operators;
			fpt=obj.FlowProcessTable;
            mG=fpt.mF(:,1:N)*fpt.mP(1:N,:)+fpt.mV;
            opB=eye(M)+spt.mE*opE*spt.mS;
            obj.opBP=fpt.mP(1:N,:)*opB;
            opBI=scaleRow(obj.opBP,vk1);
            obj.FlowOperators=struct('mG',mG,'opB',opB,'opI',opBI);
            % Get Process Operators
            tfp=obj.TableFP;        
            mPF=divideCol(tfp(:,1:N),obj.FuelExergy);
            mKP=scaleCol(mPF,vK);
            opP=zerotol(eye(N)+spt.mP(1:N,:)*opE*spt.mF(:,1:N));
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
            res=[];
            if obj.isValid
                res=obj.TableFP(1:end-1,end);
            end
        end
        
        function res=get.FinalDemand(obj)
        % Get final demand vector of the system 
            res=obj.SystemOutput;
            if obj.isValid && obj.isWaste
                idx=obj.ps.Waste.processes;
                res(idx)=scaleRow(obj.TableFP(idx,end),obj.RecycleRatio);
            end
        end    
                
        function res=get.Resources(obj)
        % Get the exergy resources vector
            res=[];
            if obj.isValid
                res=obj.TableFP(end,1:end-1);
            end
        end
    
        function res=get.SystemUnitConsumption(obj)
        % Get the total unit consumtion of the sistem
            res=[];
            if obj.isValid
                res=sum(obj.Resources)/sum(obj.FinalDemand);
            end
        end
                    
        function res=get.RecirculationFactor(obj)
        % Get the recirculation factor of the processes
            res=[];
            if obj.isValid
                res=zerotol(diag(obj.fpOperators.opCP)'-1);
            end
        end
    
        function res=get.WasteWeight(obj)
        % Get the waste weight.
            res=[];
            if obj.isWaste
                opR=obj.fpOperators.opR;
                res=diag(opR.mValues(:,opR.mRows))';
            end
        end
    
        function res=getResultInfo(obj,fmt,options)
        % Get the cResultInfo object
            res=fmt.getThermoeconomicAnalysisResults(obj,options);
        end
   
        function res=getProcessCost(obj,rsc)
		% return processes cost values
		% Input:
		%   rsc - [optional] external costs
		% Output:
		%   res - structure containing cost values (CPE,CPZ,CPR,CP,CF,CR,Z)
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
        % Get Generalized Process Unit Cost
        %  Inputs:
        %   rsc - [optional] Resources cost
        %  Outputs:
        %   res - struct containing general process cost values (cP,cPE,cPZ,cPR,cF,cR)
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
        % Get the generalized exergy cost of flows
        %  Input:
        %   rsc - cost of external resources
        %  Output
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

        function res=getStreamsCost(obj,rsc)
            czoption=(nargin==2);
            res=struct();
            zero=zeros(1,obj.NrOfStreams);
            aux=obj.StreamOperators;
            tbl=obj.StreamProcessTable;
            res.E=obj.StreamsExergy.ET;
            if czoption
                res.cE=rsc.cs0 * aux.opE;
                res.CE=res.cE .* res.E;
                res.cZ=rsc.zP * tbl.mP(1:end-1,:)*aux.opE;  
                res.CZ=res.cZ .* res.E;
            else
                res.cE=tbl.mP(end,:) * aux.opE;
                res.CE=res.cE .* res.E;
                res.cZ=zero;
                res.CZ=zero;
            end
            if obj.isWaste
                res.cR=(res.cE+res.cZ)*aux.opR;
                res.CR=res.cR .* res.E;
                res.c=res.cE+res.cZ+res.cR;
                res.C=res.CE+res.CZ+res.CR;
            else
                res.cR=zero;
                res.CR=zero;
                res.c=res.cE+res.cZ;
                res.C=res.CE+res.CZ;
            end
        end   
            
        function res = getCostTableFP(obj,ucost)
        % Get the FP Cost Table considering only internal irreversibilities
        % Input:
        %   ucost - [optional] unit cost of product. If omitted is calculated
        %   res - Direct Cost FP table

            if nargin==1
                ucost=obj.getProcessUnitCost;
            end
            aux=[ucost.cPE,1];
            res=scaleRow(obj.TableFP,aux);
        end

        function res = getDirectCostTableFPR(obj,ucost)
        % Get FPR CostTable with direct costs
        %  Inputs:
        %   ucost - [optional] Unitary costs of processes. If ommited is calculated
        %   res - Direct Cost FPR table
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
        %  Inputs:
        %   rsc - Resources cost
        %   ucost - [optional] Unitary costs of processes. If ommited is calculated        
        %  Output:
        %   res - Generalized Cost FPR table
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
        %  Inputs:
        %   rsc - [optional] Resources cost
        %  Outputs:
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
        %  Input:
        %   rsc [optional] - cost of external resources
        %  Output:
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
            NS=obj.NrOfProcesses;
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
                        obj.messageLog(cType.ERROR,'Invalid Waste type allocation %s',wt.Type{i});
                        return
                end
                if isempty(find(tmp,1))				
                    obj.messageLog(cType.ERROR,'Invalid Allocation for waste flow %s', key);
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
            wstreams=obj.ps.Waste.streams;
            obj.StreamOperators.opR=cSparseRow(wstreams,mSKR*obj.opEP,NS);
            wflows=obj.ps.Waste.flows;
            obj.FlowOperators.opR=cSparseRow(wflows,mSKR*obj.opBP,M);
            obj.RecycleRatio=wt.RecycleRatio;
            obj.WasteTable=wt;
        end 
    end   
    
    methods(Static)
        function res=similarMatrix(A,x)
        % Calculate the similar matrix B=inv(x)*A*x
        %   Input:
        %       A: Matrix
        %       x: vector
            tmp=scaleCol(A,x);
            res=divideRow(tmp,x);
        end

        function res=updateOperator(op,opR)
        % Update an operator with the corresponding waste operator
            res=op+op*opR;
        end
    end
    methods(Access=private)
        function setWasteTable(obj,wd)
        % Set the Waste Table for the cExergyCost 
        %  Input:
        %   wd - cWasteData object
            if ~obj.isWaste
                obj.messageLog(cType.ERROR,'Model must define waste flows');
                return
            end
            if ~isa(wd,'cWasteData') || ~wd.isValid
                obj.messageLog(cType.ERROR,'Wrong input parameters. Argument must be a valid cWasteData object');
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
		    for j=aR
			    for i=aP
				    tmp(i,i)=tmp(i,i)+obj.fpOperators.mFP(i,j);
			    end
		    end
		    cp=ke/(eye(N)-tmp);
        end
    end
end