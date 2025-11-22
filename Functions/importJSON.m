function res=importJSON(log,filename)
%importJSON - Read a JSON file
%   Syntax:
%     res=importJSON(inFile)
%   Input Arguments:
%     log - cMessageLogger object
%	  filename - json file
%   Output Arguments:
%     res - structure containind the data of json file
%
    res=cType.EMPTY;
    try
	    text=fileread(filename);
		res=jsondecode(text);
	catch err
        log.messageLog(cType.ERROR,err.message);
        log.messageLog(cType.ERROR,cMessages.FileNotRead,filename);
    end
end