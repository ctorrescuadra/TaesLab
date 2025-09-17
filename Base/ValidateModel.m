function [log,res]=ValidateModel(file)
    log=cMessageLogger();
    res=struct();
	% load default configuration filename			
	path=fileparts(mfilename('fullpath'));
	cfgfile=strrep(fullfile(path,'datamodel_config.json'),'\','\\');
    try		
		config=jsondecode(fileread(cfgfile));
	catch err
        log.messageLog(cType.ERROR,err.message);
		log.messageLog(cType.ERROR,cMessages.InvalidConfigFile,cfgfile);
		return
    end
    NrOfSheets=numel(config.tables);
    % Determine sheet names of the file
    try
		sheets=sheetnames(file);
    catch err
        log.messageLog(cType.ERROR,err.message);
		log.messageLog(cType.ERROR,cMessages.FileNotRead,cfgfile);
		return
    end
    opts=[config.tables.optional];
    wshts={config.tables.name};
    idx=ismember(wshts,sheets);
    % Read sheets
    for i=1:NrOfSheets
        sht=wshts{i};
        res.(sht)=cType.EMPTY;
        if idx(i)
            try
		        values=readcell(file,'Sheet',sht);
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
        flds={config.tables(i).fields.name};
        % Check Fields
        for j=1:numel(flds)
            if numel(values(1,:)) < numel(flds)
                log.messageLog(cType.error,'Invalid number of columns',numel(flds));
            end
            switch config.tables(i).fields(j).datatype
                case 1
                    tst1=strcmp(flds(j),values{1,j});
                    tst2=all(cellfun(@ischar,values(2:end,j)));
                    tst=tst1&tst2;
                case 2
                    tst1=strcmp(flds(j),values{1,j});
                    tst2=all(cellfun(@isnumeric,values(2:end,j)));
                    tst=tst1&tst2;
                case 3
                    tmp1=all(cellfun(@ischar,values(1,j:end)));
                    tmp2=(cellfun(@isnumeric,values(2:end,j:end)));
                    tmp2=all(tmp2(:));
                    tst=tmp1 && tmp2;
            end
            if ~tst
                log.messageLog(cType.ERROR,'Invalid column %s data type for sheet %s',flds{j},sht);
                continue
            end
        end
        %p.Name=sht;
        %p.Description=cType.TableDataDescription{i};
        %res.(sht)=cTableData.create(values,p);
        res.(sht)=values;
    end   
end