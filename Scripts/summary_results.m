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
	data.printError(cMessages.InvalidDataModel);
	return
end
% Select parameters
sopt=data.SummaryOptions;
if ~sopt.isEnable
	data.printError(cMessages.SummaryNotAvailable);
	return
else 
	soptions=sopt.Names(2:end);
	if length(soptions)>1
		[~,param.Summary]=optionChoice('Select Summary Report',soptions);
	else
		param.Summary=soptions{1};
	end
end
sId=cType.getSummaryId(param.Summary);
if bitget(sId,cType.STATES)
	[~,param.ResourceSample]=optionChoice('Select Resource Sample:',data.SampleNames);
end
if bitget(sId,cType.RESOURCES)
	[~,param.State]=optionChoice('Select State:',data.StateNames);
end
% Show results
res=SummaryResults(data,param);
if res.status
	outputResults(res,options);
else
	printLogger(res);
end
