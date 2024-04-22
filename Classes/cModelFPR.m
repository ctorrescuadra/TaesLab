classdef cModelFPR < cExergyModel
% cModelFPR Computes the system costs using the process model algorith
% 	It performs the thermoeconomic analysis of a plant state, including
%  	cost of flows and processes, irreversibilty cost tables and FP tables.
% 	Methods:
%		obj=cModelFPR(pm)
%		res=obj.getProcessCost(rsc)
%		res=obj.getProcessUnitCost(rsc)
%		res=obj.getCostTableFP
%		res=obj.getCostTableFPR(rsc)
%		res=obj.getProcessICT(rsc)
%		res=obj.getFlowsCost(ucost,rsc)
%		res=obj.getFlowsICT(ict,rsc)
%		res=obj.getStreamsCost(ucost,rsc)
%		res=getWasteWeight
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
        c0,cs0
    end
	
	methods
		function obj=cModelFPR(rex,wd)
		% Create a instance of this class
		%	Inputs:
		%	 rex - cExergyData object
        %    wd - cWasteData object
			obj=obj@cExergyModel(rex);
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
            obj.cs0=obj.StreamProcessTable.mP(end,:);
			obj.DefaultGraph=cType.Tables.PROCESS_ICT;
			if (nargin==2) && (obj.NrOfWastes>0)
				obj.isWaste=true;
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
				sWaste.opR=cModelFPR.computeWasteOperator(sWaste.mKR,obj.pfOperators.opP);
			end
            obj.WasteOperators=sWaste;
		end  

		function res=getProcessCost(obj,rsc)
			% return processes cost values
			% Input:
			%   rsc - [optional] external costs
			% Output:
			%   res - structure containing general cost values (CPE,CPZ,CPR,CP,CF,CR,Z)
			czoption=(nargin==2);
			N=obj.NrOfProcesses;
			zero=zeros(1,N);
			if czoption
				Ce=rsc.ce .* obj.FuelExergy;
				CPE=Ce * obj.fpOperators.opCP;
				CPZ=rsc.Z * obj.fpOperators.opCP;
			else
				Ce=obj.TableFP(end,1:N);
				CPE=Ce * obj.fpOperators.opCP;
				CPZ=zero;
			end
			if obj.isWaste
				CPR=(CPE+CPZ)*obj.WasteOperators.opCR;
				CP=CPE+CPZ+CPR;
				CR=CP*obj.WasteOperators.mRP;
			else
				CPR=zero;
				CP=CPE+CPZ;
				CR=zero;
			end
			CF= Ce+CP*obj.fpOperators.mFP(:,1:end-1);
			if czoption
				res=struct('CP',CP,'CPE',CPE,'CPZ',CPZ,'CPR',CPR,'CF',CF,'CR',CR,'Z',rsc.Z);
			else
				res=struct('CP',CP,'CPE',CPE,'CPR',CPR,'CF',CF,'CR',CR);
			end
		end
		
		function res = getProcessUnitCost(obj,rsc)
		% Get Generalized Process Unit Cost
		%  Inputs:
		%   rsc - Resources cost
        %  Outputs:
        %   res - struct containing general process cost values (cP,cPE,cPZ,cPR,cF,cR)
		%
			czoption=(nargin==2);
			N=obj.NrOfProcesses;
			zero=zeros(1,N);
            vK=obj.UnitConsumption;
			if czoption
                ce=rsc.ce;
                ke=rsc.ce .* vK;
				cPE= ke * obj.pfOperators.opP;
				cPZ= rsc.zP * obj.pfOperators.opP;
			else
				ce=obj.pfOperators.mPF(end,:);
                ke=ce .* vK;
				cPE= ke * obj.pfOperators.opP;
				cPZ= zero;
			end
			if obj.isWaste
				cPR=(cPE+cPZ)*obj.WasteOperators.opR;
				cP=cPE+cPZ+cPR;
				cR=cP*obj.WasteOperators.mKR;
			else
				cPR=zero;
				cP=cPE+cPZ;
				cR=zero;
			end
			cF=ce+cP*obj.pfOperators.mPF(1:end-1,1:end);
			if czoption
				res=struct('cP',cP,'cPE',cPE,'cPZ',cPZ,'cPR',cPR,'cF',cF,'cR',cR);
			else
				res=struct('cP',cP,'cPE',cPE,'cPR',cPR,'cF',cF,'cR',cR,'k',vK);
			end
		end  
		
		function res = getCostTableFP(obj)
		% Get the FP Cost Table considering only internal irreversibilities
			cost=[obj.getProcessUnitCost.cPE,1];
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
				cost=obj.getProcessUnitCost(rsc);
			else
				aux=obj.TableFP(end,:);
				cost=obj.getProcessUnitCost;	
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
				cp0=obj.getMinCost;
				ict=zerotol([obj.pfOperators.opI;cp0]);
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
			mR=obj.WasteOperators.opR;
			opI=cModelFPR.updateOperator(obj.pfOperators.opI,mR)+mR;
			if nargin==2
				cp0=obj.getMinCost(rsc);
				res=zerotol([scaleRow(opI,cp0);cp0]);
			else
				cp0=obj.getMinCost;
				res=zerotol([opI;cp0]);
			end		
		end

		function fcost=getFlowsCost(obj,ucost,rsc)
		% get the cost of flows from unit processes cost
		%  Inputs:
		%   ucost - unit cost of products
		%   rsc -  Cost of external resources
		%  Outputs:
		%   fcost - flows cost values (B,CE,CZ,CR,C,cE,cZ,cR,c)
			czoption=(nargin==3);
			B=obj.FlowsExergy;
            if czoption
                cb0=rsc.c0;
            else
                cb0=obj.c0;
            end
			cE=obj.flowsUnitCost(ucost.cPE,cb0);
			CE=cE.*B;
			cR=obj.flowsUnitCost(ucost.cPR);
			CR=cR.*B;
			if czoption
				cZ=obj.flowsUnitCost(ucost.cPZ);
				CZ=cZ.*B;
				c=cE+cZ+cR;
				C=CE+CZ+CR;
				fcost=struct('B',B,'CE',CE,'CZ',CZ,'CR',CR,'C',C,'cE',cE,'cZ',cZ,'cR',cR,'c',c);
			else
				c=cE+cR;
				C=CE+CR;
				fcost=struct('B',B,'CE',CE,'CR',CR,'C',C,'cE',cE,'cR',cR,'c',c);
			end

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

		function scost=getStreamsCost(obj,ucost,rsc)
		% Get the cost of streams from unit processes cost
		%  Inputs:
		%   ucost - unit cost of products
		%   rsc -  Cost of external resources
		%  Outputs:
		%   scost - streams cost values (E,CE,CZ,CR,C,cE,cZ,cR,c)
			czoption=(nargin==3);
			E=obj.StreamsExergy.ET;
			if czoption
				cse=rsc.cs0;
			else
				cse=obj.cs0;
			end
			cE=obj.streamsUnitCost(ucost.cPE,cse);
			CE=cE.*E;
			cR=obj.streamsUnitCost(ucost.cPR);
			CR=cR.*E;
			if czoption
				cZ=obj.streamsUnitCost(ucost.cPZ);
				CZ=cZ.*E;
				c=cE+cZ+cR;
				C=CE+CZ+CR;
				scost=struct('E',E,'CE',CE,'CZ',CZ,'CR',CR,'C',C,'cE',cE,'cZ',cZ,'cR',cR,'c',c);
			else
				c=cE+cR;
				C=CE+CR;
				scost=struct('E',E,'CE',CE,'CR',CR,'C',C,'cE',cE,'cR',cR,'c',c);
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
        function res=flowsUnitCost(obj,cp,c0)
		% Compute the flows unit cost given the product cost
		% Use the matrices of Table FP building
		%	Input: 
		%		cp - unit cost of product
		%		c0 - unit cost of resource flows (optional)
		%	Output:
		%	   res - unit cost of flows
            tbl=obj.FlowProcessTable;
			aux=cp*tbl.mP(1:end-1,:);
			if nargin==3
				aux=aux+c0;
			end
			res=aux*tbl.mL;
        end

        function res=streamsUnitCost(obj,cp,c0)
		% Compute the flows unit cost given the product cost
		% Use the matrices of Table FP building
		%	Input: 
		%		cp - unit cost of product
		%		c0 - unit cost of resource flows (optional)
		%	Output:
		%	   res - unit cost of flows
            tbl=obj.StreamProcessTable;
			aux=cp*tbl.mP(1:end-1,:);
			if nargin==3
				aux=aux+c0;
			end
			res=aux*tbl.mL;
        end

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