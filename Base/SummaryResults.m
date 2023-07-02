function res = SummaryResults(data)
% Get the summary cost results of a plant
%   USAGE:
%       res=SummaryResults(data)
%   INPUT:
%       data - cReadModel object containing the data model 
%   OUTPUT:
%       res - cResultInfo object with the summary results
%          It contains the following tables:
%           cType.SummaryTables.EXERGY (exergy)
%           cType.SummaryTables.UNITCONSUMPTION (pku)
%           cType.SummaryTables.PROCESS_COST (dpc)
%           cType.SummaryTables.PROCESS_UNIT_COST (dpuc)
%           cType.SummaryTables.FLOW_COST (dfc)
%           cType.SummaryTables.FLOW_UNIT_COST (dfuc)
%          If Resource Cost is defined:
%           cType.SummaryTables.PROCESS_GENERAL_COST (gpc)
%           cType.SummaryTables.PROCESS_GENERAL_UNIT_COST (gpuc)
%           cType.SummaryTables.FLOW_GENERAL_COST (gfc)
%           cType.SummaryTables.FLOW_GENERAL_UNIT_COST (gfuc)
%   See also cReadModel, cModelSummary, cResultInfo
%
    res=cStatusLogger(cType.ERROR);
    if ~isa(data,'cReadModel') || ~isValid(data)
        res.printError('Invalid data. It should be a cReadModel object');
        return
    end
    if data.NrOfStates>1
        model=cThermoeconomicModel(data,'Summary',true);
        res=model.summaryResults;
    else
        res.printWarning('Summary Results requires more than one State');
    end
end