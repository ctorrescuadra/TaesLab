function sol=ThermoeconomicAnalysis(model,varargin)
% ThermoeconomicAnalysis - provides a termoeconomic analysis of a thermoeconomic state of the plant.
% It calculates the exergy cost, Fuel-Product Irreversibility-Cost tables
%   INPUT:
% 	    model - cReadModel object whose contains the thermoeconomic data model
%       varargin - an optional structure contains additional parameters:   
%   	    State - Thermoeconomic state id. If missing first sample is taken   
%           CostTables - Indicate which cost tables are calculated
%               DIRECT:  calculates direct exergy cost tables
%               GENERALIZED: calculates generalized exergy cost tables
%               ALL: calculate both kind of tables
%           ResourceSample - Select a sample in ResourcesCost table.  
%            If missing first sample is taken
% OUTPUT:
%   res - cModelResults object contains the results of thermoeconomic Analysis
%      If DirectCost is selected (default) the follwing tables are obtained:
%       dfcost: Direct Exergy Cost of flows
%       dcost: Direct Exergy cost of processes
%       udcost: Unit Direct Exergy Cost of processes table
%       ict: Irreversibility Cost Table 
%       fict: Flows Irreversibility Cost Table
%       dcfp: Fuel-Product direct cost table
%       dcfpr: Fuel-Product direct cost table (includes waste)
%      If GeneralCost is selected:
%       gcost: Generalized cost of processes 
%       ugcost: Unit Generalized Cost of processes
%       gfcost: Generalized Cost of flows
%       gcfp: Fuel-Product generalized cost table
%       gict: Irreversibility generalized cost table 
%       gfict: Flows Irreversibility generalized cost table 
% See also cModelFPR, cReadModel, cResultInfo
%
    sol=cStatusLogger();
    % Check input parameters
	checkModel=@(x) isa(x,'cReadModel');
    % Check input parameters
    p = inputParser;
    p.addRequired('model',checkModel);
	p.addParameter('State','',@ischar);
	p.addParameter('ResourceSample','',@ischar);
	p.addParameter('CostTables',cType.DEFAULT_COST_TABLES,@cType.checkCostTables);
    try
		p.parse(model,varargin{:});
    catch err
        sol.printError(err.message);
        sol.printError('Usage: ThermoeconomicAnalysis(model,param)');
        return
    end
    param=p.Results;
    % Read productive structure
    if ~model.isValid
		model.printLogger;
        model.printError('Invalid Productive Structure. See error log');
        return
    end
    % Check CostTable parameter
    if ~model.checkCostTables(param.CostTables)
        sol.messageLog(cType.ERROR,'Invalid CostTable parameter %s',param.CostTables);
        sol.printLogger;
        return
    end
    % Read print formatted configuration
    fmt=model.readFormat;
	if fmt.isError
		fmt.printLogger;
		fmt.printError('Format Definition is NOT correct. See error log');
		return
	end	
    % Read exergy
    if isempty(param.State)
		param.State=model.getStateName(1);
    end
	rex=model.readExergy(param.State);
    if ~rex.isValid
		rex.printLogger;
        rex.printError('Invalid exergy values. See error log');
        return
    end
    % Read Waste and compute Model FP
    if(model.NrOfWastes>0)
		wt=model.readWaste;
		if wt.isValid
            fpm=cModelFPR(rex,wt);
        else
			wt.printLogger;
			wt.printError('Invalid waste definition data. See error log');
			return
		end     
    else
        fpm=cModelFPR(rex);
    end
    if ~fpm.isValid
        fpm.printLogger;
		fpm.printError('Invalid thermoeconomic analysis. See error log')
        return
    end
    % Read external resources and get results
	pct=cType.getCostTables(param.CostTables);
	param.DirectCost=bitget(pct,cType.DIRECT);
	param.GeneralCost=bitget(pct,cType.GENERALIZED);
    if model.isResourceCost && param.GeneralCost
		rsc=model.readResources(param.ResourceSample);
        rsc.setResources(fpm);
        if ~rsc.isValid
			rsc.printLogger;
			rsc.printError('Invalid resources cost values. See Error Log');
			return
        end
        param.ResourcesCost=rsc;
    end
    sol=getThermoeconomicAnalysisResults(fmt,fpm,param);
    sol.setProperties(model.ModelName,param.State);
end