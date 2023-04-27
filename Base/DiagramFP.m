function res=DiagramFP(model,varargin)
% DiagramFP - shows the Diagram FP of a plant State
% 	INPUT:
%		model - cReadModel Object containing the model information
%   	varargin - an optional structure contains additional parameters:
%			State - Indicate a state to get exergy values.
%               If not provided, first state is used
% 	OUTPUT:
%		res - cResultInfo object contains the results of the exergy analysis for the required state
% See also cProcessModel, cResultInfo
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
	% Check format definition
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
	% Set Results
	pm=cProcessModel(ex);
    res=getDiagramFP(fmt,pm);
    res.setProperties(model.ModelName,param.State);
end