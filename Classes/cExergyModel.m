classdef cExergyModel < cResultId
%cExergyModel Builds the Flow-Process exergy model
%   It provides the exergy analysis results and the FP table of a state of the plant
%
%   cExergyModel constructor:
%     obj = cExergyModel(exd)
% 
%   cExergyModel properties:
%     NrOfFlows        	   - Number of Flows
%     NrOfProcesses    	   - Number of Processes
%     NrOfStreams          - Number of Streams
%     NrOfWastes       	   - Number of Wastes
%     FlowsExergy      	   - Exergy values of flows
%     ProcessesExergy  	   - Process exergy properties
%     StreamsExergy        - Stream exergy properties
%     FlowProcessModel     - Flow Process Model matrices
%     AdjacencyTable       - SFP Adjacency Table
%     TableFP              - Table FP
%     FuelExergy           - Fuel Exergy
%     ProductExergy        - Product Exergy
%     Irreversibility      - Process Irreversibility
%     UnitConsumption      - Process Unit Consumption
%     Efficiency           - Process Efficiency
%     TotalResources	   - Total Resources Exergy
%     FinalProducts        - Final Products Exergy
%     TotalIrreversibility - Total Irreversibility
%     TotalUnitConsumption - Total Unit Consumption
%     ActiveProcesses      - Active Processes Array (not bypassed)
%
%   cExergyModel methods:
%     buildResultInfo - Build the cResultInfo object associated to EXERGY_ANALYSIS
%     TotalOutput     - Get the total exergy output the system
%     FlowProcessTable - Get the Flow-Process Table
%     InternalIrreversibility - Get the total internal irreversibilities
%     ExternalIrreversibility - Get the total external irreversibilities
%
%   See also cExergyCost, cResultId
%
	properties (GetAccess=public, SetAccess=protected)
		NrOfFlows        	  % Number of Flows
		NrOfProcesses    	  % Number of Processes
		NrOfStreams           % Number of Streams
		NrOfWastes       	  % Number of Wastes
		FlowsExergy      	  % Exergy values of flows
		ProcessesExergy  	  % Structure containing the fuel, product of a process
		StreamsExergy    	  % Exergy values of streams
		FlowProcessModel      % Flow Process Model matrices
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
		%cExergyModel - Create an instance of the class	
		%   Syntax:
		%     obj = cExergyModel(exd)
		%   Input Arguments:
		%     exd - cExergyData object
		%
            if ~isObject(exd,'cExergyData')
				obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(exd));
				return
            end
			M=exd.ps.NrOfFlows;
			B=exd.FlowsExergy;
			vF=exd.ProcessesExergy.vF;
			vF(end)=sum(B(exd.ps.SystemOutputFlows));
			% Build Exergy Adjacency Tables
			tbl=exd.AdjacencyTable;
			mat=exd.AdjacencyMatrix;
			% Demand Driven Adjacency Matrices
			AF0=divideCol(tbl.AF,vF);
			% Build the Flow-Process Table
			mgF=mat.AE*mat.AF;
			mgF0=mat.AE*AF0;
			tgF=mat.AE*tbl.AF;
			mgP=mat.AP*mat.AS;
			% Build table FP
			if exd.ps.isModelIO
				mgV=sparse(M,M);
				mgL=eye(M);
				tfp=mgP*tgF;
			else
				mgV=mat.AE*mat.AS;
				mgL=eye(M)/(eye(M)-mgV);
				tfp=mgP*mgL*tgF;
			end
			% Build the object
			obj.FlowProcessModel=struct('mV',mgV,'mF',mgF,'mF0',mgF0,'mP',mgP,'mL',mgL);
			obj.TableFP=full(tfp);
            obj.ps=exd.ps;
            obj.NrOfFlows=exd.ps.NrOfFlows;
			obj.NrOfProcesses=exd.ps.NrOfProcesses;
			obj.NrOfStreams=exd.ps.NrOfStreams;
			obj.NrOfWastes=exd.ps.NrOfWastes;
			obj.FlowsExergy=exd.FlowsExergy;			
			obj.ProcessesExergy=exd.ProcessesExergy;
			obj.StreamsExergy=exd.StreamsExergy;
			obj.AdjacencyTable=exd.AdjacencyTable;
            obj.ActiveProcesses=exd.ActiveProcesses;
			obj.DefaultGraph=cType.Tables.TABLE_FP;
			% cResultId properties
			obj.ResultId=cType.ResultId.THERMOECONOMIC_STATE;
            obj.ModelName=obj.ps.ModelName;
            obj.State=exd.State;
		end		       		
    
		function res=get.FuelExergy(obj)
		% Get the fuel exergy of processes
			res=cType.EMPTY;
			if obj.status
				res=obj.ProcessesExergy.vF(1:end-1);
			end
		end

		function res=get.ProductExergy(obj)
		% Get the product exergy of processes
			res=cType.EMPTY;
			if obj.status
				res=obj.ProcessesExergy.vP(1:end-1);
			end
		end

		function res=get.Irreversibility(obj)
		% Get the irreversibility of prcesses
			res=cType.EMPTY;
			if obj.status
				res=obj.ProcessesExergy.vI(1:end-1);
			end
		end

		function res=get.UnitConsumption(obj)
		% Get the unit consumption of the processes
			res=cType.EMPTY;
			if obj.status
				res=obj.ProcessesExergy.vK(1:end-1);	
			end
        end

        function res=get.Efficiency(obj)
		% Get the effciency of the processes
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

		function res=TotalOutput(obj)
		%TotalOutput - get the total output exergy
		%   Syntax:
		%     res=obj.TotalOutput
		%
			ind=obj.ps.SystemOutputFlows;
			res=sum(obj.FlowsExergy(ind));
		end

		function res=InternalIrreversibility(obj)
		%InternalIrreversibility - get the total internal irreversibility
		%   Syntax:
		%     res=obj.InternalIrreversibility
		%
			res=sum(obj.Irreversibility);
		end

		function res=ExternalIrreversibility(obj)
		%ExternalIrreversibility - get the total external irreversibility (waste)
		%   Syntax:
		%     res=obj.InternalIrreversibility
		%
			ind=obj.ps.Waste.flows;
			res=sum(obj.FlowsExergy(ind));
        end

        function [res,tbl]=FlowProcessTable(obj)
        %FlowProcessTable - get the Flow-Process table 
        %   Syntax:
        %     res=obj.FlowProcessTable
        %   Output Arguments
        %     res - Structure containg tables tV,tF,tP
		%     tbl - Table in matrix format
        %
            a=obj.FlowProcessModel;
            B=obj.FlowsExergy;
            P=[obj.ProductExergy,obj.TotalResources];
            N=obj.NrOfProcesses+1;
            res.tV=scaleCol(a.mV,B);
            res.tF=scaleCol(a.mF,P);
            res.tP=scaleCol(a.mP,B);
            if nargout==2
                tbl=[res.tV,res.tF;res.tP,zeros(N,N)];
            end
        end

        function res=buildResultInfo(obj,fmt)
        %buildResultInfo - Get the cResultInfo object
		%   Syntax:
		%     res = obj.buildResultInfo(fmt)
		%   Input Arguments:
		%     fmt - cResultTableBuilder object
		%   Output Arguments:
		%     res - cResultInfo associated to EXERGY_ANALYSIS
		%
            res=fmt.getExergyResults(obj);
        end
    end
end
