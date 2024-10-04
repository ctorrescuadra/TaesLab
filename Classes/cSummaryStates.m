classdef cSummaryStates < cResultId
    properties(GetAccess=public,SetAccess=private)
        TableNames % Names of the tables
        StateNames % State Names
    end

    properties(Access=private)
        ps             % cProductiveStructure
        ds             % cDataset containing the table values
        NrOfFlows      % Number of Flows
        NrOfProcesses  % Number of Processes
        NrOfStates     % Number of State
    end

    methods
        function obj = cSummaryStates(model)
            obj=obj@cResultId(cType.ResultId.SUMMARY_RESULTS);
            % Check Input Arguments
            if ~isObject(model,'cThermoeconomicModel')
                obj.addLogger(model);
                obj.messageLog(cType.ERROR,'Invalid thermoeconomic model');
                return
            end
            obj.NrOfStates=model.DataModel.NrOfStates;
            if obj.NrOfStates<2
                obj.messageLog(cType.ERROR,'Summary requires more than one State');
                return
            end
            % Get Property values
            obj.NrOfFlows=model.DataModel.NrOfFlows;
            obj.NrOfProcesses=model.DataModel.NrOfProcesses;
            obj.ps=model.productiveStructure.Info;
            % Build Dataset
            fmt=model.DataModel.FormatData;
            list=fmt.getSummaryTables(obj.ResultId,model.isResourceCost);
            obj.ds=cDataset(list);
            for i=1:length(list)
                tbl=list{i};
                tp=fmt.getTableProperties(tbl);
                size=obj.getTableSize(tp.node);
                tmp=cSummaryTable(tp.key,tp.node,size);
                setValues(obj.ds,tbl,tmp);
            end
            obj.TableNames=list;
            % Fill Summary States Dataset
            for j=1:obj.NrOfStates
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
                id=cType.Table.SUMMARY_PROCESS_COST;
                cost=rstate.getProcessCost;
                obj.setValues(id,j,cost.CP');
                % SUMMARY PROCESS UNIT COST
                id=cType.Table.SUMMARY_PROCESS_UNIT_COST;
                ucost=rstate.getProcessUnitCost;
                obj.setValues(id,j,ucost.cP');
                % SUMMARY FLOW COST
                fcost=rstate.getFlowsCost;
                id=cType.Table.SUMMARY_FLOW_COST;
                obj.setValues(id,j,fcost.C');
                id=cType.Table.SUMMARY_FLOW_UNIT_COST;
                obj.setValues(id,j,fcost.c');
                % General Cost
                if model.isResourceCost
                    rsc=getResourceCost(model.ResourceData,rstate);
                    % SUMMARY PROCESS COST
                    id=cType.Table.SUMMARY_PROCESS_GENERAL_COST;
                    cost=rstate.getProcessCost(rsc);
                    obj.setValues(id,j,cost.CP');
                    % SUMMARY PROCESS UNIT COST
                    id=cType.Table.SUMMARY_PROCESS_GENERAL_UNIT_COST;
                    ucost=rstate.getProcessUnitCost(rsc);
                    obj.setValues(id,j,ucost.cP');
                    % SUMMARY FLOW COST
                    fcost=rstate.getFlowsCost(rsc);
                    id=cType.Table.SUMMARY_FLOW_GENERAL_COST;
                    obj.setValues(id,j,fcost.C');
                    id=cType.Table.SUMMARY_FLOW_GENERAL_UNIT_COST;
                    obj.setValues(id,j,fcost.c');
                end
            end
            % cResultId properties
            obj.StateNames=model.StateNames;
            obj.DefaultGraph=cType.Tables.SUMMARY_FLOW_UNIT_COST;
            obj.ModelName=model.ModelName;
            obj.State='SUMMARY';
        end

        function res=getResultInfo(obj,fmt)
        % Get cResultInfo object
            res=fmt.getSummaryResults(obj);
        end

        function res=getValues(obj,id)
        % Get the tables
            res=getValues(obj.ds,id);
        end

        function res=getDefaultFlowVariables(obj)
        % Get the output flows keys
            id=obj.ps.SystemOutput.flows;
            res=obj.ps.FlowKeys(id);
        end

        function res=getDefaultProcessVariables(obj)
        % Get the output flows keys
            id=obj.ps.SystemOutput.processes;
            res=obj.ps.ProcessKeys(id);
        end

        function res=getRowNames(obj,node)
        % Valorar de ponerlo en cResultTable Builder
            res={};
            switch node
                case cType.Node.FLOWS
                    res=obj.ps.getFlowKeys;
                case cType.Node.PROCESSES
                    res=obj.processKeys(1:end-1);
                case cType.Node.ENV
                    res=obj.processKeys;
            end
        end
    end

    methods(Access=private)
        function setValues(obj,id,jdx,val)
        % Set the table values
            tmp=getValues(obj.ds,id);
            setValues(tmp,jdx,val);
        end
        
        function res=getTableSize(obj,node)
        % Get the table size. Revisar su necesidad
            res=[];
            switch node
                case cType.Node.FLOWS
                    res=[obj.NrOfFlows,obj.NrOfStates];
                case cType.Node.PROCESSES
                    res=[obj.NrOfProcesses,obj.NrOfStates];
                case cType.Node.ENV
                    res=[obj.NrOfProcesses+1,obj.NrOfStates];
            end
        end
    end
end