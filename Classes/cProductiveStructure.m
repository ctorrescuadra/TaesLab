classdef(Sealed) cProductiveStructure < cResultId
%cProductiveStructure - Build and validate the productive structure of a plant.
%   Constructs the productive structure from a cModelData object by parsing
%   and validating the ProductiveStructure section of the data model.
%   The productive structure encodes:
%     - Flows, Processes, and Productive Groups (Streams) with keys, types,
%       and connectivity information
%     - ProductiveTable: sparse adjacency matrices (AE, AS, AF, AP)
%       representing all flow-stream and stream-process relationships
%     - Flow and process key dictionaries for fast lookup by name
%
%   Validation is performed at construction time. If any error is found
%   (duplicate keys, invalid flow/process types, disconnected graph, etc.)
%   the object status is set to false and errors are recorded in the
%   message log.
%
%   cProductiveStructure properties:
%     NrOfProcesses     - Number of processes
%     NrOfFlows         - Number of flows
%     NrOfStreams       - Number of streams
%     NrOfWastes        - Number of wastes
%     NrOfResources     - Number of resources
%     NrOfFinalProducts - Number of final products
%     NrOfSystemOutputs - Number of system outputs (final products + wastes)
%     Flows             - Struct array with flow data (id, key, type, from, to)
%     FlowKeys          - Cell array of flow keys
%     Processes         - Struct array with process data (id, key, fuel, product, ...)
%     ProcessKeys       - Cell array of process keys
%     ProcessMatrix     - Logical process adjacency matrix (including ENV row/col)
%     Streams           - Struct array with stream data (id, key, type, process)
%     StreamKeys        - Cell array of stream keys
%     Waste             - Struct with waste flow, stream, and process indices (dependent)
%     ProductiveTable   - Struct of sparse adjacency matrices (AE, AS, AF, AP)
%     
%   cProductiveStructure methods:
%     cProductiveStructure - Construct an instance of the class
%     buildResultInfo      - Build the cResultInfo object for PRODUCTIVE_STRUCTURE
%     WasteData            - Get the default waste data
%     IncidenceMatrix      - Get the incidence matrices of the plant
%     FlowEdges            - Get the flow edges definition names 
%     FuelStreams          - Get the Fuel streams ids
%     ProductStreams       - Get the Product streams ids
%     ResourceFlows        - Get the Resource Flows id
%     ResourceProcesses    - Get the Processes with external resources
%     FinalProductFlows    - Get the Final Products Flows id
%     SystemOutputFlows    - Get the System Output Flows id
%     OutputProcesses      - Get the Processes with system outputs
%     isModelIO            - Check if model is pure Input-Output
%	  getFlowId            - Get the Id of a flow given its key                                                                                                           
%     getProcessId         - Get the Id of a process given its key                                               
%     getProcessMatrix     - Get the Process Adjacency Matrix (logical FP table)
%     getFlowTypes  	   - Get the flowId of type typeId                                
%     getProcessTypes      - Get the processId of type typeId                                                   
%     getProductNames      - Get the name of the final products flows                                              
%     getResourceNames     - Get the name of the resource flows
%     getWasteNames        - Get the name of the waste flows
%     getStreamTypes       - Get the stream-id of type typeId                                                    
%     getFlowMatrix        - Get the Structural Theory Flows Adjacency Matrix                 
%     getFlowProcessMatrix - Get the Flow-Process Adjacency Matrix (Flows, Processes)                                                      
%     getStreamMatrix      - Get the Streams graph adjacency matrix
%     getProductiveMatrix  - Get the Productive Adjacency Matrix (Streams, Flows, Processes)
%     flows2Streams        - Compute the exergy or cost of streams from flow values                              
%
%   See also cModelData, cResultId, cResultInfo, cMessageLogger
%
	properties(GetAccess=public,SetAccess=private)	
		NrOfProcesses	  % Number of processes
		NrOfFlows         % Number of flows
		NrOfStreams	      % Number of streams
		NrOfWastes        % Number of wastes
		NrOfResources	  % Number of resources
		NrOfFinalProducts % Number of final products
		NrOfSystemOutputs % Number of system output
		Processes		  % Processes info
		Flows			  % Flows info
		Streams			  % Streams info
		Waste             % Waste array structure (flow, stream, process) index
        FlowKeys          % Cell array of Flows Names (keys)
        ProcessKeys       % Cell array of Processes Names (keys)
        StreamKeys        % Cell array of Streams Names (keys)
		ProductiveTable   % Adjacency Matrix of Productive Structure
        ProcessMatrix     % Processes Matrix	
	end

    properties(Access=private)
		cstr            % Internal streams cell array
		fDict           % Flows key dictionary
		pDict           % Processes key dictionary
    end

    methods
		function obj = cProductiveStructure(dm)
		%cProductiveStructure - Construct an instance of the class
		%   Parses and validates the ProductiveStructure section of dm, building
		%   all flows, processes, streams, and productive adjacency matrices.
		%   The object is invalid if dm is not a valid cModelData, required
		%   fields are missing, keys are duplicated, or the productive graph is
		%   disconnected.
		%
		%   Syntax:
		%     obj = cProductiveStructure(dm)
		%
		%   Input Arguments:
		%     dm  - cModelData object containing a valid ProductiveStructure
		%           section with flows and processes fields
		%
		%   Output Arguments:
		%     obj - cProductiveStructure object; check isValid(obj) before use
		%
			% Check/validate data model
            if ~isObject(dm,'cModelData')
				obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(dm));
				return
            end
            data=dm.ProductiveStructure;
			% Check data structure
            if ~all(isfield(data,{'flows','processes'}))
				obj.messageLog(cType.ERROR,cMessages.InvalidDataModel);
				return
            end
            if ~all(isfield(data.flows,{'key','type'}))
                obj.messageLog(cType.ERROR,cMessages.InvalidDataModel);
				return
            end
            if ~all(isfield(data.processes,{'key','fuel','product','type'}))
				obj.messageLog(cType.ERROR,cMessages.InvalidDataModel);
				return
            end
            % Initialize productive structure info
			obj.NrOfProcesses=numel(data.processes);
			obj.NrOfFlows=numel(data.flows);
			obj.NrOfStreams=0;
			N1=obj.NrOfProcesses+1;
			M=obj.NrOfFlows;
			if M < N1
				obj.messageLog(cType.ERROR,cMessages.InvalidDataModel);
				return
			end			
            % Create flows structure and dictionary
			obj.createFlowsStructure(data.flows);
			if ~obj.status
				return
			end
			obj.fDict=cDictionary({data.flows.key});
			if ~isValid(obj.fDict)
				obj.addLogger(obj.fDict);
				obj.messageLog(cType.ERROR,cMessages.DuplicatedFlow);
				return
			end
			% Check if there are resources and final products
			if isempty(obj.ResourceFlows)
				obj.messageLog(cType.ERROR,cMessages.NoResources);
				return
			end
			if isempty(obj.FinalProductFlows)
				obj.messageLog(cType.ERROR,cMessages.NoOutputs);
				return
			end
            % Create processes structure and dictionary
			obj.createProcessesStructure(data.processes);
            if ~obj.status
                return
            end
			obj.pDict=cDictionary({data.processes.key});
			if ~isValid(obj.pDict)
				obj.addLogger(obj.pDict);
				obj.messageLog(cType.ERROR,cMessages.DuplicatedProcess);
				return
			end
            % Create productive groups (streams)
			obj.cstr=cell(1,2*N1);
            for i=1:obj.NrOfProcesses
  				obj.createProcessStreams(i,cType.Stream.FUEL);
				obj.createProcessStreams(i,cType.Stream.PRODUCT);
            end
            if ~isValid(obj)
                return
            end
            % Create enviroment elements
			if ~obj.buildEnvironment
				return
			end
			% Check Flows connectivity
            if ~obj.checkFlowsConnectivity
				return
            end
            % Set properties 
            obj.Streams=cell2mat(obj.cstr);
            obj.FlowKeys={obj.Flows.key};
            obj.ProcessKeys={obj.Processes.key};
            obj.StreamKeys={obj.Streams.key};
			% Build Productive Adjacency Table
			NS=obj.NrOfStreams;
			fto=[obj.Flows.to];
			ffrom=[obj.Flows.from];
			pstreams=obj.ProductStreams;
			pprocesses=[obj.Streams(pstreams).process];
			fstreams=obj.FuelStreams;
			fprocesses=[obj.Streams(fstreams).process];		
            mAE=sparse(1:M,fto,true(1,M),M,NS);
			mAS=sparse(ffrom,1:M,true(1,M),NS,M);
			mAF=sparse(fstreams,fprocesses,true(size(fstreams)),NS,N1);
			mAP=sparse(pprocesses,pstreams,true(size(pstreams)),N1,NS);
            obj.ProductiveTable=struct('AE',mAE,'AS',mAS,'AF',mAF,'AP',mAP);
			% Check digraph connectivity
			if ~checkGraphConnectivity(obj)
				obj.messageLog(cType.ERROR,cMessages.InvalidProductiveGraph);
				return
			end
			% Set object variables
			obj.ResultId=cType.ResultId.PRODUCTIVE_STRUCTURE;
			obj.ModelName=dm.ModelName;
			obj.State='SUMMARY';
        end
		
		%%%%%
		% Public get properties
		%%%%%
		function res=get.Waste(obj)
		%Waste - Struct with the indices of waste flows, streams, and processes
		%   Dependent property computed on demand. Returns cType.EMPTY if the
		%   object is invalid or there are no waste flows.
		%
		%   Fields:
		%     flows     - indices of flows with type WASTE
		%     streams   - stream indices for the waste flows
		%     processes - process indices for the waste streams
		%
			res=cType.EMPTY;
			if obj.status
				res.flows=getFlowTypes(obj,cType.Flow.WASTE);
				res.streams=[obj.Flows(res.flows).from];
				res.processes=[obj.Streams(res.streams).process];
			end
		end
		
		%%%%%%
		% Public methods
		%%%%%%
		function res=buildResultInfo(obj,fmt)
		%buildResultInfo - Build the cResultInfo object for PRODUCTIVE_STRUCTURE
		%   Delegates construction of the result container to the provided
		%   cResultTableBuilder, which assembles the productive structure tables
		%   according to the active format configuration.
		%
		%   Syntax:
		%     res = obj.buildResultInfo(fmt)
		%
		%   Input Arguments:
		%     fmt - cResultTableBuilder object defining the output format
		%
		%   Output Arguments:
		%     res - cResultInfo object containing the productive structure tables
		%
		%   See also cResultTableBuilder, cResultInfo
		%
			res=fmt.getProductiveStructure(obj);
		end
			
		function res=WasteData(obj)
		%WasteData - Get a default waste data template for this model
		%   Returns a struct with default allocation settings for each waste
		%   flow. Returns cType.EMPTY when there are no waste flows.
		%
		%   Syntax:
		%     res = obj.WasteData
		%
		%   Output Arguments:
		%     res - (struct) Waste template with field:
		%             wastes - (1 x NrOfWastes struct array) with fields:
		%               flow    - waste flow key (char)
		%               type    - default allocation type (char)
		%               recycle - default recycle fraction (0.0)
		%
		%   See also getWasteNames, cWasteData
		%
			res=cType.EMPTY;
			if obj.NrOfWastes > 0
				res.wastes=struct('flow',obj.getWasteNames,...
					'type',cType.DEFAULT_WASTE_ALLOCATION,...
					'recycle',0.0);
			end			
		end
	
		function [res1,res2]=IncidenceMatrix(obj)
		%IncidenceMatrix - Get the incidence matrices of the plant
		%   Computes the Fuel (iAF) and Product (iAP) incidence matrices from the
		%   productive table adjacency matrices. When called with one output,
		%   returns the combined incidence matrix (iAF - iAP).
		%
		%   Syntax:
		%     res1         = obj.IncidenceMatrix    % combined matrix
		%     [res1,res2]  = obj.IncidenceMatrix    % fuel and product separately
		%
		%   Output Arguments (two outputs):
		%     res1 - (NrOfProcesses x NrOfFlows sparse) Fuel incidence matrix
		%     res2 - (NrOfProcesses x NrOfFlows sparse) Product incidence matrix
		%
		%   Output Arguments (one output):
		%     res1 - (NrOfProcesses x NrOfFlows sparse) Combined incidence matrix
		%            (fuel - product)
		%
			aE=obj.ProductiveTable.AE';
			aS=obj.ProductiveTable.AS;
			aF=obj.ProductiveTable.AF';
			aP=obj.ProductiveTable.AP;
			iAF=aF(1:end-1,:)*(aE-aS);
			iAP=aP(1:end-1,:)*(aS-aE);
			if nargout<2
				res1=iAF-iAP;
			else
				res1=iAF; res2=iAP;
			end
		end

		function [res,src,out]=getStreamMatrix(obj)
		%getStreamMatrix - Get the stream-to-stream adjacency matrix
		%   Returns the adjacency matrix of the stream graph, where entry (i,j)
		%   is true if stream i feeds stream j. Optionally returns the resource
		%   row vector and the output column vector for the environment process.
		%
		%   Syntax:
		%     res           = obj.getStreamMatrix
		%     [res,src,out] = obj.getStreamMatrix
		%
		%   Output Arguments:
		%     res - (NrOfStreams x NrOfStreams logical sparse) Stream adjacency matrix
		%     src - (1 x NrOfStreams logical sparse) Resource row (ENV inputs)
		%     out - (NrOfStreams x 1 logical sparse) Output column (ENV outputs)
		%
		%   See also getFlowMatrix, getProcessMatrix, getProductiveMatrix
		%
			x=obj.ProductiveTable;
			res=x.AS*x.AE+x.AF(:,1:end-1)*x.AP(1:end-1,:);
			if nargout>1
				src=x.AP(end,:);
				out=x.AF(:,end);
			end
        end
	
		function [res,src,out]=getFlowMatrix(obj)
		%getFlowMatrix - Get the Structural Theory flow adjacency matrix
		%   Returns the flow-to-flow adjacency matrix of the productive structure
		%   as defined by Structural Theory of Energy Systems. Optionally returns
		%   the resource row vector and the output column vector for the
		%   environment process.
		%
		%   Syntax:
		%     res           = obj.getFlowMatrix
		%     [res,src,out] = obj.getFlowMatrix
		%
		%   Output Arguments:
		%     res - (NrOfFlows x NrOfFlows logical sparse) Flow adjacency matrix
		%     src - (1 x NrOfFlows logical sparse) Resource row (ENV inputs)
		%     out - (NrOfFlows x 1 logical sparse) Output column (ENV outputs)
		%
		%   See also getStreamMatrix, getProcessMatrix, getProductiveMatrix
		%
			x=obj.ProductiveTable;
			xAP=x.AP*x.AS; xAF=x.AE*x.AF;
			res=x.AE*x.AS+xAF(:,1:end-1)*xAP(1:end-1,:);
			if nargout>1
				src=xAP(end,:);
				out=xAF(:,end);
			end
        end
		
		function [res,src,out]=getProcessMatrix(obj)
		%getProcessMatrix - Get the process adjacency matrix (logical FP table)
		%   Returns the process-to-process adjacency matrix derived from the
		%   transitive closure of the stream adjacency matrix. Entry (i,j) is
		%   true if process i can reach process j. Optionally returns the
		%   resource row and the output column for the environment process.
		%
		%   Syntax:
		%     res           = obj.getProcessMatrix
		%     [res,src,out] = obj.getProcessMatrix
		%
		%   Output Arguments:
		%     res - (NrOfProcesses x NrOfProcesses logical) Process adjacency
		%           matrix (ENV row/col excluded when three outputs requested)
		%     src - (1 x NrOfProcesses logical) Resource row (ENV to processes)
		%     out - (NrOfProcesses x 1 logical) Output column (processes to ENV)
		%
		%   See also getStreamMatrix, getFlowMatrix, getProductiveMatrix
		%
			x=obj.ProductiveTable;
			tmp=x.AS*x.AE;
			tc=transitiveClosure(tmp);
			res=logical(x.AP*tc*x.AF);
			if nargout>1
				src=res(end,1:end-1);
				out=res(1:end-1,end);
				res=res(1:end-1,1:end-1);
			end
		end
        
        function res=getProductiveMatrix(obj)
		%getProductiveMatrix - Get the combined productive adjacency matrix
		%   Returns the block adjacency matrix combining streams, flows, and
		%   processes in a single square matrix. Used to build the SFPAT
		%   productive diagram.
		%
		%   Syntax:
		%     res = obj.getProductiveMatrix
		%
		%   Output Arguments:
		%     res - ((NS+M+N) x (NS+M+N) logical sparse) Productive adjacency
		%           matrix, where NS = NrOfStreams, M = NrOfFlows, N = NrOfProcesses
		%
		%   See also getStreamMatrix, getFlowMatrix, getFlowProcessMatrix
		%
			x=obj.ProductiveTable;
			N=obj.NrOfProcesses;
			M=obj.NrOfFlows;
			NS=obj.NrOfStreams;
			res=[zeros(NS,NS), x.AS, x.AF(:,1:end-1);...
			     x.AE, zeros(M,M), zeros(M,N);...
				 x.AP(1:end-1,:), zeros(N,M), zeros(N,N)];
		end
			
		function res=getFlowProcessMatrix(obj)
		%getFlowProcessMatrix - Get the flow-process adjacency matrix
		%   Returns the block adjacency matrix combining flows and processes in a
		%   single square matrix. Used to build the FPAT flow-process diagram.
		%
		%   Syntax:
		%     res = obj.getFlowProcessMatrix
		%
		%   Output Arguments:
		%     res - ((M+N) x (M+N) logical sparse) Flow-process adjacency matrix,
		%           where M = NrOfFlows, N = NrOfProcesses
		%
		%   See also getFlowMatrix, getProductiveMatrix
		%
			x=obj.ProductiveTable;
			N=obj.NrOfProcesses;
			res=[x.AE*x.AS,x.AE*x.AF(:,1:end-1);...
				x.AP(1:end-1,:)*x.AS,zeros(N,N)];
		end

		function res=FlowEdges(obj)
		%FlowEdges - Get the source and target stream key for each flow
		%   Returns a struct array with the source and target stream key for
		%   each flow, suitable for building flow diagram edges.
		%
		%   Syntax:
		%     res = obj.FlowEdges
		%
		%   Output Arguments:
		%     res - (1 x NrOfFlows struct array) Edge definitions with fields:
		%             from - source stream key (char)
		%             to   - target stream key (char)
		%
		%   See also getFlowMatrix, cProductiveDiagram
		%
			from=[obj.Flows.from];
			to=[obj.Flows.to];
			res=struct('from',obj.StreamKeys(from),'to',obj.StreamKeys(to));
		end

		function res=ProductStreams(obj)
		%ProductStreams - Get the indices of product (internal output) streams
		%   Returns the indices of streams whose typeId has the INTERNAL bit set,
		%   i.e., streams that carry the product leaving a process.
		%
		%   Syntax:
		%     res = obj.ProductStreams
		%
		%   Output Arguments:
		%     res - (1 x K integer array) Stream indices of product streams
		%
		%   See also FuelStreams, getStreamTypes
		%
			streamtypes=[obj.Streams.typeId];
			res=find(bitget(streamtypes,cType.INTERNAL));
		end
	
		function res=FuelStreams(obj)
		%FuelStreams - Get the indices of fuel (external input) streams
		%   Returns the indices of streams whose typeId does NOT have the
		%   INTERNAL bit set, i.e., streams that carry the fuel entering a
		%   process, including resource, output, and waste environment streams.
		%
		%   Syntax:
		%     res = obj.FuelStreams
		%
		%   Output Arguments:
		%     res - (1 x K integer array) Stream indices of fuel streams
		%
		%   See also ProductStreams, getStreamTypes
		%
			streamtypes=[obj.Streams.typeId];	
			res=find(~bitget(streamtypes,cType.INTERNAL));
		end

		function res=ResourceFlows(obj)
		%ResourceFlows - Get the indices of resource flows
		%
		%   Syntax:
		%     res = obj.ResourceFlows
		%
		%   Output Arguments:
		%     res - (1 x NrOfResources integer array) Indices of flows with
		%           type RESOURCE
		%
		%   See also FinalProductFlows, SystemOutputFlows, getFlowTypes
		%
			res=getFlowTypes(obj,cType.Flow.RESOURCE);
		end

		function res=FinalProductFlows(obj)
		%FinalProductFlows - Get the indices of final product flows
		%
		%   Syntax:
		%     res = obj.FinalProductFlows
		%
		%   Output Arguments:
		%     res - (1 x NrOfFinalProducts integer array) Indices of flows
		%           with type OUTPUT
		%
		%   See also ResourceFlows, SystemOutputFlows, getFlowTypes
		%
			res=getFlowTypes(obj,cType.Flow.OUTPUT);
		end

		function res=SystemOutputFlows(obj)
		%SystemOutputFlows - Get the indices of all system output flows
		%   Returns the combined list of final product flows (OUTPUT type) and
		%   waste flows (WASTE type).
		%
		%   Syntax:
		%     res = obj.SystemOutputFlows
		%
		%   Output Arguments:
		%     res - (1 x NrOfSystemOutputs integer array) Indices of all flows
		%           that leave the system (OUTPUT + WASTE)
		%
		%   See also FinalProductFlows, ResourceFlows, getFlowTypes
		%
			out=getFlowTypes(obj,cType.Flow.OUTPUT);
			waste=getFlowTypes(obj,cType.Flow.WASTE);
            res=[out,waste];
        end

		function res=ResourceProcesses(obj)
		%ResourceProcesses - Get the indices of processes that consume external resources
		%
		%   Syntax:
		%     res = obj.ResourceProcesses
		%
		%   Output Arguments:
		%     res - (1 x K integer array) Indices of processes connected to at
		%           least one resource flow
		%
		%   See also OutputProcesses, ResourceFlows
		%
			res=find(obj.ProcessMatrix(end,1:end-1));
		end

		function res=OutputProcesses(obj)
		%OutputProcesses - Get the indices of processes that produce system outputs
		%
		%   Syntax:
		%     res = obj.OutputProcesses
		%
		%   Output Arguments:
		%     res - (1 x K integer array) Indices of productive processes
		%           connected to at least one final product flow
		%
		%   See also ResourceProcesses, FinalProductFlows
		%
			aP=obj.getProcessTypes(cType.Process.PRODUCTIVE);
			res=transpose(find(obj.ProcessMatrix(aP,end)));
		end

		function res=isModelIO(obj)
		%isModelIO - Check if the model is a pure Input-Output system
		%   Returns true when no stream appears as both source and target of any
		%   flow, i.e., there are no internal recycling connections between streams.
		%
		%   Syntax:
		%     res = obj.isModelIO
		%
		%   Output Arguments:
		%     res - (logical) true if the model is pure Input-Output; false if
		%           any stream is both source and target of flows
		%
			from=[obj.Flows.from];
			to=[obj.Flows.to];
			res=isempty(intersect(from,to));
		end
	
		function id=getProcessId(obj,key)
		%getProcessId - Get the index of a process given its key
		%   Accepts a single key (char) or a cell array of keys. Returns 0 if
		%   the key is not found or if any key in a cell array is missing.
		%
		%   Syntax:
		%     id = obj.getProcessId(key)
		%
		%   Input Arguments:
		%     key - (char or cell array of char) Process key(s) to look up
		%
		%   Output Arguments:
		%     id  - (integer or integer array) Process index, or 0 if not found
		%
		%   See also getFlowId, ProcessKeys
		%
			id=0;
			if nargin<2,return;end
			if ischar(key)
				id=obj.pDict.getIndex(key);
			elseif iscell(key)
				[tf,id]=ismember(key,obj.ProcessKeys);
				if ~all(tf),id=0;end
			end
		end
			
		function id=getFlowId(obj,key)
		%getFlowId - Get the index of a flow given its key
		%   Accepts a single key (char) or a cell array of keys. Returns 0 if
		%   the key is not found or if any key in a cell array is missing.
		%
		%   Syntax:
		%     id = obj.getFlowId(key)
		%
		%   Input Arguments:
		%     key - (char or cell array of char) Flow key(s) to look up
		%
		%   Output Arguments:
		%     id  - (integer or integer array) Flow index, or 0 if not found
		%
		%   See also getProcessId, FlowKeys
		%
			id=0;
			if nargin<2,return;end		
			if ischar(key)
				id=obj.fDict.getIndex(key);
			elseif iscell(key)
				[tf,id]=ismember(key,obj.FlowKeys);
				if ~all(tf),id=0;end
			end
		end
	
		function res=getFlowTypes(obj,typeId)
		%getFlowTypes - Get the flowId of type typeId
		%   Syntax:
		%     res = obj.getFlowTypes(typeId)
		%   Input Arguments:
		%     typeId - Flow type id
		%   Output Arguments:  
		%     res - Array with the ids of the flows of this type
		%
			res=cType.EMPTY;
			if nargin<2,return;end
            ftypes=[obj.Flows.typeId];
			res=find(ftypes==typeId);
		end
	
		function res=getProcessTypes(obj,typeId)
		%getProcessTypes - Get the indices of processes of a given type
		%
		%   Syntax:
		%     res = obj.getProcessTypes(typeId)
		%
		%   Input Arguments:
		%     typeId - (integer) Process type identifier (see cType.Process)
		%
		%   Output Arguments:
		%     res - (integer array) Indices of processes matching typeId;
		%           returns cType.EMPTY if typeId is not provided
		%
		%   See also getFlowTypes, getStreamTypes, cType
		%
			res=cType.EMPTY;
			if nargin<2,return;end
            ptypes=[obj.Processes.typeId];
			res=find(ptypes==typeId);
		end
	
		function res=getStreamTypes(obj,typeId)
		%getStreamTypes - Get the indices of streams of a given type
		%
		%   Syntax:
		%     res = obj.getStreamTypes(typeId)
		%
		%   Input Arguments:
		%     typeId - (integer) Stream type identifier (see cType.Stream)
		%
		%   Output Arguments:
		%     res - (integer array) Indices of streams matching typeId;
		%           returns cType.EMPTY if typeId is not provided
		%
		%   See also getFlowTypes, getProcessTypes, cType
		%
			res=cType.EMPTY;
			if nargin<2,return;end
            stypes=[obj.Streams.typeId];
			res=find(stypes==typeId);
		end

		function res=getResourceNames(obj)
		%getResourceNames - Get the name of the resource flows
		%   Syntax:
		%     res = obj.getResourceNames
		%   Output Arguments:
		%     res - Cell Array with the resource names
		%
			res=obj.FlowKeys(obj.ResourceFlows);
		end

		function res=getProductNames(obj)
		%getProductNames - Get the name of the final products flows
		%   Syntax:
		%     res = obj.getProductNames
		%   Output Arguments:
		%     res - Cell Array with the final product names
		%
			res=obj.FlowKeys(obj.FinalProductFlows);
		end

		function res=getWasteNames(obj)
		%getWasteNames - Get the names of the waste flows
		%
		%   Syntax:
		%     res = obj.getWasteNames
		%
		%   Output Arguments:
		%     res - (1 x NrOfWastes cell array of char) Waste flow keys
		%
		%   See also getResourceNames, getProductNames
		%
			  res=obj.FlowKeys(obj.Waste.flows);
		end

		function [E,ET]=flows2Streams(obj,val)
		%flows2Streams - Compute stream exergy or cost values from flow values
		%   Projects a row vector of per-flow values onto the stream graph using
		%   the productive table matrices, computing each stream's net exergy (or
		%   cost) as the difference between entering and leaving flows. Applies
		%   zerotol to suppress near-zero numerical noise.
		%
		%   Syntax:
		%     E       = obj.flows2Streams(val)
		%     [E, ET] = obj.flows2Streams(val)
		%
		%   Input Arguments:
		%     val - (1 x NrOfFlows numeric) Per-flow exergy or cost values
		%
		%   Output Arguments:
		%     E  - (1 x NrOfStreams numeric) Net exergy or cost of each stream
		%     ET - (1 x NrOfStreams numeric) Total (entering) exergy per stream;
		%          only computed when two output arguments are requested
		%
		%   See also ProductiveTable, ProductStreams, FuelStreams
		%
			tbl=obj.ProductiveTable;
			BE=val*tbl.AE;
			BS=val*tbl.AS';
			fstreams=obj.FuelStreams;
			pstreams=obj.ProductStreams;
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

	methods(Access=private)
		function createFlowsStructure(obj, data)
		%createFlowsStructure - Validate and populate the Flows struct array
		%   Validates the flow type of each entry in data and assigns the Flows
		%   property. Logs an error for each invalid flow type encountered.
		%
		%   Syntax:
		%     obj.createFlowsStructure(data)
		%
		%   Input Arguments:
		%     data - (1 x NrOfFlows struct array) Raw flow data with fields:
		%              key  - flow key string
		%              type - flow type string (see cType.Flow)
		%
			% Create Flows structure array
			M = length(data);
			[tst,idx]=cType.checkFlowTypes({data.type});
            if tst 
				obj.Flows= struct('id', num2cell(1:M), ...
					'key', {data.key}, ...
					'type', {data.type}, ...
					'typeId', num2cell(idx'), ...
					'from', 0, 'to', 0);
			else %log invalid key types
				for i=idx
                	obj.messageLog(cType.ERROR,cMessages.InvalidFlowType,data(i).key,data(i).type);
				end
            end
        end

        function createProcessesStructure(obj,data)
		%createProcessesStructure - Validate and populate the Processes struct array
		%   Validates process types, fuel/product stream expressions, and flow
		%   keys. Appends the synthetic ENV (environment) process. Logs errors
		%   for any validation failure encountered.
		%
		%   Syntax:
		%     obj.createProcessesStructure(data)
		%
		%   Input Arguments:
		%     data - (1 x NrOfProcesses struct array) Raw process data with
		%            fields: key, type, fuel, product
		%
			% Initialize
			N=length(data);
			ptypes=zeros(1,N+1);
			% Loop over processes
			for i=1:N				
				%Check Process Type
                prc=data(i);
				ptype=cType.getProcessId(prc.type); 
				if isempty(ptype)	        
					obj.messageLog(cType.ERROR,cMessages.InvalidProcessType,prc.type,prc.key);
				end					
				% Check Fuel stream
				prc.fuel=regexprep(prc.fuel,cType.SPACES,cType.EMPTY_CHAR);
				if ~cParseStream.checkStream(prc.fuel)
					obj.messageLog(cType.ERROR,cMessages.InvalidFuelStream,prc.fuel,prc.key);
				end
				fl=cParseStream.getFlowsList(prc.fuel);
				if ~obj.fDict.existsKey(fl)
					obj.messageLog(cType.ERROR,cMessages.InvalidFuelStream,prc.fuel,prc.key);
				end
				% Check Product stream
				prc.product=regexprep(prc.product,cType.SPACES,cType.EMPTY_CHAR);
				if ~cParseStream.checkStream(prc.product) 
					obj.messageLog(cType.ERROR,cMessages.InvalidProductStream,prc.product,prc.key);
				end
				fl=cParseStream.getFlowsList(prc.product);
				if ~obj.fDict.existsKey(fl)
					obj.messageLog(cType.ERROR,cMessages.InvalidProductStream,prc.product,prc.key);
				elseif ptype==cType.Process.DISSIPATIVE % Check disipative processes and waste flows
                	for j=1:numel(fl)
						jkey=obj.fDict.getIndex(fl{j});
                    	if obj.Flows(jkey).typeId ~= cType.Flow.WASTE
				        	obj.messageLog(cType.ERROR,cMessages.InvalidDissipative,obj.Flows(jkey).key,prc.key);
                    	end
                	end
				end
				ptypes(i)=ptype;
			end           
            % Create process struct (including ENV)
			ids=1:N+1;
			keys=[{data.key} 'ENV'];
			types=[{data.type} 'ENVIRONMENT'];
			ptypes(N+1)=cType.Process.ENVIRONMENT;
			fuels=[{data.fuel},' '];
			products=[{data.product},' '];
            obj.Processes=struct('id',num2cell(ids),...
				'key',keys,...
				'type',types,...
				'typeId',num2cell(ptypes),...
				'fuel',fuels,...
				'product',products,...
                'fuelStreams',0,'productStreams',0);
        end

        function createProcessStreams(obj,id,fp)
		%CreateProcessStreams - Create the streams of a process
		%   Syntax:
		%     obj.createProcessStreams(id,fp)
		%   Input Arguments:
		%     id - Process Id
		%     fp - Stream type (cType.Stream.FUEL | cType.Stream.PRODUCT)
		%
			order=0;
			ns=obj.NrOfStreams;     
            % Generate stream key
			pkey=obj.Processes(id).key;
            switch fp
				case cType.Stream.FUEL
                    stype=cType.FUEL;
					descr=obj.Processes(id).fuel;
					scode=strcat(pkey,'_F');
				case cType.Stream.PRODUCT
                    stype=cType.PRODUCT;
					descr=obj.Processes(id).product;
					scode=strcat(pkey,'_P');
            end
            % Get the streams of a process
			list=cParseStream.getStreams(descr);		
            for i=1:length(list)		
				expr=list{i};
				ns=ns+1; order=order+1;
				key=sprintf('%s%d',scode,order);
                if obj.checkStreamFlows(ns,expr,fp)
				    obj.cstr{ns}=struct('id',ns,'key',key,'definition',expr,...
				    'type',stype,'typeId',fp,'process',id);
                else
					obj.messageLog(cType.ERROR,cMessages.InvalidStreamDefinition,expr,pkey);
                    return
                end
            end
            obj.NrOfStreams=ns;
			% Set the Fuel/Product streams to the processes
            switch fp
				case cType.Stream.FUEL
					obj.Processes(id).fuelStreams=order;
				case cType.Stream.PRODUCT
					obj.Processes(id).productStreams=order;
            end
        end

        function status=checkStreamFlows(obj,sid,expr,fp)
		%CheckStreamFlows - Check and set the flows of a stream
		%   Syntax:
		%     status = obj.checkStreamFlows(sid,expr,fp)
		%   Input Arguments:
		%     sid  - Stream Id
		%     expr - Stream definition expression
		%     fp   - Stream type (cType.Stream.FUEL | cType.Stream.PRODUCT)
		%   Output Arguments:
		%     status - true | false indicating if the stream flows are ok
		%
			status=true;
            [fe,fs]=cParseStream.getStreamFlows(expr,fp);
            % set input flows of the stream          
            for i=1:length(fe)
			    in=fe{i};
				idx=obj.fDict.getIndex(in);
                if idx
					if ~obj.Flows(idx).to
					    obj.Flows(idx).to=sid;
				    else
						status=false;
						obj.messageLog(cType.ERROR,cMessages.InvalidFlowToStream,in);
					end
			    else
					status=false;
					obj.messageLog(cType.ERROR,cMessages.InvalidFlowKey,in);
                end
            end
            % set output flows of the stream
            for i=1:length(fs)
			    out=fs{i};
				idx=obj.fDict.getIndex(out);
                if idx
					if ~obj.Flows(idx).from
					    obj.Flows(idx).from=sid;
				    else
						status=false;
						obj.messageLog(cType.ERROR,cMessages.InvalidStreamToFlow,obj.Flows(idx).key);
					end
			    else
					status=false;
					obj.messageLog(cType.ERROR,cMessages.InvalidFlowKey,out);
                end
            end
        end

        function res=buildEnvironment(obj)
		%buildEnvironment - Create the environment streams and update flows and processes info
		%   Syntax:
		%     res = obj.buildEnvironment
		%   Output Arguments:
		%     res - true | false indicating if the environment was built ok
		
			% Initialize
			iout=0;ires=0;iwst=0;            % Counters
			fdesc=cType.EMPTY_CHAR;
			pdesc=cType.EMPTY_CHAR;          % Stream Definition
			ns=obj.NrOfStreams;              % Number of streams global counter
            N1=obj.NrOfProcesses+1;          % Environment process Id
			env=find([obj.Flows.typeId]);    % Environment flows (OUTPUT, WASTE, RESOURCES)
            % Loop over Environment flows
			for i=env
				ftype=obj.Flows(i).typeId;
                stype=obj.Flows(i).type;
				descr=obj.Flows(i).key;
				jt=obj.Flows(i).to;
				jf=obj.Flows(i).from;
				ns=ns+1;
				switch ftype
    				case cType.Flow.OUTPUT % System Output Flows
					    iout=iout+1;
					    scode=sprintf('ENV_O%d', iout);
					    fdesc=strcat(fdesc,'+',descr);
                        if ~jt % Check if flow is OUTPUT
						    obj.Flows(i).to=ns;
				        else
					        obj.messageLog(cType.ERROR,cMessages.InvalidOutputFlow,obj.Flows(i).key);
                        end
                        if jf
						    k=obj.cstr{jf}.process;
                            if (obj.Processes(k).typeId == cType.Process.DISSIPATIVE)
					    	    obj.messageLog(cType.ERROR,cMessages.InvalidOutputFlow,obj.Flows(i).key);
                            end
                        end		
                    case cType.Flow.WASTE %Waste flows
					    iwst=iwst+1;
					    scode=sprintf('ENV_W%d', iwst);
					    fdesc=strcat(fdesc,'+',descr);
                        if ~jt % Check if flow is WASTE
						    obj.Flows(i).to=ns;	
					    else
					        obj.messageLog(cType.ERROR,cMessages.InvalidWasteFlow,obj.Flows(i).key);
                        end
                        if jf
						    k=obj.cstr{jf}.process;
                            if (obj.Processes(k).typeId == cType.Process.PRODUCTIVE)
					    	    obj.messageLog(cType.ERROR,cMessages.InvalidWasteFlow,obj.Flows(i).key);
                            end
                        end
				    case cType.Flow.RESOURCE % Resource flows
					    ires=ires+1;
					    scode=sprintf('ENV_R%d', ires);
					    pdesc=strcat(pdesc,'+',descr);
                        if ~jf % Check if flow is a resource
						    obj.Flows(i).from=ns;				
					    else
					        obj.messageLog(cType.ERROR,cMessages.InvalidResourceFlow,obj.Flows(i).key);
                        end
				end
				% Create environment stream structure
				obj.cstr{ns}=struct('id',ns,'key',scode,'definition',descr,'type',stype,'typeId',ftype,'process',N1);
			end
            % Update number of streams and wastes
			obj.NrOfStreams=ns;
            obj.NrOfWastes=iwst;
			obj.NrOfResources=ires;
			obj.NrOfFinalProducts=iout;
			obj.NrOfSystemOutputs=iwst+iout;
			% Update environment process record
			obj.Processes(N1).fuel=fdesc(2:end);
			obj.Processes(N1).product=pdesc(2:end);
			obj.Processes(N1).fuelStreams=obj.NrOfSystemOutputs;
			obj.Processes(N1).productStreams=obj.NrOfResources;
			res=obj.status;
        end

        function res=checkFlowsConnectivity(obj)
		%checkFlowsConnectivity - Check the connectivity of the flows
		%   Syntax:
		%     res = obj.checkFlowsConnectivity
		%   Output Arguments:
		%     res - true | false indicating if the flows are ok
		
			% Get the from and to of the flows
			from=[obj.Flows.from]; to=[obj.Flows.to];
			% Loop over flows to check connectivity
			for id=1:obj.NrOfFlows
				if (from(id)==to(id)) %Check if there is a loop
					if from(id)==0
						obj.messageLog(cType.ERROR,cMessages.InvalidFlowDefiniton,obj.cflw{id}.key);
					else
						obj.messageLog(cType.ERROR,cMessages.InvalidFlowLoop,obj.cflw{id}.key);
					end
				elseif (from(id)==0) && (to(id)~=0) % Check invalid FROM definition
					obj.messageLog(cType.ERROR,cMessages.InvalidStreamToFlow,obj.cflw{id}.key);
				elseif (to(id)==0) && (from(id)~=0) % Check invalid TO definition
					obj.messageLog(cType.ERROR,cMessages.InvalidFlowToStream,obj.cflw{id}.key);
				end
			end
			res=obj.status;
        end

        function res=checkGraphConnectivity(obj)
		%checkGraphConnectivity - Check the productive graph connectivity.
		%   The function checks that all nodes are connected from the source (resources)
		%   and	all nodes can reach the sink (final products).	
		%   Syntax:	
		%     res = obj.checkGraphConnectivity	
		%   Output Arguments:		
		%     res - true | false indicating if the graph is ok
		%     if false logs the non reached nodes
		
			% Get the Processes adjacency matrix
			[tfp,src,out]=obj.getProcessMatrix; 
			% Calculate nodes reached by src
			rs=bfs(tfp,find(src));		
			for i=find(~rs) % Report invalid nodes
				obj.messageLog(cType.ERROR,cMessages.NodeNotReachedFromSource,obj.ProcessKeys{i});
			end
			% Calculate final products reached by productive nodes
			aP=obj.getProcessTypes(cType.Process.PRODUCTIVE);
			gP=transpose(tfp(aP,aP)); tidx=transpose(find(out(aP)));
			rt=bfs(gP,tidx);
			for i=find(~rt)
				obj.messageLog(cType.ERROR,cMessages.OutputNotReachedFromNode,obj.ProcessKeys{i});
			end
			if obj.status
				obj.ProcessMatrix=[tfp,out;src,0];
			end
			res=obj.status;
		end
    end
end