classdef cResourceData < cMessageLogger
%cResourceData - Gets and validates the external cost resources of a productive structure.
%   This class reads, validates and stores the external cost resources based on the data
%   provided by the model.
%
%   cResourceData properties:
%     Sample  - Resource sample name
%     frsc    - Resource flows index
%     c0      - Unit cost of external resources
%     Z       - Cost associated to processes
%     C0      - Cost associated to external resources
%     ce      - Process Resource Unit Costs
%     Ce      - Process Resource Cost
%     zP      - Cost associated to process per unit of Product
%     zF      - Cost associated to process per unit of Fuel
%
%   cResourceData methods:
%     cResourceData           - Creates an instance of the class
%	  setFlowResource         - Set the unit cost of resource flows
%     setProcessResource      - Set the values of external cost of processes
%	  setResourceCost         - Set the properties of the resource costs (depending on exergy model)
%
	properties (GetAccess=public, SetAccess=private) 
		Sample  % Resource sample name
		frsc    % Resource flows index
		c0      % Unit cost of external resources
		Z       % Cost associated to processes
		C0      % Cost associated to external resources
		ce      % Process Resource Unit Costs
        Ce      % Process Resource Cost
        zP      % Cost associated to process per unit of Product
        zF      % Cost associated to process per unit of Fuel
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
		%   Output Arguments:
		%     obj - cResourceData object
		
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
			ft=sum(obj.c0)+sum(obj.Z);
            if ft<cType.EPS
				log.messageLog(cType.ERROR,cMessages.ZeroResourceCost);
				return
            end
		end

		function log=setFlowResource(obj,values)
        %setFlowResource - Set the flow-resource values of the current sample
        %   Syntax:
        %     log = obj.setFlowResource(values)
        %   Input Arguments:
        %     values - Array or key/value struct containing the flow-resource values
        %   Output Arguments:
        %     log - cMessageLogger with the operation status and errors
        %
            log=cMessageLogger();
			% Check input values
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
        %setProcessResource - Set the process-resource value of the current sample
        %   Syntax:
        %     log = obj.setProcessResource(values)
        %   Input Arguments:
        %     values - Array or key value struct containing the process-resource values
        %   Output Arguments:
        %     log - cMessageLogger with the operation status and errors
        %
            log=cMessageLogger();
			% Check input values
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

		function log=setResourceCost(obj,exm)
		%setResourceCost - Calculate the resource cost properties for the current sample
		%	These properties are calculated based on the current exergy model.
		%
		%   Syntax:
		%     log=obj.setResourceCost(exm)
		%   Input Arguments:
		%     exm - cExergyModel object
		%   Output Arguments:
		%     log - true|false indicating the status of the operation
		%
			log=cMessageLogger();
			if ~isObject(exm,'cExergyModel')
				log.messageLog(cType.ERROR,cMessages.InvalidObject,class(exm));
				return
			end
			% Set Resource Cost properties for the current sample	
			obj.C0=obj.c0 .* exm.FlowsExergy;
			% Process Resources Cost
			fpm=exm.FlowProcessModel;
			idx=obj.frsc;
			obj.ce = obj.c0(idx) * fpm.mL(idx,:) * fpm.mF0(:,1:end-1);
			obj.Ce = obj.ce .* exm.FuelExergy;
			% Set Process Properties
            idx = ~exm.ActiveProcesses;
	        obj.Z(idx) = 0.0;
			obj.zP = vDivide(obj.Z,exm.ProductExergy);
			obj.zF = vDivide(obj.Z,exm.FuelExergy);
		end
	end

	methods(Access=private)
		function res=getResourceIndex(obj,key)
		%getResourceIndex - Get the index of a resource key
		%   Syntax:
		%     log=getResourceIndex(obj,exm)
		%   Input Arguments:
		%     key - Flow key
		%   Output Arguments:
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
		%      log=setFlowsResourceData(obj,Z)
		%    Input Arguments:
		%      se - key/value structure with the unit cost of resource flows
		%    Output Arguments:
		%      log - cMessageLog object with messages and errors
		%               
			log=cMessageLogger();
			% Check input values
			if ~all(isfield(se,cType.KEYVAL))
				log.messageLog(cType.ERROR,cMessages.InvalidResourceModel);
				return	
			end
			% Check Resource Flows data
			fkeys={se.key}; id=1:length(fkeys);
			[tst,idx]=ismember(fkeys,obj.ps.FlowKeys);
			if all(tst)
				obj.c0(idx)=[se(id).value];
			else
				for i=idx
					log.messageLog(cType.ERROR,cMessages.InvalidResourceKey,se(i).key);
				end
			end
		end

		function log=setFlowResourceValues(obj,c0)
		%setFlowResourceValues - Set the unit cost of resources flows
		%   Syntax:
		%     log=setFlowResource(obj,Z)
		%   Input Arguments:
		%     c0 - Resources flows unit cost values array
		%   Output Arguments:
		%     log - cMessageLog object with messages and errors
		%
			log=cMessageLogger();
			% Check input values
            if length(c0) ~= obj.ps.NrOfFlows	
				log.messageLog(cType.ERROR,cMessages.InvalidSize,length(c0));
				return
            end
			if any(c0<0)
				log.messageLog(cType.ERROR,cMessages.NegativeResourceValue);
				return
			end
			% Check if total resources are zero
			idx=obj.frsc;
            if iscolumn(c0), c0=c0';end
			ft=sum(c0(idx))+sum(obj.Z);
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
		%    Output Arguments:
		%      log - cMessageLog object with messages and errors
		%        
			log=cMessageLogger();
			% Check input values
			if ~all(isfield(sz,cType.KEYVAL))
				log.messageLog(cType.ERROR,cMessages.InvalidResourceModel);
				return	
			end		
			% Set processes cost data
			pkeys={sz.key}; id=1:length(pkeys);
			[tst,idx]=ismember(pkeys,obj.ps.ProcessKeys);
			if all(tst)
				obj.Z(idx)=[sz(id).value];
			else
				for i=idx
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
		%    Output Arguments:
		%      log - cMessageLog object with messages and errors
		%
			log=cMessageLogger();
			% Check input values
            if length(Z) ~= obj.ps.NrOfProcesses
				log.messageLog(cType.ERROR,cMessages.InvalidZSize,length(Z));
				return
            end
            if any(Z<0)
				log.messageLog(cType.ERROR,cMessages.NegativeResourceValue);
				return
            end
            if iscolumn(Z),Z=Z';end
			ft=sum(obj.c0)+sum(Z);
			if ft<cType.EPS
				log.messageLog(cType.ERROR,cMessages.ZeroResourceCost);
				return
			end
			obj.Z=Z;
		end
	end	
end	