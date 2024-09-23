function res = WasteAnalysis(data,varargin)
%WasteAnalysis - Perform a waste analysis of a plant state.
%   It calculates the waste allocation for the criteria defined in the data model.
%   If the option 'Recycling' is active, it calculates the tables with the direct
%   and/or generalized costs as a function of the recycling of waste from 0 to 100 percent 
%
% Syntax
%   res=WasteAnalysis(data,Name,Value)
%
% Input Arguments
% 	data - cDataModel object whose contains the thermoeconomic data model
%
% Name-Value Arguments
%   State - Thermoeconomic state. If missing first sample is taken
%     array char | string
%   ActiveWaste: Waste Flow key to analyze. If missing first sample is taken
%     array char | string
%   Recycling: Waste Recycling analysis 
%     false | true (default)
%   CostTables - Indicate which cost tables are calculated
%     'DIRECT' calculates direct exergy cost tables
%     'GENERALIZED' calculates generalized exergy cost tables
%     'ALL' calculate both kind of tables
%   ResourceSample - Select a sample in ResourcesCost table. If missing first sample is taken
%     char array | string
%   Show - Show the results in the console
%     true | false (default)
%   SaveAs - Name of the file where the results will be saved. 
%     char array | string
%
% Output Arguments
%   res - cResultInfo object contains the results of thermoeconomic Analysis
%    The following tables are obtained:
%      wd - waste definition table
%      wa - waste allocation table
%      rad - recycling analysis direct cost
%      rag - recycling analysis generalized cost
%
% Example
%   <a href="matlab:open RecyclingAnalysisDemo.mlx">Recycling Analysis Demo</a>
%
% See also cDataModel, cWasteAnalysis, cResultInfo
%
    res=cMessageLogger();
	if nargin<1 || ~isObject(data,'cDataModel')
		res.printError('First argument must be a Data Model');
        res.printError('Usage: WasteAnalysis(data,options)');
		return
	end
    % Check and initialize parameters
    p = inputParser;
    p.addParameter('State',data.StateNames{1},@ischar);
    p.addParameter('ResourceSample',cType.EMPTY_CHAR,@ischar);
	p.addParameter('CostTables',cType.DEFAULT_COST_TABLES,@cType.checkCostTables);
    p.addParameter('ActiveWaste',cType.EMPTY_CHAR,@ischar);
    p.addParameter('Recycling',true,@islogical);
    p.addParameter('Show',false,@islogical);
    p.addParameter('SaveAs',cType.EMPTY_CHAR,@isFilename);
    try
        p.parse(varargin{:});
    catch err
        res.printError(err.message);
        res.printError('Usage: cRecyclingAnalysis(data,options)')
        return
    end
    % 
    param=p.Results;
    % Read waste info
    if data.NrOfWastes<1
	    res.printError(cType.ERROR,'Data model must have waste')
        return
    end
    wd=data.WasteData;
    if ~wd.status
        wd.printLogger;
        res.printError('Invalid waste data');
        return
    end
     % Check Waste Key
     if isempty(param.ActiveWaste)
         param.ActiveWaste=data.WasteFlows{1};
     end
     wid=wd.getWasteIndex(param.ActiveWaste);
     if isempty(wid)
         res.printError('Invalid waste key %s',param.ActiveWaste);
         return
     end

    % Read exergy values
	ex=data.getExergyData(param.State);
	if ~ex.status
        ex.printLogger;
        res.printError('Invalid exergy values. See error log');
        return
	end
	% Compute the Model FPR
    mfp=cExergyCost(ex,wd);
    if ~mfp.status
        mfp.printLogger;
        res.printError('Invalid model FPR. See error log');
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
			    res.printError('Invalid resource data. See Error Log');
			    return
            end
            ra=cWasteAnalysis(mfp,true,param.ActiveWaste,rsd);
        else
            ra=cWasteAnalysis(mfp,true,param.ActiveWaste); 
        end
    else
        ra=cWasteAnalysis(mfp,false,param.ActiveWaste); 
    end
    % Execute recycling analysis
    if ra.status
        res=ra.getResultInfo(data.FormatData,param);
    else
        ra.printLogger;
        res.printError('Invalid Recycling Analysis. See Error Log');
    end
    if ~res.status
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
