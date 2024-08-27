function res = SummaryResults(data,varargin)
%SummaryResults - Gets the summary cost results for a plant.
%   This function retrieves the summary tables comparing the efficiency
%   and cost results for each state defined in the exergy data model.
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
%       Exergy of the states (exergy)
%       Unit consumption of the processes (pku)
%       Direct Cost of the processes (dpc)
%       Direct unit cost of the processes (dpuc)
%       Direct flows cost (dfc)
%       Direct unit flow costs (dfuc)
%     If Resource Cost is defined:
%       Generalized Processes cost (gpc)
%       Generalized unit cost of processes (gpuc)
%       Generalized cost of flows (gfc)
%       Generalized unit cost of flows (gfuc)
%
%   Example
%     <a href="matlab:open SummaryResultsDemo.mlx">Summary Results Demo</a>
%
%   See also cDataModel, cModelSummary, cResultInfo
%
    res=cMessageLogger();
    checkModel=@(x) isa(x,'cDataModel');
    %Check and initialize parameters
    p = inputParser;
    p.addRequired('data',checkModel);
    p.addParameter('ResourceSample','',@ischar);
    p.addParameter('Show',false,@islogical);
    p.addParameter('SaveAs','',@isFilename);
    try
        p.parse(data,varargin{:});
    catch err
        res.printError(err.message);
        res.printError('Usage: SummaryResults(data,options)')
        return
    end
    param=p.Results;
    if data.NrOfStates>1
        if data.isResourceCost
            if isempty(param.ResourceSample)
                param.ResourceSample=data.SampleNames{1};
            elseif ~data.existSample(param.ResourceSample)
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