function sol=ThermoeconomicState(model,varargin)
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
	sol=cStatusLogger(); 
	checkModel=@(x) isa(x,'cReadModel');
	% Check input parameters
	p = inputParser;
	p.addRequired('model',checkModel);
	p.addParameter('State','',@ischar);
	try
		p.parse(model,varargin{:});
	catch err
		sol.printError(err.message);
        sol.printError('Usage: ExergyCostCalculator(model,param)');
		return
	end
	param=p.Results;
	% Check Productive Structure
	if ~model.isValid
		model.printLogger;
		model.printError('Invalid Productive Structure. See error log');
		return
	end	
	fmt=model.readFormat;
	if fmt.isError
		fmt.printLogger;
		fmt.printError('Format Definition is NOT correct. See error log');
		return
	end	
	% Read and check exergy values
	if isempty(param.State)
		param.State=model.getStateName(1);
	end
	rex=model.readExergy(param.State);
	if ~isValid(rex)
		rex.printLogger;
		rex.printError('Exergy Values are NOT correct. See error log');
		return
	end
	pm=cProcessModel(rex);
	% Set Results
	sol=getExergyResults(fmt,pm);
    sol.setProperties(model.ModelName,param.State);
end