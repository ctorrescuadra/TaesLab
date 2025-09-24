classdef cProductiveStructure < cResultId
%cProductiveStructure - Build the productive structure of a plant.
%   Create the cProductiveStructure object a cModelData object.
%   The productive structure includes information about:
%   - Flows, Processes and Productive Groups (Streams)
%   - The adjacency matrix of the productive graph
%   The constructor checks the data model and build the productive structure.
%   If the data model is not valid, the object status is set to false and
%   the message log contains the errors found.	
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
%     FlowKeys          - Cell array of Flows Names (keys)
%     ProcessKeys       - Cell array of Processes Names (keys)
%     StreamKeys        - Cell array of Streams Names (keys)
%     ProductiveTable   - Adjacency Matrix of the productive structure graph
%     
%   cProductiveStructure methods:
%     buildResultInfo   - Build the cResultInfo object for PRODUCTIVE_STRUCTURE
%     WasteData         - Get the default waste data
%     IncidenceMatrix   - Get the incidence matrices
%     getStreamMatrix      - Get the productive groups adjacency matrix 
%     getFlowMatrix        - Get the flows adjacency matrix
%     getProcessMatrix     - Get the process matrix (Logical FP matrix)
%     getProductiveMatrix  - Get the productive adjacency matrix
%     getFlowProcessMatrix - Get the flow-process adjacency matrix
%     FlowEdges         - Get the flow edges definition names 
%     FuelStreams       - Get the Fuel streams ids
%     ProductStreams    - Get the Product streams ids
%     ResourceFlows     - Get the Resource Flows id
%     FinalProductFlows - Get the Final Products Flows id
%     SystemOutputFlows - Get the System Output Flows id
%     ResourceProcesses - Get the Processes with external resources
%     OutputProcesses   - Get the Processes with system outputs
%     isModelIO         - Check if model is pure Input-Output
%     getProcessId      - Get the process Id given the name
%     getFlowId         - Get the flow Id given the name
%     getFlowTypes      - Get the flows id of type typeId
%     getProcessTypes   - Get the process id of type typeId
%     getStreamTypes    - Get the stream id of type typeId
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
        FlowKeys          % Cell array of Flows Names (keys)
        ProcessKeys       % Cell array of Processes Names (keys)
        StreamKeys        % Cell array of Streams Names (keys)
		ProductiveTable   % Adjacency Matrix of Productive Structure
		ProcessDigraph	  % Process Digraph (cDigraphAnalysis)	
	end

    properties(Access=private)
		cstr            % Internal streams cell array
		fDict           % Flows key dictionary
		pDict           % Processes key dictionary
    end

    methods
		function obj = cProductiveStructure(dm)
		%cProductiveStructure - Creates an instance of the class
		%   Syntax:
		%     obj = cProductiveStructure(dm)
		% 	Input Arguments:
		%     dm - cModelData object	
		%   Output Arguments:
		%     obj - cProductiveStructure object
		%
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
            % Create flows structure and dictionary
			success = obj.createFlowsStructure(data.flows);
			if ~success
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
			success=obj.createProcessesStructure(data.processes);
            if ~success
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
			obj.ModelName=data.name;
			obj.State='SUMMARY';
        end
		
		%%%%%
		% Public get properties
		%%%%%
		function res=get.Waste(obj)
		% Get an array with flows defined as waste.
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
		%   Syntax:
		%     res=obj.buildResultInfo(fmt)
		%   Input Argument:
		%     fmt - cFormatData object
		%   Output Argument
		%     res - cResultInfo object
			res=fmt.getProductiveStructure(obj);
		end
			
		function res=WasteData(obj)
		%WasteData - Get default waste data info
		%   Syntax:
		%     res=obj.WasteData
		%   Output Argument:
		%     res - Waste data info structure
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
		%IncidenceMatrix - Get incidence matrices of the plant
		%   Syntax:
		%     [res1,res2] = obj.IncidenceMatrix
		%   Output Arguments:
		%	  if output arguments are 2
		%       res1 - Fuel Incidence Matrix
		%       res2 - Product Incidence matrix
		%     if output argument is 1
		%       res1 - Incidence Matrix 
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
		%StreamMatrix - Get the Streams graph adjacency matrix
		%   Syntax:
		%     res = obj.StreamMatrix
		%   Output Argument
		%     res - streams adjacency matrix
		%     src - external resources adjacency matrix
		%     out - output streams adjacency matrix
		%
			x=obj.ProductiveTable;
			res=x.AS*x.AE+x.AF(:,1:end-1)*x.AP(1:end-1,:);
			if nargout>1
				src=x.AP(end,:);
				out=x.AF(:,end);
			end
        end
	
		function [res,src,out]=getFlowMatrix(obj)
		%StructuralMatrix - Get the Structural Theory Flows Adjacency Matrix
		%   Syntax:
		%     res = obj.StructuralMatrix
		%   Output Argument
		%     res - flows adjacency matrix 
		%     src - external resources adjacency matrix
		%     out - output streams adjacency matrix
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
		%ProcessMatrix - Get the Process Adjacency Matrix (logical FP table)
		%   Syntax:
		%     res = obj.ProcessMatrix
		%   Output Argument:
		%     res - process adjacency matrix 
		%     src - external resources adjacency matrix
		%     out - output streams adjacency matrix
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
		%ProductiveMatrix - Get the Productive Adjacency Matrix (Streams, Flows, Processes)
		%   Syntax:
		%     res = obj.ProductiveMatrix
		%   Output Argument:
		%     res - logical matrix
			x=obj.ProductiveTable;
			N=obj.NrOfProcesses;
			M=obj.NrOfFlows;
			NS=obj.NrOfStreams;
			res=[zeros(NS,NS), x.AS, x.AF(:,1:end-1);...
			     x.AE, zeros(M,M), zeros(M,N);...
				 x.AP(1:end-1,:), zeros(N,M), zeros(N,N)];
		end
			
		function res=getFlowProcessMatrix(obj)
		%FlowProcessMatrix - Get the Flow-Process Adjacency Matrix (Flows, Processes)
		%   Syntax:
		%     res = obj.FlowProcessMatrix
		%   Output Argument:
		%     res - logical matrix
			x=obj.ProductiveTable;
			N=obj.NrOfProcesses;
			res=[x.AE*x.AS,x.AE*x.AF(:,1:end-1);...
			x.AP(1:end-1,:)*x.AS,zeros(N,N)];
		end

		function res=FlowEdges(obj)
		%FlowEdges - Get a structure array with the stream node names of the flow edges
		%   Syntax:
		%     res = obj.FlowEdges
		%   Output Argument:
		%     res - struct(from,to) defining the flow edges
		%
			res=cType.EMPTY;
			if ~obj.status
				return
			end
			from=[obj.Flows.from];
			to=[obj.Flows.to];
			res=struct('from',obj.StreamKeys(from),'to',obj.StreamKeys(to));
		end

		function res=ProductStreams(obj)
		%ProductStreams - Get the product streams id (including resources)
		%   Syntax:
		%     res = obj.ProductStreams
		%   Output Arguments:
		%     res - Array with the product streams id
			streamtypes=[obj.Streams.typeId];
			res=find(bitget(streamtypes,cType.INTERNAL));
		end
	
		function res=FuelStreams(obj)
		%FuelStreams - Get the fuel streams id (including output and wastes)
		%   Syntax:
		%     res = obj.FuelStreams
		%   Output Arguments:
		%     res - Array with the fuel streams id
			streamtypes=[obj.Streams.typeId];	
			res=find(~bitget(streamtypes,cType.INTERNAL));
		end

		function res=ResourceFlows(obj)
		%ResourceFlows - Get the resource flows id
		%   Syntax: 
		%     res = ResourceFlows(obj)
		%   Output Arguments:
		%     res - Array with the resource flows id
			res=getFlowTypes(obj,cType.Flow.RESOURCE);
		end

		function res=FinalProductFlows(obj)
		%FinalProductFlows - Get the final product flows id
		%   Syntax: 
		%     res = FinalProductFlows(obj)
		%   Output Arguments:
		%     res - Array with the final products flows id
			res=getFlowTypes(obj,cType.Flow.OUTPUT);
		end

		function res=SystemOutputFlows(obj)
		%SystemOutputFlows - Get the system output flows id
		%   Syntax: 
		%     res = SystemOutputFlows(obj)
		%   Output Arguments:
		%     res - Array with the system output flows id
			out=getFlowTypes(obj,cType.Flow.OUTPUT);
			waste=getFlowTypes(obj,cType.Flow.WASTE);
            res=[out,waste];
        end

		function res=ResourceProcesses(obj)
		%ResourceProcesses - Get the id of processes with external resources
		%   Syntax: 
		%     res = ResourceProcesses(obj)
		%   Output Arguments:
		%     res - Array with the resource processes id
			res=find(obj.ProcessMatrix(end,1:end-1));
		end

		function res=OutputProcesses(obj)
		%OutputProcesses - Get the id of processes with external outputs
		%   Syntax: 
		%     res = OutputProcesses(obj)
		%   Output Arguments:
		%     res - Array with the system output processes id
			res=transpose(find(obj.ProcessMatrix(1:end-1,end)));
		end

		function res=isModelIO(obj)
		%isModelIO - Check if the model is pure Input-Output
		%   Syntax:
		%     res=obj.isModelIO
		%   Output Argument:
		%     true | false
			from=[obj.Flows.from];
			to=[obj.Flows.to];
			res=isempty(intersect(from,to));
		end
	
		function id=getProcessId(obj,key)
		%getProcessId - Get the Id of a process given its key
		%   Syntax:
		%     id = obj.getProcessId(key)
		%   Input Argument:
		%     key - process key
		%   Output Argument
		%     id - Process Id:
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
		%   Syntax:
		%     id = obj.getFlowId(key)
		%   Input Argument:
		%     key - flow key
		%   Output Argument
		%     id - flow Id:
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
		%getFlowTypes - Get the flowId of type typeId
		%   Syntax:
		%     res = obj.getFlowTypes(typeId)
		%   Input Arguments:
		%     typeId - Flow type id
		%   Output Arguments:  
		%     res - Array with the ids of the flows of this type
		%
            ftypes=[obj.Flows.typeId];
			res=find(ftypes==typeId);
		end
	
		function res=getProcessTypes(obj,typeId)
		%getProcessTypes - Get the process-id of type typeId
		%   Syntax:
		%     res = obj.getProcessTypes(TypeId)
		%   Input Arguments:
		%     typeId - Process type id
		%   Output Arguments:
		%     res - Array with the ids of the processes of this type
		%
            ptypes=[obj.Processes.typeId];
			res=find(ptypes==typeId);
		end
	
		function res=getStreamTypes(obj,typeId)
		%getStreamTypes - Get the stream-id of type typeId
		%   Syntax:
		%     res = obj.getStreamTypes(typeId)
		%   Input Arguments:
		%     typeId - stream type id
		%   Output Arguments:
		%     res - Array with the ids of the processes of this type
		%
            stypes=obj.Streams.typeId;
			res=find(stypes==typeId);
		end

		function res=getResourceNames(obj)
		%getResourceNames - Get the name of the resource flows
		%   Syntax:
		%     res = obj.getResourceNames
		%   Output Arguments:
		%     res - Cell Array with the resource names
			res=obj.FlowKeys(obj.ResourceFlows);
		end

		function res=getProductNames(obj)
		%getProductNames - Get the name of the final products flows
		%   Syntax:
		%     res = obj.getProductNames
		%   Output Arguments
		%     res - Cell Array with the final product names
			res=obj.FlowKeys(obj.FinalProductsFlows);
		end

		function res=getWasteNames(obj)
		%getWasteNames - Get the name of the waste flows
		%   Syntax
		%     res = obj.getProductNames
		%   Output Aguments
		%     res - Cell Array with the waste flow names
			  res=obj.FlowKeys(obj.Waste.flows);
		end

		function [E,ET]=flows2Streams(obj,val)
		%flows2streams - Compute the exergy or cost of streams from flow values
		%   Syntax:
		%     res = obj.flows2Streams(values)
		%   Input Arguments
		%     values - exergy/cost values
		%   Output Arguments
		%     E  - exergy/cost of streams
		%     ET - Total exergy of streams
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
		function log = createFlowsStructure(obj, data)
		%CreateFlowsStructure - Check and create the flows structure array
		%   Syntax:
		%     log = obj.createFlowsStructure(data)
		%   Input Arguments:
		%     data - Flows data strcture array
		%   Output Arguments:
		%     log - Result of the check true|false
		%
			% Create Flows structure array
			M = length(data);
			[tst,ftypes]=cType.checkFlowTypes({data.type});
            if ~tst 
                obj.messageLog(cType.ERROR,'Invalid Flow Types')
            end
			obj.Flows= struct('id', num2cell(1:M), ...
				'key', {data.key}, ...
				'type', {data.type}, ...
				'typeId', num2cell(ftypes'), ...
				'from', 0, 'to', 0);
			log = obj.status;
        end

        function log=createProcessesStructure(obj,data)
		%CreateProcessesStructure - Check and create the processes structure array
		%   Syntax:
		%	  log = obj.createProcessesStructure(data)
		%   Input Arguments:
		%	 data - Processes data structure array
		%   Output Arguments:
		%    log - Result of the check true|false
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
				if ~cParseStream.checkDefinitionFP(prc.fuel)
					obj.messageLog(cType.ERROR,cMessages.InvalidFuelStream,prc.fuel,prc.key);
				end
				fl=cParseStream.getFlowsList(prc.fuel);
				if ~obj.fDict.existsKey(fl)
					obj.messageLog(cType.ERROR,cMessages.InvalidFuelStream,prc.fuel,prc.key);
				end
				% Check Product stream
				prc.product=regexprep(prc.product,cType.SPACES,cType.EMPTY_CHAR);
				if ~cParseStream.checkDefinitionFP(prc.product) 
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
			log = obj.status;
        end

        function createProcessStreams(obj,id,fp)
		%CreateProcessStreams - Create the streams of a process
		%   Syntax:
		%     obj.createProcessStreams(id,fp)
		%   Input Arguments:
		%     id - Process Id
		%     fp - Stream type (cType.Stream.FUEL | cType.Stream.PRODUCT)
		%	 Output Arguments:
		%	   none
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
            [fe,fs]=cParseStream.getStreamFlows(expr,fp);
            % set input flows of the stream          
            for i=1:length(fe)
			    in=fe{i};
				idx=obj.fDict.getIndex(in);
                if idx
					if ~obj.Flows(idx).to
					    obj.Flows(idx).to=sid;
				    else
						obj.messageLog(cType.ERROR,cMessages.InvalidFlowToStream,obj.Flows(idx).key);
					end
			    else
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
						obj.messageLog(cType.ERROR,cMessages.InvalidStreamToFlow,obj.Flows(idx).key);
					end
			    else
					obj.messageLog(cType.ERROR,cMessages.InvalidFlowKey,out);
                end
            end
			status=obj.status;
        end

        function res=buildEnvironment(obj)
		%buildEnvironment - Create the environment streams and update flows and processes info
		%   Syntax:
		%     res = obj.buildEnvironment
		%   Output Arguments:
		%     res - true | false indicating if the environment was built ok
		%
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
		%	
			% Get the from and to of the flows
			from=[obj.Flows.from]; to=[obj.Flows.to];
            % Check loops and not defined from/to flows
			idx=find(from==to);
			for i=idx
				if from(i) %Check if there is a loop
					obj.messageLog(cType.ERROR,cMessages.InvalidFlowLoop,obj.Flows(i).key);
				else %Check if is a no defined flow
					obj.messageLog(cType.ERROR,cMessages.InvalidFlowDefinition,obj.Flows(i).key);
				end
			end
            % Check invalid FROM definition
			jdx=setdiff(find(~from),idx);
            for i=jdx
				obj.messageLog(cType.ERROR,cMessages.InvalidStreamToFlow,obj.Flows(i).key);
            end
            % Check invalid TO definition
			jdx=setdiff(find(~to),idx); 
            for i=jdx
				obj.messageLog(cType.ERROR,cMessages.InvalidFlowToStream,obj.Flows(i).key);
            end
			res=obj.status;
        end

        function res=checkGraphConnectivity(obj)
		%checkGraphConnectivity - Check the productive graph connectivity.
		%   The function checks that all nodes are connected from the source (resources)
		%   and	 that all nodes can reach the sink (final products).	
		%   Syntax:	
		%     res = obj.checkGraphConnectivity	
		%   Output Arguments:		
		%     res - true | false indicating if the graph is ok
		%
			% Build the SSR graph adjacency matrix
			% Build the SSR graph adjacency matrix
			tfp=obj.getProcessMatrix;
			nodes=obj.ProcessKeys;
			sc=cDigraphAnalysis(tfp,nodes);
			[res,src,out]=sc.isProductive;
			% Compute the transitive closure
			% Log non-SSR nodes
			if res
				obj.ProcessDigraph=sc;
			else
				for i=1:numel(src)
					obj.messageLog(cType.ERROR,cMessages.NodeNotReachedFromSource,src{i});
				end
            	for i=1:numel(out)
					obj.messageLog(cType.ERROR,cMessages.OutputNotReachedFromNode,out{i});
            	end
			end
		end
    end
end