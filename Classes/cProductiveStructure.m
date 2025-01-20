classdef cProductiveStructure < cResultId
%cProductiveStructure - Build the productive structure of a plant
%   Check the data model and build the productive structure, which
%   include information about:
%   - Flows, Processes and Productive Groups (Streams)
%   - The adjacency matrix of the productive graph
%
%   cProductiveStructure constructor:
%     obj = cProductiveStructure(dm)
% 
%   cProductiveStructure properties:
%     NrOfProcesses     - Number of processes
%     NrOfFlows         - Number of flows
%     NrOfStreams       - Number of streams
%     NrOfWastes        - Number of wastes
%     NrOfResources     - Number of resources
%     NrOfFinalProducts - Number of final products
%     NrOfSystemOutputs - Number of system output
%     Processes         - Processes info
%     Flows             - Flows info
%     Streams           - Streams info
%     Waste             - Waste array structure (flow, stream, process) index
%     Resources         - Resources array structure (flow, stream, process)  index
%     FinalProducts     - Final Products array structure (flow, stream, process) index
%     SystemOutput      - SystemOutput array structure (flow, stream, process) index
%     FlowKeys          - Cell array of Flows Names (keys)
%     ProcessKeys       - Cell array of Processes Names (keys)
%     StreamKeys        - Cell array of Streams Names (keys)
%     AdjacencyMatrix   - Adjacency Matrix of the productive structure graph
%
%   cProductiveStructure methods:
%     buildResultInfo   - Build the cResultInfo object for PRODUCTIVE_STRUCTURE
%     WasteData         - Get the default waste data
%     IncidenceMatrix   - Get the incidence matrices 
%     StructuralMatrix  - Get the structural matrix
%     ProductiveMatrix  - Get the productive matrix
%     FlowProcessMatrix - Get the flow-process adjacency matrix
%     ProcessMatrix     - Get the process matrix (Logical FP matrix)
%     FlowEdges         - Get the flow edges definition names 
%     getProcessId      - Get the process Id given the name
%     getFlowId         - Get the flow Id given the name
%     getFlowTypes      - Get the flow number of type typeId
%     getProcessTypes   - Get the process number of type typeId
%     getStreamTypes    - Get the stream number of type typeId
%     getFuelStreams    - Get the Fuel streams ids
%     getProductStreams - Get the Product streams ids
%     getResourceNames  - Get the resource flow names
%     getProductNames   - Get the final product flow names
%     getWasteNames     - Get the waste flow names
%     flows2streams     - Compute the exergy or cost of streams from flow values
%
%   See also cDataModel, cResultId
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
        Resources         % Resources array structure (flow, stream, process)  index
        FinalProducts     % Final Products array structure (flow, stream, process) index
		SystemOutput      % SystemOutput array structure (flow, stream, process) index
        FlowKeys          % Cell array of Flows Names (keys)
        ProcessKeys       % Cell array of Processes Names (keys)
        StreamKeys        % Cell array of Streams Names (keys)
		AdjacencyMatrix   % Adjacency Matrix
	end

	properties(Access=protected)
		fDict           % Flows key dictionary
		pDict           % Processes key dictionary
    end

    properties(Access=private)
		cflw			% Internal flows cell array
		cstr            % Internal streams cell array
		cprc            % Internal processes cell array
        parser          % cParseStream object
		ftypes          % Flows types
    end

    methods
		function obj = cProductiveStructure(dm)
		% cProductiveStructure - Creates an instance of the class
		% Syntax:
		%   obj = cProductiveStructure(dm)
		% Input argument:
        %   dm - cModelData object
        	obj=obj@cResultId(cType.ResultId.PRODUCTIVE_STRUCTURE);
			% Check/validate file content
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
			obj.cflw=cell(M,1);
			obj.cprc=cell(N1,1);
			obj.cstr=cell(2*N1,1);
			obj.ftypes=zeros(1,M);
            % Create flows structure
            fdata=data.flows;
			arrayfun(@(i) obj.createFlow(i,fdata(i)), 1:obj.NrOfFlows);
            if ~obj.status
                return
            end
            obj.fDict=cDictionary({fdata.key});
			if ~isValid(obj.fDict)
				obj.addLogger(obj.fDict);
				obj.messageLog(cType.ERROR,cMessages.DuplicatedFlow);
				return
			end
			if isempty(find(obj.ftypes==cType.Flow.RESOURCE,1))
				obj.messageLog(cType.ERROR,cMessages.NoResources);
				return
			end
			if isempty(find(obj.ftypes==cType.Flow.OUTPUT,1))
				obj.messageLog(cType.ERROR,cMessages.NoOutputs);
				return
			end
            % Create process structure
            pdata=data.processes;
			arrayfun(@(i) obj.createProcess(i,pdata(i)), 1:obj.NrOfProcesses);
            if ~obj.status
                return
            end
			obj.pDict=cDictionary({pdata.key});
			if ~isValid(obj.pDict)
				obj.addLogger(obj.pDict);
				obj.messageLog(cType.ERROR,cMessages.DuplicatedProcess);
				return
			end
            % Create productive groups (streams)
            obj.parser=cParseStream();
            for i=1:obj.NrOfProcesses
  				obj.createProcessStreams(i,cType.Stream.FUEL);
				obj.createProcessStreams(i,cType.Stream.PRODUCT);
            end
            if ~obj.status
                return
            end
            % Create enviroment elements
            obj.buildEnvironment;
			% Check Graph Connectivity
            if ~obj.checkFlowsConnectivity
				return
            end
            % Convert properties to structures
			obj.Flows=cell2mat(obj.cflw);
			obj.Streams=cell2mat(obj.cstr);
			obj.Processes=cell2mat(obj.cprc);
			% Build productive structure lists (internal)
			fto=[obj.Flows.to];
			ffrom=[obj.Flows.from];
			pstreams=obj.getProductStreams;
			pprocesses=[obj.Streams(pstreams).process];
			fstreams=obj.getFuelStreams;
			fprocesses=[obj.Streams(fstreams).process];
            % Adjancency Matrix
			NS=obj.NrOfStreams;
            mAE=sparse(1:M,fto,true(1,M),M,NS);
			mAS=sparse(ffrom,1:M,true(1,M),NS,M);
			mAF=sparse(fstreams,fprocesses,true(size(fstreams)),NS,N1);
			mAP=sparse(pprocesses,pstreams,true(size(pstreams)),N1,NS);
            obj.AdjacencyMatrix=struct('AE',mAE,'AS',mAS,'AF',mAF,'AP',mAP);
			if ~checkGraphConnectivity(obj)
				obj.messageLog(cType.ERROR,cMessages.InvalidProductiveGraph);
				return
			end
			obj.ModelName=data.name;
			obj.State='SUMMARY';
        end
		
		%%%%%
		% Public get properties
		%%%%%
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

		function res=get.SystemOutput(obj)
		% Get a structure with the flows, streams and processes defined as System Output
			res=cType.EMPTY;
			if obj.status
            	res.flows=[obj.FinalProducts.flows,obj.Waste.flows];
            	res.streams=[obj.FinalProducts.streams,obj.Waste.streams];
            	res.processes=[obj.FinalProducts.processes,obj.Waste.processes];
			end
        end

		%%%%%%
		% Public methods
		%%%%%%
		function res=buildResultInfo(obj,fmt)
		% buildResultInfo - Build the cResultInfo object for PRODUCTIVE_STRUCTURE
		% Syntax:
		%   res=obj.buildResultInfo(fmt)
		% Input Argument:
		%   fmt - cFormatData object
		% Output Argument
		%   res - cResultInfo object
			res=fmt.getProductiveStructure(obj);
		end
			
		function res=WasteData(obj)
		% WasteData - Get default waste data info
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
	
		function [res1,res2]=IncidenceMatrix(obj)
		% IncidenceMatrix - Get incidence matrices of the plant
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
		% StructuralMatrix - Get the Structural Theory Flows Adjacency Matrix
		% Syntax:
		%   res = obj.StructuralMatrix
		% Output Argument
		%   res - logical matrix
		%
			x=obj.AdjacencyMatrix;
			mI=eye(obj.NrOfStreams,"logical");
			res=x.AE*(mI+x.AF(:,1:end-1)*x.AP(1:end-1,:))*x.AS;
        end	
        
        function res=ProductiveMatrix(obj)
		% ProductiveMatrix - Get the Productive Adjacency Matrix (Streams, Flows, Processes)
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
		% FlowProcessMatrix - Get the Flow-Process Adjacency Matrix (Flows, Processes)
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
		% ProcessMatrix - Get the Process Adjacency Matrix (logical FP table)
		% Syntax:
		%   res = obj.ProcessMatrix
		% Output Argument:
		%   res - logical matrix
			x=obj.AdjacencyMatrix;
			tmp=x.AS*x.AE;
			tc=transitiveClosure(tmp);
			res=x.AP*tc*x.AF;
		end

		function res=FlowEdges(obj)
		% FlowEdges - Get a structure array with the stream edges names of the flows
		% Syntax:
		%   res = obj.FlowEdges
		% Output Argument:
		%   res - struct(from,to) defining the flow edges
		%
			res=cType.EMPTY;
			if ~obj.status
				return
			end
			from=[obj.Flows.from];
			to=[obj.Flows.to];
			res=struct('from',obj.StreamKeys(from),'to',obj.StreamKeys(to));
		end

		function res=isModelIO(obj)
		% isModelIO - Check if the model is Input-Output
		% Syntax:
		%   res=obj.isModelIO
		% Output Argument:
		%   true | false
			from=[obj.Flows.from];
			to=[obj.Flows.to];
			res=isempty(intersect(from,to));
		end
	
		function id=getProcessId(obj,key)
		% getProcessId - Get the Id of a process given its key
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
		% getFlowId - Get the Id of a flow given its key
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
		% getFlowTypes - Get the flowId of type typeId
		% Syntax:
		%   res = obj.getFlowTypes(typeId)
		% Input Arguments:
		%   typeId - Flow type id
		% Output Arguments:
		%   res - Array with the ids of the flows of this type
		%
			flowtypes=[obj.Flows.typeId];
			res=find(flowtypes==typeId);
		end
	
		function res=getProcessTypes(obj,typeId)
		% getProcessTypes - Get the process-id of type typeId
		% Syntax:
		%   res = obj.getProcessTypes(TypeId)
		% Input Arguments:
		%   typeId - Process type id
		% Output Arguments:
		%   res - Array with the ids of the processes of this type
		%
			processtypes=[obj.Processes.typeId];
			res=find(processtypes==typeId);
		end
	
		function res=getStreamTypes(obj,typeId)
		% getStreamTypes - Get the stream-id of type typeId
		% Syntax:
		%   res = obj.getStreamTypes(typeId)
		% Input Arguments:
		%   typeId - stream type id
		% Output Arguments:
		%   res - Array with the ids of the processes of this type
		%
			streamtypes=[obj.Streams.typeId];
			res=find(streamtypes==typeId);
		end
	
		function res=getProductStreams(obj)
		% getProductStreams - Get the product streams id (including resources)
		% Syntax:
		%   res = obj.getProductStreams
		% Output Arguments:
		%   res - Array with the product streams id
			streamtypes=[obj.Streams.typeId];
			res=find(bitget(streamtypes,cType.INTERNAL));
		end
	
		function res=getFuelStreams(obj)
		%getFuelStreams - Get the fuel streams id (including output and wastes)
		% Syntax:
		%   res = obj.getFuelStreams
		% Output Arguments:
		%   res - Array with the fuel streams id
			streamtypes=[obj.Streams.typeId];	
			res=find(~bitget(streamtypes,cType.INTERNAL));
		end

		function res=getResourceNames(obj)
		%getResourceNames - Get the name of the resource flows
		% Syntax:
		%   res = obj.getResourceNames
		% Output Arguments:
		%   res - Cell Array with the resource names
			res=obj.FlowKeys(obj.Resources.flows);
		end

		function res=getProductNames(obj)
		%getProductNames - Get the name of the final products flows
		% Syntax:
		%   res = obj.getProductNames
		% Output Arguments
		%   res - Cell Array with the final product names
			res=obj.FlowKeys(obj.FinalProducts.flows);
		end

		function res=getWasteNames(obj)
		%getWasteNames - Get the name of the waste flows
		% Syntax
		%   res = obj.getProductNames
		% Output Aguments
		%   res - Cell Array with the waste flow names
			res=obj.FlowKeys(obj.Waste.flows);
		end

		function [E,ET]=flows2Streams(obj,val)
		% flows2streams - Compute the exergy or cost of streams from flow values
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

    methods(Access=private)
        function createFlow(obj,id,data)
		% Check and create flow data
		% Input Arguments:
		%   id - Flow Id
		%   data - flows data
		%
			if ~ischar(data.key) % Check flow key
				obj.messageLog(cType.ERROR,cMessages.InvalidFlowId,id);
				return
			end
			if ~cType.checkTextKey(data.key)
				obj.messageLog(cType.ERROR,cMessages.InvalidTextKey,data.key);
				return
			end
            % Check flow Type
			typeId=cType.getFlowId(data.type);
            if isempty(typeId)
				obj.messageLog(cType.ERROR,cMessages.InvalidFlowType,data.type,data.key);
                return
            end
            % Create flow structure
            obj.cflw{id}=struct('id',id,'key',data.key,'type',data.type,...
                'typeId',typeId,'from',0,'to',0);
			obj.ftypes(id)=typeId;
        end

        function createProcess(obj,id,data)
		% Check and create process data
		% Input Arguments:
		%   id - Process Id
		%   data - Process data
		%
			if ~ischar(data.key) % Check Process Key
				obj.messageLog(cType.ERROR,cMessages.InvalidProcessId,id);
				return
			end
			if ~cType.checkTextKey(data.key)
				obj.messageLog(cType.ERROR,cMessages.InvalidTextKey,data.key);
				return
			end
			ptype=cType.getProcessId(data.type); %Check Process Type
			if isempty(ptype)	        
				obj.messageLog(cType.ERROR,cMessages.InvalidProcessType,data.type,data.key);
			end
			if ~cParseStream.checkProcess(data.fuel) % Check Fuel stream
				obj.messageLog(cType.ERROR,cMessages.InvalidFuelStream,data.fuel,data.key);
			end
			fl=cParseStream.getFlowsList(data.fuel);
			if ~obj.fDict.existsKey(fl)
				obj.messageLog(cType.ERROR,cMessages.InvalidFuelStream,data.fuel,data.key);
			end  
			if ~cParseStream.checkProcess(data.product) % Check Product stream
				obj.messageLog(cType.ERROR,cMessages.InvalidProductStream,data.product,data.key);
			end
			fl=cParseStream.getFlowsList(data.product);
			if ~obj.fDict.existsKey(fl)
				obj.messageLog(cType.ERROR,cMessages.InvalidProductStream,data.product,data.key);
			elseif ptype==cType.Process.DISSIPATIVE % Check disipative processes and waste flows
                for j=1:numel(fl)
					jkey=obj.fDict.getIndex(fl{j});
                    if obj.cflw{jkey}.typeId ~= cType.Flow.WASTE
				        obj.messageLog(cType.ERROR,cMessages.InvalidDissipative,obj.cflw{jkey}.key,data.key);
                    end
                end
			end             
            % Create process struct
            obj.cprc{id}=struct('id',id,'key',data.key,'type',data.type,'typeId',ptype,...
				'fuel',data.fuel,'product',data.product,...
                'fuelStreams',cType.EMPTY,'productStreams',cType.EMPTY);
        end

        function createProcessStreams(obj,id,fp)
	    % Create the the streams of a process
		% Input Arguments
        %   id - Process id
        %   fp - Indicates if stream is fuel or product
			order=0;
			ns=obj.NrOfStreams;     
            % Generate stream key
			pkey=obj.cprc{id}.key;
            switch fp
				case cType.Stream.FUEL
                    stype=cType.FUEL;
					descr=obj.cprc{id}.fuel;
					scode=strcat(pkey,'_F');
				case cType.Stream.PRODUCT
                    stype=cType.PRODUCT;
					descr=obj.cprc{id}.product;
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
                    return
                end
            end
            obj.NrOfStreams=ns;
			% Set the Fuel/Product streams to the processes
            switch fp
				case cType.Stream.FUEL
					obj.cprc{id}.fuelStreams=order;
				case cType.Stream.PRODUCT
					obj.cprc{id}.productStreams=order;
            end
        end

        function status=checkStreamFlows(obj,sid,expr,fp)
        % Assing the from/to stream of the flows
		% Input Arguments:
		%	sid - Stream Id
		%	expr - Stream definition
		%	fp - Stream type
		% Output Arguments:
		%   status - Result of the check true|false
		%
            switch fp
                case cType.Stream.FUEL
				    [fe,fs]=obj.parser.getFlows(expr);
			    case cType.Stream.PRODUCT
				    [fs,fe]=obj.parser.getFlows(expr);
            end
            % set input flows of the stream          
            for i=1:fe.Count
			    in=fe.getContent(i);
				idx=obj.fDict.getIndex(in);
                if idx
					if ~obj.cflw{idx}.to
					    obj.cflw{idx}.to=sid;
				    else
						obj.messageLog(cType.ERROR,cMessages.InvalidFlowToStream,obj.cflw{idx}.key);
					end
			    else
					obj.messageLog(cType.ERROR,cMessages.InvalidFlowKey,in);
                end
            end
            % set output flows of the stream
            for i=1:fs.Count
			    out=fs.getContent(i);
				idx=obj.fDict.getIndex(out);
                if idx
					if ~obj.cflw{idx}.from
					    obj.cflw{idx}.from=sid;
				    else
						obj.messageLog(cType.ERROR,cMessages.InvalidStreamToFlow,obj.cflw{idx}.key);
					end
			    else
					obj.messageLog(cType.ERROR,cMessages.InvalidFlowKey,out);
                end
            end
			status=obj.status;
        end

        function buildEnvironment(obj)
        % Create de environment entries for processes and streams
			iout=0;ires=0;iwst=0;      % Counters
			fdesc=cType.EMPTY_CHAR;
			pdesc=cType.EMPTY_CHAR;    % Stream Definition
			ns=obj.NrOfStreams;        % Number of streams global counter
            N1=obj.NrOfProcesses+1;    % Environment process Id
			env=find(obj.ftypes);      % Environment flows (OUTPUT, WASTE, RESOURCES)
            % Loop over Environment flows
			for i=env
				ftype=obj.cflw{i}.typeId;
                stype=obj.cflw{i}.type;
				descr=obj.cflw{i}.key;
				jt=obj.cflw{i}.to;
				jf=obj.cflw{i}.from;
				ns=ns+1;
				switch ftype
    				case cType.Flow.OUTPUT % System Output Flows
					    iout=iout+1;
					    scode=sprintf('ENV_O%d', iout);
					    fdesc=strcat(fdesc,'+',descr);
                        if ~jt % Check if flow is OUTPUT
						    obj.cflw{i}.to=ns;
				        else
					        obj.messageLog(cType.ERROR,cMessages.InvalidOutputFlow,obj.cflw{i}.key);
                        end
                        if jf
						    k=obj.cstr{jf}.process;
                            if (obj.cprc{k}.typeId == cType.Process.DISSIPATIVE)
					    	    obj.messageLog(cType.ERROR,cMessages.InvalidOutputFlow,obj.cflw{i}.key);
                            end
                        end		
                    case cType.Flow.WASTE %Waste flows
					    iwst=iwst+1;
					    scode=sprintf('ENV_W%d', iwst);
					    fdesc=strcat(fdesc,'+',descr);
                        if ~jt % Check if flow is WASTE
						    obj.cflw{i}.to=ns;	
					    else
					        obj.messageLog(cType.ERROR,cMessages.InvalidWasteFlow,obj.cflw{i}.key);
                        end
                        if jf
						    k=obj.cstr{jf}.process;
                            if (obj.cprc{k}.typeId == cType.Process.PRODUCTIVE)
					    	    obj.messageLog(cType.ERROR,cMessages.InvalidWasteFlow,obj.cflw{i}.key);
                            end
                        end
				    case cType.Flow.RESOURCE
					    ires=ires+1;
					    scode=sprintf('ENV_R%d', ires);
					    pdesc=strcat(pdesc,'+',descr);
                        if ~jf % Check if flow is a resource
						    obj.cflw{i}.from=ns;				
					    else
					        obj.messageLog(cType.ERROR,cMessages.InvalidResourceFlow,obj.cflw{i}.key);
                        end
				end
				obj.cstr{ns}=struct('id',ns,'key',scode,'definition',descr,'type',stype,'typeId',ftype,'process',N1);
			end
            % Update number of streams and wastes
			obj.NrOfStreams=ns;
            obj.NrOfWastes=iwst;
			obj.NrOfResources=ires;
			obj.NrOfFinalProducts=iout;
			obj.NrOfSystemOutputs=iwst+iout;
			% Create environment process record
            obj.cprc{N1}=struct('id',N1,'key','ENV','type','ENVIRONMENT','typeId',cType.Process.ENVIRONMENT,...
				'fuel',fdesc(2:end),'product',pdesc(2:end), ...
                'fuelStreams',obj.NrOfSystemOutputs,'productStreams',obj.NrOfResources);
        end

        function res=checkFlowsConnectivity(obj)
        % Check the connectivity of flow id
		% Output:
		%   res - true | false indicating is the flow edges are well defined
		%   
			for id=1:obj.NrOfFlows
				if (obj.cflw{id}.from==obj.cflw{id}.to) %Check if there is a loop
					if obj.cflw{id}.from==0
						obj.messageLog(cType.ERROR,cMessages.InvalidFlowDefiniton,obj.cflw{id}.key);
					else
						obj.messageLog(cType.ERROR,cMessages.InvalidFlowLoop,obj.cflw{id}.key);
					end
				elseif (obj.cflw{id}.from==0) && (obj.cflw{id}.to~=0) % Check invalid FROM definition
					obj.messageLog(cType.ERROR,cMessages.InvalidStreamToFlow,obj.cflw{id}.key);
				elseif (obj.cflw{id}.to==0) && (obj.cflw{id}.from~=0) % Check invalid TO definition
					obj.messageLog(cType.ERROR,cMessages.InvalidFlowToStream,obj.cflw{id}.key);
				end
			end
			res=obj.status;
        end

        function res=checkGraphConnectivity(obj)
		% Check the graph connectivity
		%   The algorithm calculates the transitive closure (logical inverse matrix)
		%   of the Stream Process Matrix
		% Output:
		%   res - true | false indicating if the productive graph is a network
		%
			x=obj.AdjacencyMatrix;
			A=x.AS*x.AE+x.AF*x.AP;
			E=eye(size(A))+transitiveClosure(A);
			y1=x.AP(end,:)*E; 
			y2=E*x.AF(:,end);
			res=all(y1) && all(y2');
		end

    end

end