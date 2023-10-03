function SaveProductiveDiagram(model,filename)
% SaveProductiveDiagram saves the productive adjacency tables into a file
%   The type of file depends on the file extension
%   *.csv, *.xlsx and *.mat are allowed
%   USAGE:
%       SaveProductiveDiagram(model,filename)
%   INPUT:
%       model - cThermoeconomicModel or cResultInfo object
%       filename - name of the output file (with extension)
% See also cThermoeconomicModel
%
    log=cStatus(cType.VALID);
    % Check Input parameters
    if (nargin<2) || ~ischar(filename) || ~isa(model,'cThermoeconomicModel') 
        log.printError('Usage: SaveProductiveDiagram(model,filename)');
        return
    end
    log=saveProductiveDiagram(model,filename);
    log.printLogger;
end