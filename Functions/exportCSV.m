function log=exportCSV(values,filename)
%exportCSV - Saves a cell array as CSV file.
%   Octave/Matlab compatibility
%   
%   Syntax:
%     log=exportCSV(values, filename)
%
%   Input Arguments:
%      values - cell array values
%      filename - CSV file name
%        char array | string
%
%    Output Arguments:
%      log - cMessageLogger containing the status of the save and error messages
%
%   Example:
%     values = {'Name', 'Age'; 'Alice', 30; 'Bob', 25};
%     filename = 'data.csv';                            
%     log = exportCSV(values, filename);
%
    log=cMessageLogger();
    if nargin~=2
        log.messageLog(cType.ERROR,cMessages.NarginError,cMessages.ShowHelp);
        return
    end
    if ~iscell(values)
        log.messageLog(cType.ERROR,cMessages.InvalidArgument,cMessages.ShowHelp);
        return
    end
    if ~isFilename(filename) || ~cType.checkFileExt(filename,cType.FileExt.CSV)
        log.messageLog(cType.ERROR,cMessages.InvalidInputFile);
        log.messageLog(cType.ERROR,cMessages.ShowHelp);
        return
    end
    try
        if isOctave
            cell2csv(filename,values);
        else
            writecell(values,filename);
        end
    catch err
        log.messageLog(cType.ERROR,err.message);
        log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
    end
end