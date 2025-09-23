function [res,log]=ValidateDataModel(cfgfile)
    log=cMessageLogger();
    tables=loadDataModelConfig(log);
    try
		sheets=sheetnames(cfgfile);
		%xls=cfgfile;
    catch err
        log.messageLog(cType.ERROR,err.message);
		log.messageLog(cType.ERROR,cMessages.FileNotRead,cfgfile);
		return
    end
    opts=[tables.optional];
    wshts={tables.name};
    check=ismember(wshts,sheets);
    for i=1:numel(tables)
        sht=wshts{i};
        res.(sht)=cType.EMPTY;
        if check(i)
            try
		        values=readcell(cfgfile,'Sheet',sht);
            catch err
		        log.messageLog(cType.ERROR,err.message);
                return
            end
        elseif ~opts(i)
            log.messageLog(cType.ERROR,'Sheet %s not found',sht);
            continue
        else
            log.messageLog(cType.INFO,'Sheet %s is optional',sht);
            continue
        end
        % Check Fields
        tbl=cModelTable(values,tables(i));
        if ~isValid(tbl)
            log.addLogger(tbl);
        end
        res.(sht)=tbl;
    end
    printLogger(log);  
end

function s=loadDataModelConfig(log)
% load default configuration filename			
	path=fileparts(mfilename('fullpath'));
	cfgfile=fullfile(path,cType.CFGFILE);
	try		
		config=jsondecode(fileread(cfgfile));
	catch err
		log.messageLog(cType.ERROR,err.message);
		log.messageLog(cType.ERROR,cMessages.InvalidConfigFile,cfgfile);
		return
	end
    s=config.datamodel;
end