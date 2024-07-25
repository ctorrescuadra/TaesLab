classdef (Sealed) cProductiveStructure < cProductiveStructureCheck
% cProductiveStructure provides the information about the productive structure of the plant
% 	Methods:
%   	res=obj.WasteData
%   	res=obj.isModelIO
%   	res=obj.FlowProcessEdges
%		res=obj.FlowStreamEdges
%   	res=obj.IncidenceMatrix
%       res=obj.StructuralMatrix
%       res=obj.ProductiveMatrix;
%		res=obj.FlowProcessMatrix;
%		res=obj.getProcessId(key)
%		res=obj.getFlowId(key)
%		res=obj.getFlowTypes(type)
%       res=obj.getProcessTypes(type)
%		res=obj.getStreamTypes(type)
%       res=obj.getProductStreams;
%		res=obj.getFuelStreams;
% See also cReadProductiveModel
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
			res=[];
			if obj.isValid
				res={obj.Flows.key};
			end
		end

		function res=get.ProcessKeys(obj)
		% Get the Processes keys as cell array
			res=[];
			if obj.isValid
				res={obj.Processes.key};
			end
		end

		function res=get.StreamKeys(obj)
		% Get the Streams keys as cell array
			res=[];
			if obj.isValid
				res={obj.Streams.key};
			end
        end
		
		function res=get.Waste(obj)
		% Get an array with flows defined as waste.
			res=[];
			if obj.isValid
				res.flows=getFlowTypes(obj,cType.Flow.WASTE);
				res.streams=[obj.Flows(res.flows).from];
				res.processes=[obj.Streams(res.streams).process];
			end
		end
		
		function res=get.Resources(obj)
		% Get a structure with the flows,streams and processes defined as Resources
			res=[];
			if obj.isValid
				res.flows=getFlowTypes(obj,cType.Flow.RESOURCE);
				res.streams=[obj.Flows(res.flows).from];
				ind=[obj.Flows(res.flows).to];
				res.processes=[obj.Streams(ind).process];
			end
		end

		function res=get.NrOfResources(obj)
		% Get the number of resources
			res=0;
			if obj.isValid
				flowtypes=[obj.Flows.typeId];
				res=sum(flowtypes==cType.Flow.RESOURCE);
			end
		end

		function res=get.FinalProducts(obj)
	    % Get a structure with the flows,streams and processes defined as Final Products
			res=[];
			if obj.isValid
				res.flows=getFlowTypes(obj,cType.Flow.OUTPUT);
				res.streams=[obj.Flows(res.flows).to];
				ind=[obj.Flows(res.flows).from];
				res.processes=[obj.Streams(ind).process];
			end
		end

		function res=get.NrOfFinalProducts(obj)
		% Get the number of final product
			res=0;
			if obj.isValid
				flowtypes=[obj.Flows.typeId];
				res=sum(flowtypes==cType.Flow.OUTPUT);
			end
		end

		function res=get.SystemOutput(obj)
		% Get a structure with the flows, streams and processes defined as System Output
			res=[];
			if obj.isValid
            	res.flows=[obj.FinalProducts.flows,obj.Waste.flows];
            	res.streams=[obj.FinalProducts.streams,obj.Waste.streams];
            	res.processes=[obj.FinalProducts.processes,obj.Waste.processes];
			end
        end

		function res=get.NrOfSystemOutput(obj)
		% Get the number of system output
			res=0;
			if obj.isValid
				res=obj.NrOfFinalProducts+obj.NrOfWastes;
			end
		end

		function res=getResultInfo(obj,fmt)
		% Get cResultInfo object
			res=fmt.getProductiveStructureResults(obj);
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

		function res=getWasteFlows(obj)
		% Get a cell array with the waste flow keys
			res={};
			if obj.NrOfWastes>0
				id=obj.Waste.flows;
				res=obj.FlowKeys(id);
			end
		end

        function res=FlowStreamEdges(obj)
        % Get a structure array with the stream edges of the flows
			res=[];
			if obj.isValid
            	res=struct('from',[obj.Flows.from],'to',[obj.Flows.to]);
			end
        end

        function res=FlowProcessEdges(obj)
        % Get a structure array with the processes edges of the flows
            res=[];
            if obj.isValid
			    fse=obj.FlowStreamEdges;
			    res.from=[obj.Streams(fse.from).process];
                res.to=[obj.Streams(fse.to).process];
            end
        end

        function res=isModelIO(obj)
        % Check if the model is Input-Output
			fse=obj.FlowStreamEdges;
            res=isempty(intersect(fse.from,fse.to));
        end

        function [res1,res2]=IncidenceMatrix(obj)
        % Get a structure with the incidence matrices (AF,AP) of the plant
			if ~obj.isValid
				return
			end
            aE=obj.AdjacencyMatrix.AE';
            aS=obj.AdjacencyMatrix.AS;
            aF=obj.AdjacencyMatrix.AF';
            aP=obj.AdjacencyMatrix.AP;
			iAF=aF(1:end-1,:)*(aE-aS);
			iAP=aP(1:end-1,:)*(aS-aE);
			if nargout<2
				res1=iAF-iAP;
			else
				res1=iAF;res2=iAP;
			end
        end

		function res=StructuralMatrix(obj)
		% Get the Structural Theory Flows Adjacency Matrix
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

		function res=FlowProcessMatrix(obj)
		% Get the Flow-Process Adjacency Matrix
			x=obj.AdjacencyMatrix;
			N=obj.NrOfProcesses;
			res=[x.AE*x.AS,x.AE*x.AF(:,1:end-1);...
			x.AP(1:end-1,:)*x.AS,zeros(N,N)];
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

		function res=getFlowTypes(obj,typeId)
		% Get the flow-id of type typeId
			flowtypes=[obj.Flows.typeId];
			res=find(flowtypes==typeId);
		end

		function res=getProcessTypes(obj,typeId)
		% Get the process-id of type typeId
			processtypes=[obj.Processes.typeId];
			res=find(processtypes==typeId);
		end

		function res=getStreamTypes(obj,typeId)
		% Get the stream-id of type typeId
			streamtypes=[obj.Streams.typeId];
			res=find(streamtypes==typeId);
		end

		function res=getProductStreams(obj)
		% Get the product streams id (include resources)
			streamtypes=[obj.Streams.typeId];
			res=find(bitget(streamtypes,cType.PRODUCTIVE));
		end

		function res=getFuelStreams(obj)
		% Get the fuel streams id (include output and wastes)
			streamtypes=[obj.Streams.typeId];	
			res=find(~bitget(streamtypes,cType.PRODUCTIVE));
		end

    end
end