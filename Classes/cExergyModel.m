classdef cExergyModel < cResultId
% cExergyModel builds the Flow-Process model
%   It provides the exergy analysis results and the FP table of the system
%
% cExergyModel constructor:
%   obj = cExergyModel(exd)
% 
% cExergyModel properties:
%   NrOfFlows        	 - Number of Flows
%   NrOfProcesses    	 - Number of Processes
%   NrOfStreams          - Number of Streams
%   NrOfWastes       	 - Number of Wastes
%   FlowsExergy      	 - Exergy values of flows
%   ProcessesExergy  	 - Process exergy properties
%   StreamsExergy        - Stream exergy properties
%   FlowProcessTable     - Flow Process Table
%   AdjacencyTable       - SFP Adjacency Table
%   TableFP              - Table FP
%   FuelExergy           - Fuel Exergy
%   ProductExergy        - Product Exergy
%   Irreversibility      - Process Irreversibility
%   UnitConsumption      - Process Unit Consumption
%   Efficiency           - Process Efficiency
%   TotalResources	     - Total Resources
%   FinalProducts        - Final Products
%   TotalIrreversibility - Total Irreversibility
%   TotalUnitConsumption - Total Unit Consumption
%   ActiveProcesses      - Active Processes (not bypassed)
%
% cExergyModel methods:
%  buildResultInfo - Build the cResultInfo object associated to EXERGY_ANALYSIS
%
% See also cExergyCost, cResultId
%
	properties (GetAccess=public, SetAccess=protected)
		NrOfFlows        	  % Number of Flows
		NrOfProcesses    	  % Number of Processes
		NrOfStreams           % Number of Streams
		NrOfWastes       	  % Number of Wastes
		FlowsExergy      	  % Exergy values of flows
		ProcessesExergy  	  % Structure containing the fuel, product of a process
		StreamsExergy    	  % Exergy values of streams
		FlowProcessTable      % Flow Process Table
        AdjacencyTable        % SFP Adjacency Table (sfp)
        TableFP               % Table FP
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
		function obj=cExergyModel(exd)
		% Build an instance of the object	
		% Syntax:
		%   obj = cExergyModel(exd)
		% Input Arguments:
		%   exd - cExergyData object
            if ~isObject(exd,'cExergyData')
				obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(exd));
				return
            end
			M=exd.ps.NrOfFlows;
			% Build Exergy Adjacency tables
			B=exd.FlowsExergy;
			E=exd.StreamsExergy.E;
            ET=exd.StreamsExergy.ET;
			vP=exd.ProcessesExergy.vP;
            vF=exd.ProcessesExergy.vF;
			tbl=exd.ps.AdjacencyMatrix;
			tAE=scaleRow(tbl.AE,B);
			tAS=scaleCol(tbl.AS,B);
			tAF=scaleRow(tbl.AF,E);
            tAP=scaleCol(tbl.AP,E);
			% Demand driven adjacency matrices
			mbF=divideCol(tAF,vP);
			mbF0=divideCol(tAF,vF);
			mbP=divideCol(tAP,ET);
			mS=double(tbl.AS);
			mE=divideCol(tAE,ET);
			% Build the Flow-Process Table
			mgF=mE*mbF;
			mgF0=mE*mbF0;
			tgF=mE*tAF;
			mgP=mbP*mS;
			tgP=mbP*tAS;
			% Build table FP
			if exd.ps.isModelIO
				mgV=sparse(M,M);
				tgV=mgV;
				mgL=eye(M);
				tfp=mgP*tgF;
			else
				mgV=mE*mS;
				tgV=mE*tAS;
				mgL=eye(M)/(eye(M)-mgV);
				tfp=mgP*mgL*tgF;
			end
			% Build the object
			obj.AdjacencyTable=struct('tE',tAE,'tS',tAS,'tF',tAF,'tP',tAP);
			obj.FlowProcessTable=struct('tV',tgV,'tF',tgF,'tP',tgP,'mV',mgV,'mF',mgF,'mF0',mgF0,'mP',mgP,'mL',mgL);
			obj.TableFP=full(tfp);
            obj.ps=exd.ps;
            obj.NrOfFlows=exd.ps.NrOfFlows;
			obj.NrOfProcesses=exd.ps.NrOfProcesses;
			obj.NrOfStreams=exd.ps.NrOfStreams;
			obj.NrOfWastes=exd.ps.NrOfWastes;
			obj.FlowsExergy=B;			
			obj.ProcessesExergy=exd.ProcessesExergy;
			obj.StreamsExergy=exd.StreamsExergy;
            obj.ActiveProcesses=exd.ActiveProcesses;
			obj.DefaultGraph=cType.Tables.TABLE_FP;
			% cResultId properties
			obj.ResultId=cType.ResultId.THERMOECONOMIC_STATE;
            obj.ModelName=obj.ps.ModelName;
            obj.State=exd.State;
		end		       		
    
		function res=get.FuelExergy(obj)
		% get the fuel exergy of processes
			res=cType.EMPTY;
			if obj.status
				res=obj.ProcessesExergy.vF(1:end-1);
			end
		end

		function res=get.ProductExergy(obj)
		% get the product exergy of processes
			res=cType.EMPTY;
			if obj.status
				res=obj.ProcessesExergy.vP(1:end-1);
			end
		end

		function res=get.Irreversibility(obj)
		% get the irreversibility of prcesses
			res=cType.EMPTY;
			if obj.status
				res=obj.ProcessesExergy.vI(1:end-1);
			end
		end

		function res=get.UnitConsumption(obj)
		% get the unit consumption of the processes
			res=cType.EMPTY;
			if obj.status
				res=obj.ProcessesExergy.vK(1:end-1);
			end
        end

        function res=get.Efficiency(obj)
			res=cType.EMPTY;
			if obj.status
            	res=vDivide(obj.ProductExergy,obj.FuelExergy);
			end
        end

		function res=get.TotalResources(obj)
		% Get total exergy of resources
			res=cType.EMPTY;
			if obj.status
				res=obj.ProcessesExergy.vF(end);
			end
		end

		function res=get.FinalProducts(obj)
		% Get total exergy of final products
			res=cType.EMPTY;
			if obj.status
				res=obj.ProcessesExergy.vP(end);
			end
		end

		function res=get.TotalUnitConsumption(obj)
		% Get total unit consumption
			res=cType.EMPTY;
			if obj.status
				res=obj.ProcessesExergy.vK(end);
			end
		end

		function res=get.TotalIrreversibility(obj)
		% Get the total irreversibility of the system
			res=cType.EMPTY;
			if obj.status
				res=obj.ProcessesExergy.vI(end);
			end
        end

        function res=buildResultInfo(obj,fmt)
        % Get the cResultInfo object
		% Syntax:
		%   res = obj.buildResultInfo(fmt)
		% Input Arguments:
		%   fmt - cResultTableBuilder object
		% Output Arguments:
		%   res - cResultInfo associated to EXERGY_ANALYSIS
		%
            res=fmt.getExergyResults(obj);
        end
	end		
end
