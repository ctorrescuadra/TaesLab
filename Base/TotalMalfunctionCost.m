function tbl = TotalMalfunctionCost(res)
% TotalMalfunctionCost shows a table with the detailed breakdown
% of the total malfunction cost index
%   Usage: 
%       TotalMalfunctionCost(res)
%   Input:
%       res - cResultInfo with diagnosis information
%   Output:
%       tbl - cTableMatrix with the results
% See also cDiagnosis
%
    % Check Parameters
    tbl=cStatus();
    if ~isa(res,'cResultInfo')
        tbl.printError('Invalid input argument');
        return
    end
    dgn=res.Info;
    if ~isa(dgn,'cDiagnosis')
        tbl.printError('Invalid input argument');
        return
    end
    % Retrieve information
    M=3;
    N=dgn.NrOfProcesses+1;
    data=zeros(N,M);
    data(:,1)=dgn.getMalfunctionCost';
    data(:,2)=dgn.getWasteMalfunctionCost';
    data(:,3)=dgn.getDemmandCorrectionCost';
    % Build the results table
    rowNames=res.Tables.dgn.RowNames;
    colNames={'Key','MF*','MR*','MPt*'};
    p.Format='%11.3f';
    p.Unit='(kW)';
    p.rowTotal=false;
    p.colTotal=true;
    p.key='tmfc';
    p.Description='Total Malfunction Cost';
    p.GraphType=0;
    p.GraphOptions=0;
    tbl=cTableMatrix.create(data,rowNames,colNames,p);
    res.summaryDiagnosis;
    printTable(tbl);
end