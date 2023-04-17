function res=ShowProductiveStructure(data)
% ShowProductiveStructure - shows information about the productive structure of a plant
% 	INPUT:
%		data - cReadModel object containing the data model information
% 	OUTPUT:
%		res - cResultInfo object containing productive structure info.
%		The following tables are obtained
%		  	flows - Flows definition table
%         	streams - Streams definition tables
%         	processes - Processes definition tables
% See also cReadModel, cProductiveStructure, cResultInfo
%
	res=cStatusLogger();
    % Check input parameters
    if nargin~=1
        res.printError('Usage: ShowProductiveStructure(model)');
        return
    end
    if ~isa(data,'cReadModel')
        data.printError('Invalid model. It should be a cReadModel object');
        return
    end
	% Check Productive Structure
	if data.isError
		data.printLogger;
		data.printError('Invalid Productive Structure. See error log');
		return
	end
	if data.isWarning
		data.printLogger;
		data.printWarning('Productive Structure has errors. See error log');
	end
	% Read print format configuration
    fmt=data.readFormat;
	if fmt.isError
		fmt.printLogger;
		fmt.printError('Format Definition is NOT correct. See error log');
		return
	end
	% Get Productive Structure info
	res=getProductiveStructureResults(fmt,data.ProductiveStructure);
	res.setProperties(data.ModelName,data.getStateName(1));
end