function log=exportJSON(data,filename)
% exportJSON save a octave/matlab object as json file
%   USAGE:
%       log=exportJSON(data, filename)
%   INPUT:
%	    data - json struct data
%	    filename - json filename
%    OUTPUT:
%       log - cLoggerStatus object containing status and error messages
%
	log=cStatusLogger(cType.VALID);
    if (nargin~=2) || (~ischar(filename)) || ~isstruct(data)
        log.messageLog(cType.ERROR,'Invalid input arguments');
        return
    end
    if ~cType.checkFileWrite(filename)
        log.messageLog(cType.ERROR,'Invalid file name: %s',filename)
        return
    end
    if ~cType.checkFileExt(filename,cType.FileExt.JSON)
        log.messageLog(cType.ERROR,'Invalid file name extension: %s',filename)
        return
    end
	try
	    text=jsonencode(data,'PrettyPrint',true);
		fid=fopen(filename,'wt');
		fwrite(fid,text);
		fclose(fid);
	catch err
        log.messageLog(cType.ERROR,err.message);
        log.messageLog(cType.ERROR,'File %s could NOT be saved',filename);
	end
end



	