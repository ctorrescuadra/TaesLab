function SaveProductiveDiagram(arg,filename)
% SaveProductiveDiagram saves the productive adjacency tables into a file
%   The type of file depends on the file extension
%   *.csv, *.xlsx and *.mat are allowed
%   USAGE:
%       SaveProductiveDiagram(arg,filename)
%   INPUT:
%       arg - cThermoeconomicModel or cResultInfo object
%       filename - name of the output file (with extension)
% See also cResulttInfo, cThermoeconomicModel
%
    log=cStatus(cType.VALID);
    % Check Input parameters
    if (nargin~=2) || ~cType.checkFileWrite(filename)
        log.printError('Usage: SaveProductiveDiagram(model,filename)');
        return
    end
    if isa(arg,'cThermoeconomicModel') || isa(arg,'cResultInfo')
        log=saveProductiveDiagram(arg,filename);
        printLogger(log);
    else
        log.printError('Invalid result info. It sould be a cThermoeconomicModel or cResultInfo object');
    end
end