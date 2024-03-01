classdef cModelFPR < cProcessModel
% cModelFPR Computes the system costs using the process model algorith
% 	It performs the thermoeconomic analysis of a plant state, including
%  	cost of flows and processes, irreversibilty cost tables and FP tables.
% 	Methods:
%		obj=cModelFPR(pm)
%		obj.setWasteOperators
%		res=obj.getDirectProcessCost
%		res=obj.getGeneralProcessCost(rsc)
%		res=obj.getDirectProcessUnitCost
%		res=obj.getGeneralProcessUnitCost(rsc)
%		res=obj.getCostTableFP
%		res=obj.getCostTableFPR(rsc)
%		res=obj.getProcessICT(rsc)
%		res=obj.getDirectFlowsCost(ucost)
%		res=obj.getGeneralFlowsCost(ucost,rsc)
%		res=obj.getFlowsICT(ict,rsc)
%		res=get.WasteWeight
%		
	properties (GetAccess=public, SetAccess=private)
		fpOperators           % FP representation operators (mFP,opCP)
		pfOperators           % PF representation operators (mPF,mKP,opP,opI)
        SystemOutput          % System outputs exergy by process
		FinalDemand			  % Final Demand
		Resources             % Resources Exergy by process
		RecirculationFactor   % Recirculation Factor
		WasteTable	          % Waste Table
		WasteOperators        % Waste Operators
		SystemUnitConsumption % Global Unit Consumption considering waste recycling
		isWaste=false		  % Waste is well defined
    end

    properties(Access=private)
        c0
    end
	
	methods
		function obj=cModelFPR(rex,wd)
		% Create a instance of this class
		%	Inputs:
		%	 rex - cExergyData object
        %    wd - cWasteData object
			obj=obj@cProcessModel(rex);
            obj.ResultId=cType.ResultId.THERMOECONOMIC_ANALYSIS;
			N=obj.NrOfProcesses;
			% Fuel-Product Exergy values
			vF=obj.FuelExergy;
			vP=obj.ProductExergy;
			vK=obj.UnitConsumption;
			% Production Operators
			tFP=obj.TableFP;
			mFP=divideRow(tFP(1:N,:),vP);
			opCP=zerotol(inv(eye(N)-mFP(1:N,1:N)));
			obj.fpOperators=struct('mFP',mFP,'opCP',opCP);
			mPF=divideCol(tFP(:,1:N),vF);
			mKP=divideCol(tFP(:,1:N),vP);
			opP=inv(eye(N)-mKP(1:N,1:N));
			opI=scaleRow(opP,vK-1);
			obj.pfOperators=struct('mPF',mPF,'mKP',mKP,'opP',opP,'opI',opI);
            obj.c0=zeros(1,obj.NrOfFlows);
			obj.c0(obj.ps.Resources.flows)=1.0;
			obj.isWaste=(obj.NrOfWastes>0);
			obj.DefaultGraph=cType.Tables.PROCESS_ICT;
			if (nargin==2)
				obj.setWasteTable(wd);
                obj.setWasteOperators;
			end
		end

		function res=get.SystemOutput(obj)
			% Get the system output exergy values vector
				res=obj.TableFP(1:end-1,end);
			end
	
		function res=get.FinalDemand(obj)
		% Override getFinalDemand
			res=obj.SystemOutput;
			if obj.isWaste
				idx=obj.ps.Waste.processes;
				res(idx)=scaleRow(obj.TableFP(idx,end),obj.WasteOperators.mSR);
			end
		end    
			
		function res=get.Resources(obj)
		% Get the exergy resources vector
			res=obj.TableFP(end,1:end-1);
		end

		function res=get.SystemUnitConsumption(obj)
			res=sum(obj.Resources)/sum(obj.FinalDemand);
		end
				
		function res=get.RecirculationFactor(obj)
		% Get the recirculation factor of the processes
			res=diag(obj.fpOperators.opCP)'-1;
        end

        function res=getResultInfo(obj,fmt,options)
		% Get cResultInfo object
            res=fmt.getThermoeconomicAnalysisResults(obj,options);
        end

        function setWasteOperators(obj,sWaste)
		% Set the Waste Operators values
		% Input:
		%	sWaste [optional] - Stucture containing  WasteOperators (tR, mRP, mKR, opR, opCR)
		%  		If it is not provided, they are calculated.
			if nargin==1
				sWaste=obj.wasteProcessTable;
				sWaste.opCR=cModelFPR.computeWasteOperator(sWaste.mRP,obj.fpOperators.opCP);
				sWaste.opR=cModelFPR.computeWasteOperator(sWaste.mKR,obj.pfOperators.opP);			else
			end
            obj.WasteOperators=sWaste;
		end
		
		function res=getDirectProcessCost(obj)
		% Get processes cost values
		% Output:
		%   res - structure containing cost values (CP,CPE,CPR,CF,CR)
			N=obj.NrOfProcesses;
			zero=zeros(1,N);
			aux=obj.TableFP(end,1:N);
			CPE=aux * obj.fpOperators.opCP;
			if obj.isWaste
				CPR=CPE * obj.WasteOperators.opCR;
				CP=CPE+CPR;
				CR=CP * obj.WasteOperators.mRP;
			else
				CP=CPE;
				CPR=zero;
				CR=zero;
			end
			CF=aux+CP*obj.fpOperators.mFP(1:end,1:end-1);
			res=struct('CP',CP,'CPE',CPE,'CPR',CPR,'CF',CF,'CR',CR);
		end		  

		function res=getGeneralProcessCost(obj,rsc)
			% return processes cost values
			% Input:
			%   rsc - [optional] external costs
			% Output:
			%   res - structure containing general cost values (CPE,CPZ,CPR,CP,CF,CR,Z) 
			N=obj.NrOfProcesses;
			zero=zeros(1,N);
			Ce=rsc.ce .* obj.ProcessesExergy.vF(1:N);
			CPE=Ce * obj.fpOperators.opCP;
			CPZ=rsc.Z * obj.fpOperators.opCP;
			if obj.isWaste
				CPR=(CPE+CPZ)*obj.WasteOperators.opCR;
				CP=CPE+CPZ+CPR;
				CR=CP*obj.WasteOperators.mRP;
			else
				CPR=zero;
				CP=CPE+CPZ;
				CR=zero;
			end
			CF= Ce+CP*obj.fpOperators.mFP(1:end,1:end-1);
			res=struct('CP',CP,'CPE',CPE,'CPZ',CPZ,'CPR',CPR,'CF',CF,'CR',CR,'Z',rsc.Z);
		end

		function res = getDirectProcessUnitCost(obj)
		% get Process Unit Cost
        %  Output:
        %   res - struct containing direct unit cost values (cP,cPE,cPR,cF,cR,k)
			N=obj.NrOfProcesses;
			zero=zeros(1,N);
			cPE=obj.pfOperators.mKP(end,1:N)*obj.pfOperators.opP;
            if obj.isWaste
				cPR=cPE*obj.WasteOperators.opR;
				cP=cPE+cPR;
				cR=cP*obj.WasteOperators.mKR;
			else
				cP=cPE;
				cPR=zero;
				cR=zero;
            end
            vK=obj.ProcessesExergy.vK(1:N);
			cF=obj.pfOperators.mPF(end,1:N)+cP*obj.pfOperators.mPF(1:end-1,1:end);
			res=struct('cP',cP,'cPE',cPE,'cPR',cPR,'cF',cF,'cR',cR,'k',vK);
		end
		
		function res = getGeneralProcessUnitCost(obj,rsc)
		% Get Generalized Process Unit Cost
		%  Inputs:
		%   rsc - Resources cost
        %  Outputs:
        %   res - struct containing general process cost values (cP,cPE,cPZ,cPR,cF,cR)
		%
			N=obj.NrOfProcesses;
			zero=zeros(1,N);     
			auxE = rsc.ce .* obj.UnitConsumption;
			cPE= auxE * obj.pfOperators.opP;
			cPZ= rsc.zP * obj.pfOperators.opP;
			if obj.isWaste
				cPR=(cPE+cPZ)*obj.WasteOperators.opR;
				cP=cPE+cPZ+cPR;
				cR=cP*obj.WasteOperators.mKR;
			else
				cPR=zero;
				cP=cPE+cPZ;
				cR=zero;
			end
			cF=rsc.ce+cP*obj.pfOperators.mPF(1:end-1,1:end);
			res=struct('cP',cP,'cPE',cPE,'cPZ',cPZ,'cPR',cPR,'cF',cF,'cR',cR);
		end  
		
		function res = getCostTableFP(obj)
		% Get the FP Cost Table considering only internal irreversibilities
			cost=[obj.getDirectProcessUnitCost.cPE,1];
			res=scaleRow(obj.TableFP,cost);
		end

		function res = getCostTableFPR(obj,rsc)
		% Get FPR CostTable
		%  Inputs:
		%   rsc - [optional] Resources cost
        %  Outputs:
        %   res - FPR Cost Table
		%
			narginchk(1,2);
			N=obj.NrOfProcesses;
			if nargin==2
				Ce= rsc.ce .* obj.ProcessesExergy.vF(1:N);
				aux=[Ce+rsc.Z,0];
				cost=obj.getGeneralProcessUnitCost(rsc);
			else
				aux=obj.TableFP(end,:);
				cost=obj.getDirectProcessUnitCost;	
			end
			tmp=obj.TableFP(1:N,:);
			if obj.isWaste
				tR=obj.WasteOperators.tR;
				recycle=scaleRow(obj.TableFP(tR.mRows,end),obj.WasteOperators.mSR);
				tmp(tR.mRows,:)=[tR.mValues,recycle];
			end
			res=[scaleRow(tmp,cost.cP);aux];
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
				ict=zerotol([obj.pfOperators.opI;ones(1,N)]);
			end
			if obj.isWaste
            	mopCR=scaleRow(obj.WasteOperators.opR,sum(ict));
		    	res=[ict(1:N,:)+mopCR;ict(end,:)];
			else
				res=ict;
			end		
		end

		function res=getProcessICT0(obj,rsc)
		% Get Process Irreversibility Cost Table, as sum of internal and external irreversibilities
		%  Inputs:
		%   rsc - [optional] Resources cost
		%  Outputs:
		%   res - Process ICT table
		%
			narginchk(1,2);
			N=obj.NrOfProcesses;
			mR=obj.WasteOperators.opR;
			opI=cModelFPR.updateOperator(obj.pfOperators.opI,mR)+mR;
			if nargin==2
				cp0=obj.getMinCost(rsc);
				res=zerotol([scaleRow(opI,cp0);cp0]);
			else
				res=zerotol([opI;ones(1,N)]);
			end		
		end

		function fcost=getDirectFlowsCost(obj,ucost)
		% get the cost of flows from unit processes cost
		%  Inputs:
		%   ucost - unit cost of products
		%  Outputs:
		%   fcost - flows cost values (B,CE,CR,C,cE,cR,c)
		%	scost - stream cost values (CSE,CSR,CS,cSE,cSR,cS)
			B=obj.FlowsExergy;
			cE=obj.flowsUnitCost(ucost.cPE,obj.c0);
			cR=obj.flowsUnitCost(ucost.cPR);
			c=cE+cR;
			CE=cE.*B;
			CR=cR.*B;
			C=CE+CR;
			fcost=struct('B',B,'CE',CE,'CR',CR,'C',C,'cE',cE,'cR',cR,'c',c);
		end

		function fcost=getGeneralFlowsCost(obj,ucost,rsc)
		% get the cost of flows from unit processes cost
		%  Inputs:
		%   ucost - unit cost of products
		%   rsc -  Cost of external resources
		%  Outputs:
		%   fcost - flows cost values (B,CE,CZ,CR,C,cE,cZ,cR,c)
			B=obj.FlowsExergy;
			cE=obj.flowsUnitCost(ucost.cPE,rsc.c0);
			cZ=obj.flowsUnitCost(ucost.cPZ);
			cR=obj.flowsUnitCost(ucost.cPR);
			c=cE+cZ+cR;
			CE=cE.*B;
			CZ=cZ.*B;
			CR=cR.*B;
			C=CE+CZ+CR;
			fcost=struct('B',B,'CE',CE,'CZ',CZ,'CR',CR,'C',C,'cE',cE,'cZ',cZ,'cR',cR,'c',c);
        end

        function res=getFlowsICT(obj,tIC,cz)
		% return the Irreversibility Cost Table for flows
        %  Input:
		%   tIC - Irreversibility cost table of processes
		%   cz [optional] - Cost of external resources
			narginchk(2,3);
			N1=obj.NrOfProcesses+1;
			res=zeros(N1,obj.NrOfFlows);
			res(1:end-1,:)=obj.flowsUnitCost(tIC(1:end-1,:));
			if nargin==2
				res(end,:)=ones(1,obj.NrOfFlows);
			else
				res(end,:)=obj.flowsUnitCost(tIC(end,:),cz.c0);
			end
        end    

		function res=getWasteWeight(obj)
		% Get the waste weight.  The diagonal of the S matrix.
			res=[];
			if obj.isWaste
				opR=obj.WasteOperators.opR;
				res=diag(opR.mValues(:,opR.mRows))';
			end
        end


	end
	
	methods (Access=private)
		function res=getMinCost(obj,rsc)
		% Get minimun cost for a given cost of external resources
		%  Input:
        %   rsc - [optional] cost of external resources
			narginchk(1,2);
			N=obj.NrOfProcesses;
			if nargin==1
				res=ones(1,N);
			else
				q0=rsc.ce+rsc.zF;
				res=q0/(eye(N)-obj.pfOperators.mPF(1:N,1:N));
			end
		end

		function cp=computeCostR(obj,aR)
		% Compute cost production cost including waste allocation, using table FP info
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

		function setWasteTable(obj,wd)
		% Set the Waste Table for the cModelFPR 
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
			obj.WasteTable=wd.getWasteTable;
		end
		
		function res=wasteProcessTable(obj)
		% Calculate the waste allocation ratios, using ModelFP info.
            res=[];
			wt=obj.WasteTable;
			NR=wt.NrOfWastes;
			N=obj.NrOfProcesses;
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
			if (any(wt.typeId==cType.WasteAllocation.COST))
				cp=obj.computeCostR(aR);
			end
			% Compute Waste table depending on waste definition type
			for i=1:NR
				j=aR(i);       
				switch wt.typeId(i)
					case cType.WasteAllocation.MANUAL
						tmp=wt.getValues(i);
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
					text=wt.WasteKeys{i};				
					obj.messageLog(cType.ERROR,'Invalid Allocation for waste flow %s', text);
					return
				end
				sol(i,:)=tmp/sum(tmp);
			end
			% Create Waste Tables
			sol=scaleRow(sol,1-wt.RecycleRatio);
            wt.updateValues(sol);
			mRP=cSparseRow(aR,sol);
			tR=cSparseRow(aR,scaleRow(sol,vP(aR)));
			mKR=cSparseRow(aR,divideCol(tR.mValues,vP));
			res=struct('mRP',mRP,'mKR',mKR,'tR',tR,'mSR',wt.RecycleRatio);
		end 
	end
    
	methods (Static,Access=private)
		function res=computeWasteOperator(mR,oP)
		% Compute waste operator
			aR=mR.mRows;
			NR=length(aR);
			tmp=mR*oP;
			res=cSparseRow(aR,(eye(NR)-tmp.mValues(:,aR))\tmp.mValues);
        end
		
		function res=updateOperator(op,opR)
		% Update an operator with the corresponding waste operator
			res=op+op*opR;
		end
	end
end