function model=ThermoeconomicTool(filename,varargin)
% Create a cThermoeconomicModel object from a data model file
%   USAGE:
%       model = ThermoeconomicTool(filename, options)
%   INPUT:
%   filename - data model filename
%   options - optional parameters
%       State: Operation state name
%       ReferenceState: Reference State name
%       ResourceSample: Resource Sample name
%       CostTables - Cost Tables output
%           DIRECT - Direct Exergy Cost Tables only
%           GENERALIZED - Generalized Cost Tables only
%           ALL - Both direct and generalized
%       DiagnosisMethod - Diagnosis method to allocate wastes
%           NONE - Deactivate diagnosis
%           WASTE_EXTERNAL - Consider waste as output
%           WASTE_INTERNAL - Allocate waste increase to productive processes 
%       Summary - Activate Summary Results
%       Debug - Print Debug information during execution
%  OUTPUT:
%   model - cThermoeconomicModel object
%  See also cThermoeconomicModel
%
    model=cStatusLogger();
    % Check input parameters
    if (nargin<1) || ~ischar(filename)
        model.printError('Usage: model=ThermoeconomicModel(filename,params)');
        return
    end
    if ~cType.checkFileRead(filename)
        model.printError('File %s does not exist',filename);
        return
    end
    % Check Data Model file
    data=CheckDataModel(filename);
    % Check optional parameters and create cThermoeconomicModel obeject
    if isValid(data)
        p = inputParser;
        p.addParameter('State',data.States{1},@ischar);
        p.addParameter('ReferenceState',data.States{1},@ischar)
        p.addParameter('ResourceSample','',@ischar);
        p.addParameter('CostTables',cType.DEFAULT_COST_TABLES,@cType.checkCostTables);
        p.addParameter('DiagnosisMethod',cType.DEFAULT_DIAGNOSIS,@cType.checkDiagnosisMethod);
        p.addParameter('Summary',false,@islogical)
        p.addParameter('Debug',true,@islogical);
        try
            p.parse(varargin{:});
        catch err
            model.printError(err.message);
            model.printError('Usage: ThermoeconomicTool(model_file,param)');
            return
        end
        model=cThermoeconomicModel(data,p.Results);
    end
end