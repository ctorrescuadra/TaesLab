function res=ThermoeconomicDiagnosis(model,varargin)
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
    res=cStatusLogger();
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
        res.printError(err.message);
        res.printError('Usage: ExergyCostCalculator(model,param)');
        return
    end
    param=p.Results;
    if param.DiagnosisMethod==cType.Diagnosis.NONE
        res.printError('Diagnosis Method is NOT Activated')
        return
    end
    % Read productive structure
    if ~model.isValid
        model.printLogger;
        res.printError('Invalid data model. See Error log');
        return
    end
     % Check if there are two states is defined
    if ~model.isDiagnosis
        model.printLogger;
        res.printError('There is NOT two states defined');
        return
    end
    if isempty(param.ReferenceState)
        param.ReferenceState=model.getStateName(1);
    end
    if isempty(param.State)
        param.State=model.getStateName(2);
    end
    if strcmp(param.ReferenceState,param.State)
        res.printError('Reference and Operation States are the same')
        return
    end
	% Read print formatted configuration
    fmt=model.readFormat;
	if fmt.isError
		fmt.printLogger;
		res.printError('Format Definition is NOT correct. See error log');
		return
	end	
    % Read reference and operation  exergy values
    rex0=model.readExergy(param.ReferenceState);
    if ~rex0.isValid
        rex0.printLogger;
        res.printError('Invalid Reference State values. See error log');
        return
    end
    rex1=model.readExergy(param.State);
    if ~rex1.isValid
        rex1.printLogger;
        res.printError('Invalid Operation State values. See error log');
        return
    end
    pdm=cType.getDiagnosisMethod(param.DiagnosisMethod);
    % Read Waste, compute Model FP and make diagnosis
    if  (model.isWaste)  && (pdm==cType.Diagnosis.WASTE_INTERNAL)
		wd=model.readWaste;
        if ~wd.isValid
            wd.printLogger;
            res.printError('Invalid waste definition. See error log');
            return
        end
        fp0=cModelFPR(rex0,wd);
        fp1=cModelFPR(rex1,wd);
        dgn=cDiagnosisR(fp0,fp1);
    else
        fp0=cModelFPR(rex0);
        fp1=cModelFPR(rex1);
        dgn=cDiagnosis(fp0,fp1);
    end
    % Get diagnosis results
    if dgn.isValid
        res=getDiagnosisResults(fmt,dgn);
        res.setProperties(model.ModelName,param.State);
    else
        dgn.printLogger;
        res.printError('Invalid diagnosis analysis. See error log');
    end
end