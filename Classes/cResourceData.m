classdef cResourceData < cMessageLogger
% cResourceData gets and validates the external cost resources of a system
%
% cResourceData Properties
% sample  - Resource sample name
% c0      - Unit cost of external resources
% Z       - Cost associated to processes
%
% cResourceData	Methods:
%	setFlowResource         - Set the unit cost of resource flows
%   setProcessResource      - Set the values of external cost of processes
%   setFlowResourceValue    - Set an individual resource flow value
%   setProcessResourceValue - Set an individual value of process resources
%	getResourceCost(exm)    - Get the corresponding cResourceCost object
%
	properties (GetAccess=public, SetAccess=private) 
		sample  % Resource sample name
		c0      % Unit cost of external resources
		Z       % Cost associated to processes
	end
	properties(Access=private)
		ps      % Productive Structure
	end
	
    methods
		function obj=cResourceData(ps,data)
		% Class constructor
		% Syntax:
		%   obj = cResourceData(ps,data)
		% Input Arguments:
		%	ps - cProductiveStructure object
        %	data - resource data sample
		%
		    % Check arguments and inititiliza class
			if ~isObject(ps,'cProductiveStructure')
				obj.messageLog(cType.ERROR,cMessages.InvalidProductiveStructure);
                return
			end
			if ~isstruct(data)  
				obj.messageLog(cType.ERROR,cMessages.InvalidResourceModel);
				return
			end
		    % Read resources flows costs
			if ~isfield(data,{'sampleId','flows'})
				obj.messageLog(cType.ERROR,cMessages.InvalidResourceModel);
				return
			end
			if all(isfield(data.flows,{'key','value'}))
					se=data.flows;
			else
				obj.messageLog(cType.ERROR,cMessages.InvalidResourceModel);
				return	
			end
			obj.Z=zeros(1,ps.NrOfProcesses);
			obj.c0=zeros(1,ps.NrOfFlows);
			obj.sample=data.sampleId;
			% Check Resource Flows data
			resources=ps.Resources.flows;
			for i=1:length(se)
				id=ps.getFlowId(se(i).key);
				if id
					if ~ismember(id,resources)
						obj.messageLog(cType.ERROR,cMessages.InvalidResourceKey,se(i).key);
					end
					if (se(i).value < 0)
						obj.messageLog(cType.ERROR,cMessages.InvalidResourceValue,se(i).key,se(i).value);
					end
					obj.c0(id)=se(i).value;
				else
					obj.messageLog(cType.ERROR,cMessages.InvalidResourceKey,se(i).key);
				end
			end
            if ~obj.status
                return
            end
		    % Read processes costs	
			if isfield(data,'processes')
				if all(isfield(data.processes,{'key','value'}))
					sz=data.processes;
				else
					obj.messageLog(cType.ERROR,cMessages.InvalidResourceModel');
					return	
				end		
				% Check processes cost data
                for i=1:length(sz)
					id=ps.getProcessId(sz(i).key);
                    if id
						if (sz(i).value >= 0)
							obj.Z(id)=sz(i).value;
						else
							obj.messageLog(cType.ERROR,cMessages.InvalidResourceValue,sz(i).key,sz(i).value);
						end
                    else
					    obj.messageLog(cType.ERROR,cMessages.InvalidResourceKey,sz(i).key);
                    end
                end
			else
				obj.messageLog(cType.INFO,cMessages.NoResourceData);
			end
			obj.ps=ps;
		end

		function log=setProcessResource(obj,Z)
		% Set the Resources cost of processes
		% Syntax:
		%   log=setProcessResource(obj,Z)
		% Input Arguments:
		%   Z - Resources cost processes values array
		% Output Argument:
		%   log - cMessageLog object with messages and errors
		%
			log=cMessageLogger();
            if length(Z) == obj.ps.NrOfProcesses
				obj.Z=Z;
			else
				log.messageLog(cType.ERROR,cMessages.InvalidZSize,length(Z));
				return
            end
            if any(Z<0)
				log.messageLog(cType.ERROR,cMessages.NegativeResourceValue);
				return
            end
		end

		function log=setFlowResource(obj,c0)
		% Set the unit cost of resources flows
		% Syntax:
		%   log=setFlowResource(obj,Z)
		% Input Arguments:
		%   c0 - Resources flows unit cost values array
		% Output Argument:
		%   log - cMessageLog object with messages and errors
		%
			log=cMessageLogger();
            if length(c0) == obj.ps.NrOfFlows
				obj.c0=c0;
			else
				log.messageLog(cType.ERROR,cMessages.InvalidCSize,length(c0));
				return
            end
            if any(c0<0)
				log.messageLog(cType.ERROR,cMessages.NegativeResourceValue);
				return
            end
		end

		function log=setFlowResourceValue(obj,key,value)
		% Set the value of a resource flow
		% Syntax:
		%   log=setFlowResourceValue(obj,key,value)
		% Input Arguments:
		%   key - Resource flow name
		%   value - unit cost of the resource
		% Output Argument:
		%   log - cMessageLog object with messages and errors
		%
			log=cMessageLogger();
			id=obj.getResourceIndex(key);
            if ~id
				log.messageLog(cType.ERROR,cMessages.InvalidResourceKey,key);
				return
            end
            if value>=0
	            obj.c0(id)=value;
            else
				log.messageLog(cType.ERROR,cMessages.InvalidResourceValue,key,value);
				return
            end
		end

		function log=setProcessResourceValue(obj,key,value)
		% Set the value of a process external resource
		% Syntax:
		%   log=setProcessResourceValue(obj,key,value)
		% Input Arguments:
		%   key - Process name
		%   value - Cost of the resource
		% Output Argument:
		%   log - cMessageLog object with messages and errors
		%
			log=cMessageLogger();
			id=obj.ps.getProcessId(key);
            if ~id
				log.messageLog(cType.ERROR,cMessages.InvalidProcessKey,key);
				return
            end
            if value>=0
	            obj.Z(id)=value;
            else
				log.messageLog(cType.ERROR,cMessages.InvalidResourceValue,key,value);
				return
            end	
		end

		function res=getResourceCost(obj,exm)
		% Get cResourceCost object
		% Syntax:
		%   log=getResourceCost(obj,exm)
		% Input Arguments:
		%   exm - cExergyModel object
		% Output Argument:
		%   res - cResourceCost object
		%
			res=cResourceCost(obj,exm);
		end
	end

	methods(Access=private)
		function res=getResourceIndex(obj,key)
		% Get the index of resource key
		%	key - key of the resource
			res=0;
			rf=obj.ps.Resources.flows;
			id=obj.ps.getFlowId(key);
			if ismember(id,rf)
				res=id;
			end
		end
	end	
end	