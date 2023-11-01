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
    if ~isa(data,'cDataModel') || ~isValid(data)
        res.printError('Invalid data parameter. It should be a valid cDataModel object');
        return
    end
	% Get Productive Diagram info
	pd=cProductiveDiagram(data.ProductiveStructure);
    res=pd.getResultInfo(data.FormatData);  
	res.setProperties(data.ModelName,'SUMMARY');
end