classdef cResourceData < cMessageLogger
%cResourceData - Gets and validates the external cost resources of a system.
% 
%   cResourceData constructor:
%     obj = cResourceData(ps, data)
%
%   cResourceData properties:
%     sample  - Resource sample name
%     frsc    - Resource flows index
%     c0      - Unit cost of external resources
%     Z       - Cost associated to processes
%
%   cResourceData	methods:
%	  setFlowResource         - Set the unit cost of resource flows
%     setProcessResource      - Set the values of external cost of processes
%	  getResourceCost         - Get the corresponding cResourceCost object
%
	properties (GetAccess=public, SetAccess=private) 
		Sample  % Resource sample name
		frsc    % Resource flows index
		c0      % Unit cost of external resources
		Z       % Cost associated to processes
	end
	properties(Access=private)
		ps      % Productive Structure
	end
	
    methods
		function obj=cResourceData(ps,data)
		%cResourceData - Creates an instance of the class
        %   Syntax:
		%     obj = cResourceData(ps,data)
		%   Input Arguments:
		%	  ps - cProductiveStructure object
        %	  data - resource data sample
		%
		    % Check arguments and initilize class
			if ~isObject(ps,'cProductiveStructure')
				obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(ps));
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
			obj.Z=zeros(1,ps.NrOfProcesses);
			obj.c0=zeros(1,ps.NrOfFlows);
			obj.Sample=data.sampleId;
			obj.frsc=ps.ResourceFlows;
			obj.ps=ps;
			% Read flows costs
			log=obj.setFlowResourceData(data.flows);
			if ~log.status
				obj.addLogger(log);
				return
			end
		    % Read processes costs	
			if isfield(data,'processes')
				log=obj.setProcessResourceData(data.processes);
				if ~log.status
					obj.addLogger(log);
					return
				end
			else
				obj.messageLog(cType.INFO,cMessages.NoProcessResourceData);
			end
		end

		function log=setFlowResource(obj,values)
        %setFlowResourceData - Set the flow-resource value of a sample
        %   Syntax:
        %     log = obj.setFlowResourceData(sample,values)
        %   Input Arguments:
        %     sample - Sample key/id
        %     values - Array or key/value struct containing the flow-resource values
        %   Output Argument:
        %     log - cMessageLogger with the operation status and errors
        %
            log=cMessageLogger();
            if isstruct(values)
                lrsd=obj.setFlowResourceData(values);
                log.addLogger(lrsd);
            elseif isnumeric(values)
                lrsd=obj.setFlowResourceValues(values);
                log.addLogger(lrsd);
            else
                log.messageLog(cType.Error,cMessages.InvalidArgument,class(values));
            end
        end

        function log=setProcessResource(obj,values)
        %setProcessResourceData - Set the process-resource value of a sample
        %   Syntax:
        %     log = obj.setProcessResourceData(sample,values)
        %   Input Arguments:
        %     sample - Sample key/id
        %     values - Array or key value struct containing the process-resource values
        %   Output Argument:
        %     log - cMessageLogger with the operation status and errors
        %
            log=cMessageLogger();
            if isstruct(values)
                lrsd=obj.setProcessResourceData(values);
                log.addLogger(lrsd);
            elseif isnumeric(values)
                lrsd=obj.setProcessResourceValues(values);
                log.addLogger(lrsd);
            else
                log.messageLog(cType.Error,cMessages.InvalidArgument,class(values));
            end
        end

		function res=getResourceCost(obj,exm)
		%getResourceCost - Get cResourceCost object
		%   Syntax:
		%     log=getResourceCost(obj,exm)
		%   Input Arguments:
		%     exm - cExergyModel object
		%   Output Argument:
		%     res - cResourceCost object
		%
			res=cResourceCost(obj,exm);
		end

	end

	methods(Access=private)
		function res=getResourceIndex(obj,key)
		%getResourceIndex - Get the index of resource key
		%   Syntax:
		%     log=getResourceIndex(obj,exm)
		%   Input Arguments:
		%     key - Flow key
		%   Output Argument:
		%     res - Flow index
		%
			res=0;
			id=obj.ps.getFlowId(key);
			if ismember(id,obj.frsc)
				res=id;
			end
		end

		function log=setFlowResourceData(obj,se)
 		%setFlowResourceData - Set the unit cost of resource flows
		%    Syntax:
		%      log=setProcessResource(obj,Z)
		%    Input Arguments:
		%      sz - key/value structure with the unit cost of resource flows
		%    Output Argument:
		%      log - cMessageLog object with messages and errors
		%               
			log=cMessageLogger();
			if ~all(isfield(se,{'key','value'}))
				log.messageLog(cType.ERROR,cMessages.InvalidResourceModel);
				return	
			end
			% Check Resource Flows data
			for i=1:length(se)
				id=obj.getResourceIndex(se(i).key);
				if id
					if (se(i).value < 0)
						log.messageLog(cType.ERROR,cMessages.InvalidResourceValue,se(i).key,se(i).value);
					else
						obj.c0(id)=se(i).value;
					end
				else
					log.messageLog(cType.ERROR,cMessages.InvalidResourceKey,se(i).key);
				end
			end
			idx=obj.frsc;
			ft=sum(obj.c0(idx));
			if ft<cType.EPS
				log.messageLog(cType.ERROR,cMessages.ZeroResourceCost);
				return
			end
		end

		function log=setFlowResourceValues(obj,c0)
		%setFlowResourceValues - Set the unit cost of resources flows
		%   Syntax:
		%     log=setFlowResource(obj,Z)
		%   Input Arguments:
		%     c0 - Resources flows unit cost values array
		%   Output Argument:
		%     log - cMessageLog object with messages and errors
		%
			log=cMessageLogger();
            if length(c0) ~= obj.ps.NrOfFlows	
				log.messageLog(cType.ERROR,cMessages.InvalidCSize,length(c0));
				return
            end
			if any(c0<0)
				log.messageLog(cType.ERROR,cMessages.NegativeResourceValue);
				return
			end
			idx=obj.frsc;
			ft=sum(c0(idx));
			if ft<cType.EPS
				log.messageLog(cType.ERROR,cMessages.ZeroResourceCost);
				return
			end
			obj.c0(idx)=c0(idx);	
		end

		function log=setProcessResourceData(obj,sz)
		%setProcessResourceData - Set the Resources cost of processes
		%    Syntax:
		%      log=setProcessResource(obj,Z)
		%    Input Arguments:
		%      sz - key/value structure with the resource cost of processes
		%    Output Argument:
		%      log - cMessageLog object with messages and errors
		%        
			log=cMessageLogger();
			if ~all(isfield(sz,{'key','value'}))
				log.messageLog(cType.ERROR,cMessages.InvalidResourceModel');
				return	
			end		
			% Check processes cost data
            for i=1:length(sz)
				id=obj.ps.getProcessId(sz(i).key);
                if id
					if (sz(i).value >= 0)
						obj.Z(id)=sz(i).value;
					else
						log.messageLog(cType.ERROR,cMessages.InvalidResourceValue,sz(i).key,sz(i).value);
					end
                else
					log.messageLog(cType.ERROR,cMessages.InvalidResourceKey,sz(i).key);
                end
            end
		end

		function log=setProcessResourceValues(obj,Z)
		%setProcessResourceValues - Set the Resources cost of processes
		%    Syntax:
		%      log=setProcessResource(obj,Z)
		%    Input Arguments:
		%      Z - Resources cost processes values array
		%    Output Argument:
		%      log - cMessageLog object with messages and errors
		%
			log=cMessageLogger();
            if length(Z) ~= obj.ps.NrOfProcesses
				log.messageLog(cType.ERROR,cMessages.InvalidZSize,length(Z));
				return
            end
            if any(Z<0)
				log.messageLog(cType.ERROR,cMessages.NegativeResourceValue);
				return
            end
			obj.Z=Z;
		end
	end	
end	