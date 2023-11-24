classdef cProductiveStructureCheck < cResultId
% cReadProductiveModel gets and validates the productive structure data model
% 	Methods:
% 		obj=readProductiveStructure(data)
% See also cProductiveStructure
%
	properties(GetAccess=public,SetAccess=private)	
		NrOfProcesses	% Number of processes
		NrOfFlows       % Number of flows
		NrOfStreams	    % Number of streams
		NrOfWastes      % Number of Wastes
		Processes		% Processes info
		Flows			% Flows info
		Streams			% Streams info
	end
	properties(Access=protected)
		fDict           % Flows key dictionary
		pDict           % Processes key dictionary
        flowtypes       % Flows typeId array
        processtypes    % Process typeId array
        streamtypes     % Stream typeId array
    end
    properties(Access=private)
		cflw			% Internal flows cell array
		cstr            % Internal streams cell array
		cprc            % Internal processes cell array
        parser          % cStreamParser object
    end

    methods
		function obj = cProductiveStructureCheck(data)
		% Class constructor.
        %   data - flow/process data structure from cReadDataModel
        	obj=obj@cResultId(cType.ResultId.PRODUCTIVE_STRUCTURE);
			% Check/validate file content
			if (nargin~=1) || ~isstruct(data) 
				obj.messageLog(cType.ERROR,'Invalid data model');
				return
			end
			% Check data structure
            if ~all(isfield(data,{'flows','processes'}))
				obj.messageLog(cType.ERROR,'Invalid data model. Fields Missing');
				return
            end
            if ~all(isfield(data.flows,{'key','type'}))
                obj.messageLog(cType.ERROR,'Invalid flows data. Fields Missing');
				return
            end
            if ~all(isfield(data.processes,{'key','fuel','product','type'}))
				obj.messageLog(cType.ERROR,'Invalid processes data. Fields Missing');
				return
            end
            % Initialize productive structure info
			obj.status=cType.VALID;
			obj.NrOfProcesses=numel(data.processes);
			obj.NrOfFlows=numel(data.flows);
			obj.NrOfStreams=0;
			N1=obj.NrOfProcesses+1;
			M=obj.NrOfFlows;
			obj.cflw=cell(M,1);
			obj.cprc=cell(N1,1);
			obj.cstr=cell(2*N1,1);
            % Create flows structure
            fdata=data.flows;
            for i=1:obj.NrOfFlows
                obj.createFlow(i,fdata(i));
            end
            if ~isValid(obj)
                return
            end
            obj.fDict=cDictionary({fdata.key});
            % Create products structure
            pdata=data.processes;
            for i=1:obj.NrOfProcesses
                obj.createProcess(i,pdata(i));
            end
            if ~isValid(obj)
                return
            end
			obj.pDict=cDictionary({pdata.key});
            % Create productive groups (streams)
            obj.parser=cParseStream();
            for i=1:obj.NrOfProcesses
  				obj.createProcessStreams(i,cType.Stream.FUEL);
				obj.createProcessStreams(i,cType.Stream.PRODUCT);
            end
            if ~isValid(obj)
                return
            end
            % Create enviroment elements
            obj.buildEnvironment;
			% Check Graph Connectivity
            if ~obj.checkGraphConnectivity
				obj.messageLog(cType.ERROR,'Invalid productive structure graph');
				return
            end
            % Convert to structure and build typeId arrays
            if isValid(obj)
			    obj.Flows=cell2mat(obj.cflw);
			    obj.Streams=cell2mat(obj.cstr);
			    obj.Processes=cell2mat(obj.cprc);            
                obj.flowtypes=[obj.Flows.typeId];
			    obj.streamtypes=[obj.Streams.typeId];
			    obj.processtypes=[obj.Processes.typeId];
            end
        end
    end

    methods(Access=private)
        function createFlow(obj,id,data)
		% Check and create flow data
			if ~ischar(data.key) % Check flow key
				obj.messageLog(cType.ERROR,'Invalid flow keyId %d',id);
				return
			end
			if ~cType.checkTextKey(data.key)
				obj.messageLog(cType.ERROR,'Invalid flow key %s',data.key);
				return
			end
            % Check flow Type
			typeId=cType.getFlowId(data.type);
            if cType.isEmpty(typeId)
				obj.messageLog(cType.ERROR,'Invalid type %s for flow %s',data.type,data.key);
                return
            end
            % Create flow structure
            obj.cflw{id}=struct('id',id,'key',data.key,'type',data.type,...
                'typeId',typeId,'from',0,'to',0);
        end

        function createProcess(obj,id,data)
		% Check and create process data
			if ~ischar(data.key) % Check Process Key
				obj.messageLog(cType.ERROR,'Invalid process keyId %d',id);
				return
			end
			if ~cType.checkTextKey(data.key)
				obj.messageLog(cType.ERROR,'Invalid process key %s',data.key);
				return
			end
			ptype=cType.getProcessId(data.type); %Check Process Type
			if cType.isEmpty(ptype)	        
				obj.messageLog(cType.ERROR,'Invalid type %s in process %s',data.type,data.key);
			end
			if ~cParseStream.checkProcess(data.fuel) % Check Fuel stream
				obj.messageLog(cType.ERROR,'Invalid fuel stream %s in process %s',data.fuel,data.key);
			end
			fl=cParseStream.getFlowsList(data.fuel);
			if ~obj.fDict.existsKey(fl)
				obj.messageLog(cType.ERROR,'Invalid fuel flow %s in process %s',data.fuel,data.key);
			end  
			if ~cParseStream.checkProcess(data.product) % Check Product stream
				obj.messageLog(cType.ERROR,'Invalid product stream %s in process %s',data.product,data.key);
			end
			fl=cParseStream.getFlowsList(data.product);
			if ~obj.fDict.existsKey(fl)
				obj.messageLog(cType.ERROR,'Invalid product flow %s in process %s',data.product,data.key);
			elseif ptype==cType.Process.DISSIPATIVE % Check disipative processes and waste flows
                for j=1:numel(fl)
					jkey=obj.fDict.getIndex(fl{j});
                    if obj.cflw{jkey}.typeId ~= cType.Flow.WASTE
				        obj.messageLog(cType.ERROR,'Product %s of dissipative process %s must be a waste',obj.cflw{jkey}.key,data.key);
                    end
                end
			end             
            % Create process struct
            obj.cprc{id}=struct('id',id,'key',data.key,'type',data.type,'typeId',ptype,...
				'fuel',data.fuel,'product',data.product,...
                'fuelStreams',[],'productStreams',[]);
        end

        function createProcessStreams(obj,id,fp)
	    % Create the the streams of a process
        %   id - Process id
        %   fp - Indicates if stream is fuel or product
			ns=obj.NrOfStreams;     
            order=0;
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
            tmp=zeros(1,length(list));
            for i=1:length(list)		
				expr=list{i};
				ns=ns+1;
                order=order+1;
                tmp(i)=ns;
				key=sprintf('%s%d',scode,order);
                [finp,fout]=obj.getStreamFlows(ns,expr,fp);
                if isValid(obj)
				    obj.cstr{ns}=struct('id',ns,'key',key,'definition',expr,...
				    'type',stype,'typeId',fp,'process',id,'InputFlows',finp,'OutputFlows',fout);
                else
                    return
                end
            end
            obj.NrOfStreams=ns;
			% Set the Fuel/Product streams to the processes
            switch fp
				case cType.Stream.FUEL
					obj.cprc{id}.fuelStreams=tmp;
				case cType.Stream.PRODUCT
					obj.cprc{id}.productStreams=tmp;
            end
        end

        function [finp,fout]=getStreamFlows(obj,sid,expr,fp)
        % Get the input and output flows of a stream
		%	Input:
		%		sid - Stream Id
		%		expr - Stream definition
		%		fp - Stream type
		%	Output:
		%		fin - Array containing the flow id of the stream input flows
		%		fout - Array containing the flow id of the stream output flows
            switch fp
                case cType.Stream.FUEL
				    [fe,fs]=obj.parser.getFlows(expr);
			    case cType.Stream.PRODUCT
				    [fs,fe]=obj.parser.getFlows(expr);
            end
            % set input flows of the stream          
            finp=zeros(1,fe.Count);
            for i=1:fe.Count
			    in=fe.Content{i};
				idx=obj.fDict.getIndex(in);
                if ~cType.isEmpty(idx)
					if ~obj.cflw{idx}.to
					    obj.cflw{idx}.to=sid;
				    else
						obj.messageLog(cType.WARNING,'Flow %s has not correct (TO) definition',obj.cflw{i}.key);
					end
			    else
					obj.messageLog(cType.WARNING,'Flow %s is not defined',in);
                end
                finp(i)=idx;
            end
            % set output flows of the stream
            fout=zeros(1,fs.Count);
            for i=1:fs.Count
			    in=fs.Content{i};
				idx=obj.fDict.getIndex(in);
                if ~cType.isEmpty(idx)
					if ~obj.cflw{idx}.from
					    obj.cflw{idx}.from=sid;
				    else
						obj.messageLog(cType.WARNING,'Flow %s has not correct (FROM) definition',obj.cflw{i}.key);
					end
			    else
					obj.messageLog(cType.WARNING,'Flow %s is not defined',in);
                end
                fout(i)=idx;
            end
        end

        function buildEnvironment(obj)
        % Create de environment entries for processes and streams
			iout=0;ires=0;iwst=0; % Counters
			fdesc='';pdesc='';    % Stream Definition
			ns=obj.NrOfStreams;   % Number of streams global counter
            ftypes=cellfun(@(x) x.typeId, obj.cflw');
            env=find(ftypes);     % Environment flows (OUTPUT, WASTE, RESOURCES)
            M=length(env);
            fstr=zeros(1,M);      % Initialize Fuel streams of environment
            pstr=zeros(1,M);      % Initialize Product streams of environment
            N1=obj.NrOfProcesses+1; % Environment process Id
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
					    fe=[]; fs=obj.cflw{i}.id;
					    scode=sprintf('ENV_O%d', iout);
					    fdesc=strcat(fdesc,'+',descr);
                        if ~jt % Check if flow is OUTPUT
						    obj.cflw{i}.to=ns;
				        else
					        obj.messageLog(cType.WARNING,'Output flow %s has not correct (TO) definition',obj.cflw{i}.key);
                        end
                        if jf
						    k=obj.cstr{jf}.process;
                            if (obj.cprc{k}.typeId == cType.Process.DISSIPATIVE)
					    	    obj.messageLog(cType.WARNING,'Flow %s should be defined as OUTPUT',obj.cflw{i}.key);
                            end
                        end		
                	    fstr(iout)=ns;
                    case cType.Flow.WASTE %Waste flows
                        iout=iout+1;
					    iwst=iwst+1;
					    fe=[]; fs=obj.cflw{i}.id;
					    scode=sprintf('ENV_W%d', iwst);
					    fdesc=strcat(fdesc,'+',descr);
                        if ~jt % Check if flow is WASTE
						    obj.cflw{i}.to=ns;	
					    else
					        obj.messageLog(cType.WARNING,'Waste flow %s has not correct (TO) definition',obj.cflw{i}.key);
                        end
                        if jf
						    k=obj.cstr{jf}.process;
                            if (obj.cprc{k}.typeId == cType.Process.PRODUCTIVE)
					    	    obj.messageLog(cType.WARNING,'Flow %s should be defined as OUTPUT',obj.cflw{i}.key);
                            end
                        end
                        fstr(iout)=ns;
				    case cType.Flow.RESOURCE
					    ires=ires+1;
					    fs=[]; fe=obj.cflw{i}.id;
					    scode=sprintf('ENV_R%d', ires);
					    pdesc=strcat(pdesc,'-',descr);
                        if ~jf % Check if flow is a resource
						    obj.cflw{i}.from=ns;				
					    else
					        obj.messageLog(cType.WARNING,'Resource flow %s has not correct (FROM) definition',obj.cflw{i}.key);
                        end
                	    pstr(ires)=ns;
				end
				obj.cstr{ns}=struct('id',ns,'key',scode,'definition',descr,'type',stype,'typeId',ftype,'process',N1,...
					'InputFlows',fe,'OutputFlows',fs);	
			end
            % Update number of streams and wastes
			obj.NrOfStreams=ns;
            obj.NrOfWastes=iwst;
			% Create environment process record
            obj.cprc{N1}=struct('id',N1,'key','ENV','type','ENVIRONMENT','typeId',cType.Process.ENVIRONMENT,...
				'fuel',fdesc(2:end),'product',pdesc(2:end), ...
                'fuelStreams',fstr(1:iout),'productStreams',pstr(1:ires));
        end

        function res=checkFlowConnectivity(obj,id)
        % Check the connectivity of flow id
		%	Input:
		%		id - Id of the flow
			res=false;
			if (obj.cflw{id}.from==obj.cflw{id}.to) %Check if there is a loop
				if obj.cflw{id}.from==0
					obj.messageLog(cType.WARNING,'Flow %s do not exist',obj.cflw{id}.key);
				else
					obj.messageLog(cType.WARNING,'Flow %s is defined as a LOOP',obj.cflw{id}.key);
				end
			elseif (obj.cflw{id}.from==0) && (obj.cflw{id}.to~=0) % Check invalid FROM definition
				obj.messageLog(cType.WARNING,'Flow %s has not correct (FROM) definition',obj.cflw{id}.key);
			elseif (obj.cflw{id}.to==0) && (obj.cflw{id}.from~=0) % Check invalid TO definition
				obj.messageLog(cType.WARNING,'Flow %s has not correct (TO) definition',obj.cflw{id}.key);
			else
				res=true;
			end
        end

        function res=checkGraphConnectivity(obj)
        % Get the productive structure graph and check its conectivity
			res=false;
			N=obj.NrOfProcesses;
            NS=obj.NrOfStreams;
            NL=NS+N+2;
            sNode=NL-1;
            tNode=NL;
			G=false(NL,NL);
            % Flows connections
			for i=1:obj.NrOfFlows
				if obj.checkFlowConnectivity(i)
					idx=obj.cflw{i}.from;
					jdx=obj.cflw{i}.to;
					G(idx,jdx)=true;
				end
			end
			if ~obj.isValid
				return
			end
            % Stream Process connections
            for i=1:NS
				str=obj.cstr{i};
				switch str.typeId
				case cType.Stream.FUEL
					jdx=str.process+NS;
					G(i,jdx)=true;
				case cType.Stream.PRODUCT
					idx=str.process+NS;
					G(idx,i)=true;
				case cType.Stream.RESOURCE
					G(sNode,i)=true;
    				otherwise
					G(i,tNode)=true;
				end
            end
            % Compute direct and reverse connectivity
            sc=bfs(sparse(G),sNode); 
            tc=bfs(sparse(G'),tNode);
			res=all(sc) && all(tc);
		end
    end
end