function res = SummaryResults(data,varargin)
%SummaryResults - Get the summary cost results of a plant
%   This funtion obtains the summary tables comparing the effciency and
%   cost results for each state defined in the exergy data model.
%
%   Syntax
%     res=SummaryResults(data,Name,Value)
%
%   Input Arguments
%     data - cReadModel object containing the data model
%
%   Name-Value Arguments
%     ResourceSample - Select a sample in ResourcesCost table. If missing first sample is taken
%       char array
%     Show -  Show results on console
%       true | false (default)
%     SaveAs - Name of the file to save the results
%       char array | string
%
%   Output Arguments
%     res - cResultInfo object with the summary results
%     It contains the following tables:
%       cType.SummaryTables.EXERGY (exergy)
%       cType.SummaryTables.UNITCONSUMPTION (pku)
%       cType.SummaryTables.PROCESS_COST (dpc)
%       cType.SummaryTables.PROCESS_UNIT_COST (dpuc)
%       cType.SummaryTables.FLOW_COST (dfc)
%       cType.SummaryTables.FLOW_UNIT_COST (dfuc)
%     If Resource Cost is defined:
%       cType.SummaryTables.PROCESS_GENERAL_COST (gpc)
%       cType.SummaryTables.PROCESS_GENERAL_UNIT_COST (gpuc)
%       cType.SummaryTables.FLOW_GENERAL_COST (gfc)
%       cType.SummaryTables.FLOW_GENERAL_UNIT_COST (gfuc)
%
%   Example
%     <a href="matlab:open SummaryResultsDemo.mlx">Summary Results Demo</a>
%
%   See also cDataModel, cModelSummary, cResultInfo
%
    res=cStatus();
    checkModel=@(x) isa(x,'cDataModel');
    %Check and initialize parameters
    p = inputParser;
    p.addRequired('data',checkModel);
    p.addParameter('ResourceSample','',@ischar);
    p.addParameter('Show',false,@islogical);
    p.addParameter('SaveAs','',@ischar);
    try
        p.parse(data,varargin{:});
    catch err
        res.printError(err.message);
        res.printError('Usage: SummaryResults(data,param)')
        return
    end
    param=p.Results;
    if data.NrOfStates>1
        if data.isResourceCost
            if isempty(param.ResourceSample)
                param.ResourceSample=data.getResourceSample(1);
            elseif ~ismember(param.ResourceSample,data.ResourceSamples)
                res.printError('Invalid Resource Sample %s',param.ResourceSample);
            end
        end
        model=cThermoeconomicModel(data,'Summary',true,...
                'ResourceSample',param.ResourceSample);
        res=model.summaryResults;
    else
        res.printError('Summary Results requires more than one state');
    end
    if ~isValid(res)
		res.printLogger;
        res.printError('Invalid cResultInfo. See error log');
		return
    end
    % Show and Save results if required
    if param.Show
        printResults(res);
    end
    if ~isempty(param.SaveAs)
        SaveResults(res,param.SaveAs);
    end
end