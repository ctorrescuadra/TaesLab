function outputResults(res,options)
% outputResults - Interactive selection of output tables result options
%  INPUT:
%	res - cResultsInfo object 
%	options - struct with applied options
%  OUTPUT:
%	sol - struct tables in the selected format
%
	ShowConsole=askQuestion('Show in Console',options.Console);
	if ShowConsole
		res.printResults;
	end
	SaveResult=askQuestion('Save Result',options.Save);
    if SaveResult
		[~,name]=fileparts(pwd);
		default_file=strcat(name,'_results.xlsx');
		resFileName=fileChoice('Results filename',default_file);
		log=res.saveResults(resFileName);
		printLogger(log);
    end
end