classdef cWasteTable < cResultId
%cWasteTable  Manage waste allocation table information
%
	properties (GetAccess=public,SetAccess=private)
		NrOfWastes     % Number of Wastes
		Type           % Type processing of wastes (text)
        typeId         % Type Id for processing wastes
		Processes      % Dissipative processes
		Flows          % Waste flows
		Values         % Cost allocation ratios
		RecycleRatio   % Ratio of recycling
	end

	properties (Access=private)
		ps				% Productive Structure 
	end

    methods
        function obj = cWasteTable(rwst)
        %cWasteTable Construct an instance of this class
        %   Input:
        %       rwst - cReadWaste object
            obj=obj@cResultId(cType.ResultId.WASTE_ANALYSIS);
            if ~isa(rwst,'cReadWaste') || ~rwst.isValid
                obj.messageLog(cType.ERROR,'Invalid Waste Definition object')
            end
            wd=rwst.getWasteDefinition;
            obj.ps=wd.ps;
            obj.NrOfWastes=obj.ps.NrOfWastes;
            obj.Type=wd.type;
            obj.typeId=wd.typeId;
            obj.Processes=obj.ps.Waste.processes;
            obj.Flows=obj.ps.Waste.flows;
            obj.Values=wd.values;
            obj.RecycleRatio=wd.recycle;
            obj.status=true;
        end

		function res=getValues(obj,arg)
        % Get the allocation ratios of a waste
        % Input:
        %  arg - waste id (key or id)
        % Output:
        %  res - vector with the allocation waste ratios of waste id
            res=[];
            if ischar(arg)
                id=obj.getWasteIndex(arg);
                if isempty(id)
                    return
                end
            elseif isscalar(arg) && isnumeric(arg)
                id = arg;
            else
                return
            end
            res=obj.Values(id,:);
        end

        function status=setValues(obj,arg,val)
        % set the cost distribution values of a waste
        % Input:
        %  arg - key/id of the waste
        %  val - Vector contains the distribution values
            status=false;
            if ischar(arg)
                id=obj.getWasteIndex(arg);
                if isempty(id)
                    return
                end
            elseif isscalar(arg) && isnumeric(arg)
                id=arg;
            else
                return
            end
            if size(obj.Values,2)~=length(val)
                return
            end
            if any(val>0) && isempty(find(val<0,1))
                obj.typeId(id)=0;
                obj.Type{id}='MANUAL';
                obj.Values(id,:)=val;
                status=true;
            end
        end
    
        function res=getType(obj,key)
        % get the waste type
        % Input:
        %  arg - key/id of the waste
            res=[];
            if ischar(key)
                id=obj.getWasteIndex(key);
                if ~isempty(id)
                    res=obj.Type{id};
                end
            end
        end

        function status=setType(obj,arg,type)
        % set the waste type
        % Input:
        %  arg - key/id of the waste
        %  type - new type value
            status=false;
            if ischar(arg)
                id=obj.getWasteIndex(arg);
                if isempty(id)
                    return
                end
            elseif isscalar(arg) && isnumeric(arg)
                    id=arg;
            else
                return
            end
            tId=cType.getWasteId(type);
            if ~cType.isEmpty(tId)
                obj.Type{id}=type;
                obj.typeId(id)=tId;
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
    
        function status=setRecycleRatio(obj,arg,val)
        % set the recycle ratio
        % Input:
        %  arg - key/id of the waste
        %  val - recycle ratio value
            status=false;
            if ischar(arg)
                id=obj.getWasteIndex(arg);
                if isempty(id)
                    return
                end
            elseif isscalar(arg) && isnumeric(arg)
                id=arg;
            else
                return
            end
            if val<0 || val>1
                return
            end
            status=true;
            obj.RecycleRatio(id)=val;
        end			
        
        function updateValues(obj,val)
        % update waste allocation values after calculation
        % Input:
        %	val - waste allocation values
            obj.Values=val;
        end
    
        function idx=getWasteIndex(obj,key)
        %  Get the index of waste
            idx=[];
            id=obj.ps.getFlowId(key);
            if ~cType.isEmpty(id)
                wf=obj.ps.Waste.flows;
                idx=find(wf==id);
            end
        end
    end                    
end   
