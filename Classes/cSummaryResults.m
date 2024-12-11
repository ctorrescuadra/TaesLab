classdef (Sealed) cSummaryResults < cResultId
% cSummaryResults gets the summary results tables of the model
%   There is two types of summary tables
%    STATES - Summarize the results for each state
%    RESOURCES - Summarize the results for each resource sample
% 
% cSummaryResults Properties
%   Tables     - List of the Summary Tabled created
%   NrOfTables - Number of Tables
% 
% cSummaryResults Methods
%   buildResultInfo            - Build the cResultInfo object with the summary tables
%   defaultSummaryTables       - Get the default summary tables option name
%   setSummaryTables           - Set the values of the summary tables
%   getValues                  - Get the summary tables info
%   getRowNames                - Get the row names of the summary tables
%   getColNames                - Get the column names of the summary tables
%   getDefaultFlowVariables    - Get the names of the output flows for summary graphs
%   getDefaultProcessVariables - Get the names of the output processes for summary graphs
%
% See also cThermoeconomicModel
%
    properties(GetAccess=public,SetAccess=private)
        Tables       % Names of Summary Tabled created
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
        % Build an instance of this class
        % Syntax:
        %   obj = cSummaryResults(model,option)
        % Input Arguments:
        %   model - cThermoeconomicModel object
        %   option - Type of summary results to obtain
        %    If it is missing is determined by the model (cSummaryOptions)
        %
            obj=obj@cResultId(cType.ResultId.SUMMARY_RESULTS);
            % Check Input Arguments
            if ~isObject(model,'cThermoeconomicModel')
                obj.addLogger(model);
                obj.messageLog(cType.ERROR,cMessages.InvalidThermoeconomicModel);
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
            if ~obj.option
                obj.messageLog(cType.ERROR,cMessages.InvalidSummaryOption);
                return
            end
            % Get summary tables properties and create dataset
            fmt=obj.dm.FormatData;
            list=fmt.getSummaryTables(obj.option,obj.rsd);
            obj.ds=cDataset(list);
            if obj.ds.status
                obj.Tables=list;
            else
                obj.messageLog(cType.ERROR,cMessages.InvalidSummaryData);
            end
            % Initialize Dataset
            for i=1:obj.NrOfTables
                tbl=obj.Tables{i};
                tp=fmt.getTableProperties(tbl);
                size=obj.getTableSize(tp);
                tmp=cSummaryTable(tp,size);
                setValues(obj.ds,i,tmp);
            end          
            % Fill Dataset Tables
            obj.setSummaryTables(model);
            % cResultId properties
            obj.sopt=sopt;
            obj.DefaultGraph=obj.setDefaultSummaryGraph;
            obj.ModelName=model.ModelName;
            obj.State=model.State;
            obj.Sample=model.Sample;
        end

        function res=get.NrOfTables(obj)
        % Get Number of tables
            res=length(obj.ds);
        end

        function res=buildResultInfo(obj,fmt)
        % Get cResultInfo object
        % Syntax:
        %   res=obj.buildResultInfo(fmt)
        % Input Argument
        %   fmt - cResultTableBuilder object
        % Output Argument
        %   res - cResultInfo object with the summary results
            res=fmt.getSummaryResults(obj);
        end

        function res=defaultSummaryTables(obj)
        % Get the default summary tables option name
        % Syntax:
        %   res=obj.defaultSummaryTable
        % Output Argument:
        %   res - Get the default summary option name
            res=obj.sopt.defaultOption;
        end
        
        function setSummaryTables(obj,model,option)
        % Fill the values of the summary tables with the values of the model
        % Syntax:
        %   obj.setSummaryTables(model,option)
        % Input Argument:
        %   model - cThermoeconomicModel object
        %   option - Type of summary result
            if nargin==2
                option=obj.option;
            end
            if bitget(option,cType.STATES)
                obj.setStateTables(model)
            end
            if bitget(option,cType.RESOURCES)
                obj.setResourceTables(model)
            end
        end
    
        function res=getValues(obj,id)
        % Get dataset tables
        % Syntax:
        %   res = obj.getValues(id)
        % Input Argument
        %   id - Id/Name of the table
        % Output Argument
        %   res - cSummaryTable 
            res=getValues(obj.ds,id);
        end

        function res=getRowNames(obj,key)
        % Get the row names of the table
        % Syntax:
        %   res = obj.getRowNames(id)
        % Input Argument
        %   key - Id/Name of the table
        % Output Argument
        %   res - cell array with the row names of the table
            ps=obj.dm.ProductiveStructure;
            tbl=obj.getValues(key);
            switch tbl.Node
                case cType.NodeType.FLOW
                    res=ps.FlowKeys;
                case cType.NodeType.PROCESS
                    res=ps.ProcessKeys(1:end-1);
                case cType.NodeType.ENV
                    res=ps.ProcessKeys;
            end
        end

        function res=getColNames(obj,key)
        % Get the column names of the tables
        % Syntax:
        %   res = obj.getColNames(id)
        % Input Argument
        %   key - Id/Name of the table
        % Output Argument
        %   res - cell array with the row names of the table
            tbl=obj.getValues(key);
            switch tbl.Type
                case cType.SummaryId.STATES
                    res=obj.dm.StateNames;
                case cType.SummaryId.RESOURCES
                    res=obj.dm.SampleNames;
            end
        end
    
        function res=getDefaultFlowVariables(obj)
        % Get the output flows keys
        % Syntax:
        %   res = obj.getDefaultFlowVariables
        % Output Argument
        %   res - cell array with system output flows names
            ps=obj.dm.ProductiveStructure;
            id=ps.SystemOutput.flows;
            res=ps.FlowKeys(id);
        end
    
        function res=getDefaultProcessVariables(obj)
        % Get the output processes keys
        % Syntax:
        %   res = obj.getDefaultFlowVariables
        % Output Argument
        %   res - cell array with system output processes names
            ps=obj.dm.ProductiveStructure;
            id=ps.SystemOutput.processes;
            res=ps.ProcessKeys(id);
        end

        function res=isStateSummary(obj)
        % Check if States Summary results are available
        % Syntax:
        %   res = obj.isStateSummary
        % Output Argument
        %   res - true | false
            res=logical(bitget(obj.option,cType.STATES));
        end

        function res=isSampleSummary(obj)
        % Check if Samples Summary results are available
        % Syntax:
        %   res = obj.isStateSummary
        % Output Argument
        %   res - true | false
            res=logical(bitget(obj.option,cType.RESOURCES));
        end
            
    end
    
    methods(Access=private)
        function setValues(obj,id,jdx,val)
        % Set the table values
        % Input Arguments:
        %   id - Name/Key of the summary table
        %   jdx - Column (State/sample) to update
        %   val - Vector with the cost values to updat
            tmp=getValues(obj.ds,id);
            setValues(tmp,jdx,val);
        end
            
        function res=getTableSize(obj,tp)
        % Get the table size.
        % Input Argument
        %   tp - Table properties
            if tp.table==cType.STATES
                NC=obj.dm.NrOfStates;
            else
                NC=obj.dm.NrOfSamples;
            end
            switch tp.node
                case cType.NodeType.FLOW
                    NR=obj.dm.NrOfFlows;
                case cType.NodeType.PROCESS
                    NR=obj.dm.NrOfProcesses;
                case cType.NodeType.ENV
                    NR=obj.dm.NrOfProcesses+1;
            end
            res=[NR,NC];
        end

        function res=setDefaultSummaryGraph(obj)
        % Get default summary graph
            if bitget(obj.option,cType.STATES)
                res=cType.Tables.SUMMARY_FLOW_UNIT_COST;
            else
                res=cType.Tables.RSUMMARY_FLOW_GENERAL_UNIT_COST;
            end
        end
        
        function setStateTables(obj,model)
        % Fill State Tables
        % Input Argument:
        %   model - cThermoeconomicModel
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
                    rsc=getResourceCost(rd,rstate);
                    % SUMMARY PROCESS COST
                    id=cType.Tables.SUMMARY_PROCESS_GENERAL_COST;
                    cost=rstate.getProcessCost(rsc);
                    obj.setValues(id,j,cost.CP');
                    % SUMMARY PROCESS UNIT COST
                    id=cType.Tables.SUMMARY_PROCESS_GENERAL_UNIT_COST;
                    ucost=rstate.getProcessUnitCost(rsc);
                    obj.setValues(id,j,ucost.cP');
                    % SUMMARY FLOW COST
                    fcost=rstate.getFlowsCost(rsc);
                    id=cType.Tables.SUMMARY_FLOW_GENERAL_COST;
                    obj.setValues(id,j,fcost.C');
                    id=cType.Tables.SUMMARY_FLOW_GENERAL_UNIT_COST;
                    obj.setValues(id,j,fcost.c');
                end
            end
        end

        function setResourceTables(obj,model)
        % Fill Resource Tables
        % Input Argument
        %   model - cThermoeconomicModel
            rstate=model.getResultState;
            for j=1:model.DataModel.NrOfSamples
                rd=obj.dm.getResourceData(j);
                rsc=getResourceCost(rd,rstate);
                % SUMMARY PROCESS COST
                id=cType.Tables.RSUMMARY_PROCESS_GENERAL_COST;
                cost=rstate.getProcessCost(rsc);
                obj.setValues(id,j,cost.CP');
                % SUMMARY PROCESS UNIT COST
                id=cType.Tables.RSUMMARY_PROCESS_GENERAL_UNIT_COST;
                ucost=rstate.getProcessUnitCost(rsc);
                obj.setValues(id,j,ucost.cP');
                % SUMMARY FLOW COST
                fcost=rstate.getFlowsCost(rsc);
                id=cType.Tables.RSUMMARY_FLOW_GENERAL_COST;
                obj.setValues(id,j,fcost.C');
                id=cType.Tables.RSUMMARY_FLOW_GENERAL_UNIT_COST;
                obj.setValues(id,j,fcost.c');
            end
        end
    end
end