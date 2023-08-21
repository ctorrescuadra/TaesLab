function res=ThermoeconomicAnalysis(data,varargin)
% Get the termoeconomic analysis of a plant state.
% It calculates the exergy cost, Fuel-Product and Irreversibility-Cost tables
%   USAGE:
%       res=ThermoeconomicAnalysis(data, options)
%   INPUT:
% 	    data - cReadModel object whose contains the thermoeconomic data model
%       options - an structure contains additional parameters:   
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
    res=cStatusLogger();
    % Check input parameters
	checkModel=@(x) isa(x,'cDataModel');
    % Check input parameters
    p = inputParser;
    p.addRequired('data',checkModel);
	p.addParameter('State','',@ischar);
	p.addParameter('ResourceSample','',@ischar);
	p.addParameter('CostTables',cType.DEFAULT_COST_TABLES,@cType.checkCostTables);
    try
		p.parse(data,varargin{:});
    catch err
        res.printError(err.message);
        res.printError('Usage: ThermoeconomicAnalysis(data,param)');
        return
    end
    param=p.Results;
    % Read productive structure
    if ~data.isValid
		data.printLogger;
        res.printError('Invalid Productive Structure. See error log');
        return
    end
    % Check CostTable parameter
    if ~data.checkCostTables(param.CostTables)
        res.printError('Invalid CostTable parameter %s',param.CostTables);
        return
    end
    % Read print formatted configuration
    fmt=data.FormatData;
    % Read exergy
    if isempty(param.State)
		param.State=data.getStateName(1);
    end
	ex=data.getExergyData(param.State);
	if ~isValid(ex)
        ex.printLogger;
		res.printError('Invalid Exergy Values. See error log');
        return
	end
    % Read Waste and compute Model FP
    if(data.NrOfWastes>0)
		wt=data.WasteData;
        fpm=cModelFPR(ex,wt); 
    else
        fpm=cModelFPR(ex);
    end
    if ~fpm.isValid
        fpm.printLogger;
		res.printError('Invalid thermoeconomic analysis. See error log')
        return
    end
    % Read external resources and get results
	pct=cType.getCostTables(param.CostTables);
	param.DirectCost=bitget(pct,cType.DIRECT);
	param.GeneralCost=bitget(pct,cType.GENERALIZED);
    if data.isResourceCost && param.GeneralCost
        if isempty(param.ResourceSample)
			param.ResourceSample=data.getResourceSample(1);
        end
		rd=data.getResourceData(param.ResourceSample);
		rsc=getResourceCost(rd,fpm);
        if ~rsc.isValid
			rsc.printLogger;
			res.printError('Invalid resources cost values. See Error Log');
			return
        end
        param.ResourcesCost=rsc;
    end
    res=getThermoeconomicAnalysisResults(fmt,fpm,param);
    res.setProperties(data.ModelName,param.State);
end