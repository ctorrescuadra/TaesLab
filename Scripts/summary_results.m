% summary_results
% Script to launch function SummaryResults
% Shows summary cost result for different states
% Select the data file model as <folder>_model.<ext>
% Prompt some parameters interactively
%
% Select data file model
data=selectDataModel();
if data.isError
	data.printLogger;
	data.printError('Invalid data model. See error log');
	return
end
% Show results
res=SummaryResults(data);
if ~res.isError
	tbl=outputResults(res);
end
