function model=ThermoeconomicModel(filename,varargin)
%ThermoeconomicModel - Create a cThermoeconomicModel object from a data model file 
%   This function creates a cThermoeconomicModel object. Once the object is created, all the
%   public methods of the class could be used, allowing interactively obtaining all
%   the results of a thermoeconomic analysis.
%
% Syntax
%   model = ThermoeconomicModel(filename,Name,Value)
%
% Input Arguments
%   filename - Name of the file with the data mode
%
% Name-Value Arguments
%   ReferenceState - Reference state name. If it is not defined, first state is taken.
%     char array | string
%   State - Operation state name. If it is not defined, first state is taken.  
%     char array | string
%   ResourceSample - Resource Sample name. If it is not defined, first sample is taken
%     char array | string
%   CostTables - Cost Tables output
%     'DIRECT' Direct Exergy Cost Tables only
%     'GENERALIZED' Generalized Cost Tables only
%     'ALL' - Both direct and generalized are obtained
%   DiagnosisMethod - Diagnosis method to allocate wastes
%     'NONE' - Deactivate diagnosis
%     'WASTE_EXTERNAL' Consider waste as output
%     'WASTE_INTERNAL' Allocate waste increase to productive processes 
%   ActiveWaste - Name of the active waste flow for analysis. If it is not defined, first state is taken.
%     char array | string
%   Summary - Get the Summary Results if available
%     'NONE' No summary are required
%     'STATES' Get States summary
%     'RESOURCES' Get Resources Results
%     'ALL' Get both kind of summaries
%   Recycling - Activate Recycling Analysis
%     true | false (default)    
%   Debug - Print Debug information during execution
%     true | false (default)
%
% Output Argument
%   model - cThermoeconomicModel object
%
% Examples
%   <a href="matlab:open ThermoeconomicModelDemo.mlx">Thermoeconomic Model Demo</a>
%    
% See also cThermoeconomicModel
%
    model=cMessageLogger();
    % Check input parameters
    if (nargin<1) || ~isFilename(filename)
        model.printError('Invalid data model file name');
        model.printError('Usage: model=ThermoeconomicModel(filename,options)');
        return
    end
    if ~exist(filename,'file')
        model.printError('File %s does NOT exists',filename);
        return
    end
    if isstring(filename)
        filename=convertStringsToChars(filename);
    end
    % Check Data Model file
        data=readModel(filename);
        sopt=cSummaryOptions(data);
    % Check optional parameters and create cThermoeconomicModel obeject
    if data.status
        p = inputParser;
        refstate=data.StateNames{1};
        p.addParameter('State',refstate,@ischar);
        p.addParameter('ReferenceState',refstate,@ischar);
        p.addParameter('ResourceSample',cType.EMPTY_CHAR,@ischar);
        p.addParameter('CostTables',cType.DEFAULT_COST_TABLES,@cType.checkCostTables);
        p.addParameter('DiagnosisMethod',cType.DEFAULT_DIAGNOSIS,@cType.checkDiagnosisMethod);
        p.addParameter('Recycling',false,@islogical);
        p.addParameter('ActiveWaste',cType.EMPTY_CHAR,@ischar);
        p.addParameter('Summary',cType.DEFAULT_SUMMARY,@sopt.checkNames);
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