function res=ThermoeconomicDiagnosis(data,varargin)
% Compares an operation state of the plant with the reference state, and get the diagnosis tables
%   USAGE:
%       res=ThermoeconomicDiagnosis(data, options)     
%   INPUT:
% 	    data - cReadModel object containing the thermoeconomic data model
%       options - a structure contains the additional parameters:
%           ReferenceState - Reference State for diagnosis. If not provided first state is used.
%           State - Operation State for diagnosis. If not provided second state is used
%           DiagnosisMethod - Select the method to compute diagnosis
%               WASTE_EXTERNAL: Waste are considered output, and method compute cost variation
%               WASTE_INTERNAL: Waste are allocated to productive units, and method compute Malfunction cost of wastes
%           Show -  Show results on console (true/false)
%           SaveAs - Save results in an external file
%   OUTPUT:
%       res - cResultInfo object contains the results of thermoeconomic diagnosis.
%           It contains the following tables
%               cType.Tables.DIAGNOSIS (dgn)
%               cType.Tables.MALFUNCTION (mf)
%               cType.Tables.MALFUNCTION_COST (mfc)
%               cType.Tables.IRREVERSIBILITY_VARIATION (dit)
% See also cReadModel, cResultInfo, cDiagnosis
%
    res=cStatusLogger();
    % Check input parameters
	checkModel=@(x) isa(x,'cDataModel');
    p = inputParser;
    p.addRequired('data',checkModel);
    p.addParameter('ReferenceState','',@ischar)
	p.addParameter('State','',@ischar);
    p.addParameter('DiagnosisMethod',cType.DEFAULT_DIAGNOSIS,@cType.checkDiagnosisMethod);
    p.addParameter('Show',false,@islogical);
    p.addParameter('SaveAs','',@ischar);
    try
        p.parse(data,varargin{:});
    catch err
        res.printError(err.message);
        res.printError('Usage: ThermoeconomicDiagnosis(data,param)');
        return
    end
    param=p.Results;
    if param.DiagnosisMethod==cType.DiagnosisMethod.NONE
        res.printError('Diagnosis Method is NOT Activated')
        return
    end
    % Read productive structure
    if ~data.isValid
        data.printLogger;
        res.printError('Invalid data model. See Error log');
        return
    end
     % Check if there are two states is defined
    if ~data.isDiagnosis
        data.printLogger;
        res.printError('There is NOT two states defined');
        return
    end
    if isempty(param.ReferenceState)
        param.ReferenceState=data.getStateName(1);
    end
    if isempty(param.State)
        param.State=data.getStateName(2);
    end
    if strcmp(param.ReferenceState,param.State)
        res.printError('Reference and Operation States are the same')
        return
    end
    % Read reference and operation  exergy values
    rex0=data.getExergyData(param.ReferenceState);
    if ~isValid(rex0)
        rex0.printLogger;
        res.printError('Invalid exergy values. See error log');
        return
    end
    rex1=data.getExergyData(param.State);
    if ~isValid(rex1)
        rex1.printLogger;
        res.printError('Invalid exergy values. See error log');
        return
    end
    % Read Waste, compute Model FP
    if  data.isWaste
		wd=data.WasteData;
        fp0=cModelFPR(rex0,wd);
        fp1=cModelFPR(rex1,wd);
    else
        fp0=cModelFPR(rex0);
        fp1=cModelFPR(rex1);
    end
    % Make the thermoeconomic diagnosis
    method=cType.getDiagnosisMethod(param.DiagnosisMethod);
    dgn=cDiagnosis(fp0,fp1,method);
    % Get diagnosis results
    if dgn.isValid
        res=dgn.getResultInfo(data.FormatData);
        res.setProperties(data.ModelName,param.State);
    else
        dgn.printLogger;
        res.printError('Invalid Thermoeconomic Diagnosis. See error log');
    end
    % Show and Save results if required
    if param.Show
        summaryDiagnosis(res);
        printResults(res);
    end
    if ~isempty(param.SaveAs)
        SaveResults(res,param.SaveAs);
    end
end