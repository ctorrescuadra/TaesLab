function res = SummaryResults(data,varargin)
%SummaryResults - Get the summary results for a plant.
%   This function retrieves the summary tables to compare different states or samples of the model
%   There are two types of Summary Result Tables:
%     - STATES: Comparing cost values for the different states
%     - RESOURCES: Comparing cost values for the different resource samples
%
%   Syntax
%     res=SummaryResults(data,Name,Value)
%
%   Input Arguments
%     data - cReadModel object containing the data model
%
%   Name-Value Arguments
%     Summary - Type of Summary to obtain
%       'NONE' No summary results are obtained
%       'STATES' State summary is obtained
%       'RESOURCES' Resources summary is obtained
%       'ALL' Both summary reports are obtained 
%     States - Select a state in the States table. If missing first state is taken
%     ResourceSample - Select a sample in ResourcesCost table. If missing first sample is taken
%       char array
%     Show -  Show results on console
%       true | false (default)
%     SaveAs - Name of the file to save the results
%       char array | string
%
%   Output Arguments
%     res - cResultInfo object with the summary results
%      It contains the following tables for STATES
%       Exergy of the states (exergy)
%       Unit consumption of the processes (pku)
%       Direct Cost of the processes (dpc)
%       Direct unit cost of the processes (dpuc)
%       Direct flows cost (dfc)
%       Direct unit flow costs (dfuc)
%      If Resource Cost is defined:
%       Generalized Processes cost (gpc)
%       Generalized unit cost of processes (gpuc)
%       Generalized cost of flows (gfc)
%       Generalized unit cost of flows (gfuc)
%      For RESOURCES
%       Generalized Processes cost (rgpc)
%       Generalized unit cost of processes (rgpuc)
%       Generalized cost of flows (rgfc)
%       Generalized unit cost of flows (rgfuc)
%   Example
%     <a href="matlab:open SummaryResultsDemo.mlx">Summary Results Demo</a>
%
%   See also cDataModel, cSummaryResults, cResultInfo
%
    res=cMessageLogger();
    % Check data model
	if nargin <1 || ~isObject(data,'cDataModel')
		res.printError(cMessages.DataModelRequired);
        res.printError(cMessages.ShowHelp);
		return
	end
    sopt=data.SummaryOptions;
    if sopt.isEnable
        doption=sopt.defaultOption;
    else
        res.printError(cMessages.SummaryNotAvailable);
        return
    end
    %Check and initialize parameters
    p = inputParser;
    p.addParameter('State',data.StateNames{1},@data.existState);
    p.addParameter('ResourceSample',cType.EMPTY_CHAR,@ischar);
    p.addParameter('Summary',doption,@sopt.checkName);
    p.addParameter('Show',false,@islogical);
    p.addParameter('SaveAs',cType.EMPTY_CHAR,@isFilename);
    try
        p.parse(varargin{:});
    catch err
        res.printError(err.message);
        res.printError(cMessages.ShowHelp);
        return
    end
    % Preparing parameters
    param=p.Results;
    if ~cType.getSummaryId(param.Summary)
        res.printError(cMessages.SummaryNotAvailable);
        return
    end
    if data.isResourceCost
        if isempty(param.ResourceSample)
            param.ResourceSample=data.SampleNames{1};
        elseif ~data.existSample(param.ResourceSample)
            res.printError(cMessages.InvalidResourceName,param.ResourceSample);
        end
    end
    % Get the summary results from the thermoeconomic model
    model=cThermoeconomicModel(data,...
            'ResourceSample',param.ResourceSample,...
            'State',param.State,...
            'Summary',param.Summary);
    res=model.summaryResults;
    if isempty(res)
        model.printError(cMessages.SummaryNotAvailable);
    end
    % Show and Save results if required
    if param.Show
        printResults(res);
    end
    if ~isempty(param.SaveAs)
        SaveResults(res,param.SaveAs);
    end
end