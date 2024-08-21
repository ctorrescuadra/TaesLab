classdef cWasteData < cStatusLogger
% cWasteData gets and validates the waste definition table.
%
% 	Methods:
% 	  obj=cWasteData(ps,data)
%	  res=obj.getWasteFlows;
%	  res=obj.getWasteIndex(key)
%	  res=obj.existWaste(key)
%	  res=obj.getValues(key)
%     res=obj.getType(key)
%     res=obj.getRecycleRatio(key)
%	  log=obj.setType(key,val)
%     log=obj.setValues(key,vals)
%	  log=obj.setRecycleRatio(key,val)
%	  log=obj.updateValues(vals)
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
		%	ps - cProductiveStructure object
		%	data - waste definition data from cReadModel
		%
			% Check input arguments
			obj=obj@cStatusLogger();
			if ~isstruct(data)
				obj.messageLog(cType.ERROR,'Invalid waste data');
				return
			end
            if ~isa(ps,'cProductiveStructure') || ~isValid(ps)
				obj.messageLog(cType.ERROR,'Invalid productive structure');
				return
            end

			% Check data structure
			if  ~isfield(data,'wastes')
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
                if cType.isEmpty(id)
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
							if cType.isEmpty(jp)
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
			if obj.isValid
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
		% Input:
		%  idx - state index to retrieve
			res=[];
			if nargin==1
				res=obj.Names;
                return
			end
			aux=1:length(obj.Names);
            if ~all(ismember(idx,aux))
                return
            end
			if length(idx)==1
                res=obj.Names{idx};
            else
                res=obj.Names(idx);
			end
		end
			
		function res=getWasteIndex(obj,key)
		% Return the id of the corresponding waste key
		% Input:
		%  ind - state index to retrieve
			res=false;
			if ischar(key)
				[~,res]=ismember(key,obj.Names);
			end
		end
			
		function res=existWaste(obj,key)
		% Determine if waste key is defined
			res=false;
			if ischar(key)
				res=ismember(key,obj.Names);
			end
        end

		function res=getValues(obj,key)
		% Get the allocation ratios of a waste
		% Input:
		%  key - waste id (key or id)
		% Output:
		%  res - vector with the allocation waste ratios of waste id
			res=[];
			if ischar(key)
				id=obj.getWasteIndex(key);
				if isempty(id)
					return
				end
				res=obj.Values(id,:);
			end
		end
	
		function status=setValues(obj,key,val)
		% set the cost distribution values of a waste
		% Input:
		%  arg - key/id of the waste
		%  val - Vector contains the distribution values
			status=false;
			if ischar(key)
				id=obj.getWasteIndex(key);
				if isempty(id)
					return
				end
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
		
		function res=getType(obj,key)
		% get the waste type
		% Input:
		%  key - waste key
			res=[];
			if ischar(key)
				id=obj.getWasteIndex(key);
				if ~isempty(id)
					res=obj.Type{id};
				end
			end
		end
	
		function status=setType(obj,key,type)
		% set the waste type
		% Input:
		%  arg - key/id of the waste
		%  type - new type value
			status=false;
			if ischar(key)
				id=obj.getWasteIndex(key);
				if isempty(id)
					return
				end
			end
			tId=cType.getWasteId(type);
			if ~cType.isEmpty(tId)
				obj.Type{id}=type;
				obj.TypeId(id)=tId;
				status=true;
			end
		end            
					
		function res=getRecycleRatio(obj,key)
		% get the recycle ratio value of a waste
		% Input:
		%  arg - key/id of the waste
			res=[];
			if ischar(key)
				id=obj.getWasteIndex(key);
				if ~isempty(id)
					res=obj.RecycleRatio(id);
				end
			end		
		end
		
		function status=setRecycleRatio(obj,key,val)
		% set the recycle ratio
		% Input:
		%  arg - key/id of the waste
		%  val - recycle ratio value
			status=false;
			if ~ischar(key)
				return
			end
			id=obj.getWasteIndex(key);
			if isempty(id)
				return
			end
			if val<0 || val>1
				return
			end
			status=true;
			obj.RecycleRatio(id)=val;
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
end	