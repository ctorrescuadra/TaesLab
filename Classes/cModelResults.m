classdef (Sealed) cModelResults < cMessageLogger
    %cModelResults - Class container for the model results.
    %   This class store the results of cThermoeconomicModel according to its ResultId
    %
    %   cModelResults constructor:
    %     obj = cModelResults(data)
    %   
    %   cModelResults methods:
    %     getResults      - Get a cResultInfo from the container
    %     setResults      - Store a cResultInfo in the container
    %     clearResults    - Delete a cResultInfo from the container
    %     getModelResults - Get the current results of a state
    %
    %   See cThermoeconomicModel
    %
    properties(Access=private)
        results    % cResultInfo cell array container
    end

    methods
        function obj = cModelResults(data)
        %cModelResults - Construct an instance of this class
        %   Initialize the results model from data model
        %
        %   Syntax:
        %     obj = cModelResults(data)
        %   Input Arguments:
        %     data - cDataModel object
        %
            % Check inputs
            if ~isObject(data,'cDataModel')
                obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(data));
                return
            end
            % Create results array
            obj.results=cell(1,cType.MAX_RESULT_INFO);
            dm=getResultInfo(data);
            obj.setResults(dm);
        end

        function res=getResults(obj,id)
        % getResults - Get the cResultInfo from the container
        %   Syntax:
        %     res = obj.getResults(id)
        %   Input Arguments:
        %     id - ResultId index
        %   Output Arguments:
        %     res - cResultInfo for the corresponding index
            res=cType.EMPTY;
            if nargin==1
                res=obj.results;
            elseif isIndex(id,1:cType.MAX_RESULT_INFO)
                res=obj.results{id};
            end
        end

        function res=clearResults(obj,id)
        %clearResults - Clear the result index in the container
        %   Syntax:
        %     res = obj.clearResults(id)
        %   Input Arguments:
        %     id - ResultId index to remove from the container
        %   Output Arguments:
        %     res - previous cResultInfo stored
            if ~isIndex(id,1:cType.MAX_RESULT_INFO)
                return
            end
            res=obj.getResults(id);
            if ~isempty(res)
                obj.results{id}=cType.EMPTY;
                if id<=cType.MAX_RESULT
                    obj.clearResults(cType.ResultId.RESULT_MODEL);
                end
            end
        end

        function setResults(obj,res,force)
        %setResults - Store the cResultInfo in the results container using ResultId as index
        %   Syntax:
        %     obj.setResults(id)
        %   Input Arguments:
        %     res   - cResultInfo to store
        %     force - store without comparison
        %       true | false (default)
        %
            if ~isObject(res,'cResultInfo')
                return
            end
            if nargin==2
                force=false;
            end
            id=res.ResultId;
            res0=obj.results{id};
            if force || cModelResults.checkAssign(res0,res)
                obj.results{id}=res;
                if id<=cType.MAX_RESULT
                    obj.clearResults(cType.ResultId.RESULT_MODEL);
                end
            end
        end

        function res=getModelResults(obj)
        %getModelResult - Get a cell array with the cResultInfo objects of the current state
        %   Syntax:
        %     res = obj.getModelResults
        %   Output Arguments:
        %     res - cell array with the current cResultInfo objects
        %   
            stateResults=obj.results(1:cType.MAX_RESULT);
            res=obj.results(~cellfun(@isempty,stateResults));
        end
    end

    methods(Static,Access=private)
        function res = checkAssign(obj1,obj2)
        % Check if the set function (obj1=obj2) should be execute
            % Check if obj2 is valid
            if ~isObject(obj2,'cResultInfo')
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