classdef (Sealed) cProductiveStructure < cProductiveStructureCheck
% cProductiveStructure provides the information about the productive structure of the plant
% 	Methods:
%   	res=obj.WasteData
%   	res=obj.isModelIO
%   	res=obj.FlowProcessEdges
%   	res=obj.IncidenceMatrix
%   	res=obj.getConfigInfo;
%		id=obj.getProcessId(key)
%		id=obj.getFlowId(key)
% See also cReadProductiveModel
%
	properties (GetAccess=public, SetAccess=private)
		NrOfResources			% Number of resources
		NrOfFinalProducts		% Number of final products
		NrOfSystemOutput        % Number of system output
		AdjacencyMatrix         % Adjacency Matrix containing the productive structure
        FlowStreamEdges         % Flow definition (from,to) for streams
 	    FuelStreams             % Fuel Streams array index
		ProductStreams          % Product Streams array index
		ProductiveProcesses     % Productive Processes
        Waste                   % Waste array structure (flow, stream, process) index
        Resources               % Resources array structure (flow, stream, process)  index
        FinalProducts           % Final Products array structure (flow, stream, process) index
		SystemOutput            % SystemOutput array structure (flow, stream, process) index
        FlowKeys                % Cell array of Flows Names (keys)
        ProcessKeys             % Cell array of Processes Names (keys)
        StreamKeys              % Cell array of Streams Names (keys)
	end
	
	properties (Access=private)
		flowstreams    % flows definition (from,to)
    end
		
	methods
		function obj=cProductiveStructure(data)
        % Constructor of productive structure
		% cfg - readProductiveModel object class
			obj=obj@cProductiveStructureCheck(data);
            if ~obj.isValid
				return
            end
			M=obj.NrOfFlows;
            N1=obj.NrOfProcesses+1;
            NS=obj.NrOfStreams;
			% Build productive structure lists (internal)
			fto=[obj.Flows.to];
			ffrom=[obj.Flows.from];
			pstreams=find(bitget(obj.streamtypes,cType.PRODUCTIVE));
			pprocesses=[obj.Streams(pstreams).process];
			fstreams=setdiff(1:obj.NrOfStreams,pstreams);
			fprocesses=[obj.Streams(fstreams).process];
            % Adjancency Matrix
            mAE=sparse(1:M,fto,true(1,M),M,NS);
			mAS=sparse(ffrom,1:M,true(1,M),NS,M);
			mAF=sparse(fstreams,fprocesses,true(size(fstreams)),NS,N1);
			mAP=sparse(pprocesses,pstreams,true(size(pstreams)),N1,NS);
            obj.AdjacencyMatrix=struct('AE',mAE,'AS',mAS,'AF',mAF,'AP',mAP);
			obj.FuelStreams=fstreams;
			obj.ProductStreams=pstreams;
        end

        function res=get.FlowKeys(obj)
		% Get the Flows keys as cell array
			res={obj.Flows.key};
		end

		function res=get.ProcessKeys(obj)
		% Get the Processes keys as cell array
			res={obj.Processes.key};
		end

		function res=get.StreamKeys(obj)
		% Get the Streams keys as cell array
			res={obj.Streams.key};
        end
		
		function res=get.Waste(obj)
		% Get an array with flows defined as waste.
			res.flows=find(bitget(obj.flowtypes,cType.WASTE));
			res.streams=find(bitget(obj.streamtypes,cType.WASTE));
			res.processes=find(bitget(obj.processtypes,cType.WASTE));
		end
		
		function res=get.Resources(obj)
		% Get a structure with the flows,streams and processes defined as Resources
			res.flows=find(obj.flowtypes==cType.Flow.RESOURCE);
			res.streams=[obj.Flows(res.flows).from];
			ind=[obj.Flows(res.flows).to];
			res.processes=[obj.Streams(ind).process];
		end

		function res=get.ProductiveProcesses(obj)
		% Get a structure with the productive processes
			id=find(obj.processtypes==cType.Process.PRODUCTIVE);
			res.key={obj.Processes(id).key};
            res.id=id;
		end

		function res=get.NrOfResources(obj)
		% Get the number of resources
			res=sum(obj.flowtypes==cType.Flow.RESOURCE);
		end

		function res=get.FinalProducts(obj)
	    % Get a structure with the flows,streams and processes defined as Final Products
			res.flows=find(obj.flowtypes==cType.Flow.OUTPUT);
			res.streams=[obj.Flows(res.flows).to];
			ind=[obj.Flows(res.flows).from];
			res.processes=[obj.Streams(ind).process];
		end

		function res=get.NrOfFinalProducts(obj)
		% Get the number of final product
			res=numel(find(obj.flowtypes==cType.Flow.OUTPUT));
		end

		function res=get.SystemOutput(obj)
		% Get a structure with the flows, streams and processes defined as System Output
            res.flows=[obj.FinalProducts.flows,obj.Waste.flows];
            res.streams=[obj.FinalProducts.streams,obj.Waste.streams];
            res.processes=[obj.FinalProducts.processes,obj.Waste.processes];
        end

		function res=get.NrOfSystemOutput(obj)
		% Get the number of system output
			res=obj.NrOfFinalProducts+obj.NrOfWastes;
		end

        function res=get.FlowStreamEdges(obj)
        % Get a structure array with the stream edges of the flows
            res=struct('from',[obj.Flows.from],'to',[obj.Flows.to]);
        end
		
		function res=WasteData(obj)
        % Get default waste data info
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
				res.wastes=[];
            end			
        end

        function res=isModelIO(obj)
        % Check if the model is Input-Output
            res=isempty(intersect(obj.FlowStreamEdges.from,obj.FlowStreamEdges.to));
        end

        function res=FlowProcessEdges(obj)
        % Get a structure array with the processes edges of the flows
            res=[];
            if ~obj.isValid
                return
            end
            AS=obj.FlowStreamEdges.from; AE=obj.FlowStreamEdges.to;
			res.from=[obj.Streams(AS).process];
            res.to=[obj.Streams(AE).process];
        end

        function res=IncidenceMatrix(obj)
        % Get a structure with the incidence matrices (AF,AP) of the plant
			res=[];
			if ~obj.isValid
				return
			end
            aE=obj.AdjacencyMatrix.AE';
            aS=obj.AdjacencyMatrix.AS;
            aF=obj.AdjacencyMatrix.AF';
            aP=obj.AdjacencyMatrix.AP;
			iAF=aF(1:end-1,:)*(aE-aS);
			iAP=aP(1:end-1,:)*(aS-aE);
            res=struct('iAF',iAF,'iAP',iAP);
        end

		function res=StructuralMatrix(obj)
		% Get the Structural Theory Flows Adjacency table
			x=obj.AdjacencyMatrix;
			mI=eye(obj.NrOfStreams,"logical");
			res=x.AE*(mI+x.AF(:,1:end-1)*x.AP(1:end-1,:))*x.AS;
		end

		function res=ProductiveMatrix(obj)
		% Get the Productive Adjacency Matrix
			x=obj.AdjacencyMatrix;
			N=obj.NrOfProcesses;
			M=obj.NrOfFlows;
			NS=obj.NrOfStreams;
			res=[zeros(NS,NS), x.AS, x.AF(:,1:end-1);...
				 x.AE, zeros(M,M), zeros(M,N);...
				 x.AP(1:end-1,:), zeros(N,M), zeros(N,N)];
		end

		function res=getConfigInfo(obj)
		% Get the Productive Structure Config info
			res=struct('NrOfFlows',obj.NrOfFlows,'NrOfProcesses',obj.NrOfProcesses,...
						'NrOfStreams',obj.NrOfStreams,'NrOfWastes',obj.NrOfWastes,'Flows',obj.Flows,...
						'Processes',obj.Processes,'Streams',obj.Streams);	
		end

		function id=getProcessId(obj,key)
        % Get the Id of a process given its key 
        %  Input:
        %   key - process key
			id=cType.EMPTY;
			if ischar(key)
				id=obj.pDict.getIndex(key);
			elseif iscell(key)
				try
					id=cellfun(@(x) obj.getProcessId(x),key);
				catch
					return
				end
			end
		end
		
		function id=getFlowId(obj,key)
        % Get the Id of a flow given its key
        %  Input:
        %   key - flow key
			id=cType.EMPTY;
			if ischar(key)
				id=obj.fDict.getIndex(key);
			elseif iscell(key)
				try
					id=cellfun(@(x) obj.getFlowId(x),key);
				catch
					return
				end
			end
        end
    end
end