classdef cModelSummary < cResultId
%   cModelSummary obtain the summary cost tables
    properties(GetAccess=public,SetAccess=private)
        NrOfStates      % Number of States
        StateNames      % States Names
        ExergyData      % Exergy Data
        UnitConsumption % Process Unit Consumption Values
        Irreversibility % Process Irreversibility Values
        CostValues      % Cost Values cell array
    end
    properties(Access=private)
        ps
    end
    methods
        function obj=cModelSummary(model)
        % Create an instance of cRecyclingAnalysis
        %   Input:
        %       model - cThermoeconomicModel object  
        %
            obj=obj@cResultId(cType.ResultId.SUMMARY_RESULTS);
            if ~isa(model,'cThermoeconomicModel') || ~model.isValid
                obj.addLogger(model);
                obj.messageLog(cType.ERROR,'Invalid Thermoeconomic Model');
                return
            end
            if model.DataModel.NrOfStates<2
                  obj.messageLog(cType.ERROR,'Summary Requires more than one State');
                  return
            end
            NrOfFlows=model.DataModel.NrOfFlows;
            NrOfProcesses=model.DataModel.NrOfProcesses;
            obj.NrOfStates=model.DataModel.NrOfStates;
            if model.isResourceCost
                NrOfTables=cType.GENERAL_SUMMARY_TABLES;
            else
                NrOfTables=cType.DIRECT_SUMMARY_TABLES;
            end
            values=cell(1,NrOfTables);
            for i=1:NrOfTables
                if bitget(i-1,2)
                    NrOfRows=NrOfFlows;
                else
                    NrOfRows=NrOfProcesses;
                end
                values{i}=zeros(NrOfRows,obj.NrOfStates);
            end
            rstates=model.getResultStates;
            pku=zeros(NrOfProcesses+1,obj.NrOfStates);
            pI=zeros(NrOfProcesses+1,obj.NrOfStates);
            rex=zeros(NrOfFlows,obj.NrOfStates);
            for j=1:obj.NrOfStates
                cost=rstates{j}.getDirectProcessCost;
                obj.setValues(cType.SummaryId.PROCESS_DIRECT_COST,j,cost.CP');
                ucost=rstates{j}.getDirectProcessUnitCost;
                obj.setValues(cType.SummaryId.PROCESS_DIRECT_UNIT_COST,j,ucost.cP');
                fcost=rstates{j}.getDirectFlowsCost(ucost);
                obj.setValues(cType.SummaryId.FLOW_DIRECT_COST,j,fcost.C');
                obj.setValues(cType.SummaryId.FLOW_DIRECT_UNIT_COST,j,fcost.c');
                if model.isResourceCost
                    rsc=getResourceCost(model.ResourceData,rstates{j});
                    cost=rstates{j}.getGeneralProcessCost(rsc);
                    obj.setValues(cType.SummaryId.PROCESS_GENERALIZED_COST,j,cost.CP');
                    ucost=rstates{j}.getGeneralProcessUnitCost(rsc);
                    obj.setValues(cType.SummaryId.PROCESS_GENERALIZED_UNIT_COST,j,ucost.cP');
                    fcost=rstates{j}.getGeneralFlowsCost(ucost,rsc);
                    obj.setValues(cType.SummaryId.FLOW_GENERALIZED_COST,j,fcost.C');
                    obj.setValues(cType.SummaryId.FLOW_GENERALIZED_UNIT_COST,j,fcost.c');
                end
                pku(:,j)=rstates{j}.ProcessesExergy.vK';
                pI(:,j)=rstates{j}.ProcessesExergy.vI';
                rex(:,j)=rstates{j}.FlowsExergy';
            end
            obj.status=true;
            obj.ExergyData=rex;
            obj.UnitConsumption=pku;
            obj.Irreversibility=pI;
            obj.StateNames=model.StateNames;
            obj.ps=model.productiveStructure.Info;
        end

        function res=getDefaultFlowVariables(obj)
        % get the output flows keys
            id=obj.ps.SystemOutput.flows;
            res={obj.ps.Flows(id).key};
        end

        function res=getDefaultProcessVariables(obj)
        % get the output flows keys
            id=obj.ps.SystemOutput.processes;
            res={obj.ps.Processes(id).key};
        end
    end

    methods(Access=private)
        function setValues(obj,TableId,StateId,val)
        % Set the cost values
            obj.CostValues{TableId}(:,StateId)=val;
        end
    end
end
