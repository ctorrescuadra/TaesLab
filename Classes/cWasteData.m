classdef cWasteData < cStatusLogger
% cWasteData gets and validates the waste definition table.
%   If waste table is not provided, the default waste table from productive
%   structure is used
% 	Methods:
% 		obj=cWasteData(ps,data)
%		res=obj.getWasteDefinition;
%		wt=obj.getWasteTable;
%
	properties (GetAccess=public,SetAccess=private)
		Flows			% Waste Flow List
		Type        	% Waste Allocation types
		TypeId      	% Waste Type Id
		Values      	% Waste Allocation values
		RecycleRatio    % Recycle Ratio
		ps              % Productive Structure handler
	end
    
	methods
		function obj=cWasteData(dm,ps)
		% Class constructor
		%	ps - cProductiveStructure object
		%	data - waste definition data from cReadModel
		%
			% Check input arguments
			obj=obj@cStatusLogger(cType.VALID);
			if ~isa(dm,'cModelData') || ~isValid(dm) 
				obj.messageLog(cType.ERROR,'Invalid waste data');
				return
			end
            if ~isa(ps,'cProductiveStructure') || ~ps.isValid
				obj.messageLog(cType.ERROR,'Invalid productive structure');
				return
            end
            % Take waste definition
            if dm.isWaste
                data=dm.WasteDefinition;
            else
                data=ps.WasteData;
                obj.messageLog(cType.INFO,'Waste Definition is not available. Default is used');
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
				obj.Flows=cSetList({wd.flow});
				obj.Type={wd.type};
				obj.TypeId=wasteType;
				obj.Values=values;
				obj.RecycleRatio=recycleRatio;
				obj.ps=ps;
			end
		end

		function res=getWasteTable(obj)
		% get the cWasteTable object
			res=cWasteTable(obj);
		end
	end
end	