classdef cWasteData < cMessageLogger
% cWasteData contains the waste information.
%
% cWasteData Properties:
% NrOfWastes    - Number of wastes
% Names			- Waste Flow names
% Flows         - Waste Flows Id
% Processes     - Dissipative Processes Id
% Type        	- Waste Allocation types
% TypeId      	- Waste Type Id
% Values      	- Waste Allocation values
% RecycleRatio  - Recycle Ratio
%
% cWasteData Methods:
% getWasteFlows    - Get the waste flows key
% getWasteIndex    - Get the waste flows index
% existWaste       - Check if a waste flow is defined
% getValues        - Get the allocation cost values of a waste
% getType          - Get the allocation type of a waste
% getRecycleRatio  - Get the recycling ratio of a waste
% setType          - Set the allocation type of a waste
% setValues        - Set the allocation calues of a waste
% setRecycleRatio  - Set the recycling ratio of a waste
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
		% Class constructor
		% Syntax:
		%   obj = cWasteData(ps,data)
		% Input Arguments
		%	ps - cProductiveStructure object
		%	data - waste definition from cModelData
		%
			% Check input arguments
            if ~isObject(ps,'cProductiveStructure')
				obj.messageLog(cType.ERROR,'Invalid productive structure');
				return
            end
			% Check data structure
			if  ~isstruct(data) || ~isfield(data,'wastes')
                obj.messageLog(cType.ERROR,'Invalid waste date. Fields Missing');
				return
			end
			% Check waste info
            wd=data.wastes;
			NR=length(wd);
			if NR ~= ps.NrOfWastes
				obj.messageLog(cType.ERROR,'Invalid number of wastes %d',NR);
				return
			end
			if ~all(isfield(data.wastes,{'flow','type'}))
				obj.messageLog(cType.ERROR,'Invalid waste date. Fields Missing');
				return
			end
			% Initialize arrays
            values=zeros(NR,ps.NrOfProcesses);
            wasteType=ones(1,NR);
			recycleRatio=zeros(1,NR);
			% Check each waste 
			for i=1:NR
				% Check waste type			
                if cType.checkWasteKey(wd(i).type)
					wasteType(i)=cType.getWasteId(wd(i).type);
                else
                    obj.messageLog(cType.ERROR,'Invalid waste allocation method %s',wd(i).type);
                end
                % Check key
                id=ps.getFlowId(wd(i).flow);
                if isempty(id)
				    obj.messageLog(cType.ERROR,'Invalid waste flow %s',wd(i).flow);
					continue
                end 
				if ~ps.Flows(id).type == cType.Flow.WASTE
					obj.messageLog(cType.ERROR,'Flow %s must be waste',wd(i).flow);
				end
				% Check Recycle Ratio
				if isfield(wd(i),'recycle')
					if (wd(i).recycle>1) || (wd(i).recycle<0) 
						obj.messageLog(cType.ERROR,'Invalid recycle ratio %f for waste %s',wd(i).recycle,wd(i).flow);
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
							obj.messageLog(cType.ERROR,'Value fields missing for waste %s',wd(i).flow);
							return
                        end
                        for j=1:length(wval)
							jp=ps.getProcessId(wval(j).process);
							if isempty(jp)
								obj.messageLog(cType.ERROR,'Invalid process name %s',wval(j).process);
								continue
							end
							if(ps.Processes(jp).type==cType.Process.DISSIPATIVE)
								obj.messageLog(cType.ERROR,'Waste %s cannot be asssigned to dissipative units',wval(j).process);
								continue
							end
							if (wval(j).value <= 0)
								obj.messageLog(cType.ERROR,'Waste distribution value %s: %f cannot be NEGATIVE',wval(j).process,wval(j).value);
								continue
							end
							values(i,jp)=wval(j).value;
                        end
					    else %if no values provided set type to DEFAULT
						    wasteType(i)=cType.WasteAllocation.DEFAULT;
						    obj.messageLog(cType.ERROR,'Waste allocation of flow %s is defined as MANUAL and does not have values defined ',wd(i).flow);
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
		% Return the name of the corresponding index
		% Syntax:
		%   res = getWasteFlows  
		% Input Arguments:
		%  idx - state index to retrieve
		% Output Arguments:
		%  res - cell array with the waste flows keys
		%
			res=cType.EMPTY_CELL;
			if nargin==1
				res=obj.Names;
                return
			end
			if ~isIndex(idx,1:obj.NrOfWastes)
				return
			end
			if isscalar(idx)
                res=obj.Names{idx};
            else
                res=obj.Names(idx);
			end
		end
			
		function res=getWasteIndex(obj,key)
		% Get the id of the corresponding waste key
		% Syntax:
		%   res = obj.getWasteIndex(key)
		% Input Argument:
		%  key - waste flow name
		% Output Argument:
		%  res - waste flow id
		%
			res=false;
			if ischar(key)
				[~,res]=ismember(key,obj.Names);
			end
		end
			
		function res=existWaste(obj,key)
		% Determine if waste key is defined
		% Syntax:
		%   res = obj.existWaste(key)
		% Input Argument:
		%  key - waste flow name
		% Output Argument:
		%  res - true | false
		%
			res=false;
			if ischar(key)
				res=ismember(key,obj.Names);
			end
        end

		function res=getValues(obj,arg)
		% Get the allocation ratios of a waste
		% Syntax:
		%   res = obj.getValues(arg)
		% Input:
		%   arg - waste key or id
		% Output:
		%  res - vector with the allocation waste ratios of waste id
			res=cType.EMPTY;
			id=validateArg(obj,arg);
			if id>0
                res=obj.Values(id,:);
			end
		end
	
		function status=setValues(obj,arg,val)
		% Set the cost allocation values of a waste
		% Syntax:
		%   res = obj.setValues(arg,val)
		% Input Arguments:
		%  arg - waste key name or id
		%  val - Vector contains the allocation values
		% Output Arguments:
		%  res - true | false
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
		% Get the waste type
		% Syntax:
		%   res = obj.getType(arg)
		% Input Argument:
		%   arg - waste key or id
		% Output Argument:
		%   res - waste type 
		%
			res=cType.EMPTY_CHAR;
			id=validateArg(obj,arg);
			if id>0
				res=obj.Type{id};
			end
		end
	
		function status=setType(obj,arg,type)
		% Syntax:
		%   res = obj.setType(arg,val)
		% Input Arguments:
		%  arg - waste key name or id
		%  type -waste type
		% Output Arguments:
		%  res - true | false
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
		% Get the recycle ratio value of a waste
		% Syntax:
		%   res = obj.RecycleRatio(arg)
		% Input Argument:
		%   arg - waste key or id
		% Output Argument:
		%   res - waste recycle ratio
		%
			res=cType.EMPTY;
			id=validateArg(obj,arg);
			if id>0
				res=obj.RecycleRatio(id);
			end	
		end
		
		function status=setRecycleRatio(obj,arg,val)
		% Set the recycle ratio
		% Syntax:
		%   res = obj.setType(arg,val)
		% Input Arguments:
		%  arg - waste key name or id
		%  val - recycle ratio
		% Output Arguments:
		%  res - true | false
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
		% Set the waste table values (internal use)
			status=false;
			if all(size(val)==size(obj.Values))
				obj.Values=val;
				status=true;
			end
		end
	end	
		
	methods(Access=private)
		% Check if value is a Index
		function res=validateArg(obj,arg)
			res=cType.EMPTY;
			if ischar(arg)
				res=obj.getWasteIndex(arg);
			elseif isIndex(arg,1:obj.NrOfObjects)
				res=arg;
			end
		end
	end
end	