classdef cWasteTable < cStatusLogger
%cWasteTable  Manage waste allocation table information
%
	properties (GetAccess=public,SetAccess=private)
		NrOfWastes     % Number of Wastes
        Names          % Waste Flows names
        Flows          % Waste flows id
		Type           % Type processing of wastes (text)
        typeId         % Type Id for processing wastes
        Processes      % Dissipative processes id
		Values         % Cost allocation ratios
		RecycleRatio   % Ratio of recycling
	end

	properties (Access=private)
        wlist           % Waste Flow List 
	end

    methods
        function obj = cWasteTable(wd)
        % cWasteTable Construct an instance of this class
        %   Input:
        %       wd - cWasteData object
            obj=obj@cStatusLogger(cType.VALID);
            if ~isa(wd,'cWasteData') || ~wd.isValid
                obj.messageLog(cType.ERROR,'Invalid cWasteData object')
            end
            ps=wd.ps;
            obj.wlist=wd.Flows;
            obj.NrOfWastes=ps.NrOfWastes;
            obj.Type=wd.Type;
            obj.typeId=wd.TypeId;
            obj.Processes=ps.Waste.processes;
            obj.Names=wd.Flows.Entries;
            obj.Flows=ps.Waste.flows;
            obj.Values=wd.Values;
            obj.RecycleRatio=wd.RecycleRatio;
        end

        function res=getWasteIndex(obj,key)
            res=obj.wlist.getIndex(key);
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
                obj.typeId(id)=0;
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
        
        function updateValues(obj,val)
        % update waste allocation values after calculation
        % Input:
        %	val - waste allocation values
            obj.Values=val;
        end

        function status=setTableValues(obj,val)
        % Set the waste table values (internal use)
            status=false;
            if all(size(val)==size(obj.Values))
                obj.Values=val;
                status=true;
            end
        end
    end                    
end   
