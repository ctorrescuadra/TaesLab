classdef cExergyModel < cResultId
% cExergyModel Container class of the exergy flows, streams and processes values
%  	It contains the Adjacency Table of the productive structure of a state of the plant
%   and the FlowProcess and StreamProcess matrices models
% See also cExergyCost
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
        StreamProcessTable    % Stream Process Table
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
		function obj=cExergyModel(rex)
		% Constructor of the exergy container.	
		% rex - cExergyData object
			obj=obj@cResultId(cType.ResultId.THERMOECONOMIC_STATE);
            if ~isa(rex,'cExergyData') || ~rex.isValid
				obj.messageLog(cType.ERROR,'Input parameter is not a valid cExergyData object');
				return
            end
			obj.status=cType.VALID;
			M=rex.ps.NrOfFlows;
			NS=rex.ps.NrOfStreams;
			% Build Exergy Adjacency tables
			B=rex.FlowsExergy;
			E=rex.StreamsExergy.E;
            ET=rex.StreamsExergy.ET;
			vP=rex.ProcessesExergy.vP;
            vF=rex.ProcessesExergy.vF;
			tbl=rex.ps.AdjacencyMatrix;
			tAE=scaleRow(tbl.AE,B);
			tAS=scaleCol(tbl.AS,B);
			tAF=scaleRow(tbl.AF,E);
            tAP=scaleCol(tbl.AP,E);
			% Build the Stream-Process Table
			mbF=divideCol(tAF,vP);
			mbF0=divideCol(tAF,vF);
			mbP=divideCol(tAP,ET);
			mS=double(tbl.AS);
			mE=divideCol(tAE,ET);
			% Build the Flow-Process Table
			mgV=mE*mS;
			tgV=scaleCol(mgV,B);
			mgF=mE*mbF;
			mgF0=mE*mbF0;
			tgF=scaleCol(mgF,vP);
			mgP=mbP*mS;
			tgP=scaleCol(mgP,B);
			% Build table FP
			if rex.ps.isModelIO
				mgL=eye(M);
				mbL=eye(NS)+mS*mE;
				tfp=mgP*tgF;
			else
				mgL=eye(M)/(eye(M)-mgV);
				mbL=eye(NS)+mS*mgL*mE;
				tfp=mgP*mgL*tgF;
			end
			% build the object
			obj.StreamProcessTable=struct('tE',tAE,'tS',tAS,'tF',tAF,'tP',tAP,'mE',mE,'mS',mS,'mF',mbF,'mF0',mbF0,'mP',mbP,'mL',mbL);
			obj.FlowProcessTable=struct('tV',tgV,'tF',tgF,'tP',tgP,'mV',mgV,'mF',mgF,'mF0',mgF0,'mP',mgP,'mL',mgL);
			obj.TableFP=full(tfp);
            obj.ps=rex.ps;
            obj.NrOfFlows=rex.ps.NrOfFlows;
			obj.NrOfProcesses=rex.ps.NrOfProcesses;
			obj.NrOfStreams=rex.ps.NrOfStreams;
			obj.NrOfWastes=rex.ps.NrOfWastes;
			obj.FlowsExergy=B;			
			obj.ProcessesExergy=rex.ProcessesExergy;
			obj.StreamsExergy=rex.StreamsExergy;
            obj.ActiveProcesses=rex.ActiveProcesses;
			obj.DefaultGraph=cType.Tables.TABLE_FP;
            obj.ModelName=obj.ps.ModelName;
            obj.State=rex.State;
		end		       		
    
		function res=get.FuelExergy(obj)
		% get the fuel exergy of processes
			res=[];
			if obj.isValid
				res=obj.ProcessesExergy.vF(1:end-1);
			end
		end

		function res=get.ProductExergy(obj)
		% get the product exergy of processes
			res=[];
			if obj.isValid
				res=obj.ProcessesExergy.vP(1:end-1);
			end
		end

		function res=get.Irreversibility(obj)
		% get the irreversibility of prcesses
			res=[];
			if obj.isValid
				res=obj.ProcessesExergy.vI(1:end-1);
			end
		end

		function res=get.UnitConsumption(obj)
		% get the unit consumption of the processes
			res=[];
			if obj.isValid
				res=obj.ProcessesExergy.vK(1:end-1);
			end
        end

        function res=get.Efficiency(obj)
			res=[];
			if obj.isValid
            	res=vDivide(obj.ProductExergy,obj.FuelExergy);
			end
        end

		function res=get.TotalResources(obj)
		% Get total exergy of resources
			res=[];
			if obj.isValid
				res=obj.ProcessesExergy.vF(end);
			end
		end

		function res=get.FinalProducts(obj)
		% Get total exergy of final products
			res=[];
			if obj.isValid
				res=obj.ProcessesExergy.vP(end);
			end
		end

		function res=get.TotalUnitConsumption(obj)
		% Get total unit consumption
			res=[];
			if obj.isValid
				res=obj.ProcessesExergy.vK(end);
			end
		end

		function res=get.TotalIrreversibility(obj)
		% Get the total irreversibility of the system
			res=[];
			if obj.isValid
				res=obj.ProcessesExergy.vI(end);
			end
        end

        function res=getResultInfo(obj,fmt)
        % Get the cResultInfo object
            res=fmt.getExergyResults(obj);
        end
	end		
end
