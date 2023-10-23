classdef (Sealed) cModelResults < cStatusLogger
    %cModelResults is a class container of the model results
    %   This class store the results of cThermoeconomicTool 
    %   according to its ResultId
    %   cModelResults methods:
    %       obj=cModelResults(data)
    %       res=obj.getResults(id)
    %       obj.setResults(res)
    %       obj.clearResults(id)
    %       obj.getModelInfo
    properties(Access=private)
        results    % cResultInfo cell array
        modelName  % Model Name
        state      % State Name 
    end

    methods
        function obj = cModelResults(data)
        %cModelResults Construct an instance of this class
        %  Initialize the results model from data model
        %   data - cDataModel object
            if ~isa(data,'cDataModel') || ~data.isValid
                obj.messageLog(cType.ERROR,'Invalid data model');
                return
            end
            ps=getProductiveStructureResults(data.FormatData,data.ProductiveStructure);
            ps.setProperties(data.ModelName,'SUMMARY');
            obj.results=cell(1,cType.MAX_RESULT_INFO);
            obj.setResults(ps);
            obj.modelName=data.ModelName;
            obj.status=cType.VALID;
        end

        function res=get.state(obj)
        % get the State name from thermoeconomicState
            res='';
            ts=obj.getResults(cType.ResultId.THERMOECONOMIC_STATE);
            if ~isempty(ts)
                res=ts.State;
            end
        end

        function res=getResults(obj,id)
        % Get the cResultInfo from the container
        %   Input:
        %       id - ResultId index
        %   Output:
        %       res - cResultInfo with ResultId equal to index
            res=obj.results{id};
        end

        function res=clearResults(obj,id)
        % Clear the result index in the container
        %   Input:
        %       id - ResultId index to remove from the container
        %   Output
        %       res - previous cResultInfo stored
            res=obj.getResults(id);
            obj.results{id}=[];
        end

        function setResults(obj,res)
        % Store the cResultInfo in the results container using ResultId as index
        %   Input:
        %       res - cResultInfo to store
            id=res.ResultId;
            res0=obj.results{id};
            if cModelResults.checkAssign(res0,res)
                obj.results{id}=res;
            end
        end

        function res=getModelInfo(obj)
        % Get the cResultInfo objects of the current state
            stateResults=obj.results(1:cType.MAX_RESULT);
            res=obj.results(~cellfun(@isempty,stateResults));
        end
    end

    methods(Static,Access=private)
        function res = checkAssign(obj1,obj2)
        % Check if the set function (obj1=obj2) should be made
            res=false;
            % Determine the objectId of both objects
            if isempty(obj1)
                id1=cType.EMPTY;
            elseif isa(obj1,'cResultInfo') && isValid(obj1)
                id1=getObjectId(obj1.Info);
            else
                return
            end
            if isempty(obj2)
                id2=cType.EMPTY;
            elseif isa(obj2,'cResultInfo') && isValid(obj2)
                id2=getObjectId(obj2.Info);
            else
                return
            end
            % Assign is made only if obj1~=obj2
            res=(id1~=id2);
        end
    end
end