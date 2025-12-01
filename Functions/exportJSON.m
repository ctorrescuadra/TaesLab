function log=exportJSON(S,filename)
%exportJSON - Save struct as JSON file
%   Input:
%     S - struct array
%     filename - name of the output file
%   Output:
%     log: cMessageLogger class containing status and messages
%
    log=cMessageLogger();
    % Check input arguments
    if nargin~=2
        log.messageLog(cType.ERROR,cMessages.NarginError,cMessages.ShowHelp);
        return
    end
    if ~isstruct(S)
        log.messageLog(cType.ERROR,cMessages.InvalidArgument,cMessages.ShowHelp);
        return
    end
    if ~isFilename(filename) || ~cType.checkFileExt(filename,cType.FileExt.JSON)
        log.messageLog(cType.ERROR,cMessages.InvalidInputFile);
        log.messageLog(cType.ERROR,cMessages.ShowHelp);
        return
    end
    % Save struct as JSON 
    try
        text=jsonencode(S,'PrettyPrint',true);
        fid=fopen(filename,'wt');
        fwrite(fid,text);
        fclose(fid);
    catch err
        log.messageLog(err.message);
        log.messageLog(cMessages.FileNotSaved,filename);
    end
end