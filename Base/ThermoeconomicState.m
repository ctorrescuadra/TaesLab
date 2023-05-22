function res=ThermoeconomicState(data,state)
% ThermoeconomicState - shows the exergy values of a thermoeconomic state for a giving data 
% 	INPUT:
%		data - cReadModel Object containing the data information
%   	state - char[] indicates a state of the plant
% 	OUTPUT:
%		res - cResultsInfo object contains the results of the exergy analysis for the required state
%   	The following tables are obtained:
%		  	eflows - exergy of flows
%         	estreams - exergy of the streams
%         	eprocesses - exergy table of the processes
%         	tfp - Exergy Fuel-Product table
% See also cReadModel, cProcessModel, cResultInfo
%
	res=cStatusLogger(); 
	if nargin~=2 || ~isa(data,'cReadModel') || ~ischar(state)
		res.printError('Usage: ThermoeconomicState(data, state)');
	end
	% Check Productive Structure
	if ~data.isValid
		data.printLogger;
		res.printError('Invalid Productive Structure. See error log');
		return
	end
	% Check if exist state
	if ~data.existState(state)
		res.printError('The state %s not exists',state);
		return
	end
	fmt=data.readFormat;
	if fmt.isError
		fmt.printLogger;
		res.printError('Format Definition is NOT correct. See error log');
		return
	end	
	% Read and check exergy values
	ex=data.readExergy(state);
	if ~isValid(ex)
		ex.printLogger;
		res.printError('Exergy Values are NOT correct. See error log');
		return
	end
	pm=cProcessModel(ex);
	% Set Results
	if isValid(pm)
		res=getExergyResults(fmt,pm);
    	res.setProperties(data.ModelName,param.State);
	else
		pm.printLogger;
		res.printError('Invalid Process Model. See error log');
	end
end