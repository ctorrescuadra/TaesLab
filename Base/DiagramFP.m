function res=DiagramFP(data,varargin)
% Get the Diagram FP of a plant State
%	USAGE:
%		res=DiagramFP(data, options)
% 	INPUT:
%		data - cReadModel Object containing the data information
%   	optiond - a structure contains additional parameters (optional)
%			State - Indicate a state to get exergy values. If not provided, first state is used
%			Table - Select table for the Diagram FP
%				cType.Tables.TABLE_FP (tfp)
%				cType.Tables.COST_TABLE_FP (dcfp) 
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
	p.addParameter('Table',cType.Tables.TABLE_FP,@ischar);
	try
		p.parse(data,varargin{:});
	catch err
		res.printError(err.message);
        res.printError('Usage: ExergyCostCalculator(data,param)');
		return
	end
	param=p.Results;
	% Check Productive Structure
	if ~data.isValid
		data.printLogger;
		res.printError('Invalid Productive Structure. See error log');
		return
	end	
	% Check format definition
	fmt=data.FormatData;
	% Read and check exergy values
	if isempty(param.State)
		param.State=data.getStateName(1);
	end
	ex=data.getExergyData(param.State);
	% Set Results
	pm=cModelFPR(ex);
    res=getDiagramFP(fmt,pm,param.Table);
    res.setProperties(data.ModelName,param.State);
end