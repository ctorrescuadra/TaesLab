function res=ThermoeconomicAnalysis(data,varargin)
%ThermoeconomicAnalysis gets the termoeconomic analysis of a plant state.
%   Calculate the exergy cost, Fuel-Product and Irreversibility-Cost tables.
%   If the data model has information on resource costs, generalised costs can be calculated, 
%   otherwise only direct costs can be calculated.
%   With the option 'CostTables' we choose the type of costs we want to calculate. 
%   With the option 'ResourceSample' we choose the resource cost sample data.
%
% Syntax
%   res=ThermoeconomicAnalysis(data,Name,Value)
%
% Input Arguments
% 	data - cDataModel object which contains the data model
%
% Name-Value Arguments
%   State - Thermoeconomic state id. If missing first sample is taken
%     array char | string
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
%    If DirectCost is selected (default) the following tables are obtained:
%      dfcost: Direct Exergy Cost of flows
%      dcost: Direct Exergy cost of processes
%      udcost: Unit Direct Exergy Cost of processes table
%      dict: Irreversibility Cost Table 
%      dfict: Flows Irreversibility Cost Table
%      dcfp: Fuel-Product direct cost table
%      dcfpr: Fuel-Product direct cost table (includes waste)
%    If GeneralCost is selected, the following tables are obtained:
%       gcost: Generalized cost of processes 
%       ugcost: Unit Generalized Cost of processes
%       gfcost: Generalized Cost of flows
%       gcfp: Fuel-Product generalized cost table
%       gict: Irreversibility generalized cost table 
%       gfict: Flows Irreversibility generalized cost table
%
% Example
%   <a href="matlab:open ThermoeconomicAnalysisDemo.mlx">Thermoeconomic Analysis Demo</a>
%
% See also cDataModel, cExergyCost, cResultInfo
%
    res=cMessageLogger();
    % Check input parameters
	checkModel=@(x) isa(x,'cDataModel');
    p = inputParser;
    p.addRequired('data',checkModel);
	p.addParameter('State',data.StateNames{1},@ischar);
	p.addParameter('ResourceSample',cType.EMPTY_CHAR,@ischar);
	p.addParameter('CostTables',cType.DEFAULT_COST_TABLES,@cType.checkCostTables);
    p.addParameter('Show',false,@islogical);
    p.addParameter('SaveAs',cType.EMPTY_CHAR,@isFilename);
    try
		p.parse(data,varargin{:});
    catch err
        res.printError(err.message);
        res.printError('Usage: ThermoeconomicAnalysis(data,options)');
        return
    end
    param=p.Results;
    % Check data model
    if ~data.isValid
		data.printLogger;
        res.printError('Invalid Data Model. See error log');
        return
    end
    % Read exergy
	ex=data.getExergyData(param.State);
	if ~isValid(ex)
        ex.printLogger;
		res.printError('Invalid exergy values. See error log');
        return
	end
    % Read Waste and compute Model FP
    if(data.NrOfWastes>0)
        fpm=cExergyCost(ex,data.WasteData); 
    else
        fpm=cExergyCost(ex);
    end
    if ~fpm.isValid
        fpm.printLogger;
		res.printError('Invalid Thermoeconomic Analysis. See error log')
        return
    end
    % Read external resources and get results
	pct=cType.getCostTables(param.CostTables);
	param.DirectCost=bitget(pct,cType.DIRECT);
	param.GeneralCost=bitget(pct,cType.GENERALIZED);
    if data.isResourceCost && param.GeneralCost
        if isempty(param.ResourceSample)
			param.ResourceSample=data.SampleNames{1};
        end
		rd=data.getResourceData(param.ResourceSample);
		rsc=getResourceCost(rd,fpm);
        if ~rsc.isValid
			rsc.printLogger;
			res.printError('Invalid resource cost values. See Error Log');
			return
        end
        param.ResourcesCost=rsc;
    end
    res=fpm.getResultInfo(data.FormatData,param);
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