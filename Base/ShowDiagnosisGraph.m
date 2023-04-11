function ShowDiagnosisGraph(arg,graph)
% ShowDiagnosisGraph shows a barplot of the irreversibility-cost tables
%   INPUT
%	    arg: cResultInfo or cThermoeconomicModel object   
%       graph - type of graph to plot
%           cType.Graph.MALFUNCTION (mf)
%           cType.Graph.MALFUNCTION_COST (mfc)
%           cType.Graph.IRREVERSIBILITY (dit)
%
    log=cStatusLogger();
    % Check Input Parameters
    if (nargin==1)
        graph=cType.Tables.MALFUNCTION_COST;
    end
    if ~(isa(arg,'cResultInfo') || isa(arg,'cThermoeconomicModel'))
        log.printError('Invalid model. It sould be a cResultInfo or cThermoeconomicModel object');
        return
    end
    % Show the plot
    log=graphDiagnosis(arg,graph);
    printLogger(log);
end
