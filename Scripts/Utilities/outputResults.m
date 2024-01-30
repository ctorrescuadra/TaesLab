function tbl=outputResults(res,options)
% outputResults - Interactive selection of output tables result options
%  INPUT:
%	res - cResultsInfo object 
%	options - struct with applied options
%  OUTPUT:
%	sol - struct tables in the selected format
%
    tbl=[];
    log=cStatusLogger();
	options.VarFormat=false;
	[nopt,options.VarMode]=optionChoice('Select Variable Output:',cType.VarModeOptions);
	ShowConsole=askQuestion('Show in Console','Y');
	if ShowConsole
		res.printResults;
	end
	SaveResult=askQuestion('Save Result','N');
    if SaveResult
		[~,name]=fileparts(pwd);
		default_file=strcat(name,'_results.xlsx');
		resFileName=fileChoice('Results filename',default_file);
		log=res.saveResults(resFileName);
		printLogger(log);
    end
	if nopt ~= cType.VarMode.NONE
	    tbl=res.getResultTables(options.VarMode,options.VarFormat);
	    log.printInfo('Tables (tbl) available in Variables Editor');
	end
end