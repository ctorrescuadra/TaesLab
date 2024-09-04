function log=exportCSV(values,filename)
%exportCSV - Save a cell array as CSV file
%
%  Syntax
%    log=exportCSV(values, filename)
%
%  Input Arguments
%    values - cell array values
%    filename - CSV file name
%      char array | string
%
%  Output Arguments
%    log - cMessageLogger containing the status of the save and error messages
%
%  See also cTable
%
    log=cMessageLogger();
    try
        if isOctave
            cell2csv(filename,values);
        else
            writecell(values,filename);
        end
    catch err
        log.messageLog(cType.ERROR,err.message);
        log.messageLog(cType.ERROR,'File %s could NOT be saved',filename);
    end
end