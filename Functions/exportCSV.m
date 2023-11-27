function log=exportCSV(data,filename)
% exportCSV saves table cell as XLS file
%   USAGE:
%       log=exportCSV(data, filename)
%   INPUT:
%       data - cell array which contains the data
%       filename - name of CSV file
%   OUTPUT
%       log - cLoggerStatus object containing status and error messages
%
    % Validate parameters
	log=cStatusLogger(cType.VALID);
    if (nargin~=2) || (~ischar(filename)) || ~iscell(data)
        log.messageLog(cType.ERROR,'Invalid input arguments');
        return
    end
    if ~cType.checkFileWrite(filename)
        obj.messageLog(cType.ERROR,'Invalid file name: %s',filename);
        return
    end
    if ~cType.checkFileExt(filename,cType.FileExt.CSV)
        obj.messageLog(cType.ERROR,'Invalid file name extension: %s',filename)
        return
    end
    % Save data as CSV
	try
        if isOctave
			cell2csv(filename,data);
		else
			writecell(data,filename);
        end
        log.messageLog(cType.INFO,'File %s has been saved',filename);
	catch err
        log.messageLog(cType.ERROR,err.message);
        log.messageLog(cType.ERROR,'File %s could NOT be saved',filename);
	end
end