function res=ThermoeconomicDiagnosis(data,varargin)
%ThermoeconomicDiagnosis - Compare two states of the plant and make a thermoeconomic diagnosis
%   This function makes a thermoeconomic diagnosis of the plant, comparing two plant states. 
%   Two different methods could be used to analyze the increase in waste generation: 
%   'WASTE_EXTERNAL' accounts for the waste cost increase, and
%   'WASTE_INTERNAL' internalises the waste costs to the productive processes that generate them. 
%   The data model must have at least two states defined to perform the analysis.
% 
%   Syntax:
%	  res = ThermoeconomicDiagnosis(data,Name,Value)
% 
%   Input Arguments:
%     data - cReadModel object containing the data information
%    
%   Name-Value Arguments:
%     Reference State - Reference State. If not provided first state is used
%       char array
%     State - State to compare. If not provided second state is used
%       char array
%     DiagnosisMethod - Select the method to compute diagnosis
%       'WASTE_EXTERNAL' Waste are considered output, and method compute waste cost variation
%       'WASTE_INTERNAL' Waste are allocated to productive units, and method compute Malfunction cost of wastes
%     Show -  Show the results on console.  
%       true | false (default)
%     SaveAs - Name of file (with extension) to save the results.
%     char array | string
% 
%   Output Arguments:
%     res - cResultsInfo object contains the results of the thermoeconomic diagnosis for the required state
%      The following tables are obtained:
%       dgn - diagnosis summary table
%        mf - malfunction table
%       mfc - malfunction cost table
%       dit - irreversibility variation
%      tmfc - total malfunction cost
%       dft - Fuel Impact
%
%   Example:
%     <a href="matlab:open ThermoeconomicDiagnosisDemo.mlx">Thermoeconomic Diagnosis Demo</a>
%
%   See also cDataModel, cDiagnosis, cResultInfo

    % Initialize and validate input parameters
    res=cTaesLab();
	if nargin <1 || ~isObject(data,'cDataModel')
		res.printError(cMessages.DataModelRequired,cMessages.ShowHelp);
		return
	end
    % Check optional input parameters
    p = inputParser;
    p.addParameter('ReferenceState',data.StateNames{1},@data.existState)
	p.addParameter('State',cType.EMPTY_CHAR,@ischar);
    p.addParameter('DiagnosisMethod',cType.DEFAULT_DIAGNOSIS,@cType.checkDiagnosisMethod);
    p.addParameter('Show',false,@islogical);
    p.addParameter('SaveAs',cType.EMPTY_CHAR,@isFilename);
    try
        p.parse(varargin{:});
    catch err
        res.printError(err.message);
        return
    end
    % Validate parameters
    param=p.Results;
    if ~data.isDiagnosis
        res.printError(cMessages.DiagnosisNotAvailable);
        return
    end
    if ~cType.getDiagnosisMethod(param.DiagnosisMethod)
        res.printError(cMessages.DiagnosisNotAvailable);
        return
    end
    if isempty(param.State)
        param.State=data.StateNames{2};
    elseif ~data.existState(param.State)
        res.printError(cMessages.InvalidStateName,param.State);
        return
    end
    if strcmp(param.ReferenceState,param.State)
        res.printError(cMessages.InvalidDiagnosisState)
        return
    end
    % Read reference and operation  exergy values
    rex0=data.getExergyData(param.ReferenceState);
    if ~rex0.status
        res.printError(cMessages.InvalidExergyData,param.ReferenceState);
        return
    end
    rex1=data.getExergyData(param.State);
    if ~rex1.status
        res.printError(cMessages.InvalidExergyData,param.State);
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
    if dgn.status
        res=dgn.buildResultInfo(data.FormatData);
    else
        dgn.printLogger;
        res.printError(cMessages.InvalidObject,class(dgn));
        return
    end
    if ~res.status
		res.printLogger;
        res.printError(cMessages.InvalidObject,class(res));
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