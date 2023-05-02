classdef cExergyModel < cResultId
% cExergyModel Container class of the exergy flows, streams and processes values
%  	It contains the Adjacency table of the productive structure of a state of the plant
% Methods:  
%	res=obj.getStreamProcessTable
%	res=obj.getFlowProcessTable
%   res=obj.getStreamsCost(fcost,pcost,rsc)
% See also cExergyCostModel, cProcessModel
%
	properties (GetAccess=public, SetAccess=protected)
		NrOfFlows        	  % Number of Flows
		NrOfProcesses    	  % Number of Processes
		NrOfStreams           % Number of Streams
		NrOfWastes       	  % Number of Wastes
		FlowsExergy      	  % Exergy values of flows
		ProcessesExergy  	  % Structure containing the fuel, product of a process
		StreamsExergy    	  % Exergy values of streams
		AdjacencyTable   	  % Adjacency table of the productive structure with exergy values
		FuelExergy            % Fuel Exergy
		ProductExergy         % Product Exergy
		Irreversibility       % Irreversibility
		UnitConsumption       % Unit Consumption
        Efficiency            % Process Efficiency
		TotalResources		  % Total Resources
		FinalProducts         % Final Products
		TotalIrreversibility  % Total Irreversibility
		TotalUnitConsumption  % Total Unit Consumption
        ActiveProcesses       % Active Processes (not bypass)
	    ps					  % Productive Structure
    end
    
	methods
		function obj=cExergyModel(rex)
		% Constructor of the exergy container.	
		% rex - cReadExergy object
			obj=obj@cResultId(cType.ResultId.THERMOECONOMIC_STATE);
            if ~isa(rex,'cReadExergy') || ~rex.isValid
				obj.messageLog(cType.ERROR,'Input parameter is not a valid cReadExergy object');
				return
            end
			obj.status=cType.VALID;
			obj.NrOfFlows=rex.ps.NrOfFlows;
			obj.NrOfProcesses=rex.ps.NrOfProcesses;
			obj.NrOfStreams=rex.ps.NrOfStreams;
			obj.NrOfWastes=rex.ps.NrOfWastes;
			% build Adjacency matrices
			B=rex.FlowsExergy;
			E=rex.StreamsExergy.E;
			tbl=rex.ps.AdjacencyMatrix;
			mAE=scaleRow(tbl.AE,B);
			mAS=scaleCol(tbl.AS,B);
			mAF=scaleRow(tbl.AF,E);
            mAP=scaleCol(tbl.AP,E);
			% build the object
            obj.ps=rex.ps;
			obj.FlowsExergy=B;			
			obj.ProcessesExergy=rex.ProcessesExergy;
			obj.StreamsExergy=rex.StreamsExergy;
            obj.ActiveProcesses=rex.ActiveProcesses;
            obj.AdjacencyTable=struct('mAE',mAE,'mAS',mAS,'mAF',mAF,'mAP',mAP);
		end		       		
    
		function res=get.FuelExergy(obj)
		% get the fuel exergy of processes
			res=obj.ProcessesExergy.vF(1:end-1);
		end

		function res=get.ProductExergy(obj)
		% get the product exergy of processes
			res=obj.ProcessesExergy.vP(1:end-1);
		end

		function res=get.Irreversibility(obj)
		% get the irreversibility of prcesses
			res=obj.ProcessesExergy.vI(1:end-1);
		end

		function res=get.UnitConsumption(obj)
		% get the unit consumption of the processes
			res=obj.ProcessesExergy.vK(1:end-1);
        end

        function res=get.Efficiency(obj)
            res= vDivide(obj.ProductExergy,obj.FuelExergy);
        end

		function res=get.TotalResources(obj)
		% Get total exergy of resources
			res=obj.ProcessesExergy.vF(end);
		end

		function res=get.FinalProducts(obj)
		% Get total exergy of final products
			res=obj.ProcessesExergy.vP(end);
		end

		function res=get.TotalUnitConsumption(obj)
		% Get total unit consumption
			res=obj.ProcessesExergy.vK(end);
		end

		function res=get.TotalIrreversibility(obj)
		% get the total irreversibility of the system
			res=obj.ProcessesExergy.vI(end);
		end
		
		function res=getStreamProcessTable(obj)
		% get the Stream-Procces table
			fs=obj.ps.FlowStreamEdges;
			tV=sparse(fs.from,fs.to,obj.FlowsExergy,obj.NrOfStreams,obj.NrOfStreams,obj.NrOfFlows);
			res=struct('tF',obj.AdjacencyTable.mAF,'tP',obj.AdjacencyTable.mAP,'tV',tV);
		end
			
		function res=getFlowProcessTable(obj)
		% get the Flow-Process table
			mgS=divideRow(obj.AdjacencyTable.mAS,obj.StreamsExergy.ET);
			mgF=divideRow(obj.AdjacencyTable.mAF,obj.StreamsExergy.ET);
			tF=obj.AdjacencyTable.mAE*mgF;
			tP=obj.AdjacencyTable.mAP*mgS;
			if obj.ps.isModelIO
				tV=sparse(obj.NrOfFlows,obj.NrOfFlows); % zero matrix
			else
				tV=obj.AdjacencyTable.mAE*mgS;
			end
			res=struct('tF',tF,'tP',tP,'tV',tV);
        end

		function res=getAdjacencyTable(obj)
		% Get the adjacency table values
			x=obj.AdjacencyTable;
			fnodes=obj.ps.FlowKeys;
			snodes=obj.ps.StreamKeys;
			pnodes=obj.ps.ProcessKeys;
			[idx,jdx,eval]=find(x.mAE);
			esource=fnodes(idx);
			etarget=snodes(jdx);
			[idx,jdx,sval]=find(x.mAS);
			ssource=snodes(idx);
			starget=fnodes(jdx);
			[idx,jdx,fval]=find(x.mAF(:,1:end-1));
			fsource=snodes(idx);
			ftarget=pnodes(jdx);
			[idx,jdx,pval]=find(x.mAP(1:end-1,:));
			psource=pnodes(idx);
			ptarget=snodes(jdx);
			source=[esource,ssource,fsource,psource];
			target=[etarget,starget,ftarget,ptarget];
			values=[eval;sval;fval;pval];
			res=[{'Source','Target','Values'};[source',target',num2cell(values)]];
		end
	
		function res=getStreamsCost(obj,fcosts,pcosts,rsc)
		% Get the cost of the streams as function of flows and process costs.
			czoption=(nargin==4);
			E=obj.StreamsExergy.ET;
			tmp=divideCol(obj.AdjacencyTable.mAP,E);
			if czoption
				cs0=rsc.cs0;
			else
				cs0=tmp(end,:);
			end
			mP=tmp(1:end-1,:);
			mE=divideCol(obj.AdjacencyTable.mAE,E);
			cE=cs0+fcosts.cE*mE+pcosts.cPE*mP;
			CE= cE .* E;
			cR=fcosts.cR*mE + pcosts.cPR*mP;
			CR=cR .* E;
			if czoption
				cZ = fcosts.cZ*mE+pcosts.cPZ*mP;
				c = cE + cR + cZ;
				CZ = cZ .* E;
				C = c .* E;
				res=struct('E',E,'CE',CE,'CZ',CZ,'CR',CR,'C',C,'cE',cE,'cZ',cZ,'cR',cR,'c',c);
			else
				c = cE + cR;
				C = c .* E;
				res=struct('E',E,'CE',CE,'CR',CR,'C',C,'cE',cE,'cR',cR,'c',c);
			end
		end
	end		
end