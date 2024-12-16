classdef (Sealed) cProductiveStructure < cProductiveStructureCheck
% cProductiveStructure - provides the information about the productive structure of the plant
%
% cProductiveStructureProperties
%   NrOfResources	   - Number of resources
%   NrOfFinalProducts  - Number of final products
%   NrOfSystemOutput   - Number of system output
%   AdjacencyMatrix    - Adjacency Matrix containing the productive structure
%   Waste              - Waste array structure (flow, stream, process) index
%   Resources          - Resources array structure (flow, stream, process)  index
%   FinalProducts      - Final Products array structure (flow, stream, process) index
%   SystemOutput       - System Output array structure (flow, stream, process) index
%   FlowKeys           - Cell array of Flows Names (keys)
%   ProcessKeys        - Cell array of Processes Names (keys)
%   StreamKeys         - Cell array of Streams Names (keys)
%   FlowEdges          - Struct (from,to) of flow edges
%
% cProductiveStructure Methods:
%   buildResultInfo   - Build the cResultInfo object for ProductiveStructure
%   WasteData         - Get default waste data
%   isModelIO         - Check if model is Input-Output
%   IncidenceMatrix   - Get the incidence matrix
%   StructuralMatrix  - Get the structura matrix
%   ProductiveMatrix  - Get the productive matrix
%   FlowProcessMatrix - Get the fuel-process matrix
%   getWasteFlows     - Get the waste flows names of the model
%   getProcessId      - Get the process Id of a process
%   getFlowId         - Get the the flow Id of a flow 
%   getFlowTypes      - Get the flows (Id) of a flow type
%   getProcessTypes   - Get the processes (Id) of a process type
%   getStreamTypes    - Get the streams (id) of a stream type
%   getFuelStreams    - Get the fuel Streams
%   getProductStreams - Get the product Streams
%
% See also cProductiveStructureCheck
%
	properties (GetAccess=public, SetAccess=private)
		NrOfResources			% Number of resources
		NrOfFinalProducts		% Number of final products
		NrOfSystemOutput        % Number of system output
		AdjacencyMatrix         % Adjacency Matrix containing the productive structure
        Waste                   % Waste array structure (flow, stream, process) index
        Resources               % Resources array structure (flow, stream, process)  index
        FinalProducts           % Final Products array structure (flow, stream, process) index
		SystemOutput            % SystemOutput array structure (flow, stream, process) index
        FlowKeys                % Cell array of Flows Names (keys)
        ProcessKeys             % Cell array of Processes Names (keys)
        StreamKeys              % Cell array of Streams Names (keys)
		FlowEdges               % Struct (from, to) with edge names (keys)
	end
		
	methods
		function obj=cProductiveStructure(data)
        % Constructor of productive structure
		% Input arguments:
		%   data - cModelData object
		%
			obj=obj@cProductiveStructureCheck(data);
            if ~obj.status
				return
            end
			M=obj.NrOfFlows;
            N1=obj.NrOfProcesses+1;
            NS=obj.NrOfStreams;
			% Build productive structure lists (internal)
			fto=[obj.Flows.to];
			ffrom=[obj.Flows.from];
			pstreams=obj.getProductStreams;
			pprocesses=[obj.Streams(pstreams).process];
			fstreams=obj.getFuelStreams;
			fprocesses=[obj.Streams(fstreams).process];
            % Adjancency Matrix
            mAE=sparse(1:M,fto,true(1,M),M,NS);
			mAS=sparse(ffrom,1:M,true(1,M),NS,M);
			mAF=sparse(fstreams,fprocesses,true(size(fstreams)),NS,N1);
			mAP=sparse(pprocesses,pstreams,true(size(pstreams)),N1,NS);
            obj.AdjacencyMatrix=struct('AE',mAE,'AS',mAS,'AF',mAF,'AP',mAP);
        end

        function res=get.FlowKeys(obj)
		% Get the Flows keys as cell array
			res=cType.EMPTY_CELL;
			if obj.status
				res={obj.Flows.key};
			end
		end

		function res=get.ProcessKeys(obj)
		% Get the Processes keys as cell array
			res=cType.EMPTY_CELL;
			if obj.status
				res={obj.Processes.key};
			end
		end

		function res=get.StreamKeys(obj)
		% Get the Streams keys as cell array
			res=cType.EMPTY_CELL;
			if obj.status
				res={obj.Streams.key};
			end
        end
		
		function res=get.Waste(obj)
		% Get an array with flows defined as waste.
			res=cType.EMPTY;
			if obj.status
				res.flows=getFlowTypes(obj,cType.Flow.WASTE);
				res.streams=[obj.Flows(res.flows).from];
				res.processes=[obj.Streams(res.streams).process];
			end
		end
		
		function res=get.Resources(obj)
		% Get a structure with the flows,streams and processes defined as Resources
			res=cType.EMPTY;
			if obj.status
				res.flows=getFlowTypes(obj,cType.Flow.RESOURCE);
				res.streams=[obj.Flows(res.flows).from];
				ind=[obj.Flows(res.flows).to];
				res.processes=[obj.Streams(ind).process];
			end
		end

		function res=get.NrOfResources(obj)
		% Get the number of resources
			res=0;
			if obj.status
				flowtypes=[obj.Flows.typeId];
				res=sum(flowtypes==cType.Flow.RESOURCE);
			end
		end

		function res=get.FinalProducts(obj)
	    % Get a structure with the flows,streams and processes defined as Final Products
			res=cType.EMPTY;
			if obj.status
				res.flows=getFlowTypes(obj,cType.Flow.OUTPUT);
				res.streams=[obj.Flows(res.flows).to];
				ind=[obj.Flows(res.flows).from];
				res.processes=[obj.Streams(ind).process];
			end
		end

		function res=get.NrOfFinalProducts(obj)
		% Get the number of final product
			res=0;
			if obj.status
				flowtypes=[obj.Flows.typeId];
				res=sum(flowtypes==cType.Flow.OUTPUT);
			end
		end

		function res=get.SystemOutput(obj)
		% Get a structure with the flows, streams and processes defined as System Output
			res=cType.EMPTY;
			if obj.status
            	res.flows=[obj.FinalProducts.flows,obj.Waste.flows];
            	res.streams=[obj.FinalProducts.streams,obj.Waste.streams];
            	res.processes=[obj.FinalProducts.processes,obj.Waste.processes];
			end
        end

		function res=get.NrOfSystemOutput(obj)
		% Get the number of system output
			res=0;
			if obj.status
				res=obj.NrOfFinalProducts+obj.NrOfWastes;
			end
		end

		function res=get.FlowEdges(obj)
		% Get a structure array with the stream edges of the flows
			res=cType.EMPTY;
			if ~obj.status
				return
			end
			from=[obj.Flows.from];
			to=[obj.Flows.to];
			res=struct('from',obj.StreamKeys(from),'to',obj.StreamKeys(to));
			end

		function res=buildResultInfo(obj,fmt)
		% Build the cResultInfo object for PRODUCTIVE_STRUCTURE
		% Syntax:
		%   res=obj.buildResultInfo(fmt)
		% Input Argument:
		%   fmt - cFormatData object
		% Output Argument
		%   res - cResultInfo object
			res=fmt.getProductiveStructure(obj);
        end
		
		function res=WasteData(obj)
        % Get default waste data info
		% Syntax:
		%   res=obj.WasteData
		% Output Argument:
		%   res - Waste data info structure
			NR=obj.NrOfWastes;
            if NR>0
				wastes=cell(NR,1);
				for i=1:NR
					wastes{i}.flow=obj.Flows(obj.Waste.flows(i)).key;
					wastes{i}.type='DEFAULT';
                	wastes{i}.recycle=0.0;
				end
				res.wastes=cell2mat(wastes);
			else
				res.wastes=cType.EMPTY;
            end			
        end

        function res=isModelIO(obj)
        % Check if the model is Input-Output
		% Syntax:
		%   res=obj.isModelIO
		% Output Argument:
		%   true | false
			from=[obj.Flows.from];
			to=[obj.Flows.to];
            res=isempty(intersect(from,to));
        end

        function [res1,res2]=IncidenceMatrix(obj)
        % Get a structure with the incidence matrices of the plant
		% Syntax:
		%   [res1,res2] = obj.IncidenceMatrix
		% Output Arguments:
		%	if output arguments are 2
		%    res1 - Fuel Incidence Matrix
		%    res2 - Product Incidence matrix
		%   if output argument is 1
		%    res1 - Incidence Matrix 
		%
            aE=obj.AdjacencyMatrix.AE';
            aS=obj.AdjacencyMatrix.AS;
            aF=obj.AdjacencyMatrix.AF';
            aP=obj.AdjacencyMatrix.AP;
			iAF=aF(1:end-1,:)*(aE-aS);
			iAP=aP(1:end-1,:)*(aS-aE);
			if nargout<2
				res1=iAF-iAP;
			else
				res1=iAF; res2=iAP;
			end
        end

		function res=StructuralMatrix(obj)
		% Get the Structural Theory Flows Adjacency Matrix
		% Syntax:
		%   res = obj.StructuralMatrix
		% Output Argument
		%   res - logical matrix
			x=obj.AdjacencyMatrix;
			mI=eye(obj.NrOfStreams,"logical");
			res=x.AE*(mI+x.AF(:,1:end-1)*x.AP(1:end-1,:))*x.AS;
		end

		function res=ProductiveMatrix(obj)
		% Get the Productive Adjacency Matrix (Streams, Flows, Processes)
		% Syntax:
		%   res = obj.ProductiveMatrix
		% Output Argument:
		%   res - logical matrix
			x=obj.AdjacencyMatrix;
			N=obj.NrOfProcesses;
			M=obj.NrOfFlows;
			NS=obj.NrOfStreams;
			res=[zeros(NS,NS), x.AS, x.AF(:,1:end-1);...
				 x.AE, zeros(M,M), zeros(M,N);...
				 x.AP(1:end-1,:), zeros(N,M), zeros(N,N)];
		end

		function res=FlowProcessMatrix(obj)
		% Get the Flow-Process Adjacency Matrix (Flows, Processes)
		% Syntax:
		%   res = obj.FlowProcessMatrix
		% Output Argument:
		%   res - logical matrix
			x=obj.AdjacencyMatrix;
			N=obj.NrOfProcesses;
			res=[x.AE*x.AS,x.AE*x.AF(:,1:end-1);...
			x.AP(1:end-1,:)*x.AS,zeros(N,N)];
		end

		function res=ProcessMatrix(obj)
		% Get the Process Adjacency Matrix (Logical FP table)
		% Syntax:
		%   res = obj.ProcessMatrix
		% Output Argument:
		%   res - logical matrix
			x=obj.AdjacencyMatrix;
			tmp=x.AS*x.AE;
			tc=transitiveClosure(tmp);
			res=x.AP*tc*x.AF;
		end

		function id=getProcessId(obj,key)
        % Get the Id of a process given its key
		% Syntax:
		%   id = obj.getProcessId(key)
        % Input Argument:
        %   key - process key
		% Output Argument
		%   id - Process Id:
			id=0;
			if ischar(key)
				id=obj.pDict.getIndex(key);
			elseif iscell(key)
				try
					id=cellfun(@(x) obj.pDict.getIndex(x),key);
				catch
					return
				end
			end
		end
		
		function id=getFlowId(obj,key)
        % Get the Id of a flow given its key
		% Syntax:
		%   id = obj.getFlowId(key)
        % Input Argument:
        %   key - flow key
		% Output Argument
		%   id - flow Id:
			id=0;
			if ischar(key)
				id=obj.fDict.getIndex(key);
			elseif iscell(key)
				try
					id=cellfun(@(x) obj.fDict.getIndex(x),key);
				catch
					return
				end
			end
        end

		function res=getFlowTypes(obj,typeId)
		% Get the flowId of type typeId
		% Syntax:
		%   res = obj.getFlowTypes(key)
		% Input Arguments:
		%   typeId - Flow type id
		% Output Arguments:
		%   res - Array with the ids of the flows of this type
		%
			flowtypes=[obj.Flows.typeId];
			res=find(flowtypes==typeId);
		end

		function res=getProcessTypes(obj,typeId)
		% Get the process-id of type typeId
		% Syntax:
		%   res = obj.getProcessTypes(key)
		% Input Arguments:
		%   typeId - Process type id
		% Output Arguments:
		%   res - Array with the ids of the processes of this type
		%
			processtypes=[obj.Processes.typeId];
			res=find(processtypes==typeId);
		end

		function res=getStreamTypes(obj,typeId)
		% Get the stream-id of type typeId
		% Syntax:
		%   res = obj.getStreamTypes(key)
		% Input Arguments:
		%   typeId - stream type id
		% Output Arguments:
		%   res - Array with the ids of the processes of this type
		%
			streamtypes=[obj.Streams.typeId];
			res=find(streamtypes==typeId);
		end

		function res=getProductStreams(obj)
		% Get the product streams id (including resources)
		% Syntax:
		%   res = obj.getProductStreams(key)
		% Output Aguments
		%   res - Array with the product streams id
			streamtypes=[obj.Streams.typeId];
			res=find(bitget(streamtypes,cType.PRODUCTIVE));
		end

		function res=getFuelStreams(obj)
		% Get the fuel streams id (including output and wastes)
		% Syntax:
		%   res = obj.getFuelStreams(key)
		% Output Aguments
		%   res - Array with the fuel streams id
			streamtypes=[obj.Streams.typeId];	
			res=find(~bitget(streamtypes,cType.PRODUCTIVE));
		end

		function [E,ET]=flows2Streams(obj,val)
		% Compute the exergy or cost of streams from flow values
		% Syntax:
		%   res = obj.flows2Streams(values)
		% Input Arguments
		%   values - exergy/cost values
		% Output Arguments
		%   E  - exergy/cost of streams
		%   ET - Total exergy of streams
			tbl=obj.AdjacencyMatrix;
            BE=val*tbl.AE;
			BS=val*tbl.AS';
            fstreams=obj.getFuelStreams;
            pstreams=obj.getProductStreams;
			E=zeros(1,obj.NrOfStreams);
			E(fstreams)=zerotol(BE(fstreams)-BS(fstreams));
			E(pstreams)=zerotol(BS(pstreams)-BE(pstreams));
			if nargout==2
				ET=zeros(1,obj.NrOfStreams);
				ET(fstreams)=BE(fstreams);
				ET(pstreams)=BS(pstreams);
			end
		end

    end
end