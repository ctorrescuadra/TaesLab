classdef (Sealed) cModelResults < cStatusLogger
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
            if isa(data,'cResultInfo') && (data.Id==cType.ResultId.PRODUCTIVE_STRUCTURE)
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

        function printResults(obj)
        % Print the results table on console
            mt=obj.getModelTables;
            printResults(mt);
        end

        function log=saveResults(obj,filename)
        % Save result tables in different file formats depending on file
        % extension (XLSX,CSV,MAT,TXT)
        % Input:
        %   filename - File name. Extensión is used to determine the save mode.
        % Output:
        %   log - cStatusLog object with save status and error messages      
            log=cStatusLogger(cType.VALID);
            % check input parameters
            if ~isValid(obj)
                return
            end
            if ~cType.checkFileWrite(filename)
                message=sprintf('Invalid file name %s',filename);
                log.messageLog(cType.ERROR,message);
                return
            end
            fileType=cType.getFileType(filename);
            % Save the files depending on the extension (fileType)
            mt=obj.getModelTables;
            switch fileType
                case cType.FileType.MAT
                    slog=obj.saveAsMAT(filename);
                case cType.FileType.CSV
                    slog=mt.saveAsCSV(filename);
                case cType.FileType.XLSX
                    slog=mt.saveAsXLS(filename);
                case cType.FileType.TXT
                    slog=mt.saveAsTXT(filename);
                otherwise
                    message=sprintf('File extension %s is not supported',filename);
                    log.messageLog(cType.ERROR,message);
                    return
            end
            log.addLogger(slog);
            if isValid(log)
               message=sprintf('Results file %s has been saved',filename);
               log.messageLog(cType.INFO,message);
            end
        end

        function res=getActiveIndex(obj)
        % Get not null cResultInfo cell array
            res=obj.index(~cellfun(@isempty,obj.index));
        end

        function res=getModelTables(obj)
        % Get a cModelTables object with all tables of the active model
            tables=struct();
            tmp=obj.getActiveIndex;
            for k=1:numel(tmp)
                dm=tmp{k};
                list=dm.getListOfTables;
                for i=1:dm.NrOfTables
                    tables.(list{i})=dm.Tables.(list{i});
                end
            end
            res=cModelTables(cType.ResultId.RESULT_MODEL,tables);
            res.setProperties(obj.ModelName,obj.State);
        end
    end

    methods (Access=private)
        function setIndex(obj,id,arg)
        % build index table
            obj.index{id}=arg;
        end

        function log=saveAsMAT(obj,filename)
        % save the results into a MAT file
            log=cStatusLogger(cType.VALID);
            if isOctave
                message=sprintf('This file type is not available for Octave');
                log.messageLog(cType.ERROR,message);
            end
            try
                save(filename,'obj');
            catch err
                obj.messageLog(cType.ERROR,err.message);
                obj.messageLog(cType.ERROR,'File %s has NOT been saved', filename);
                return    
            end
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