function res=ExergyAnalysis(data,varargin)
%ExergyAnalysis - Get the exergy analysis for a plant state.
%   Given a data model of a plant, this function performs an exergy analysis,
%   including the exergy balances and the Fuel-Product table.
% 
%   Syntax:
%     res = ExergyAnalysis(data,Name,Value)
% 
%   Input Arguments:
%     data - cReadModel object containing the data information
%    
%   Name-Value Arguments:
%     State - State name of the exergy data. If not provided, first state is used
%       char array
%     Show -  Show the results on console.  
%       true | false (default)
%     SaveAs - Name of file (with extension) to save the results.
%       char array | string
% 
%   Output Arguments:
%     res - cResultsInfo object contains the results of the exergy analysis for the required state
%      The following tables are obtained:
%       eflows - exergy of the flows
%       estreams - exergy of the streams
%       eprocesses - exergy balance of the processes
%       tfp - Exergy Fuel-Product table
%
%   Examples:
%     <a href="matlab:open ExergyAnalysisDemo.mlx">Exergy Analysis Demo</a>
%
%   See also cDataModel, cExergyModel, cResultInfo
%
	res=cTaesLab();
	if nargin<1 || ~isObject(data,'cDataModel')
		res.printError(cMessages.DataModelRequired,cMessages.ShowHelp);
		return
	end
	% Check input parameters
	p = inputParser;
	p.addParameter('State',data.StateNames{1},@data.existState);
    p.addParameter('Show',false,@islogical);
    p.addParameter('SaveAs',cType.EMPTY_CHAR,@isFilename);
	try
		p.parse(varargin{:});
	catch err
		res.printError(err.message);

		return
	end
	param=p.Results;
	% Read and check exergy values
	ex=data.getExergyData(param.State);
	if ~ex.status
		ex.printLogger;
		res.printError(cMessages.InvalidExergyData,param.State);
		return
	end
	pm=cExergyModel(ex);
	% Set Results
	if pm.status
		res=pm.buildResultInfo(data.FormatData);
	else
		pm.printLogger;
		res.printError(cMessages.InvalidObject,class(pm));
		return
	end
	if ~res.status
		res.printLogger;
        res.printError(cMessages.InvalidObject,class(res));
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