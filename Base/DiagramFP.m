function res=DiagramFP(data,varargin)
% Get the Diagram FP of a plant State
%	USAGE:
%		res=DiagramFP(data, options)
% 	INPUT:
%		data - cReadModel Object containing the data information
%   	option - a structure contains additional parameters (optional)
%			State - Indicate a state to get exergy values. If not provided, first state is used
% 	OUTPUT:
%		res - cResultInfo object contains the adjacency FP table and additional variables
% See also cModelFPR, cResultInfo
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
        res.printError('Usage: SaveDiagramFP(data,param)');
		return
	end
	param=p.Results;
	% Check Productive Structure
	if ~data.isValid
		data.printLogger;
		res.printError('Invalid data model. See error log');
		return
	end	
	% Check format definition
	fmt=data.FormatData;
	% Read and check exergy values
	if isempty(param.State)
		param.State=data.getStateName(1);
	end
	ex=data.getExergyData(param.State);
	if ~isValid(ex)
        ex.printLogger;
		res.printError('Invalid Exergy Values. See error log');
        return
	end
	% Set Results
	pm=cModelFPR(ex);
    res=getDiagramFP(fmt,pm);
    res.setProperties(data.ModelName,param.State);
end