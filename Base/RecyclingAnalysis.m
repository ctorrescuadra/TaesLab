function sol = RecyclingAnalysis(model,varargin)
% RecyclingAnalysis provide a recycling analysis of the plant
%   Given a waste flow calculates the cost of output flows (final products
%   and wastes) when it is recycled from 0 to %100.
%   INPUT:
%       model - cReadModel object
%       varargin 
%           State: Operation state
%           WasteFlow: WasteFlow key to recycle
%   OUTPUT:
%       res - cResultInfo object with the recicling table and
%           cRecyclingAnalysis info.
% See also cReadModel, cRecyclingAnalysis, cResultInfo
%
    sol=cStatusLogger();
    checkModel=@(x) isa(x,'cReadModel');
    %Check and initialize parameters
    p = inputParser;
    p.addRequired('model',checkModel);
    p.addParameter('State','',@ischar);
    p.addParameter('ResourceSample','',@ischar);
	p.addParameter('CostTables',cType.DEFAULT_COST_TABLES,@cType.checkCostTables);
    p.addParameter('WasteFlow','',@ischar);
    try
        p.parse(model,varargin{:});
    catch err
        sol.printError(err.message);
        sol.printError('Usage: cRecyclingAnalysis(model,param)')
        return
    end
    % 
    param=p.Results;
    % Check Productive Structure
    if ~model.isValid
	    model.printLogger;
	    sol.printError('Invalid Thermoeconomic Model');
	    return
    end
    % Read format definition
    fmt=model.readFormat;
	if fmt.isError
		fmt.printLogger;
		fmt.printError('Format Definition is NOT correct. See error log');
		return
	end
    % Read waste info
    if model.NrOfWastes<1
	    sol.printError(cType.ERROR,'Model must have waste')
        return
    end
    wt=model.readWaste;
    if ~wt.isValid
        wt.printLogger;
        sol.printError('Invalid waste model');
        return
    end
    % Check Waste Key
    if isempty(param.WasteFlow)
        wid=wt.Flows(1);
        param.WasteFlow=model.ProductiveStructure.Flows(wid).key;
    else
        wid=wt.getWasteIndex(param.WasteFlow);
        if isempty(wid)
            sol.printError('Invalid waste key %s',param.WasteFlow);
            return
        end
    end
    % Read exergy values
    if isempty(param.State)
        param.State=model.getStateName(1);
    end
	rex=model.readExergy(param.State);
	if ~rex.isValid
        rex.printLogger;
        sol.printError('Invalid Exergy Values. See error log');
        return
	end
	% Compute thermoeconomic model using the selected algorithm
    mfp=cModelFPR(rex);
    if ~isValid(mfp)
        mfp.printLogger;
        mfp.printError('Invalid Model FPR. See error log');
    end
    % Read external resources and get results
	pct=cType.getCostTables(param.CostTables);
	param.DirectCost=bitget(pct,cType.DIRECT);
	param.GeneralCost=bitget(pct,cType.GENERALIZED);
    if model.isResourceCost && param.GeneralCost
		rsc=model.readResources(param.ResourceSample);
        rsc.setResources(mfp);
        if ~rsc.isValid
			rsc.printLogger;
			rsc.printError('Invalid resources cost values. See Error Log');
			return
        end
        ra=cRecyclingAnalysis(mfp,wt,rsc);
    else
        ra=cRecyclingAnalysis(mfp,wt);
    end
    % Execute recycling analysis
    if isValid(ra)
        ra.doAnalysis(param.WasteFlow)
        sol=getRecyclingAnalysisResults(fmt,ra,param);
        sol.setProperties(model.ModelName,param.State);
    end
end
