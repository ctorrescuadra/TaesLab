function res=ExergyCostCalculator(model,varargin)
% ExergyCostCalculator Calculates the exergy cost values of a thermoeconomic model
% 	INPUT:
%   	model - cReadModel object whose contains the thermoeconomic data model
%   	varargin - optional structure contains additional parameters: 
%   		State - Thermoeconomic state id. If missing first sample is taken   
%       	CostTables - Indicate which cost tables are calculated
%           	DIRECT:  calculates direct exergy cost tables
%           	GENERALIZED: calculates generalized exergy cost tables
%           	ALL: calculate both kind of tables
%       	ResourceSample - Select a sample in ResourcesCost table.  If missing first sample is taken
% 	OUTPUT:
%   	res - A cResultInfo object contains the results of Exergy Cost
%	   		The following tables are obtained if DirectCost is selected
%       		dfcost: Direct Exergy Cost of flows
%       		dcost: Direct Exergy cost of processes
%       		udcost: Unit Direct Exergy Cost of processes table
%       		ict: Irreversibility Cost Table 
%       		fict: Flows Irreversibility Cost Table
%      		If GeneralCost is selected:
%       		gcost: Generalized cost of processes 
%       		ugcost: Unit Generalized Cost of processes
%       		gfcost: Generalizaed Cost of flows
%       		gict: Irreversibility generalized cost table 
%       		gfict: Flows Irreversibility generalized cost table 
% See also  cReadModel, cExergyCost, cResultInfo
%
	res=cStatusLogger();
	checkModel=@(x) isa(x,'cReadModel');
    %Check input parameters
    p = inputParser;
    p.addRequired('model',checkModel);
	p.addParameter('State','',@ischar);
	p.addParameter('ResourceSample','',@ischar);
	p.addParameter('CostTables',cType.DEFAULT_COST_TABLES,@cType.checkCostTables);
    try
		p.parse(model,varargin{:});
    catch err
		res.printError(err.message);
        res.printError('Usage: ExergyCostCalculator(model,param)');
        return
    end
    param=p.Results;
    % Check productive structure
    if ~model.isValid
		model.printLogger;
		res.printError('Invalid Productive Structure. See error log');
		return
    end
    % Check CostTable parameter
    if ~model.checkCostTables(param.CostTables)
		model.printLogger;
        res.printError('Invalid CostTable parameter %s',param.CostTables);
        return
    end
    % Read print formatted configuration
	fmt=model.readFormat;
	if fmt.isError
		fmt.printLogger;
		res.printError('Format Definition is NOT correct. See error log');
		return
	end		
    % Read exergy
	if isempty(param.State)
		param.State=model.getStateName(1);
	end
	ex=model.readExergy(param.State);
	if ~ex.isValid
		ex.printLogger;
		res.printError('Invalid Exergy Values. See error log');
		return
	end	
	% Read Waste definition and compute waste operator
    if(model.NrOfWastes>0)
		wt=model.readWaste;
        if ~wt.isValid
			wt.printLogger;
			res.printError('Invalid waste definition data. See error log');
			return
        end
	    ect=cExergyCost(ex,wt);
    else
        ect=cExergyCost(ex);
    end
    if ~ect.isValid
		ect.printLogger;
		res.printError('Invalid Exergy Cost Computation. See error log')
		return
    end
    % Read external resources and get results
	pct=cType.getCostTables(param.CostTables);
	param.DirectCost=bitget(pct,cType.DIRECT);
	param.GeneralCost=bitget(pct,cType.GENERALIZED);
	if model.isResourceCost && param.GeneralCost
		rsc=model.readResources(param.ResourceSample);
		rsc.setResources(ect);
        if ~rsc.isValid
			rsc.printLogger;
			res.printError('Invalid resources cost values. See error log');
			return
        end
		param.ResourcesCost=rsc;
	end
	res=getExergyCostResults(fmt,ect,param);
	res.setProperties(model.ModelName,param.State);
end