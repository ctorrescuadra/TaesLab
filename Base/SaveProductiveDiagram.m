function SaveProductiveDiagram(model,filename)
% SaveProductiveDiagram saves the adjacency tables of the productive diagram into a file
%   The type of file depends on the file extension
%   *.csv, *.xlsx and *.mat are allowed
%  USAGE:
%   SaveProductiveDiagram(model,filename)
%  INPUT:
%   model - cThermoeconomicModel or cResultInfo object
%   filename - name of the output file (with extension)
%
% See also cThermoeconomicModel, cProductiveDaiagram
%
    log=cStatus(cType.VALID);
    % Check Input parameters
    if (nargin<2) || ~isText(filename)
        log.printError('Usage: SaveProductiveDiagram(model,filename)');
        return
    end
    if ~isa(model,'cThermoeconomicModel') || ~isValid(model)
        log.printError('Invalid model object');
        return
    end
    if isstring(filename)
        filename=convertStringsToChars(filename);
    end
    log=saveProductiveDiagram(model,filename);
    log.printLogger;
end