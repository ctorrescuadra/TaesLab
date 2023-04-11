function sol=ShowProductiveStructure(model)
% ShowProductiveStructure - shows information about the productive structure of a plant
% 	INPUT:
%		model - cReadModel object containing the model information
% 	OUTPUT:
%		res - cResultInfo object containing productive structure info.
%		The following tables are obtained
%		  	flows - Flows definition table
%         	streams - Streams definition tables
%         	processes - Processes definition tables
% See also cReadModel, cProductiveStructure, cResultInfo
%
	sol=cStatusLogger();
    % Check input parameters
    if nargin~=1
        sol.printError('Usage: ShowProductiveStructure(model)');
        return
    end
    if ~isa(model,'cReadModel')
        data.printError('Invalid model. It should be a cReadModel object');
        return
    end
	% Check Productive Structure
	if model.isError
		model.printLogger;
		model.printError('Invalid Productive Structure. See error log');
		return
	end
	if model.isWarning
		model.printLogger;
		model.printWarning('Productive Structure has errors. See error log');
	end
	% Read print format configuration
    fmt=model.readFormat;
	if fmt.isError
		fmt.printLogger;
		fmt.printError('Format Definition is NOT correct. See error log');
		return
	end
	% Get Productive Structure info
	sol=getProductiveStructureResults(fmt,model.ProductiveStructure);
	sol.setProperties(model.ModelName,model.getStateName(1));
end