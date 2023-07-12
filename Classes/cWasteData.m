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
		Flows			% Waste Flow keys
		Type        	% Waste Allocation types
		TypeId      	% Waste Type Id
		Values      	% Waste Allocation values
		RecycleRatio    % Recycle Ratio
		ps              % Productive Structure Handler
	end
    
	methods
		function obj=cWasteData(data,ps)
		% Class constructor
		%	ps - cProductiveStructure object
		%	data - waste definition data from cReadModel
		%
			% Check input arguments
			obj=obj@cStatusLogger(cType.VALID);
			if ~isstruct(data) 
				obj.messageLog(cType.ERROR,'Invalid waste data provided');
				return
			end
			if ~isa(ps,'cProductiveStructure') || ~ps.isValid
				obj.messageLog(cType.ERROR,'No Valid Productive Structure provided');
				return
			end
            obj.status=cType.VALID;
			% Check data structure
			if  ~isfield(data,'wastes')
                obj.messageLog(cType.ERROR,'Invalid waste date. Fields Missing');
				return
			end
			% Check waste info
            wd=data.wastes;
			NR=length(wd);
			if NR ~= ps.NrOfWastes
				message=sprintf('Invalid number of wastes %d defined.',NR);
				obj.messageLog(cType.ERROR,message);
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
                    message=sprintf('Invalid Waste Allocation method %s',wd(i).type);
                    obj.messageLog(cType.ERROR,message);
                end
                % Check key
                id=ps.getFlowId(wd(i).flow);
                if cType.isEmpty(id)
                   	message=sprintf('Invalid flow id %s',wd(i).flow);
				    obj.messageLog(cType.ERROR,message);
					continue
                end 
				if ~ps.Flows(id).type == cType.Flow.WASTE
					message=sprintf('flow %s must be waste',wd(i).flow);
					obj.messageLog(cType.ERROR,message);
				end
				% Check Recycle Ratio
				if isfield(wd(i),'recycle')
					if (wd(i).recycle>1) || (wd(i).recycle<0) 
						obj.messageLog(cType.ERROR,'Invalid Recycle Ratio');
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
							message=sprintf('Values fields missing for waste %s',wd(i).flow);
							obj.messageLog(cType.ERROR,message);
							return
                        end
                        for j=1:length(wval)
							jp=ps.getProcessId(wval(j).process);
							if cType.isEmpty(jp)
								message=sprintf('Invalid process name %s',wval(j).process);
								obj.messageLog(cType.ERROR,message);
								continue
							end
							if(ps.Processes(jp).type==cType.Process.DISSIPATIVE)
								message=sprintf('Waste %s cannot be asssigned to dissipative units',wval(j).process);
								obj.messageLog(cType.ERROR,message);
								continue
							end
							if (wval(j).value <= 0)
								message=sprintf('Waste distribution value %s %f cannot be NEGATIVE',wval(j).process,wval(j).value);
								obj.messageLog(cType.ERROR,message);
								continue
							end
							values(i,jp)=wval(j).value;
                        end
					    else %if no values provided set type to DEFAULT
						    wasteType(i)=cType.WasteAllocation.DEFAULT;
						    message=sprintf('Waste allocation of flow %s is defined as MANUAL and does not have values defined ',wd(i).flow);
						    obj.messageLog(cType.ERROR,message);
					end             
				end
			end
			% Create the object
			if obj.isValid
				obj.Flows={wd.flow};
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