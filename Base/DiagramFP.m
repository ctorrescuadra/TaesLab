function res=DiagramFP(data,varargin)
% Get the Diagram FP of a plant State
%	USAGE:
%		res=DiagramFP(data, options)
% 	INPUT:
%		data - cReadModel Object containing the data information
%   	option - a structure contains additional parameters (optional)
%			State - Indicate a state to get exergy values. If not provided, first state is used
%           Show -  Show results on console (true/false)
%           SaveAs - Save results in an external file 
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
		res.printError('Invalid exergy values. See error log');
        return
	end	
	% Get FP Diagram model and set results
	pm=cModelFPR(ex);
    dfp=cDiagramFP(pm);
    if ~isValid(dfp)
        dfp.printLogger;
        res.printError('Invalid Diagram FP. See error log');
    end
	res=dfp.getResultInfo(data.FormatData);
    res.setProperties(data.ModelName,param.State);
    % Show and Save results if required
    if param.Show
        printResults(res);
    end
    if ~isempty(param.SaveAs)
        SaveResults(res,param.SaveAs);
    end
end