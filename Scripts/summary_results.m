%summary_results
% 	Script to launch function SummaryResults
% 	Shows summary cost result for different states
% 	Select the data file model as <folder>_model.<ext>
% 	Prompt input parameters interactively
% Output:
%	res - cResultInfo containing Summary Results
%
% Select data file model
options=struct('Console','Y','Save','N');
param=struct();
data=selectDataModel();
if ~data.status
	data.printLogger;
	data.printError('Invalid data model. See error log');
	return
end
if data.isResourceCost
	[~,param.ResourceSample]=optionChoice('Select Resource Sample:',data.SampleNames);
else
	param.ResourceSample=data.SampleNames{1};
end
% Show results
sr=SummaryResults(data,param);
if sr.status
	outputResults(sr,options);
	sr.printInfo('Results (sr) available in Workspace');
else
	printLogger(sr);
end
