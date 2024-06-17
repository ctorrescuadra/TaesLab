function res=ThermoeconomicDiagnosis(data,varargin)
%ThermoeconomicDiagnosis - Compare to states of the plant and make a thermoeconomic diagnosis
%	This function makes a thermoeconomic diagnosis of the plant comparing two states 
%   of the plant. Two diferent methods could be used: 'WASTE_EXTERNAL' accounts the increse of
%   of the cost of wastes, and 'WASTE_INTERNAL' internalised the waste cost to the productive
%   processes whose generate them. THe data model must have at least to states defined to 
%   perform the analysis
% 
%	Syntax
%	  res = ThermoeconomicDiagnosis(data,Name,Value)
% 
%   Input Arguments
%     data - cReadModel object containing the data information
%    
%   Name-Value Arguments
%     Reference State - Reference State. If not provided first state is used
%       char array
%     State - State to compare. If not provided second state is used
%		char array
%     DiagnosisMethod - Select the method to compute diagnosis
%       'WASTE_EXTERNAL' Waste are considered output, and method compute waste cost variation
%       'WASTE_INTERNAL' Waste are allocated to productive units, and method compute Malfunction cost of wastes
%     Show -  Show the results on console.  
%       true | false (default)
%     SaveAs - Name of file (with extension) to save the results.
%       char array | string
% 
%   Output Arguments
%     res - cResultsInfo object contains the results of the thermoeconomic diagnosis for the required state
%     The following tables are obtained:
%		dgn - diagnosis summary table
%       mf - malfunction table
%       mfc - malfunction cost table
%       dit - irreversibility variation
%
%   Example
%     <a href="matlab:open ThermoeconomicDiagnosisDemo.mlx">Thermoeconomic Diagnosis Demo</a>
%
%   See also cDataModel, cDiagnosis, cResultInfo
%
    res=cStatus();
    % Check input parameters
	checkModel=@(x) isa(x,'cDataModel');
    p = inputParser;
    p.addRequired('data',checkModel);
    p.addParameter('ReferenceState',data.getStateName(1),@ischar)
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
    % Check data model
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
        fp0=cExergyCost(rex0,wd);
        fp1=cExergyCost(rex1,wd);
    else
        fp0=cExergyCost(rex0);
        fp1=cExergyCost(rex1);
    end
    % Execute thermoeconomic diagnosis
    method=cType.getDiagnosisMethod(param.DiagnosisMethod);
    dgn=cDiagnosis(fp0,fp1,method);
    % Get diagnosis results
    if dgn.isValid
        res=dgn.getResultInfo(data.FormatData);
    else
        dgn.printLogger;
        res.printError('Invalid Thermoeconomic Diagnosis. See error log');
    end
    if ~isValid(res)
		res.printLogger;
        res.printError('Invalid cResultInfo. See error log');
		return
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