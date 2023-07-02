function res=ProductiveDiagram(data)
% Get the adjacency tables of the productive structure
%	USAGE:
%		res=ProductiveDiagram(data)
% 	INPUT:
%		data - cReadModel object containing the data model information
% 	OUTPUT:
%		res - cResultInfo object containing productive structure info.
%		The following tables are obtained
%		  	fat - Flows adjacency matrix
%         	pat - Productive adjacency matrix
% See also cReadModel, cProductiveStructure, cResultInfo
%
	res=cStatusLogger();
    % Check input parameters
    if nargin~=1
        res.printError('Usage: ShowProductiveStructure(data)');
        return
    end
    if ~isa(data,'cReadModel')
        res.printError('Invalid data. It should be a cReadModel object');
        return
    end
	% Check Productive Structure
	if data.isError
		data.printLogger;
		res.printError('Invalid Productive Structure. See error log');
		return
	end
	if data.isWarning
		data.printLogger;
		res.printWarning('Productive Structure has errors. See error log');
	end
	% Read print format configuration
    fmt=data.readFormat;
	if fmt.isError
		fmt.printLogger;
		res.printError('Format Definition is NOT correct. See error log');
		return
	end
	% Get Productive Diagram info
	res=getProductiveDiagram(fmt,data.ProductiveStructure);
	res.setProperties(data.ModelName,'SUMMARY');
end