classdef cResourceData < cMessageLogger
%cResourceData - Read and validate the external resource costs for a productive structure.
%   Stores and manages per-flow unit costs (c0) and per-process external costs (Z)
%   for one resource cost sample. Once bound to a cExergyModel via setResourceCost,
%   the cost-allocation properties (C0, ce, Ce, zP, zF) are computed and stored.
%
%   The object is invalid if the data struct is malformed, required keys are
%   missing, or the total resource cost is zero.
%
%   cResourceData properties:
%     Sample  - Resource cost sample name
%     frsc    - Indices of resource flows in FlowKeys
%     c0      - (1 x NrOfFlows double) Per-flow unit cost of external resources
%     Z       - (1 x NrOfProcesses double) External cost allocated to each process
%     C0      - (1 x NrOfFlows double) Absolute cost of external resource flows
%     ce      - (1 x NrOfProcesses double) Resource unit cost per process
%     Ce      - (1 x NrOfProcesses double) Absolute resource cost per process
%     zP      - (1 x NrOfProcesses double) External cost per unit of process product
%     zF      - (1 x NrOfProcesses double) External cost per unit of process fuel
%
%   cResourceData methods:
%     cResourceData      - Construct an instance of this class
%     setFlowResource    - Set the unit cost of resource flows for the current sample
%     setProcessResource - Set the external process costs for the current sample
%     setResourceCost    - Compute cost-allocation properties for the current sample
%
%   See also cProductiveStructure, cExergyModel, cMessageLogger
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
		%cResourceData - Construct an instance of this class
		%   Reads and validates the resource cost sample data against the productive
		%   structure. Initialises flow unit costs (c0) and process costs (Z). The
		%   object is invalid if ps is not a valid cProductiveStructure, the data
		%   struct is malformed, any resource key is unrecognised, or the total
		%   resource cost is zero.
		%
		%   Syntax:
		%     obj = cResourceData(ps, data)
		%
		%   Input Arguments:
		%     ps   - cProductiveStructure object with a valid productive structure
		%     data - (struct) Resource cost sample with required fields:
		%              sampleId  - sample name (char)
		%              flows     - (struct array) flow cost entries with key/value fields
		%            Optional field:
		%              processes - (struct array) process cost entries with key/value fields
		%
		%   Output Arguments:
		%     obj  - cResourceData object; check isValid(obj) before use
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
			ft=sum(obj.c0)+sum(obj.Z);
            if ft<cType.EPS
				log.messageLog(cType.ERROR,cMessages.ZeroResourceCost);
				return
            end
		end

		function log=setFlowResource(obj,values)
		%setFlowResource - Set the unit cost of resource flows for the current sample
		%   Accepts either a numeric array of all-flow unit costs or a key/value
		%   struct array to update individual resource flows by name.
		%
		%   Syntax:
		%     log = obj.setFlowResource(values)
		%
		%   Input Arguments:
		%     values - (1 x NrOfFlows double) Unit cost array; or
		%              (struct array) key/value pairs for individual resource flows
		%
		%   Output Arguments:
		%     log - cMessageLogger object; check isValid(log) to verify success
		%
		%   See also setProcessResource, setResourceCost
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
		%setProcessResource - Set the external process costs for the current sample
		%   Accepts either a numeric array of all-process costs or a key/value
		%   struct array to update individual processes by name.
		%
		%   Syntax:
		%     log = obj.setProcessResource(values)
		%
		%   Input Arguments:
		%     values - (1 x NrOfProcesses double) Process cost array; or
		%              (struct array) key/value pairs for individual processes
		%
		%   Output Arguments:
		%     log - cMessageLogger object; check isValid(log) to verify success
		%
		%   See also setFlowResource, setResourceCost
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
		%setResourceCost - Compute cost-allocation properties for the current sample
		%   Uses the provided cExergyModel to compute the absolute resource costs
		%   (C0, Ce) and the per-unit allocation vectors (ce, zP, zF). Must be
		%   called after flow and process costs have been set.
		%
		%   Syntax:
		%     log = obj.setResourceCost(exm)
		%
		%   Input Arguments:
		%     exm - cExergyModel object bound to the same productive structure
		%
		%   Output Arguments:
		%     log - cMessageLogger object; check isValid(log) to verify success
		%
		%   See also setFlowResource, setProcessResource, cExergyModel
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
		%getResourceIndex - Get the index of a resource flow given its key
		%
		%   Syntax:
		%     res = obj.getResourceIndex(key)
		%
		%   Input Arguments:
		%     key - (char) Flow key to look up
		%
		%   Output Arguments:
		%     res - (integer) Flow index if the key identifies a resource flow;
		%           0 if the key is not found or is not a resource flow
		%
			res=0;
			id=obj.ps.getFlowId(key);
			if ismember(id,obj.frsc)
				res=id;
			end
		end

		function log=setFlowResourceData(obj,se)
		%setFlowResourceData - Validate and apply resource flow costs from key/value data
		%
		%   Syntax:
		%     log = obj.setFlowResourceData(se)
		%
		%   Input Arguments:
		%     se  - (struct array) Key/value pairs with fields key and value
		%           for each resource flow
		%
		%   Output Arguments:
		%     log - cMessageLogger object; check isValid(log) to verify success
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
		%setFlowResourceValues - Validate and apply resource flow costs from a numeric array
		%
		%   Syntax:
		%     log = obj.setFlowResourceValues(c0)
		%
		%   Input Arguments:
		%     c0  - (1 x NrOfFlows double) Unit cost values for all flows; only
		%           resource-flow positions are stored
		%
		%   Output Arguments:
		%     log - cMessageLogger object; check isValid(log) to verify success
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
		%setProcessResourceData - Validate and apply process costs from key/value data
		%
		%   Syntax:
		%     log = obj.setProcessResourceData(sz)
		%
		%   Input Arguments:
		%     sz  - (struct array) Key/value pairs with fields key and value
		%           for each process cost entry
		%
		%   Output Arguments:
		%     log - cMessageLogger object; check isValid(log) to verify success
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
		%setProcessResourceValues - Validate and apply process costs from a numeric array
		%
		%   Syntax:
		%     log = obj.setProcessResourceValues(Z)
		%
		%   Input Arguments:
		%     Z   - (1 x NrOfProcesses double) External cost values for all processes
		%
		%   Output Arguments:
		%     log - cMessageLogger object; check isValid(log) to verify success
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