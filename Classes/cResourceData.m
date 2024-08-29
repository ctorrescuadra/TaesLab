classdef cResourceData < cMessageLogger
% cResourceData gets and validates the external cost resources of a system
% 	Methods:
% 		obj=cResourceData(ps,data)
%		obj.setFlowResource(c0)
%   	obj.setProcessResource(Z)
%		obj.setFlowResourceValue(key,value)
%		obj.setProcessResourceValue(key,value)
%		obj.getResourceIndex(key)
%		obj.getResourceCost(exm)
	properties (GetAccess=public, SetAccess=private) 
		sample  % Resource sample name
		c0      % Unit cost of external resources
		Z       % Cost associated to processes
	end
	properties(Access=private)
		ps
	end
	
    methods
		function obj=cResourceData(ps,data)
		% Class constructor
		%	ps - cProductiveStructure object
        %	data - cModelData object
		%
		    % Check arguments and inititiliza class
			if ~isa(ps,'cProductiveStructure') || ~isValid(ps)
				obj.messageLog(cType.ERROR,'No Productive Structure provided');
                return
			end
			if ~isstruct(data)  
				obj.messageLog(cType.ERROR,'Invalid resource data.');
				return
			end
			obj.Z=zeros(1,ps.NrOfProcesses);
			obj.c0=zeros(1,ps.NrOfFlows);
		    % Read resources flows costs
			if ~isfield(data,{'sampleId','flows'})
				obj.messageLog(cType.ERROR,'Invalid data model. Fields missing');
				return
			end
			obj.sample=data.sampleId;

			if all(isfield(data.flows,{'key','value'}))
					se=data.flows;
			else
				obj.messageLog(cType.ERROR,'Wrong resource cost file. Flows fields missing.');
				return	
			end
			% Check Resource Flows data
			resources=ps.Resources.flows;
			for i=1:length(se)
				id=ps.getFlowId(se(i).key);
				if ~isempty(id)
					if ~ismember(id,resources)
						obj.messageLog(cType.ERROR,'Flow key %s is not a resource',se(i).key);
					end
					if (se(i).value < 0)
						obj.messageLog(cType.ERROR,'Value of resource cost %s is negative %f',se(i).key,se(i).value);
					end
					obj.c0(id)=se(i).value;
				else
					obj.messageLog(cType.ERROR,'Resource flow key %s is missing',se(i).key);
				end
			end
            if ~obj.isValid
                return
            end
		    % Read processes costs	
			if isfield(data,'processes')
				if all(isfield(data.processes,{'key','value'}))
					sz=data.processes;
				else
					obj.messageLog(cType.ERROR,'Wrong resource cost data. Processes fields missing.');
					return	
				end		
				% Check processes cost data
                for i=1:length(sz)
					id=ps.getProcessId(sz(i).key);
                    if ~isempty(id)
						if (sz(i).value >= 0)
							obj.Z(id)=sz(i).value;
						else
							obj.messageLog(cType.ERROR,'Value of process cost %s is negative: %f',sz(i).key,sz(i).value);
						end
                    else
					    obj.messageLog(cType.ERROR,'Process key %s is missing',sz(i).key);
                    end
                end
			else
				obj.messageLog(cType.INFO,'Processes cost data is missing. Default values are assumed.');
			end
			obj.ps=ps;
		end

		function log=setProcessResource(obj,Z)
		% Set the Resources cost of processes
		%  Input:
		%   Z - Resources cost processes values
			log=cMessageLogger();
            if length(Z) == obj.ps.NrOfProcesses
				obj.Z=Z;
			else
				log.messageLog(cType.ERROR,'Invalid processes resources size',length(Z));
				return
            end
            if any(Z<0)
				log.messageLog(cType.ERROR,'Values of process resources must be non-negatives');
				return
            end
		end

		function log=setFlowResource(obj,c0)
		% Set the Resources unit cost of flows
		%  Input:
		%   c0 - Resources cost flows values
			log=cMessageLogger();
            if length(c0) == obj.ps.NrOfFlows
				obj.c0=c0;
			else
				log.messageLog(cType.ERROR,'Invalid flows resources size',length(c0));
				return
            end
            if any(c0<0)
				log.messageLog(cType.ERROR,'Values of flows resources must be non-negatives');
				return
            end
		end

		function log=setFlowResourceValue(obj,key,value)
		% Set the value of a resource
		%	key - key of the resource
		%	value - cost of the resource
			log=cMessageLogger();
			id=obj.getResourceIndex(key);
            if isempty(id)
				log.messageLog(cType.ERROR,'Invalid key: %s',key);
				return
            end
            if value>=0
	            obj.c0(id)=value;
            else
				log.messageLog(cType.ERROR,'Flows resource cost values must be non-negatives');
				return
            end
		end

		function log=setProcessResourceValue(obj,key,value)
		% Set the value of a resource
		%	key - key of the resource
		%	value - cost of the resource
			log=cMessageLogger();
			id=obj.ps.getProcessId(key);
            if isempty(id)
				log.messageLog(cType.ERROR,'Invalid key: %s',key);
				return
            end
            if value>=0
	            obj.Z(id)=value;
            else
				log.messageLog(cType.ERROR,'Processes resource cost values must be non-negatives');
				return
            end	
		end
	
		function id=getResourceIndex(obj,key)
		%  Get the index of resource key
		%	key - key of the resource
			id=obj.ps.getFlowId(key);
			if ~isempty(id)
				rf=obj.ps.Resources.flows;
				if isempty(find(rf==id,1))
					id=cType.EMPTY;
				end
			end
		end

		function res=getResourceCost(obj,exm)
		% Get cResourceCost object
			res=cResourceCost(obj,exm);
		end
	end	
end	