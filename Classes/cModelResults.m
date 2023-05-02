classdef (Sealed) cModelResults < cResultId
    %cModelResults is a class container of the model results
    %  This class contains the results of the cThermoeconomicModel class
    %  cModelResults methods
    %   obj=cModelResults(ps)
    %   obj.printResults
    %   obj.saveResults(filename)
    %
    properties(Access=public)
        ProductiveStructure       % Productive Structure results
        ThermoeconomicState       % Exergy Analysis results
        ThermoeconomicAnalysis    % Thermoeconomic Analysis results
        ThermoeconomicDiagnosis   % Thermoeconomic Diagnosis results
    end
    properties(GetAccess=public,SetAccess=private)
        ModelName     % Model Name
        State         % State Name
    end

    properties (Access=private)
        index         % Cell array of cResultInfo
    end

    methods
        function obj = cModelResults(data)
        %cModelResults Construct an instance of this class
        %  Initialize the results model from data model
            obj=obj@cResultId(cType.ResultId.RESULT_MODEL);
            if isa(data,'cResultInfo') && (data.ResultId==cType.ResultId.PRODUCTIVE_STRUCTURE)
                obj.ProductiveStructure=data;
            else
                obj.messageLog(cType.ERROR,'Invalid input parameter');
                return
            end
            obj.index=cell(1,cType.MAX_RESULT);
            obj.index{cType.ResultId.PRODUCTIVE_STRUCTURE}=data;
            obj.ModelName=data.ModelName;
            obj.status=cType.VALID;
        end

        function res=get.State(obj)
        % get the State name
            if isempty(obj.ThermoeconomicState)
                res='';
            else
                res=obj.ThermoeconomicState.State;
            end
        end

        function set.ThermoeconomicState(obj,arg)
        %set.ThermoeconomicState assign a cResultInfo object to the
        % property ThermoeconomicState
            if cModelResults.checkAssign(obj.ThermoeconomicState,arg)
                obj.ThermoeconomicState=arg;
                obj.setIndex(cType.ResultId.THERMOECONOMIC_STATE,arg);
            end
        end

        function set.ThermoeconomicAnalysis(obj,arg)
        %set.ThermoeconomicState assign a cResultInfo object to the
        % property ThermoeconomicState
            if cModelResults.checkAssign(obj.ThermoeconomicAnalysis,arg)
                obj.ThermoeconomicAnalysis=arg;
                obj.setIndex(cType.ResultId.THERMOECONOMIC_ANALYSIS,arg);
            end
        end

        function set.ThermoeconomicDiagnosis(obj,arg)
        %set.ThermoeconomicDiagnosis assign a cResultInfo object to the
        % property ThermoeconomicDiagnosis
            if cModelResults.checkAssign(obj.ThermoeconomicDiagnosis,arg)
                obj.ThermoeconomicDiagnosis=arg;
                obj.setIndex(cType.ResultId.THERMOECONOMIC_DIAGNOSIS,arg);
            end
        end

        function res=getModelInfo(obj)
        % Get not null cResultInfo cell array
            res=obj.index(~cellfun(@isempty,obj.index));
        end

        function res=getModelTables(obj)
        % Get a cModelTables object with all tables of the active model
            tables=struct();
            tmp=obj.getModelInfo;
            for k=1:numel(tmp)
                dm=tmp{k};
                list=dm.getListOfTables;
                for i=1:dm.NrOfTables
                    tables.(list{i})=dm.Tables.(list{i});
                end
            end
            res=cModelTables(obj.ResultId,tables);
            res.setProperties(obj.ModelName,obj.State);
        end
    end

    methods (Access=private)
        function setIndex(obj,id,arg)
        % build index table
            obj.index{id}=arg;
        end
    end

    methods (Static,Access=private)
        function res = checkAssign(obj1,obj2)
        % Check if the set function (obj1=obj2) should be made
            res=false;
            % Determine the objectId of both objects
            if isempty(obj1)
                id1=cType.EMPTY;
            elseif isa(obj1,'cResultInfo') && isValid(obj1)
                id1=obj1.objectId;
            else
                return
            end
            if isempty(obj2)
                id2=cType.EMPTY;
            elseif isa(obj2,'cResultInfo') && isValid(obj2)
                id2=obj2.objectId;
            else
                return
            end
            % Assign is made only if obj1~=obj2
            res=(id1~=id2);
        end
    end
end