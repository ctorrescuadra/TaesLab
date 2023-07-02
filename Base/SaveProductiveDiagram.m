function SaveProductiveDiagram(model,filename)
% SaveProductiveDiagram saves the productive adjacency tables into a file
%   The type of file depends on the file extension
%   *.csv, *.xlsx and *.mat are allowed
%   USAGE:
%       SaveProductiveDiagram(model,filename)
%   INPUT:
%       model - cThermoeconomicModel object
%       filename - name of the output file (with extension)
% See also cmodelultInfo, cThermoeconomicModel
%
    log=cStatus(cType.VALID);
    % Check Input parameters
    if (nargin~=2) || ~cType.checkFileWrite(filename)
        log.printError('Usage: SaveProductiveDiagram(model,filename)');
        return
    end
    if isa(model,'cThermoeconomicModel')
        log=saveProductiveDiagram(model,filename);
        printLogger(log);
    else
        log.printError('Invalid result model. It sould be a cThermoeconomicModel object');
    end
end