function SaveProductiveDiagram(res,filename)
% SaveProductiveDiagram saves the productive adjacency tables into a file
%   The type of file depends on the file extension
%   *.csv, *.xlsx and *.mat are allowed
%   INPUT:
%       res - cThermoeconomicModel object
%       filename - name of the output file (with extension)
% See also cResultInfo, cThermoeconomicModel
%
    log=cStatus(cType.VALID);
    % Check Input parameters
    if (nargin~=2) || ~cType.checkFileWrite(filename)
        log.printError('Usage: SaveProductiveDiagram(res,filename)');
        return
    end
    if isa(res,'cThermoeconomicModel')
        log=saveProductiveDiagram(res,filename);
        printLogger(log);
    else
        log.printError('Invalid result. It sould be a cThermoeconomicModel object');
    end
end