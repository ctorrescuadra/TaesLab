classdef (Sealed) cExergyCost < cExergyModel
% cFlowExergyCost Calculates exergy cost of flows and processes, using Flow-Process approach
% 	Methods:
%		obj=cFlowExergyCost(rex,wt)
%		obj.setWasteOperators(wt)
%   	res=obj.getFlowsCost
%   	res=obj.getFlowsCost(rsc)
%		res=obj.getFlowsICT(rsc)               
%		[cost,ucost]=obj.getProcessCost(fcosts,rsc)
%		res=obj.getProcessICT(fICT,rsc)
%       res=obj.getStreamsCost(fcost,rsc);
% See also cExergyModel
	properties(GetAccess=public,SetAccess=private)
        AdjacencyMatrix     % Structure containing the adjacency submatrices
        IncidenceMatrix     % Structure containing the incidence matrices including waste
		mG	                % Characteristic matrix
		WasteTable          % Waste Table Info
		opB                 % Production Operator
		opR                 % Waste Operator
        isWaste=false       % Waste is well defined
	end

	properties (Access=private)
		mV,mF,mF0,mP,mH,mR  % Extended table matrices
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
            NS=obj.NrOfStreams;
			tbl=obj.FlowProcessTable;
			obj.mV=tbl.mV;
			obj.mF=tbl.mF(:,1:N);
			obj.mF0=tbl.mF0(:,1:N);
			obj.mP=tbl.mP(1:N,:);
			obj.c0=tbl.mP(end,:);
			obj.mG=obj.mF * obj.mP + obj.mV;
			obj.opB=zerotol(inv(full(eye(M)-obj.mG)));
            spm=obj.StreamProcessTable;
            obj.mH=spm.mE*(eye(NS)+spm.mF(:,1:end-1)*spm.mP(1:end-1,:));
            if (nargin==2) && isa(wd,'cWasteData')
                obj.setWasteOperators(wd);
            end
            obj.DefaultGraph=cType.Tables.PROCESS_ICT;
		end

        function res=get.AdjacencyMatrix(obj)
        % Get Adjancency Matrix including waste Allocation
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
                aux=wft.mValues*obj.mP*obj.opB;
                obj.mR=wft;
                obj.opR=cSparseRow(aR,(eye(NR)-aux(:,aR))\aux);
                obj.isWaste=true;
            end
        end
    
        function res=getFlowsCost(obj,rsc)
        % Get the generalized exergy cost of flows
        %  Input:
        %   rsc - cost of external resources
        %  Output
        %   res - cost of flows structure (B,CE,CZ,CR,C,cE,cZ,cR,c)
            czoption=(nargin==2);
            zero=zeros(1,obj.NrOfFlows);	
            B=obj.FlowsExergy;
            if czoption
                cE=rsc.c0 * obj.opB;
                CE=cE .* B;
                cZ=rsc.zP * obj.mP*obj.opB;  
                CZ=cZ .* B;
            else
                cE=obj.c0 * obj.opB;
                CE=cE .* B;
                cZ=zero;
                CZ=zero;
            end
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
            if czoption
                res=struct('B',B,'CE',CE,'CZ',CZ,'CR',CR,'C',C,'cE',cE,'cZ',cZ,'cR',cR,'c',c);
            else
                res=struct('B',B,'CE',CE,'CR',CR,'C',C,'cE',cE,'cR',cR,'c',c);    	
            end
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
                cn=cm*obj.mF0;
            else
                cm=obj.getMinCost(rsc);
                cn=cm*obj.mF0+rsc.zF;
            end
            ce=cn .* (obj.UnitConsumption-1);
            fict=[scaleRow(obj.mP*obj.opB,ce);cm];
            if obj.isWaste
                cmR=scaleRow(obj.opR,sum(fict));
                rict=cSparseRow(obj.dprocess,cmR.mValues,obj.NrOfProcesses+1);
                res=fict+rict;
            else
                res=fict;
            end
        end
        
		function [res1,res2]=getProcessCost(obj,fcosts,rsc)
		% Get the cost related to processes.
		%  Inputs:
		%   fcosts - structure containing the flows costs
		%	cz - [optional] cost of external resources
		%  Output:
		%   res1 - exergy costs of processes (CP,CPE,CPZ,CPR,CF,CR,Z)
		%   res2 - unit exergy costs of proceses (cP,cPE,cPZ,cPR,cF,cR)
		%
            czoption=(nargin==3);
			zero=zeros(1,obj.NrOfProcesses);
            cPE=obj.processUnitCost(fcosts.cE);
            CPE=cPE .* obj.ProductExergy;
			cF=fcosts.c*obj.mF0;
            CF=cF .* obj.FuelExergy;
            if obj.isWaste
                cR=fcosts.c*obj.mR;
                CR=cR .* obj.ProductExergy;
                cPR=obj.processUnitCost(fcosts.cR,cR);
                CPR=cPR .* obj.ProductExergy;
			else
				cR=zero;
				CR=zero;
				cPR=zero;
				CPR=zero;
            end
            if czoption
                cPZ=obj.processUnitCost(fcosts.cZ,rsc.zP);
                CPZ = cPZ .* obj.ProductExergy;
                cP=cPE+cPZ+cPR;
                CP=CPE+CPZ+CPR;
			    res1=struct('CP',CP,'CPE',CPE,'CPR',CPR,'CPZ',CPZ,'CF',CF,'CR',CR,'Z',rsc.Z);
			    res2=struct('cP',cP,'cPE',cPE,'cPR',cPR,'cPZ',cPZ,'cF',cF,'cR',cR);
            else
                cP=cPE+cPR;
                CP=CPE+CPR;
                res1=struct('CP',CP,'CPE',CPE,'CPR',CPR,'CF',CF,'CR',CR);
                res2=struct('cP',cP,'cPE',cPE,'cPR',cPR,'cF',cF,'cR',cR,'k',obj.UnitConsumption);
            end
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
            ce=cn .* (obj.UnitConsumption-1);
            opIn=fICT(1:end-1,:)*obj.mF+diag(ce);
            if obj.isWaste
                tmp=scaleRow(obj.mR,sum(fICT));
                opEx=cSparseRow(obj.dprocess,tmp.mValues);
                res=[opIn+opEx;cn];
            else
                res=[opIn;cn];
            end
        end

        function scost=getStreamsCost(obj,ucost,rsc)
            czoption=(nargin==3);
            tbl=obj.StreamProcessTable;
            zero=zeros(1,obj.NrOfStreams);
            E=obj.StreamsExergy.ET;
            if obj.isWaste
                cbR=ucost.c*obj.mR*tbl.mP(1:end-1,:);
			    cR=obj.streamsUnitCost(ucost.cR,cbR);
			    CR=cR.*E;
            else
                cR=zero;
                CR=zero;
            end
			if czoption
                zps=rsc.zP*tbl.mP(1:end-1,:);
                cE=obj.streamsUnitCost(ucost.cE,rsc.cs0);
                CE=cE.*E;
				cZ=obj.streamsUnitCost(ucost.cZ,zps);
				CZ=cZ.*E;
				c=cE+cZ+cR;
				C=CE+CZ+CR;
				scost=struct('E',E,'CE',CE,'CZ',CZ,'CR',CR,'C',C,'cE',cE,'cZ',cZ,'cR',cR,'c',c);
			else
                cse=tbl.mP(end,:);
                cE=obj.streamsUnitCost(ucost.cE,cse);
                CE=cE.*E;
				c=cE+cR;
				C=CE+CR;
				scost=struct('E',E,'CE',CE,'CR',CR,'C',C,'cE',cE,'cR',cR,'c',c);
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
                        tmp=scaleCol(obj.opB(:,idx),obj.FlowsExergy(idx));
                        sol(obj.ps.Resources.processes)=tmp(obj.ps.Resources.flows)';
                    case cType.WasteAllocation.IRREVERSIBILITY
                        idx=aR(i);
                        sol=scaleRow(obj.mP*obj.opB(:,idx),kn);
                    otherwise
                        obj.messageLog(cType.ERROR,'Waste type %s allocation NOT Allowed',wt.Type{i});
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

        function res=streamsUnitCost(obj,ucost,c0)
        % Calculate the streams cost given the flows cost
        % Input:
        %   ucost - Unit cost of flows
        %   c0 - [optional] Resources cost
            if nargin==3
                res=c0+ucost*obj.mH;
            else
                res=ucost*obj.mH;
            end
        end

        function res=processUnitCost(obj,ucost,c0)
        % Calculate the processes cost given the flows cost
        % Input:
        %   ucost - Unit cost of flows
        %   c0 - [optional] Resources cost
            if nargin==3
                res=c0+ucost*obj.mF;
            else
                res=ucost*obj.mF;
            end
        end
    end      
end