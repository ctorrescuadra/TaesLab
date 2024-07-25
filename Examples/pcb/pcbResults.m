function pcbResults(inputFile,outputFile)
%pcbResults Summary of generalized cost for pcb_model
%   Usage:
%     pcbResults pcb_model20.xlsx pcb_results20.xlsx
%
    model=ThermoeconomicModel(inputFile,'Debug',false,'CostTables','GENERALIZED','DiagnosisMethod','NONE');
    states=model.StateNames;
    samples=model.SampleNames;
    rowNames=model.productiveStructure.Info.FlowKeys;
    colNames=['key',samples];
    M=model.DataModel.NrOfSamples;
    N=model.DataModel.NrOfFlows;
    L=model.DataModel.NrOfStates;
    idx=model.productiveStructure.Info.getFlowTypes(cType.Flow.OUTPUT);
    res=zeros(N,M);
    for i=1:L
        model.State=states{i};
        for j=1:M
            model.ResourceSample=samples{j};
            tbl=model.getTable('gfcost');
            res(:,j)=tbl.getColumnValues('C');
        end
        values=[colNames;[rowNames(idx)',num2cell(res(idx,:))]];
        writecell(values,outputFile,'Sheet',states{i});
    end
    model.printInfo('Results have been saved in file %s',outputFile);
end