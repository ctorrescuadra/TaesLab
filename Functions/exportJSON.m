function log=exportJSON(S,filename)
%exportJSON - save struct as JSON file
%   Input:
%     S - struct array
%     filename - name of the output file
%   Output:
%     log: cMessageLogger class containing status and messages
%
    log=cMessageLogger(); 
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