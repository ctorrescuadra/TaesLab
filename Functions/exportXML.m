function log=exportXML(data,filename)
% exportXML save a octave/matlab object as json file
%   INPUT:
%	    data - struct data
%	    filename - json filename
%   OUTPUT:
%       log - cLoggerStatus object containing status and error messages
%
	log=cStatusLogger(cType.VALID);
    if isOctave
        log.messageLog(cType.ERROR,'This function is not yet implemented');
        return
    end
    if (nargin~=2) || (~ischar(filename)) || ~isstruct(data)
        log.messageLog(cType.ERROR,'Invalid input arguments');
        return
    end
    if ~cType.checkFileWrite(filename)
        log.messageLog(cType.ERROR,'Invalid filename %s',filename);
        return
    end
    if ~cType.checkFileExt(filename,cType.FileExt.XML)
        log.messageLog(cType.ERROR,'Invalid filename extension %s',filename);
        return
    end
	try
		writestruct(data,filename,'StructNodeName','root','AttributeSuffix','Id');
        log.messageLog(cType.INFO,'File %s has been saved',filename);
	catch err
        log.messageLog(cType.ERROR,err.message);
        log.messageLog(cType.ERROR,'File %s could NOT be saved',filename);
	end
end





