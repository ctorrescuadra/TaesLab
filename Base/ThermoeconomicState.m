function res=ThermoeconomicState(data,varargin)
% Get the exergy balances and the Fuel-Product table for a plant state
%	USAGE:
%		res=ThermoeconomicState(data, options)
% 	INPUT:
%		data - cReadModel Object containing the data information
%   	options - A structure contains additional parameters:
%			State - Indicate a state to get exergy values.
%               If not provided, first state is used
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
	checkModel=@(x) isa(x,'cDataModel');
	% Check input parameters
	p = inputParser;
	p.addRequired('data',checkModel);
	p.addParameter('State','',@ischar);
	try
		p.parse(data,varargin{:});
	catch err
		res.printError(err.message);
        res.printError('Usage: ThermoeconomicState(data,param)');
		return
	end
	param=p.Results;
	% Check Productive Structure
	if ~data.isValid
		data.printLogger;
		res.printError('Invalid data model. See error log');
		return
	end	
	% Read and check exergy values
	if isempty(param.State)
		param.State=data.getStateName(1);
	end
	ex=data.getExergyData(param.State);
	if ~isValid(ex)
		ex.printLogger;
		res.printError('Exergy values are NOT correct. See error log');
		return
	end
	pm=cProcessModel(ex);
	% Set Results
	if isValid(pm)
		res=pm.getResultInfo(data.FormatData);
    	res.setProperties(data.ModelName,param.State);
	else
		pm.printLogger;
		res.printError('Invalid Process Model. See error log');
	end
end