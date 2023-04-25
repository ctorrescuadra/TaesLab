function res=ThermoeconomicState(model,varargin)
% ThermoeconomicState - shows the exergy values of a thermoeconomic state for a giving model 
% 	INPUT:
%		model - cReadModel Object containing the model information
%   	varargin - an optional structure contains additional parameters:
%			State - Indicate a state to get exergy values.
%               If not provided, first state is used
% 	OUTPUT:
%		res - cResultsInfo object contains the results of the exergy analysis for the required state
%   	The following tables are obtained:
%		  	eflows - exergy of flows
%         	estreams - exergy of the streams
%         	eprocesses - exergy table of the processes
%         	tfp - Exergy Fuel-Product table
% See also cReadModel, cProcessModel, cModelResults
%
	res=cStatusLogger(); 
	checkModel=@(x) isa(x,'cReadModel');
	% Check input parameters
	p = inputParser;
	p.addRequired('model',checkModel);
	p.addParameter('State','',@ischar);
	try
		p.parse(model,varargin{:});
	catch err
		res.printError(err.message);
        res.printError('Usage: ExergyCostCalculator(model,param)');
		return
	end
	param=p.Results;
	% Check Productive Structure
	if ~model.isValid
		model.printLogger;
		res.printError('Invalid Productive Structure. See error log');
		return
	end	
	fmt=model.readFormat;
	if fmt.isError
		fmt.printLogger;
		res.printError('Format Definition is NOT correct. See error log');
		return
	end	
	% Read and check exergy values
	if isempty(param.State)
		param.State=model.getStateName(1);
	end
	ex=model.readExergy(param.State);
	if ~isValid(ex)
		ex.printLogger;
		res.printError('Exergy Values are NOT correct. See error log');
		return
	end
	pm=cProcessModel(ex);
	% Set Results
	if isValid(pm)
		res=getExergyResults(fmt,pm);
    	res.setProperties(model.ModelName,param.State);
	else
		pm.printLogger;
		res.printError('Invalid Process Model. See error log');
	end
end