function res=DiagramFP(data,varargin)
% DiagramFP gets the Diagram FP tables for a plant State
%  USAGE:
%	res = DiagramFP(data, options)
%  INPUT:
%	data - cReadModel Object containing the data model information
%   options - a structure (pairs Name/Value) contains additional parameters.
%		State - Indicate a state to get exergy values. 
%               If it is not provided, the first state is used.
%       Show -  Show results on console (true/false)
%       SaveAs - Save results in an external file 
% 	OUTPUT:
%	 res - cResultInfo object contains the FP diagram tables
%    The following tables are obtained:
%		atfp - Diagram FP adjacency matrix                                     
%       atcfp - Cost Diagram FP adjacency matrix
%      
% See also cExergyCost, cResultInfo
%
	res=cStatus(); 
	checkModel=@(x) isa(x,'cDataModel');
	% Check input parameters
	p = inputParser;
	p.addRequired('data',checkModel);
	p.addParameter('State','',@ischar);
    p.addParameter('Show',false,@islogical);
    p.addParameter('SaveAs','',@ischar);
	try
		p.parse(data,varargin{:});
	catch err
		res.printError(err.message);
        res.printError('Usage: DiagramFP(data,param)');
		return
	end
	param=p.Results;
	% Check Data Model
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
		res.printError('Invalid exergy values. See error log');
        return
	end	
	% Get FP Diagram model and set results
	pm=cExergyCost(ex);
    dfp=cDiagramFP(pm);
    if ~isValid(dfp)
        dfp.printLogger;
        res.printError('Invalid Diagram FP. See error log');
		return
    end
	res=dfp.getResultInfo(data.FormatData);
	if ~isValid(res)
		res.printLogger;
        res.printError('Invalid cResultInfo. See error log');
		return
	end
    % Show and Save results if required
    if param.Show
        printResults(res);
    end
    if ~isempty(param.SaveAs)
        SaveResults(res,param.SaveAs);
    end
end