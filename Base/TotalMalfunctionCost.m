function tbl = TotalMalfunctionCost(arg)
% TotalMalfunctionCost shows a table with the detailed breakdown
% of the total malfunction cost index
%   Usage: 
%       TotalMalfunctionCost(res)
%   Input:
%       arg - cResultSet with diagnosis information
%   Output:
%       tbl - cTableMatrix with the results
% See also cDiagnosis
%
    % Check Parameters
    tbl=cStatus();
    switch arg.classId
    case cType.ClassId.RESULT_INFO
        dgn=arg.Info;
        if ~isa(dgn,'cDiagnosis')
            tbl.printError('Invalid input argument');
            return
        end
        res=arg;
    case cType.ClassId.RESULT_MODEL
        res=arg.thermoeconomicDiagnosis;
        if isempty(res)
            tbl.printError('Invalid input argument');
            return
        end
        dgn=res.Info;
    otherwise
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