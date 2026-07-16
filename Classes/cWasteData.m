classdef cWasteData < cMessageLogger
%cWasteData - Store and manage waste flow allocation data for a productive structure.
%   Validates waste definition data against the productive structure. Provides
%   per-waste allocation type, manual allocation values, and recycle ratio
%   management. Used by cExergyCost to perform waste allocation and recycling
%   analysis.
%
%   The object is invalid if the data struct is malformed, waste keys do not
%   match the productive structure, or allocation values are inconsistent.
%
%   cWasteData properties:
%     NrOfWastes    - Number of waste flows
%     Names         - (1 x NrOfWastes cell array of char) Waste flow keys
%     Flows         - (1 x NrOfWastes integer array) Waste flow indices
%     Processes     - (1 x NrOfWastes integer array) Dissipative process indices
%     Type          - (1 x NrOfWastes cell array of char) Waste allocation type names
%     TypeId        - (1 x NrOfWastes integer array) Waste allocation type identifiers
%     Values        - (NrOfWastes x NrOfProcesses double) Manual allocation values
%     RecycleRatio  - (1 x NrOfWastes double) Recycle ratio for each waste flow
%     ps            - cProductiveStructure object for the productive structure
%
%   cWasteData methods:
%     cWasteData       - Construct an instance of this class
%     getWasteFlows    - Get waste flow keys, optionally filtered by index
%     getWasteIndex    - Get the index of a waste flow given its key
%     existsWaste      - Check if a waste flow key is defined
%     getValues        - Get the manual allocation values of a waste
%     getType          - Get the allocation type name of a waste
%     getRecycleRatio  - Get the recycle ratio of a waste
%     setType          - Set the allocation type of a waste
%     setValues        - Set the manual allocation values of a waste
%     setRecycleRatio  - Set the recycle ratio of a waste
%     updateValues     - Replace the full waste allocation matrix (internal use)
%
%   See also cModelData, cExergyCost, cProductiveStructure
%
	properties (GetAccess=public,SetAccess=private)
        NrOfWastes      % Number of wastes
		Names			% Waste Flow names
		Flows           % Waste Flows Id
		Processes       % Dissipative Processes
		Type        	% Waste Allocation types
		TypeId      	% Waste Type Id
		Values      	% Waste Allocation values
		RecycleRatio    % Recycle Ratio
		ps              % Productive Structure handler
	end
    
	methods
		function obj=cWasteData(ps,data)
		%cWasteData - Construct an instance of this class
		%   Validates waste definition data against the productive structure.
		%   Checks waste keys, allocation types, recycle ratios, and any manual
		%   allocation values. The object is invalid if ps is not a valid
		%   cProductiveStructure, the data struct is malformed, or any waste
		%   definition contains an error.
		%
		%   Syntax:
		%     obj = cWasteData(ps, data)
		%
		%   Input Arguments:
		%     ps   - cProductiveStructure object with a valid productive structure
		%     data - (struct) Waste definition data with required field:
		%              wastes - (1 x NrOfWastes struct array) with fields:
		%                         flow    - waste flow key (char)
		%                         type    - allocation type (char, see cType.WasteAllocation)
		%                         recycle - recycle fraction [0,1] (optional, default 0)
		%                         values  - manual allocation entries (optional)
		%
		%   Output Arguments:
		%     obj  - cWasteData object; check isValid(obj) before use
		%
			% Check input arguments
            if ~isObject(ps,'cProductiveStructure')
				obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(ps));
				return
            end
			% Check data structure
			if  ~isstruct(data) || ~isfield(data,'wastes')
                obj.messageLog(cType.ERROR,cMessages.InvalidWasteData);
				return
			end
			% Check waste info
            wd=data.wastes;
			NR=length(wd);
			if NR ~= ps.NrOfWastes
				obj.messageLog(cType.ERROR,cMessages.InvalidWasteData);
				return
			end
			if ~all(isfield(data.wastes,{'flow','type'}))
				obj.messageLog(cType.ERROR,cMessages.InvalidWasteData);
				return
			end
			% Initialize arrays
            values=zeros(NR,ps.NrOfProcesses);
            wasteType=ones(1,NR);
			recycleRatio=zeros(1,NR);
			% Check each waste 
			for i=1:NR
				% Check key
				id=ps.getFlowId(wd(i).flow);
				if ~id
					obj.messageLog(cType.ERROR,cMessages.InvalidWasteKey,wd(i).flow);
					continue
				end 
				% Get waste type	
				wid=cType.getWasteId(wd(i).type);
				if ~isempty(wid)
					wasteType(i)=wid;
                else
                    obj.messageLog(cType.ERROR,cMessages.InvalidWasteAllocation,wd(i).type,wd(i).flow);
				end 
				if ~ps.Flows(id).type == cType.Flow.WASTE
					obj.messageLog(cType.ERROR,cMessages.NoWasteFlow,wd(i).flow);
				end
				% Check Recycle Ratio
				if isfield(wd(i),'recycle')
					if (wd(i).recycle>1) || (wd(i).recycle<0) 
						obj.messageLog(cType.ERROR,cMessages.InvalidRecycling,wd(i).recycle,wd(i).flow);
					end
				else
					wd(i).recycle=0.0;
					data.wastes(i).recycle=0.0;
				end
				recycleRatio(i)=wd(i).recycle;      
				% Ckeck manual allocation cost
				if (wasteType(i) == cType.WasteAllocation.MANUAL)
					if isfield(wd(i),'values')
                        wval=wd(i).values;
                        if ~all(isfield(wval,{'process','value'})) 
							obj.messageLog(cType.ERROR,cMessages.NoWasteAllocationValues,wd(i).flow);
							return
                        end
                        for j=1:length(wval)
							jp=ps.getProcessId(wval(j).process);
                            if isempty(jp)
								obj.messageLog(cType.ERROR,cMessages.InvalidProcessKey,wval(j).process);
								continue
                            end
							if(ps.Processes(jp).typeId==cType.Process.DISSIPATIVE)                             
								obj.messageLog(cType.ERROR,cMessages.InvalidAllocationProcess,wval(j).process);
								continue
							end
							if wval(j).value>0
								values(i,jp)=wval(j).value;
							else
    							obj.messageLog(cType.ERROR,cMessages.NegativeWasteAllocation,wd(i).flow,wval(j).value);
								continue
							end
                        end
					    else %if no values provided set type to DEFAULT
						    wasteType(i)=cType.WasteAllocation.DEFAULT;
                            wd(i).type=cType.DEFAULT_WASTE_ALLOCATION;
						    obj.messageLog(cType.INFO,cMessages.NoWasteAllocationValues,wd(i).flow);
					end             
				end
			end
			% Create the object
			if obj.status
				obj.NrOfWastes=ps.NrOfWastes;
				obj.Names={wd.flow};
				obj.Flows=ps.Waste.flows;
				obj.Processes=ps.Waste.processes;
				obj.Type={wd.type};
				obj.TypeId=wasteType;
				obj.Values=values;
				obj.RecycleRatio=recycleRatio;
				obj.ps=ps;
			end
		end

		function res=getWasteFlows(obj,idx)
		%getWasteFlows - Get waste flow keys, optionally filtered by index
		%   When called with no arguments returns all waste flow keys. When
		%   called with an index returns the key for that waste.
		%
		%   Syntax:
		%     res = obj.getWasteFlows
		%     res = obj.getWasteFlows(idx)
		%
		%   Input Arguments:
		%     idx - (integer, optional) Waste index in range [1, NrOfWastes]
		%
		%   Output Arguments:
		%     res - (cell array of char) Waste flow key(s); cType.EMPTY_CELL if
		%           idx is out of range
		%
		%   See also getWasteIndex, existsWaste
		%
			res=cType.EMPTY_CELL;
			if nargin==1
				res=obj.Names;
                return
			end
			if isIndex(idx,1,obj.NrOfWastes)
				res=obj.Names(idx);
			end
		end
			
		function res=getWasteIndex(obj,key)
		%getWasteIndex - Get the index of a waste flow given its key
		%
		%   Syntax:
		%     res = obj.getWasteIndex(key)
		%
		%   Input Arguments:
		%     key - (char) Waste flow key to look up
		%
		%   Output Arguments:
		%     res - (integer) Index of the waste flow; 0 if not found
		%
		%   See also existsWaste, getWasteFlows
		%
			res=0;
			if ischar(key)
				[~,res]=ismember(key,obj.Names);
			end
		end
			
		function res=existsWaste(obj,key)
		%existsWaste - Check if a waste flow key is defined in this object
		%
		%   Syntax:
		%     res = obj.existsWaste(key)
		%
		%   Input Arguments:
		%     key - (char) Waste flow key to check
		%
		%   Output Arguments:
		%     res - (logical) true if key is among the defined waste flows;
		%           false otherwise
		%
		%   See also getWasteIndex, getWasteFlows
		%
			res=false;
			if ischar(key)
				res=ismember(key,obj.Names);
			end
        end

		function res=getValues(obj,arg)
		%getValues - Get the manual allocation values of a waste
		%
		%   Syntax:
		%     res = obj.getValues(arg)
		%
		%   Input Arguments:
		%     arg - (char or integer) Waste flow key or index
		%
		%   Output Arguments:
		%     res - (1 x NrOfProcesses double) Manual allocation values for
		%           the specified waste; cType.EMPTY if arg is invalid
		%
		%   See also setValues, getType, getRecycleRatio
		%
			res=cType.EMPTY;
			id=validateArg(obj,arg);
			if id>0
                res=obj.Values(id,:);
			end
		end
	
		function status=setValues(obj,arg,val)
		%setValues - Set the manual allocation values of a waste
		%   Sets the type to MANUAL and stores the allocation row vector. All
		%   values must be non-negative and at least one must be positive.
		%
		%   Syntax:
		%     status = obj.setValues(arg, val)
		%
		%   Input Arguments:
		%     arg - (char or integer) Waste flow key or index
		%     val - (1 x NrOfProcesses double) Allocation values (non-negative)
		%
		%   Output Arguments:
		%     status - (logical) true if the values were accepted; false otherwise
		%
		%   See also getValues, setType, setRecycleRatio
		%
			status=false;
			id=validateArg(obj,arg);
			if id<1
				return
			end
			if size(obj.Values,2)~=length(val)
				return
			end
			if any(val(:)>0) && isempty(find(val<0,1))
				obj.TypeId(id)=0;
				obj.Type{id}='MANUAL';
				obj.Values(id,:)=val;
				status=true;
			end
		end
		
		function res=getType(obj,arg)
		%getType - Get the allocation type name of a waste
		%
		%   Syntax:
		%     res = obj.getType(arg)
		%
		%   Input Arguments:
		%     arg - (char or integer) Waste flow key or index
		%
		%   Output Arguments:
		%     res - (char) Allocation type name (see cType.WasteAllocation);
		%           cType.EMPTY_CHAR if arg is invalid
		%
		%   See also setType, getValues, getRecycleRatio
		%
			res=cType.EMPTY_CHAR;
			id=validateArg(obj,arg);
			if id>0
				res=obj.Type{id};
			end
		end
	
		function status=setType(obj,arg,type)
		%setType - Set the allocation type of a waste
		%
		%   Syntax:
		%     status = obj.setType(arg, type)
		%
		%   Input Arguments:
		%     arg  - (char or integer) Waste flow key or index
		%     type - (char) Allocation type name (see cType.WasteAllocation)
		%
		%   Output Arguments:
		%     status - (logical) true if the type was accepted; false otherwise
		%
		%   See also getType, setValues, setRecycleRatio
		%
			status=false;
			id=validateArg(obj,arg);
			if id<1
				return
			end
			tId=cType.getWasteId(type);
			if ~isempty(tId)
				obj.Type{id}=type;
				obj.TypeId(id)=tId;
				status=true;
			end
		end            
					
		function res=getRecycleRatio(obj,arg)
		%getRecycleRatio - Get the recycle ratio of a waste
		%
		%   Syntax:
		%     res = obj.getRecycleRatio(arg)
		%
		%   Input Arguments:
		%     arg - (char or integer) Waste flow key or index
		%
		%   Output Arguments:
		%     res - (double) Recycle ratio in [0, 1]; cType.EMPTY if arg is invalid
		%
		%   See also setRecycleRatio, getValues, getType
		%
			res=cType.EMPTY;
			id=validateArg(obj,arg);
			if id>0
				res=obj.RecycleRatio(id);
			end	
		end
		
		function status=setRecycleRatio(obj,arg,val)
		%setRecycleRatio - Set the recycle ratio of a waste
		%
		%   Syntax:
		%     status = obj.setRecycleRatio(arg, val)
		%
		%   Input Arguments:
		%     arg - (char or integer) Waste flow key or index
		%     val - (double) Recycle ratio; must be a scalar in [0, 1]
		%
		%   Output Arguments:
		%     status - (logical) true if the ratio was accepted; false otherwise
		%
		%   See also getRecycleRatio, setType, setValues
		%
			status=false;
			id=validateArg(obj,arg);
			if id<1
				return
			end
			status = isscalar(val) || ~isnumeric(val) || val<0 || val>1;
			if status
				obj.RecycleRatio(id)=val;
			end
		end			
	
		function status=updateValues(obj,val)
		%updateValues - Replace the full waste allocation matrix (internal use)
		%   Replaces the Values matrix if val has the same dimensions. Used
		%   internally by cExergyCost after waste recycling computation.
		%
		%   Syntax:
		%     status = obj.updateValues(val)
		%
		%   Input Arguments:
		%     val - (NrOfWastes x NrOfProcesses double) Waste allocation matrix
		%
		%   Output Arguments:
		%     status - (logical) true if dimensions match and values were updated;
		%              false otherwise
		%
			status=false;
			if all(size(val)==size(obj.Values))
				obj.Values=val;
				status=true;
			end
		end
	end	
		
	methods(Access=private)
		function res=validateArg(obj,arg)
		%validateArg - Resolve a waste key or index to a validated waste index
		%
		%   Syntax:
		%     res = obj.validateArg(arg)
		%
		%   Input Arguments:
		%     arg - (char) waste flow key; or (integer) waste index in [1, NrOfWastes]
		%
		%   Output Arguments:
		%     res - (integer) Validated waste index; cType.EMPTY if arg is invalid
		%
			res=cType.EMPTY;
			if ischar(arg)
				res=obj.getWasteIndex(arg);
			elseif isIndex(arg,1,obj.NrOfWastes)
				res=arg;
			end
		end
	end
end	