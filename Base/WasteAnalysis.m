function res = WasteAnalysis(data,varargin)
% Provide a recycling analysis of the plant
% Given a waste flow calculates the cost of output flows (final products and wastes)
% when it is recycled from 0 to %100.
%   USAGE: 
%       res = RecyclingAnalysis(data, options)
%   INPUT:
%       data - cReadModel object
%       options - A structure containing optional parameters 
%           State: Operation state
%           WasteFlow: WasteFlow key to analyze
%           Recycling: Waste Recycling analysis
%           CostTables: Select the recycling tables to obtain
%               DIRECT - Only Direct cost are selected (default)
%               GENERALIZED - Only Generalized costs are selected
%               ALL - Both Direct and Generalized are selected
%           ResourceSample: Resource sample name
%           Show -  Show results on console (true/false)
%           SaveAs - Save results in an external file
%
%   OUTPUT:
%       res - cResultInfo object with the waste analysis tables:
%               cType.Tables.WASTE_DEFINITION (wd)
%               cType.Tables.WASTE_ALLOCATION (wa)
%               cType.Tables.WASTE_RECYCLING_DIRECT (rad)
%               cType.Tables.WASTE_RECYCLING_GENERAL (rag)
% See also cDataModel, cRecyclingAnalysis, cResultInfo
%
    res=cStatusLogger();
    checkModel=@(x) isa(x,'cDataModel');
    %Check and initialize parameters
    p = inputParser;
    p.addRequired('data',checkModel);
    p.addParameter('State','',@ischar);
    p.addParameter('ResourceSample','',@ischar);
	p.addParameter('CostTables',cType.DEFAULT_COST_TABLES,@cType.checkCostTables);
    p.addParameter('ActiveWaste','',@ischar);
    p.addParameter('Recycling',true,@islogical);
    p.addParameter('Show',false,@islogical);
    p.addParameter('SaveAs','',@ischar);
    try
        p.parse(data,varargin{:});
    catch err
        res.printError(err.message);
        res.printError('Usage: cRecyclingAnalysis(data,param)')
        return
    end
    % 
    param=p.Results;
    % Check data model
    if ~data.isValid
	    data.printLogger;
	    res.printError('Invalid data model. See error log');
	    return
    end
    
    % Read waste info
    if data.NrOfWastes<1
	    res.printError(cType.ERROR,'Data model must have waste')
        return
    end
    wd=data.WasteData;
    if ~wd.isValid
        wd.printLogger;
        res.printError('Invalid waste data');
        return
    end
    % Read exergy values
    if isempty(param.State)
        param.State=data.getStateName(1);
    end
	ex=data.getExergyData(param.State);
	if ~ex.isValid
        ex.printLogger;
        res.printError('Invalid exergy values. See error log');
        return
	end
	% Compute the Model FPR
    mfp=cExergyCost(ex,wd);
    if ~isValid(mfp)
        mfp.printLogger;
        res.printError('Invalid model FPR. See error log');
    end
    % Check Waste Key
    wt=mfp.WasteTable;
    if isempty(param.ActiveWaste)
        param.ActiveWaste=wt.WasteKeys{1};
    else
        wid=wt.getWasteIndex(param.ActiveWaste);
        if isempty(wid)
            res.printError('Invalid waste key %s',param.ActiveWaste);
            return
        end
    end
    % Read external resources and get results
	pct=cType.getCostTables(param.CostTables);
	param.DirectCost=bitget(pct,cType.DIRECT);
	param.GeneralCost=bitget(pct,cType.GENERALIZED);
    if param.Recycling   
        if data.isResourceCost && param.GeneralCost
            if isempty(param.ResourceSample)
			    param.ResourceSample=data.getResourceSample(1);
            end
		    rsd=data.getResourceData(param.ResourceSample);
            if ~rsd.isValid
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
    if isValid(ra)
        res=ra.getResultInfo(data.FormatData,param);
    else
        ra.printLogger;
        res.printError('Invalid Recycling Analysis. See Error Log');
    end
    % Show and Save results if required
    if param.Show
        printResults(res);
    end
    if ~isempty(param.SaveAs)
        SaveResults(res,param.SaveAs);
    end
end
