function log=exportXLS(data,filename)
% exportXLS saves table cell as XLS file
%   USAGE:
%       log=exportXLS(data, filename)
%   INPUT:
%       data - cell array which contains the data
%       filename - name of XLSX file
%   OUTPUT
%       log - cLoggerStatus object containing status and error messages
%
	log=cStatusLogger(cType.VALID);
    if (nargin~=2) || (~ischar(filename)) || ~iscell(data)
        log.messageLog(cType.ERROR,'Invalid input arguments');
        return
    end
    if ~cType.checkFileWrite(filename)
        obj.messageLog(cType.ERROR,'Invalid file name %s',filename)
        return
    end
    if ~cType.checkFileExt(filename,cType.FileExt.XLSX)
        obj.messageLog(cType.ERROR,'Invalid filename extension %s',filename)
        return
    end
    if isOctave
        xls=xlsopen(filename,1);
		[xls,status]=oct2xls(data,xls);
        xls=xlsclose(xls);
        if status && isempty(xls)
            log.messageLog(cType.INFO,'File %s has been saved',filename);
        else
            log.messageLog(cType.ERROR,'File %s could NOT be saved',filename);
        end
    else 
        try
			writecell(data,filename);
            log.messageLog(cType.INFO,'File %s has been saved',filename);
        catch err
            log.messageLog(cType.ERROR,err.message);
            log.messageLog(cType.ERROR,'File %s could NOT be saved',filename);
        end
    end
end