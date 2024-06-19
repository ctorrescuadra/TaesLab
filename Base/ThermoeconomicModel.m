function model=ThermoeconomicModel(filename,varargin)
%ThermoeconomicModel - Create a cThermoeconomicModel object from a data model file 
%   This function creates a cThermoeconomicModel object containing all the needed information
%   to perform a thermo-economic analysis of a plant.
%   The class cThermoeconomicModel is the kernel of TaesLab and it has a set of methods
%   that allow interactively obtaining all the results of a thermoeconomic analysis.
%
%   Syntax
%     model = ThermoeconomicModel(filename,Name,Value)
%
%   Input Arguments
%     filename - Name of the file with the data mode
%
%   Name-Value Arguments
%     ReferenceState - Reference state name. If it is not defined, first state is taken.
%       char array | string
%     State - Operation state name. If it is not defined, first state is taken.  
%       char array | string
%     ResourceSample - Resource Sample name. If it is not defined, first sample is taken
%       char array | string
%     CostTables - Cost Tables output
%       'DIRECT' Direct Exergy Cost Tables only
%       'GENERALIZED' Generalized Cost Tables only
%       'ALL' - Both direct and generalized are obtained
%     DiagnosisMethod - Diagnosis method to allocate wastes
%       'NONE' - Deactivate diagnosis
%       'WASTE_EXTERNAL' Consider waste as output
%       'WASTE_INTERNAL' Allocate waste increase to productive processes 
%     ActiveWaste - Name of the active waste flow for analysis. If it is not defined, first state is taken.
%       char array | string
%     Recycling - Activate Recycling Analysis
%       true | false (default)    
%     Summary - Activate Summary Results
%       true | false (default)
%     Debug - Print Debug information during execution
%       true | false (default)
%
%   Output Argument
%     model - cThermoeconomicModel object
%
%   Examples
%     <a href="matlab:open ThermoeconomicModelDemo.mlx">Thermoeconomic Model Demo</a>
%    
%   See also cThermoeconomicModel
%
    model=cStatus(cType.VALID);
    % Check input parameters
    if (nargin<1) || ~isText(filename)
        model.printError('Usage: model=ThermoeconomicModel(filename, params)');
        return
    end
    if isstring(filename)
        filename=convertStringsToChars(filename);
    end
    if ~cType.checkFileRead(filename)
        model.printError('File %s does not exist',filename);
        return
    end
    % Check Data Model file
        data=checkDataModel(filename);
    % Check optional parameters and create cThermoeconomicModel obeject
    if isValid(data)
        p = inputParser;
        refstate=data.getStateNames(1);
        p.addParameter('State',refstate,@ischar);
        p.addParameter('ReferenceState',refstate,@isText);
        p.addParameter('ResourceSample','',@ischar);
        p.addParameter('CostTables',cType.DEFAULT_COST_TABLES,@cType.checkCostTables);
        p.addParameter('DiagnosisMethod',cType.DEFAULT_DIAGNOSIS,@cType.checkDiagnosisMethod);
        p.addParameter('Recycling',false,@islogical);
        p.addParameter('ActiveWaste','',@ischar);
        p.addParameter('Summary',false,@islogical);
        p.addParameter('Debug',true,@islogical);
        try
            p.parse(varargin{:});
        catch err
            model.printError(err.message);
            model.printError('Usage: ThermoeconomicModel(filename, params)');
            return
        end
        if p.Results.Debug
            data.printLogger;
        end
        model=cThermoeconomicModel(data,p.Results);
    else
        data.printLogger;
    end
end