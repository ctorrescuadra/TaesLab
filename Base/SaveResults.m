function SaveResults(arg,filename)
% SaveResults saves a cResultInfo into a file
%   The type of file depends on the file extension
%   *.csv, *.xlsx and *.mat are allowed
%   It calls cResultInfo method saveResults
%   USAGE:
%       SaveResults(res,filename)
%   INPUT:
%       arg - cResultInfo, cThermoeconomicModel or cDataModel objects
%       filename - name of the output file (with extension)
% See also cResultInfo, cThermoeconomicModel or cDataModel
%
    log=cStatus(cType.VALID);
    % Check Input parameters
    if (nargin~=2) || ~isText(filename)
        log.printError('Usage: SaveResults(res,filename)');
        return
    end
    if isstring(filename)
        filename=convertStringsToChars(filename);
    end
    switch getClassId(arg)
        case cType.ClassId.RESULT_INFO
            res=arg;
        case cType.ClassId.DATA_MODEL
            res=arg.getResultInfo;
        case cType.ClassId.RESULT_MODEL
            res=arg.resultModelInfo;
        otherwise
            log.printError('Invalid result parameter');
        return
    end
    % Save the results
    log=saveResults(res,filename);
    printLogger(log);
end