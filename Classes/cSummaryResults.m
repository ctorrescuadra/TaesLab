classdef (Sealed) cSummaryResults < cResultId
%cSummaryResults - Compute and organise multi-state/multi-sample summary tables.
%   cSummaryResults collects thermoeconomic result vectors from a
%   cThermoeconomicModel and stores them in a cDataset of cSummaryTable
%   objects, one per registered summary table name.
%
%   There are two independent summary types, which can be requested
%   individually or together via the option argument:
%     STATES    - Tabulates one result column per exergy state, allowing
%                 comparison of exergy values, costs and efficiencies
%                 across different operating conditions.
%     RESOURCES - Tabulates one result column per resource-cost sample,
%                 allowing sensitivity analysis to input cost variations.
%
%   The available types depend on the data model (see cSummaryOptions).
%   If the model has only one state and one sample, construction fails.
%
%   cSummaryResults Properties:
%     Tables     - Cell array of summary table name strings created
%     NrOfTables - Number of tables in the dataset
%
%   cSummaryResults Methods:
%     cSummaryResults            - Construct and fill the summary dataset
%     buildResultInfo            - Return the cResultInfo for display/export
%     defaultSummaryTables       - Return the default summary option name
%     getDefaultFlowVariables    - Return the system output flow keys
%     getDefaultProcessVariables - Return the system output process keys
%     getSummaryColumns          - Return column names for a summary type
%     getValues                  - Retrieve a cSummaryTable by name or index
%     isSampleSummary            - True if resource-sample tables were built
%     isStateSummary             - True if state-comparison tables were built
%     setSummaryTables           - Refill tables from an updated model
%
%   See also cThermoeconomicModel, cSummaryTable, cSummaryOptions,
%            cResultInfo, cResultId
%
    properties(GetAccess=public,SetAccess=private)
        Tables       % Names of Summary Tables created
        NrOfTables   % Number of Tables
    end

    properties(Access=private)
        dm     % cDataModel object
        ds     % cDataset containing the table values
        option % Summary Results option
        rsd    % Resource Data available
        sopt   % cSummaryOption object 
    end

    methods
        function obj = cSummaryResults(model,option)
        %cSummaryResults - Construct and fill the summary dataset
        %   Validates the model, determines the active summary option,
        %   creates one cSummaryTable per registered summary table name,
        %   then calls setSummaryTables to populate the values matrices.
        %   Construction fails when:
        %     - model is not a cThermoeconomicModel
        %     - the data model has neither multiple states nor multiple samples
        %     - option is provided but is not valid for this data model
        %
        %   Syntax:
        %     obj = cSummaryResults(model)
        %     obj = cSummaryResults(model, option)
        %
        %   Input Arguments:
        %     model  - cThermoeconomicModel object to summarise.
        %     option - (optional) Numeric summary Id (cType.SummaryId value):
        %                cType.SummaryId.STATES    - state-comparison tables only
        %                cType.SummaryId.RESOURCES - resource-sample tables only
        %                cType.SummaryId.ALL       - both types
        %              When omitted, the model's default summary option is used.
        %
        %   Output Arguments:
        %     obj - cSummaryResults object.  Use isValid(obj) to confirm
        %           successful construction before calling other methods.
        %
            % Check Input Arguments:
            if ~isObject(model,'cThermoeconomicModel')
                obj.addLogger(model);
                obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(model));
                return
            end
            obj.dm=model.DataModel;
            obj.rsd=obj.dm.isResourceCost;
            sopt=obj.dm.SummaryOptions;
            if ~sopt.isEnable
                obj.messageLog(cType.ERROR,cMessages.SummaryNotAvailable);
                return
            end
            % Check Option
            if nargin==1
                obj.option=sopt.Id;
            elseif checkId(sopt,option)
                obj.option=option;
            else
                obj.messageLog(cType.ERROR,cMessages.InvalidSummaryOption);
                return
            end
            % Option NONE is provided
            if ~obj.option
                obj.messageLog(cType.ERROR,cMessages.InvalidSummaryOption);
                return
            end
            % Get summary tables properties
            fmt=obj.dm.FormatData;
            tdlist=fmt.getSummaryTables(obj.option,obj.rsd);
            % Create dataset using table name as key
            tname={tdlist.key};
            obj.ds=cDataset(tname);
            if obj.ds.status
                obj.Tables=tname;
            else
                obj.messageLog(cType.ERROR,cMessages.InvalidSummaryData);
            end
            % Initialize Dataset with cSummaryTable objects
            for idx=1:obj.NrOfTables
                td=tdlist(idx);
                tmp=cSummaryTable(obj.dm,td);
                setValues(obj.ds,idx,tmp);
            end          
            % Fill Dataset Tables
            obj.setSummaryTables(model);
            % cResultId properties
            obj.sopt=sopt;
            obj.ResultId=cType.ResultId.SUMMARY_RESULTS;
            obj.DefaultGraph=obj.getDefaultSummaryGraph;
            obj.ModelName=model.ModelName;
            obj.State=model.State;
            obj.Sample=model.Sample;
        end

        function res=get.NrOfTables(obj)
        %get.NrOfTables - Return the number of summary tables in the dataset
            res=length(obj.ds);
        end

        function res=buildResultInfo(obj,fmt)
        %buildResultInfo - Return the cResultInfo for display and export
        %   Delegates to cResultTableBuilder.getSummaryResults, which
        %   converts each cSummaryTable in the dataset into a cTableMatrix.
        %
        %   Syntax:
        %     res = obj.buildResultInfo(fmt)
        %
        %   Input Arguments:
        %     fmt - cResultTableBuilder object.
        %
        %   Output Arguments:
        %     res - cResultInfo (SUMMARY_RESULTS) ready for ShowResults/SaveResults.
        %
            res=fmt.getSummaryResults(obj);
        end

        function res=defaultSummaryTables(obj)
        %defaultSummaryTables - Return the default summary option name
        %   Delegates to cSummaryOptions.defaultOption, returning the most
        %   complete option available for this data model.
        %
        %   Syntax:
        %     res = obj.defaultSummaryTables()
        %
        %   Output Arguments:
        %     res - Option name string (e.g. 'ALL', 'STATES', 'RESOURCES').
        %
            res=obj.sopt.defaultOption;
        end
        
        function setSummaryTables(obj,model,option)
        %setSummaryTables - Refill summary tables from a (possibly updated) model
        %   Dispatches to setStateTables and/or setResourceTables depending
        %   on the bits set in option.  Can be called after model changes
        %   (e.g. after setExergyData) to refresh the summary without
        %   reconstructing the whole cSummaryResults object.
        %
        %   Syntax:
        %     obj.setSummaryTables(model)
        %     obj.setSummaryTables(model, option)
        %
        %   Input Arguments:
        %     model  - cThermoeconomicModel object.
        %     option - (optional) Numeric summary Id.  Defaults to obj.option
        %              when omitted.
        %
            if nargin==2
                option=obj.option;
            end
            % Set state tables values
            if bitget(option,cType.STATES)
                obj.setStateTables(model)
            end % Set resource tables values
            if bitget(option,cType.RESOURCES)
                obj.setResourceTables(model)
            end
        end
    
        function res=getValues(obj,id)
        %getValues - Retrieve a cSummaryTable by name or index
        %
        %   Syntax:
        %     res = obj.getValues(id)
        %
        %   Input Arguments:
        %     id  - Table name string or positive integer index.
        %
        %   Output Arguments:
        %     res - cSummaryTable object for the requested entry, or a
        %           cMessageLogger with status false if id is invalid.
        %
            res=getValues(obj.ds,id);
        end

        function res=getSummaryColumns(obj,type)
        %getSummaryColumns - Return the column names for a given summary type
        %   Maps the summary type to the appropriate name array from the
        %   data model: state names for STATES tables, sample names for
        %   RESOURCES tables.
        %
        %   Syntax:
        %     res = obj.getSummaryColumns(type)
        %
        %   Input Arguments:
        %     type - Summary type selector (cType.SummaryId value):
        %              cType.SummaryId.STATES    -> dm.StateNames
        %              cType.SummaryId.RESOURCES -> dm.SampleNames
        %
        %   Output Arguments:
        %     res  - Cell array of column name strings.
        %
            switch type
                case cType.SummaryId.STATES
                    res=obj.dm.StateNames;
                case cType.SummaryId.RESOURCES
                    res=obj.dm.SampleNames;
            end
        end
    
        function res=getDefaultFlowVariables(obj)
        %getDefaultFlowVariables - Return the system output flow key strings
        %   Retrieves the indices of system output flows from the productive
        %   structure and returns the corresponding key names.
        %
        %   Syntax:
        %     res = obj.getDefaultFlowVariables()
        %
        %   Output Arguments:
        %     res - Cell array of flow key strings for system output flows.
        %
            ps=obj.dm.ProductiveStructure;
            id=ps.SystemOutputFlows;
            res=ps.FlowKeys(id);
        end
    
        function res=getDefaultProcessVariables(obj)
        %getDefaultProcessVariables - Return the system output process key strings
        %   Retrieves the indices of output processes from the productive
        %   structure and returns the corresponding key names.
        %
        %   Syntax:
        %     res = obj.getDefaultProcessVariables()
        %
        %   Output Arguments:
        %     res - Cell array of process key strings for output processes.
        %
            ps=obj.dm.ProductiveStructure;
            id=ps.OutputProcesses;
            res=ps.ProcessKeys(id);
        end

        function res=isStateSummary(obj)
        %isStateSummary - Return true if state-comparison tables were built
        %   Tests bit 1 (cType.STATES) of the active option.
        %
        %   Syntax:
        %     res = obj.isStateSummary()
        %
        %   Output Arguments:
        %     res - Logical scalar.
        %
            res=logical(bitget(obj.option,cType.STATES));
        end

        function res=isSampleSummary(obj)
        %isSampleSummary - Return true if resource-sample tables were built
        %   Tests bit 2 (cType.RESOURCES) of the active option.
        %
        %   Syntax:
        %     res = obj.isSampleSummary()
        %
        %   Output Arguments:
        %     res - Logical scalar.
        %
            res=logical(bitget(obj.option,cType.RESOURCES));
        end
            
    end
    
    methods(Access=private)
        function setValues(obj,id,jdx,val)
        %setValues - Set the dataset table values
        %   Syntax:
        %     obj.setValues(id,jdx,val)
        %   Input Arguments:
        %     id - Name/Key of the summary table
        %     jdx - Column (State/sample) to update
        %     val - Vector with the cost values to update
        %
            tmp=getValues(obj.ds,id);
            setValues(tmp,jdx,val);
        end

        function res=getDefaultSummaryGraph(obj)
        %getDefaultSummaryGraph - Return the default graph table name
        %   Selects the flow-unit-cost summary table for state summaries,
        %   or the resource generalised flow-unit-cost table for resource
        %   summaries.
            if bitget(obj.option,cType.STATES)
                res=cType.Tables.SUMMARY_FLOW_UNIT_COST;
            else
                res=cType.Tables.RSUMMARY_FLOW_GENERAL_UNIT_COST;
            end
        end
        
        function setStateTables(obj,model)
        %setStateTables - Fill state-summary tables from the model
        %   Iterates over all states in the data model, runs the analysis
        %   for each state, and writes the result vectors column-by-column
        %   into the corresponding cSummaryTable objects.
        %
        %   Syntax:
        %     obj.setStateTables(model)
        %
        %   Input Arguments:
        %     model - cThermoeconomicModel object.
        %
            if model.isResourceCost
                rd=model.ResourceData;
            end
            for j=1:model.DataModel.NrOfStates
                rstate=model.getResultState(j);
                % SUMMARY EXERGY
                id=cType.Tables.SUMMARY_EXERGY;
                val=rstate.FlowsExergy';
                obj.setValues(id,j,val);
                % SUMMARY UNIT CONSUMPTION
                id=cType.Tables.SUMMARY_UNIT_CONSUMPTION;
                val=rstate.ProcessesExergy.vK';
                obj.setValues(id,j,val);
                %SUMMARY IRREVERSIBILITY
                id=cType.Tables.SUMMARY_IRREVERSIBILITY;
                val=rstate.ProcessesExergy.vI';           
                obj.setValues(id,j,val);
                % SUMMARY PROCESS COST
                id=cType.Tables.SUMMARY_PROCESS_COST;
                cost=rstate.getProcessCost;
                obj.setValues(id,j,cost.CP');
                % SUMMARY PROCESS UNIT COST
                id=cType.Tables.SUMMARY_PROCESS_UNIT_COST;
                ucost=rstate.getProcessUnitCost;
                obj.setValues(id,j,ucost.cP');
                % SUMMARY FLOW COST
                fcost=rstate.getFlowsCost;
                id=cType.Tables.SUMMARY_FLOW_COST;
                obj.setValues(id,j,fcost.C');
                id=cType.Tables.SUMMARY_FLOW_UNIT_COST;
                obj.setValues(id,j,fcost.c');
                % General Cost
                if model.isResourceCost
                    setResourceCost(rd,rstate);
                    % SUMMARY PROCESS COST
                    id=cType.Tables.SUMMARY_PROCESS_GENERAL_COST;
                    cost=rstate.getProcessCost(rd);
                    obj.setValues(id,j,cost.CP');
                    % SUMMARY PROCESS UNIT COST
                    id=cType.Tables.SUMMARY_PROCESS_GENERAL_UNIT_COST;
                    ucost=rstate.getProcessUnitCost(rd);
                    obj.setValues(id,j,ucost.cP');
                    % SUMMARY FLOW COST
                    fcost=rstate.getFlowsCost(rd);
                    id=cType.Tables.SUMMARY_FLOW_GENERAL_COST;
                    obj.setValues(id,j,fcost.C');
                    id=cType.Tables.SUMMARY_FLOW_GENERAL_UNIT_COST;
                    obj.setValues(id,j,fcost.c');
                end
            end
        end

        function setResourceTables(obj,model)
        %setResourceTables - Fill resource-summary tables from the model
        %   Iterates over all resource-cost samples in the data model,
        %   runs the generalised-cost analysis for each sample, and writes
        %   the result vectors column-by-column into the corresponding
        %   cSummaryTable objects.
        %
        %   Syntax:
        %     obj.setResourceTables(model)
        %
        %   Input Arguments:
        %     model - cThermoeconomicModel object.
        %
            rstate=model.getResultState;
            for j=1:model.DataModel.NrOfSamples
                rd=obj.dm.getResourceData(j);
                setResourceCost(rd,rstate);
                % SUMMARY PROCESS COST
                id=cType.Tables.RSUMMARY_PROCESS_GENERAL_COST;
                cost=rstate.getProcessCost(rd);
                obj.setValues(id,j,cost.CP');
                % SUMMARY PROCESS UNIT COST
                id=cType.Tables.RSUMMARY_PROCESS_GENERAL_UNIT_COST;
                ucost=rstate.getProcessUnitCost(rd);
                obj.setValues(id,j,ucost.cP');
                % SUMMARY FLOW COST
                fcost=rstate.getFlowsCost(rd);
                id=cType.Tables.RSUMMARY_FLOW_GENERAL_COST;
                obj.setValues(id,j,fcost.C');
                id=cType.Tables.RSUMMARY_FLOW_GENERAL_UNIT_COST;
                obj.setValues(id,j,fcost.c');
            end
        end
    end
end