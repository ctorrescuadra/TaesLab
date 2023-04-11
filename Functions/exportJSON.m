function log=exportJSON(data,filename)
% exportJSON save a octave/matlab object as json file
%   INPUT:
%	    data - json struct data
%	    filename - json filename
%    OUTPUT:
%       log - cLoggerStatus object containing status and error messages
%
	log=cStatusLogger(cType.VALID);
    if (nargin~=2) || (~ischar(filename)) || ~iscell(data)
        log.messageLog(cType.ERROR,'Invalid input arguments');
        return
    end
    if ~cType.checkFileWrite(filename)
        message=sprintf('Invalid filename extension %s',filename);
        log.messageLog(cType.ERROR,message)
        return
    end
    if ~cType.checkFileExt(filename,cType.FileExt.JSON)
        message=sprintf('Invalid filename extension %s',filename);
        log.messageLog(cType.ERROR,message)
        return
    end
	try
	    text=jsonencode(data,'PrettyPrint',true);
		fid=fopen(filename,'wt');
		fwrite(fid,text);
		fclose(fid);
        message=sprintf('File %s has been saved',filename);
        log.messageLog(cType.INFO,message);
	catch err
        log.messageLog(cType.ERROR,err.message);
        log.messageLog(cType.ERROR,'File %s could NOT be saved',filename);
	end
end



	