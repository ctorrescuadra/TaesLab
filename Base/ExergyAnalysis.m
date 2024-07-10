function res=ExergyAnalysis(data,varargin)
%ExergyAnalysis - Get the exergy balances for one state of the plant
%	Given a data model of a plant this function performs an exergy analysis
%   including the exergy balances and the Fuel-Product table.
% 
%	Syntax
%	  res = ExergyAnalysis(data,Name,Value)
% 
%   Input Arguments
%     data - cReadModel object containing the data information
%    
%   Name-Value Arguments
%     State - State name of the exergy data. If not provided first state is used
%		char array
%     Show -  Show the results on console.  
%       true | false (default)
%     SaveAs - Name of file (with extension) to save the results.
%       char array | string
% 
%   Output Arguments
%     res - cResultsInfo object contains the results of the exergy analysis for the required state
%     The following tables are obtained:
%		eflows - exergy of the flows
%       estreams - exergy of the streams
%       eprocesses - exergy balance of the processes
%       tfp - Exergy Fuel-Product table
%
%   Example
%     <a href="matlab:open ExergyAnalysisDemo.mlx">Exergy Analysis Demo</a>
%
%   See also cDataModel, cExergyModel, cResultInfo
%
	res=cStatus(); 
	checkModel=@(x) isa(x,'cDataModel');
	% Check input parameters
	p = inputParser;
	p.addRequired('data',checkModel);
	p.addParameter('State',data.StateNames{1},@ischar);
    p.addParameter('Show',false,@islogical);
    p.addParameter('SaveAs','',@isFilename);
	try
		p.parse(data,varargin{:});
	catch err
		res.printError(err.message);
        res.printError('Usage: ExergyAnalysis(data,options)');
		return
	end
	param=p.Results;
	% Check data model
	if ~data.isValid
		data.printLogger;
		res.printError('Invalid data model. See error log');
		return
	end	
	% Read and check exergy values
	ex=data.getExergyData(param.State);
	if ~isValid(ex)
		ex.printLogger;
		res.printError('Exergy values are NOT correct. See error log');
		return
	end
	pm=cExergyModel(ex);
	% Set Results
	if isValid(pm)
		res=pm.getResultInfo(data.FormatData);
	else
		pm.printLogger;
		res.printError('Invalid Process Model. See error log');
	end
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