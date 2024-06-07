function res = SummaryResults(data,varargin)
% SummaryResults get the summary cost results of a plant
%  USAGE:
%   res=SummaryResults(data)
%  INPUT:
%   data - cReadModel object containing the data model
%   options - Structure contains additional parameters (optional)
%    Show -  Show results on console (true/false)
%    SaveAs - Save results in an external file
%   OUTPUT:
%    res - cResultInfo object with the summary results
%    It contains the following tables:
%       cType.SummaryTables.EXERGY (exergy)
%       cType.SummaryTables.UNITCONSUMPTION (pku)
%       cType.SummaryTables.PROCESS_COST (dpc)
%       cType.SummaryTables.PROCESS_UNIT_COST (dpuc)
%       cType.SummaryTables.FLOW_COST (dfc)
%       cType.SummaryTables.FLOW_UNIT_COST (dfuc)
%    If Resource Cost is defined:
%       cType.SummaryTables.PROCESS_GENERAL_COST (gpc)
%       cType.SummaryTables.PROCESS_GENERAL_UNIT_COST (gpuc)
%       cType.SummaryTables.FLOW_GENERAL_COST (gfc)
%       cType.SummaryTables.FLOW_GENERAL_UNIT_COST (gfuc)
%
%   See also cDataModel, cModelSummary, cResultInfo
%
    res=cStatusLogger();
    checkModel=@(x) isa(x,'cDataModel');
    %Check and initialize parameters
    p = inputParser;
    p.addRequired('data',checkModel);
    p.addParameter('Show',false,@islogical);
    p.addParameter('SaveAs','',@ischar);
    try
        p.parse(data,varargin{:});
    catch err
        res.printError(err.message);
        res.printError('Usage: cRecyclingAnalysis(data,param)')
        return
    end
    param=p.Results;
    if data.NrOfStates>1
        model=cThermoeconomicModel(data,'Summary',true);
        res=model.summaryResults;
    else
        res.printWarning('Summary Results requires more than one state');
    end
    % Show and Save results if required
    if param.Show
        printResults(res);
    end
    if ~isempty(param.SaveAs)
        SaveResults(res,param.SaveAs);
    end
end