classdef (Sealed) cModelResults < cMessageLogger
    % cModelResults is a class container of the model results
    %   This class store the results of cThermoeconomicModel according to its ResultId
    %   
    % cModelResults Methods:
    %   getResults      - Get a cResultInfo from the container
    %   setResults      - Store a cResultInfo in the container
    %   clearResults    - Delete a cResultInfo from the container
    %   getModelResults - Get the current results of a state
    properties(Access=private)
        results    % cResultInfo cell array container
    end

    methods
        function obj = cModelResults(data)
        % cModelResults Construct an instance of this class
        %  Initialize the results model from data model
        % Syntax:
        %   obj = cModelResults(data)
        % Input Arguments:
        %   data - cDataModel object
        %
            % Check inputs
            if ~isObject(data,'cDataModel')
                obj.messageLog(cType.ERROR,'Invalid data model');
                return
            end
            % Create results array
            obj.results=cell(1,cType.MAX_RESULT_INFO);
            dm=getResultInfo(data);
            obj.setResults(dm);
        end

        function res=getResults(obj,id)
        % Get the cResultInfo from the container
        % Syntax:
        %   res = obj.getResults(id)
        % Input Arguments:
        %   id - ResultId index
        % Output:
        %   res - cResultInfo with ResultId equals to index
            res=cType.EMPTY;
            if cType.isIndex(id,1:cType.MAX_RESULT_INFO)
                res=obj.results{id};
            end
        end

        function res=clearResults(obj,id)
        % Clear the result index in the container
        % Syntax:
        %   res = obj.clearResults(id)
        % Input Arguments:
        %   id - ResultId index to remove from the container
        % Output Arguments:
        %   res - previous cResultInfo stored
            if ~cType.isIndex(id,1:cType.MAX_RESULT_INFO)
                return
            end
            res=obj.getResults(id);
            if ~isempty(obj.results{id})
                obj.results{id}=cType.EMPTY;
                if id<=cType.MAX_RESULT
                    obj.clearResults(cType.ResultId.RESULT_MODEL);
                end
            end
        end

        function setResults(obj,res)
        % Store the cResultInfo in the results container using ResultId as index
        % Syntax:
        %   obj.setResults(id)
        % Input Arguments:
        %   res - cResultInfo to store
        %
            if ~isResultInfo(res)
                return
            end
            id=res.ResultId;
            res0=obj.results{id};
            if cModelResults.checkAssign(res0,res)
                obj.results{id}=res;
                if id<=cType.MAX_RESULT
                    obj.clearResults(cType.ResultId.RESULT_MODEL);
                end
            end
        end

        function res=getModelResults(obj)
        % Get a cell array with the cResultInfo objects of the current state
        % Syntax:
        %   res = obj.getModelResults
        % Output Arguments:
        %   res - cell array with the current cResultInfo objects
        %   
            stateResults=obj.results(1:cType.MAX_RESULT);
            res=obj.results(~cellfun(@isempty,stateResults));
        end
    end

    methods(Static,Access=private)
        function res = checkAssign(obj1,obj2)
        % Check if the set function (obj1=obj2) should be execute
            % Check if obj2 is valid
            if ~isResultInfo(obj2)
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