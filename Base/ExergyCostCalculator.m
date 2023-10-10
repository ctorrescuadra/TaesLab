function res=ExergyCostCalculator(data,varargin)
% Calculates the exergy cost values of a plant state
% It uses the Structural Theory algorithm to compute the flows cost
%	USAGE:
%		res=ExergyCostCalculator(data, options)
% 	INPUT:
%   	data - cReadModel object whose contains the thermoeconomic data model
%   	options - Structure contains additional parameters (optional)
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
	checkModel=@(x) isa(x,'cDataModel');
    %Check input parameters
    p = inputParser;
    p.addRequired('data',checkModel);
	p.addParameter('State','',@ischar);
	p.addParameter('ResourceSample','',@ischar);
	p.addParameter('CostTables',cType.DEFAULT_COST_TABLES,@cType.checkCostTables);
    try
		p.parse(data,varargin{:});
    catch err
		res.printError(err.message);
        res.printError('Usage: ExergyCostCalculator(data,param)');
        return
    end
    param=p.Results;
    % Check productive structure
    if ~data.isValid
		data.printLogger;
		res.printError('Invalid data model. See error log');
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
	% Read Waste definition and compute waste operator
    if(data.NrOfWastes>0)
		wd=data.WasteData;
	    ect=cExergyCost(ex,wd);
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
	if data.isResourceCost && param.GeneralCost
        if isempty(param.ResourceSample)
			param.ResourceSample=data.getResourceSample(1);
        end
		rsd=data.getResourceData(param.ResourceSample);
		rsc=getResourceCost(rsd,ect);
        if ~rsc.isValid
			rsc.printLogger;
			res.printError('Invalid resources cost values. See error log');
			return
        end
		param.ResourcesCost=rsc;
	end
	res=getExergyCostResults(fmt,ect,param);
	res.setProperties(data.ModelName,param.State);
end