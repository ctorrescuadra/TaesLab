classdef cSummaryResources < cResultId
    properties(GetAccess=public,SetAccess=private)
        ColNames     % Column Names
        NrOfTables   % Number of Tables
    end

    properties(Access=private)
        ps     % cProductiveStructure
        ds     % cDataset containing the table values
        M      % Number of Flows
        N      % Number of Processes
        NC     % Number of States/Colums
    end

    methods
        function obj = cSummaryResources(model)
            obj=obj@cResultId(cType.ResultId.SUMMARY_RESULTS);
            % Check Input Arguments
            if ~isObject(model,'cThermoeconomicModel')
                obj.addLogger(model);
                obj.messageLog(cType.ERROR,'Invalid thermoeconomic model');
                return
            end
            if ~model.isResourceCost
                obj.messageLog(cType.ERROR,'Resource Cost must be defined');
                return
            end
            obj.NC=length(model.SampleNames);
            obj.ColNames=model.SampleNames;
            if obj.NC<2
                obj.messageLog(cType.ERROR,'Summary requires more than one Resource Sample');
                return
            end
            % Get Property values
            obj.M=model.DataModel.NrOfFlows;
            obj.N=model.DataModel.NrOfProcesses;
            obj.ps=model.productiveStructure.Info;
            % Build Dataset
            fmt=model.DataModel.FormatData;
            list=fmt.getSummaryTables(9,model.isResourceCost);
            obj.ds=cDataset(list);
            for i=1:length(list)
                tbl=list{i};
                tp=fmt.getTableProperties(tbl);
                size=obj.getTableSize(tp.node);
                tmp=cSummaryTable(tp.key,tp.node,size);
                setValues(obj.ds,tbl,tmp);
            end
            rstate=model.getResultState;
            % Fill Summary States Dataset
            for j=1:obj.NC
                rsd=model.getResourceData(j);
                rsc=rsd.getResourceCost(rstate);
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
            % cResultId properties
            obj.DefaultGraph=cType.Tables.SUMMARY_FLOW_UNIT_COST;
            obj.ModelName=model.ModelName;
            obj.State='SUMMARY';
        end

        function res=get.NrOfTables(obj)
            res=0;
            if obj.status
                res=length(obj.ds);
            end
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
    end

    methods(Access=private)
        function setValues(obj,id,jdx,val)
        % Set the table values
            tmp=getValues(obj.ds,id);
            setValues(tmp,jdx,val);
        end
        
        function res=getTableSize(obj,node)
        % Get the table size.
            res=[];
            switch node
                case cType.NodeType.FLOW
                    res=[obj.M,obj.NC];
                case cType.NodeType.PROCESS
                    res=[obj.N,obj.NC];
                case cType.NodeType.ENV
                    res=[obj.N+1,obj.NC];
            end
        end
    end
end