classdef (Sealed) cExergyCost < cExergyModel
% cFlowExergyCost Calculates exergy cost of flows and processes, using Flow-Process approach
% 	Methods:
%		obj=cFlowExergyCost(rex,wt)
%		obj.setWasteOperators(wt)
%   	res=obj.getDirectFlowsCost
%   	res=obj.getGeneralFlowsCost(rsc)
%		res=obj.getFlowsICT(rsc)               
%		[cost,ucost]=obj.getDirectProcessCost(fcosts)
%   	[cost,ucost]=obj.getGeneralProcessCost(fcosts,rsc)
%		res=obj.getProcessICT(fICT,rsc)
%	 Methods inherited from cExergyModel:
%   	res=obj.getStreamProcessTable
%		res=obj.getFlowProcessTable
%   	res=obj.getStreamsCost
% See also cExergyModel
	properties(GetAccess=public,SetAccess=private)
        AdjacencyMatrix     % Structure containing the adjacency submatrices
        IncidenceMatrix     % Structure containing the incidence matrices including waste
		mG	                % Characteristic matrix
		WasteTable          % Waste Table Info
		mL                  % Production Operator
		opR                 % Waste Operator
        isWaste=false       % Waste is well defined
	end

	properties (Access=private)
		mV,mF,mF0,mP,mR     % Extended table matrices
		c0					% Unit cost of resources	
        dprocess            % Dissipative processes list
	end

	methods
		function obj=cExergyCost(rex,wd)
		% Creates the cExergyCost object
		%   rex - cExergyData object
        %   wd - cWasteData object
			obj=obj@cExergyModel(rex);
            obj.ResultId=cType.ResultId.EXERGY_COST_CALCULATOR;
            M=obj.NrOfFlows;
			N=obj.NrOfProcesses;
			tbl=obj.getFlowProcessTable;
			obj.mV=divideCol(tbl.tV,obj.FlowsExergy);
			obj.mF=divideCol(tbl.tF(:,1:N),obj.ProductExergy);
			obj.mF0=divideCol(tbl.tF(:,1:N),obj.FuelExergy);
			mP=divideCol(tbl.tP,obj.FlowsExergy);
			obj.mP=mP(1:N,:);
			obj.c0=mP(end,:);
			obj.mG=obj.mF*obj.mP+obj.mV;
			obj.mL=zerotol(inv(full(eye(M)-obj.mG)));
            if (nargin==2) && isa(wd,'cWasteData')
                obj.setWasteOperators(wd)
            end
		end

        function res=get.AdjacencyMatrix(obj)
			res=struct('mV',obj.mV,'mF',obj.mF,'MF0',obj.mF0,'mP',obj.mP,'mR',obj.mR);
		end

        function res=get.IncidenceMatrix(obj)
        % Get the incidence matrix including waste allocation
            [iAF,iAP]=obj.ps.IncidenceMatrix;
            iAR=cSparseRow(obj.WasteTable.Flows,obj.WasteTable.Values,obj.NrOfFlows);
            res=struct('iAF',iAF,'iAP',iAP,'iAR',sparse(iAR)');
        end

        function res=getResultInfo(obj,fmt,options)
        % Get the cResultInfo object
            res=fmt.getExergyCostResults(obj,options);
        end

        function setWasteOperators(obj,wd)
        % Update waste operators mR,opR from waste table
            if ~isa(wd,'cWasteData') || ~wd.isValid
                obj.messageLog(cType.ERROR,'Wrong input parameters. Argument must be a valid cWasteData object');
                return
            end
            if ~obj.isValid
                obj.messageLog(cType.ERROR,'Invalid Exergy Cost object')
                return
            end
            if obj.NrOfWastes<1
                obj.messageLog(cType.ERROR,'Model must define waste flows');
                return
            end
            wt=wd.getWasteTable;
            NR=obj.NrOfWastes;
            obj.WasteTable=wt;
            obj.dprocess=wt.Processes;
            wft=obj.wasteFlowsTable(wt);
            if obj.isValid		
                aR=wft.mRows;
                aux=wft.mValues*obj.mP*obj.mL;
                obj.mR=wft;
                obj.opR=cSparseRow(aR,(eye(NR)-aux(:,aR))\aux);
                obj.isWaste=true;
            end
        end
        function res=getDirectFlowsCost(obj)
        % Get the exergy cost of flows
        %  Output
        %   res - cost of flows structure (CI,CR,C,cI,cR,c);
            zero=zeros(1,obj.NrOfFlows);		
            B=obj.FlowsExergy;
            cE=obj.c0*obj.mL;
            CE=cE .* B;
            if obj.isWaste
                cR=cE*obj.opR;
                CR=cR .* B;
                c=cE+cR;
                C=CE+CR;
            else
                cR=zero;
                CR=zero;
                c=cE;
                C=CE;
            end
            res=struct('B',B,'CE',CE,'CR',CR,'C',C,'cE',cE,'cR',cR,'c',c);    		
        end
    
        function res=getGeneralFlowsCost(obj,rsc)
        % Get the generalized exergy cost of flows
        %  Input:
        %   rsc - cost of external resources
        %  Output
        %   res - cost of flows structure (B,CE,CZ,CR,C,cE,cZ,cR,c)
            zero=zeros(1,obj.NrOfFlows);	
            B=obj.FlowsExergy;
            cE=rsc.c0 * obj.mL;
            cZ=rsc.zP * obj.mP*obj.mL;
            CE=cE .* B;
            CZ=cZ .* B;
            if obj.isWaste
                cR=(cE+cZ)*obj.opR;
                CR=cR .* B;
                c=cE+cZ+cR;
                C=CE+CZ+CR;
            else
                cR=zero;
                CR=zero;
                c=cE+cZ;
                C=CE+CZ;
            end
            res=struct('B',B,'CE',CE,'CZ',CZ,'CR',CR,'C',C,'cE',cE,'cZ',cZ,'cR',cR,'c',c);    	
        end
            
        function res=getFlowsICT(obj,rsc)
        % Get the irreversibility-cost table of flows
        %  Input:
        %   rsc [optional] - cost of external resources
        %  Output:
        %   res - irreversivility cost table for flows
            narginchk(1,2);
            if nargin==1
                cm=obj.getMinCost;
                cn=cm*(obj.mF-obj.mF0);
            else
                cm=obj.getMinCost(rsc);
                cn=cm*(obj.mF-obj.mF0) + rsc.zP - rsc.zF;
            end
            fict=[scaleRow(obj.mP*obj.mL,cn);cm];
            if obj.isWaste
                cmR=scaleRow(obj.opR,sum(fict));
                rict=cSparseRow(obj.dprocess,cmR.mValues,obj.NrOfProcesses+1);
                res=fict+rict;
            else
                res=fict;
            end
        end

		function [res1,res2]=getDirectProcessCost(obj,fcosts)
		% get the cost related to processes.
		%  Inputs:
		%   fcosts - structure containing the flows costs
		%  Output:
		%   res1 - exergy costs of processes (CF,CR,CP,CPI,CPR)
		%   res2 - unit exergy costs of proceses (cF,cR, cP, cPI, cPR)
		%
			zero=zeros(1,obj.NrOfProcesses);
			cPE=fcosts.cE*obj.mF;
			cF=fcosts.c*obj.mF0;
            CPE=cPE .* obj.ProductExergy;
            CF=cF .* obj.FuelExergy;
			if (obj.isWaste)
                cR=fcosts.c*obj.mR;
                cPR=fcosts.cR*obj.mF+cR;
                cP=cPE+cPR;
                CR=cR .* obj.ProductExergy;
                CP=cP .* obj.ProductExergy;
                CPR=cPR .* obj.ProductExergy;
			else
				CP=CPE;
				cP=cPE;
				cR=zero;
				CR=zero;
				cPR=zero;
				CPR=zero;
			end
            res1=struct('CP',CP,'CPE',CPE,'CPR',CPR,'CF',CF,'CR',CR);
			res2=struct('cP',cP,'cPE',cPE,'cPR',cPR,'cF',cF,'cR',cR,'k',obj.UnitConsumption);
	    end
        
		function [res1,res2]=getGeneralProcessCost(obj,fcosts,rsc)
		% Get the cost related to processes.
		%  Inputs:
		%   fcosts - structure containing the flows costs
		%	cz - [optional] cost of external resources
		%  Output:
		%   res1 - exergy costs of processes (CP,CPE,CPZ,CPR,CF,CR,Z)
		%   res2 - unit exergy costs of proceses (cP,cPE,cPZ,cPR,cF,cR)
		%
			zero=zeros(1,obj.NrOfProcesses);
            cPE=fcosts.cE*obj.mF;
			cF=fcosts.c*obj.mF0;
            cPZ=fcosts.cZ*obj.mF+rsc.zP;
            CPE=cPE .* obj.ProductExergy;
            CF=cF .* obj.FuelExergy;
            CPZ = cPZ .* obj.ProductExergy;
            if (obj.isWaste)
                cR=fcosts.c*obj.mR;
                cPR=fcosts.cR*obj.mF+cR;
                cP=cPE+cPZ+cPR;
                CR=cR .* obj.ProductExergy;
                CP=cP .* obj.ProductExergy;
                CPR=cPR .* obj.ProductExergy;
			else
				CP=CPE+CPZ;
				cP=cPE+cPZ;
				cR=zero;
				CR=zero;
				cPR=zero;
				CPR=zero;
            end
			res1=struct('CP',CP,'CPE',CPE,'CPR',CPR,'CPZ',CPZ,'CF',CF,'CR',CR,'Z',rsc.Z);
			res2=struct('cP',cP,'cPE',cPE,'cPR',cPR,'cPZ',cPZ,'cF',cF,'cR',cR);
		end
		
        function res=getProcessICT0(obj,fICT)
		% get the processes ICT given the flows ICT
        %  Input:
		%   fICT - flows ICT
        %  Output:
        %   res - Processes ICT
            tmp=scaleCol(fICT,obj.FlowsExergy);
            [~,iAP]=obj.IncidenceMatrix(obj);
            res=zerotol(divideCol(tmp*iAP',obj.ProductExergy));
		end        
        
        function res=getProcessICT(obj,fICT,rsc)
        % Compute the Process ICT from Flow ICT (Alternative)
        %   Input:
        %       fICT - Flows ICT 
        %       rsc [optional] - Resources Cost
            if nargin==3
                cn=fICT(end,:)*obj.mF0+rsc.zF;
            else
                cn=ones(1,obj.NrOfProcesses);
            end
            ku=cn .* (obj.UnitConsumption-1);
            opIn=fICT(1:end-1,:)*obj.mF+diag(ku);
            if obj.NrOfWastes>0
                tmp=scaleRow(obj.mR,sum(fICT));
                opEx=cSparseRow(obj.dprocess,tmp.mValues);
                res=[opIn+opEx;cn];
            else
                res=[opIn;cn];
            end
        end
    end   
    
    methods(Access=private)
        function res=wasteFlowsTable(obj,wt)
        % return the waste allocation matrix in cSparseRow format
        % Input:
        %	wt - Waste table
            res=[];
            aR=wt.Flows;
            NR=wt.NrOfWastes;
            N=obj.NrOfProcesses;
            pR=zeros(NR,N);
            sol=zeros(1,N);
            kn=sum(obj.mF-obj.mF0);
            for i=1:NR
                switch wt.typeId(i)
                    case cType.WasteAllocation.MANUAL
                        if isempty(find(wt.Values(i,:),1))
                            obj.messageLog(cType.ERROR,'Waste values cannot be zeros');
                            return
                        end
                        sol=wt.Values(i,:);
                        sol(~obj.ActiveProcesses)=0.0;
                    case cType.WasteAllocation.DEFAULT
                        idx=aR(i);
                        tmp=scaleCol(obj.mL(:,idx),obj.FlowsExergy(idx));
                        sol(obj.ps.Resources.processes)=tmp(obj.ps.Resources.flows)';
                    case cType.WasteAllocation.IRREVERSIBILITY
                        idx=aR(i);
                        sol=scaleRow(obj.mP*obj.mL(:,idx),kn);
                    otherwise
                        obj.messageLog(cType.ERROR,'Waste type %d allocation NOT Allowed',wt.Type(i));
                        return
                end
                pR(i,:)=sol/sum(sol);
            end
            wt.updateValues(pR)
            pR=scaleRow(pR,1-wt.RecycleRatio);
            tR=scaleRow(pR,obj.FlowsExergy(aR));
            bR=divideCol(tR,obj.ProductExergy);
            res=cSparseRow(aR,bR,obj.NrOfFlows);
        end
            
        function cm=getMinCost(obj,rsc)
        % Calculate the minimun cost of the flows
        %  Input:
        %   rsc - [optional] cost of external resources
            narginchk(1,2);
            M=obj.NrOfFlows;
            if nargin==1
                cm=ones(1,M);
            else
                v0=rsc.c0+rsc.zF*obj.mP;
                cm=v0/(eye(M)-obj.mV-obj.mF0*obj.mP);
            end
        end
    end      
end