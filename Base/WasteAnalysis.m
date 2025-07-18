function res = WasteAnalysis(data,varargin)
%WasteAnalysis - Waste recycling analysis of a plant state.
%   Calculates waste allocation according to the criteria defined in the data model.
%   If the 'Recycling' option is active, it calculates tables with direct
%   and/or generalized costs depending on the waste recycling from 0 to 100%.
%
%   Syntax
%     res=WasteAnalysis(data,Name,Value)
%
%   Input Arguments
% 	  data - cDataModel object whose contains the thermoeconomic data model
%
%   Name-Value Arguments
%     State - Thermoeconomic state. If missing first sample is taken
%       array char | string
%     Recycling: Waste Recycling analysis 
%       false | true (default)
%     ActiveWaste: Waste Flow key to analyze. If missing first sample is taken
%       array char | string
%     CostTables - Indicate which cost tables are calculated
%       'DIRECT' calculates direct exergy cost tables
%       'GENERALIZED' calculates generalized exergy cost tables
%       'ALL' calculate both kind of tables
%     ResourceSample - Select a sample in ResourcesCost table. If missing first sample is taken
%       char array | string
%     Show - Show the results in the console
%       true | false (default)
%     SaveAs - Name of the file where the results will be saved. 
%       char array | string
%
%   Output Arguments
%     res - cResultInfo object contains the results of thermoeconomic Analysis
%     The following tables are obtained:
%      wd - waste definition table
%      wa - waste allocation table
%      rad - recycling analysis direct cost
%      rag - recycling analysis generalized cost
%
%   Example
%     <a href="matlab:open RecyclingAnalysisDemo.mlx">Recycling Analysis Demo</a>
%
%   See also cDataModel, cWasteAnalysis, cResultInfo
%
    res=cMessageLogger();
    if nargin<1 || ~isObject(data,'cDataModel')
		res.printError(cMessages.DataModelRequired);
        res.printError(cMessages.ShowHelp);
		return
    end
    if ~data.isWaste
	    res.printError(cMessages.NoWasteModel)
        return
    end
    % Check and initialize parameters
    p = inputParser;
    p.addParameter('State',data.StateNames{1},@data.existState);
    p.addParameter('ResourceSample',cType.EMPTY_CHAR,@ischar);
	p.addParameter('CostTables',cType.DEFAULT_COST_TABLES,@cType.checkCostTables);
    p.addParameter('Recycling',true,@islogical);
    p.addParameter('ActiveWaste',cType.EMPTY_CHAR,@ischar);
    p.addParameter('Show',false,@islogical);
    p.addParameter('SaveAs',cType.EMPTY_CHAR,@isFilename);
    try
        p.parse(varargin{:});
    catch err
        res.printError(err.message);
        res.printError(cMessages.ShowHelp)
        return
    end
    % 
    param=p.Results;
    % Read waste info
    wd=data.WasteData;
    if ~wd.status
        wd.printLogger;
        res.printError(cMessages.InvalidObject,class(wd));
        return
    end
    % Check Waste Key
    if isempty(param.ActiveWaste)
        param.ActiveWaste=data.WasteFlows{1};
    end
    wid=wd.getWasteIndex(param.ActiveWaste);
    if ~wid
        res.printError(cMessages.InvalidWasteFlow,param.ActiveWaste);
        return
    end
    % Read exergy values
	ex=data.getExergyData(param.State);
	if ~ex.status
        ex.printLogger;
        res.printError(cMessages.InvalidExergyData,param.State);
        return
	end
	% Compute the Model FPR
    fpm=cExergyCost(ex,wd);
    if ~fpm.status
        fpm.printLogger;
        res.printError(cMessages.InvalidObject,class(fpm));
    end
    % Read external resources and get results
	pct=cType.getCostTables(param.CostTables);
	param.DirectCost=bitget(pct,cType.DIRECT);
	param.GeneralCost=bitget(pct,cType.GENERALIZED);
    if param.Recycling   
        if data.isResourceCost && param.GeneralCost
            if isempty(param.ResourceSample)
			    param.ResourceSample=data.SampleNames{1};
            end
		    rsd=data.getResourceData(param.ResourceSample);
            if ~rsd.status
			    rsd.printLogger;
			    res.printError(cMessages.InvalidResourceCost);
			    return
            end
            ra=cWasteAnalysis(fpm,true,param.ActiveWaste,rsd);
        else
            ra=cWasteAnalysis(fpm,true,param.ActiveWaste); 
        end
    else
        ra=cWasteAnalysis(fpm,false,param.ActiveWaste); 
    end
    % Execute recycling analysis
    if ra.status
        res=ra.buildResultInfo(data.FormatData,param);
    else
        ra.printLogger;
        res.printError(cMessages.InvalidWasteAnalysis);
    end
    if ~res.status
		res.printLogger;
        res.printError(cMessages.InvalidObject,class(res));
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
