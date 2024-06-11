% summary_results
% Script to launch function SummaryResults
% Shows summary cost result for different states
% Select the data file model as <folder>_model.<ext>
% Prompt input parameters interactively
% Output:
%	res - cResultInfo containing Summary Results
%
% Select data file model
options=struct('Console','Y','Save','N');
data=selectDataModel();
if ~data.isValid
	data.printLogger;
	data.printError('Invalid data model. See error log');
	return
end
% Show results
res=SummaryResults(data);
if res.isValid
	outputResults(res,options);
	res.printInfo('Results (res) available in Workspace');
else
	printLogger(res);
end
