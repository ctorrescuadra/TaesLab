function sol=ThermoeconomicDiagnosis(model,varargin)
% ThermoeconomicDiagnosis Compares a thermoeconomic state with reference state, and get the diagnosis tables
%   INPUT:
% 	    model - cReadModel object containing the thermoeconomic data model
%       varargin - an optional structure contains additional parameters:
%           ReferenceState - Reference State for diagnosis. If not provided first state is used.
%           State - Operation State for diagnosis. If not provided second state is used
%           DiagnosisMethod - Select the method to compute diagnosis
%               WASTE_OUTPUT: Waste are considered output, and method compute cost variation
%               WASTE_INTERNAL: Waste are allocated to productive units, and method compute Malfunction cost of wastes
%   OUTPUT:
%   res - cResultInfo object contains the results of thermoeconomic diagnosis.
% See also cDiagnosis, cReadModel, cResultInfo
%
    sol=cStatusLogger();
    % Check input parameters
	checkModel=@(x) isa(x,'cReadModel');
    p = inputParser;
    p.addRequired('model',checkModel);
    p.addParameter('ReferenceState','',@ischar)
	p.addParameter('State','',@ischar);
    p.addParameter('DiagnosisMethod',cType.DEFAULT_DIAGNOSIS,@cType.checkDiagnosisMethod);
    try
        p.parse(model,varargin{:});
    catch err
        sol.printError(err.message);
        sol.printError('Usage: ExergyCostCalculator(model,param)');
        return
    end
    param=p.Results;
    if param.DiagnosisMethod==cType.Diagnosis.NONE
        sol.printError('Diagnosis Method is NOT Activated')
        return
    end
    % Read productive structure
    if ~model.isValid
        model.printLogger;
        model.printError('Invalid data model. See Error log');
        return
    end
     % Check if there are two states is defined
    if ~model.isDiagnosis
        model.printLogger;
        model.printError('There is NOT two states defined');
        return
    end
    if isempty(param.ReferenceState)
        param.ReferenceState=model.getStateName(1);
    end
    if isempty(param.State)
        param.State=model.getStateName(2);
    end
    if strcmp(param.ReferenceState,param.State)
        sol.printError('Reference and Operation States are the same')
        return
    end
	% Read print formatted configuration
    fmt=model.readFormat;
	if fmt.isError
		fmt.printLogger;
		sol.printError('Format Definition is NOT correct. See error log');
		return
	end	
    % Read reference and operation  exergy values
    rex0=model.readExergy(param.ReferenceState);
    if ~rex0.isValid
        rex0.printLogger;
        sol.printError('Invalid Reference State values. See error log');
        return
    end
    rex1=model.readExergy(param.State);
    if ~rex1.isValid
        rex1.printLogger;
        sol.printError('Invalid Operation State values. See error log');
        return
    end
    % Read Waste, compute Model FP and make diagnosis
    fp0=cModelFPR(rex0);
    fp1=cModelFPR(rex1);
    pdm=cType.getDiagnosisMethod(param.DiagnosisMethod);
    if  (model.isWaste) && (pdm==cType.Diagnosis.WASTE_INTERNAL)
		wt=model.readWaste;
        if ~wt.isValid
            wt.printLogger;
            sol.printError('Invalid waste definition. See error log');
            return
        end
        fp0.setWasteOperators(wt)
        fp1.setWasteOperators(wt)
        dgn=cDiagnosisR(fp0,fp1);
    else
        dgn=cDiagnosis(fp0,fp1);
    end
    % Get diagnosis results
    if dgn.isValid
        sol=getDiagnosisResults(fmt,dgn);
        sol.setProperties(model.ModelName,param.State);
    else
        dgn.printLogger;
        sol.printError('Invalid diagnosis analysis. See error log');
    end
end