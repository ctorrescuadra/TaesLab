classdef cReadResources < cStatusLogger
% cReadResources Reads and validates the external cost resources of a system
% 	Methods:
% 		obj=cReadResources(data)
%		obj.setResources(exm)
%		obj.setFlowResources(c0)
%   	obj.setProcessResources(Z)
%		obj.setResourcesFlowValue(key,value)
%		obj.getResourceIndex(key)
	properties (GetAccess=public, SetAccess=private)
		c0      % Unit cost of external resources
		cs0     % Unit cost of external stream
		ce      % Processes Resources Costs
		Z       % Cost associated to processes
        zP      % Cost associated to process per unit of Product
        zF      % Cost associated to process per unit of Fuel
	end

	properties (Access=private)
		exm     % cExergyModel object
	end
    
	methods
		function obj=cReadResources(data,ps)
		% Class constructor
        %	data - Resources Cost data
		%
		    % Check arguments and inititiliza class
			obj=obj@cStatusLogger(cType.VALID);
			if ~isstruct(data)    
				obj.messageLog(cType.ERROR,'Invalid resources data provided');
				return
			end
			obj.Z=zeros(1,ps.NrOfProcesses);
			obj.c0=zeros(1,ps.NrOfFlows);
            obj.cs0=zeros(1,ps.NrOfStreams);
            obj.ce=zeros(1,ps.NrOfProcesses);
			obj.exm=cStatusLogger;
		    % Read resources flows costs
			if ~isfield(data,'flows')
				obj.messageLog(cType.ERROR,'Invalid data model. Fields missing');
				return
			end
			if all(isfield(data.flows,{'key','value'}))
					se=data.flows;
			else
				obj.messageLog(cType.ERROR,'Wrong resources cost file. Flows Fields missing.');
				return	
			end
			% Check Resource Flows data
			resources=ps.Resources.flows;
			for i=1:length(se)
				id=ps.getFlowId(se(i).key);
				if ~cType.isEmpty(id)
					if ~ismember(id,resources)
						message=sprintf('Flow key %s is not a resource',se(i).key);
						obj.messageLog(cType.ERROR,message);
					end
					if (se(i).value < 0)
						message=sprintf('Value of resource cost %s is negative %f',se(i).key,data(i).value);
						obj.messageLog(cType.ERROR,message);
					end
					obj.c0(id)=se(i).value;
				else
					message=sprintf('Resources Flow key %s is missing',se(i).key);
					obj.messageLog(cType.ERROR,message);
				end
			end
		    % Read processes costs	
			if isfield(data,'processes')
				if all(isfield(data.processes,{'key','value'}))
					sz=data.processes;
				else
					obj.messageLog(cType.ERROR,'Wrong resources cost data. Processes Fields missing.');
					return	
				end		
				% Check processes cost data
                for i=1:length(sz)
					id=ps.getProcessId(sz(i).key);
                    if ~cType.isEmpty(id)
						if (sz(i).value >= 0)
							obj.Z(id)=sz(i).value;
						else
							txt=sprintf('Value of process cost %s is negative: %f',data(i).key,data(i).value);
							obj.messageLog(cType.WARNING,txt);
						end
                    else
					    obj.messageLog(cType.ERROR,'process key %s is missing',sz(i).key);
                    end
                end
			else
				obj.messageLog(cType.INFO,'Processes Costs data missing, default values are assumed.');
			end
		end
		
		function setResources(obj,exm)
		% Set the resources cost values for a given state exm
		%	Input:
		%	 exm - cExergyModel object with state information
			if ~obj.isValid
				obj.messageLog(cType.ERROR,'Invalid Resource data provided');
				return
			end
			if ~isa(exm,'cExergyModel') || ~exm.isValid
				obj.messageLog(cType.ERROR,'No exergy data model');
				return
			end
			obj.exm=exm;
			obj.setFlowResources;
			obj.setProcessResources;
		end

		function res=setProcessResources(obj,Z)
		% Set the Resources cost of processes
        %  Input:
        %   Z [optional] - Resources cost processes values
			res=false;
			if ~obj.isValid
				return
			end
			if nargin==2
				if length(Z) == obj.exm.NrOfProcesses
					obj.Z=Z;
				else
					obj.messageLog(cType.WARNING,'Invalid Processes Resources size',length(Z));
					return
				end
				if ~isempty(find(Z<0,1))
					obj.messageLog(cType.WARNING,'Values of flows resources must be non-negatives');
                	return
				end
			end
			idx=~obj.exm.ActiveProcesses;
			N=obj.exm.NrOfProcesses;
			vP=obj.exm.ProcessesExergy.vP(1:N);
			vF=obj.exm.ProcessesExergy.vF(1:N);
			obj.Z(idx)=0.0;
			obj.zP=vDivide(obj.Z,vP);
			obj.zF=vDivide(obj.Z,vF);
            res=true;
		end

		function res=setFlowResources(obj,c0)
        % Set the Resources unit cost of flows
        %  Input:
        %   c0 [optional] - Resources cost flows values
			res=false;
			if ~isValid(obj)
				return
			end	
			if nargin==2
				if length(c0) == obj.exm.NrOfFlows
				obj.c0=c0;
				else
					obj.messageLog(cType.WARNING,'Invalid Flows Resources size',length(c0));
					return
				end
				if ~isempty(find(c0<0,1))
					obj.messageLog(cType.WARNING,'Values of flows resources must be non-negatives');
                	return
				end
			end
			fid=obj.exm.ps.Resources.flows;
			pid=obj.exm.ps.Resources.processes;
			sid=obj.exm.ps.Resources.streams;
			obj.cs0(sid)=obj.c0(fid);
            if isa(obj.exm,'cModelFPR')
				obj.ce=obj.exm.getProcessResourcesCost(obj);
			else
				obj.ce(pid)=obj.c0(fid);
            end
            res=true;
        end

		function res=setResourcesFlowValue(obj,key,value)
		% Set the value of a resource
		%	key - key of the resource
		%	value - cost of the resource
			res=false;
			if ~isValid(obj)
				return
			end
			id=obj.getResourceIndex(key);
			if ~cType.isEmpty(id)
				obj.c0(id)=value;
				res=obj.setFlowResources;
			end			
		end

		function id=getResourceIndex(obj,key)
		%  Get the index of resource key
		%	key - key of the resource
			id=obj.exm.ps.getFlowId(key);
			if ~cType.isEmpty(id)
				rf=obj.exm.ps.Resources.flows;
				if isempty(find(rf==id,1))
					id=cType.EMPTY;
				end
			end
		end
	end	
end	