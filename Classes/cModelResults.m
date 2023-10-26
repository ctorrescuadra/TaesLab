classdef (Sealed) cModelResults < cStatusLogger
    %cModelResults is a class container of the model results
    %   This class store the results of cThermoeconomicTool according to its ResultId
    %   cModelResults methods:
    %       obj=cModelResults(data)
    %       res=obj.getResults(id)
    %       obj.setResults(res)
    %       obj.clearResults(id)
    %       obj.getModelInfo
    properties(Access=private)
        results    % cResultInfo cell array
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
            obj.status=cType.VALID;
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
        % Check if the set function (obj1=obj2) should be execute
            % Check if obj2 is not empty and is valid
            if isempty(obj2) || ~isa(obj2,'cResultInfo') || ~isValid(obj2)
                res=false;
                return
            end
            % If obj1 is empty do assign
            if isempty(obj1)
                res=true;
                return
            end
            % Compare if objects are different
            res=(obj1~=obj2);
        end
    end
end