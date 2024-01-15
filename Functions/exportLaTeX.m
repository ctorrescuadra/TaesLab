function log=exportLaTeX(tbl,filename)
% exportLaTeX generates the LaTex table code file of cTable object
% USAGE:
%   exportLaTeX(tbl, filename)
% INPUT:
%   tbl - cTable object to convert
%   filename - [Optional] Name of the file.
%       If not specified, use the name of the table as filename.
% See also cTable
%
    % Check Inputs
    log=cStatusLogger(cType.VALID);
    if (nargin~=2) || (~ischar(filename)) || ~isa(tbl,'cTable')
        log.messageLog(cType.ERROR,'Invalid input arguments');
        return
    end
    if ~cType.checkFileWrite(filename)
        log.messageLog(cType.ERROR,'Invalid file name: %s',filename);
        return
    end
    if ~cType.checkFileExt(filename,cType.FileExt.LaTeX)
        log.messageLog(cType.ERROR,'Invalid file name extension: %s',filename)
        return
    end
    % Determine column aligment
    N=tbl.NrOfRows;
    M=tbl.NrOfCols;
    colAlign=[repmat('l',1,M)];
    for j=2:M
        if isNumericColumn(tbl,j-1)
            colAlign(j)='r';
        end
    end
    % Get dinamic text from table
    btab=['\begin{tabular}{',colAlign,'}'];
    header=[strjoin(tbl.ColNames,' & '),'\\'];
    body=cell(N,1);
    fdata=[tbl.RowNames',tbl.formatData];
    for i=1:tbl.NrOfRows 
        body{i}=[strjoin(fdata(i,:),' & '),'\\'];
    end
    % Write the LaTeX code file
    try
        fId = fopen (filename, 'wt');
        fprintf(fId,'%s\n',btab);
        fprintf(fId,'\t%s\n','\toprule');
        fprintf(fId,'\t%s\n',header);
        fprintf(fId,'\t%s\n','\midrule');
        for i=1:N
            fprintf(fId,'\t%s\n',body{i});
        end
        fprintf(fId,'\t%s\n','\bottomrule');
        fprintf(fId,'%s\n','\end{tabular}');
        fclose(fId);
        log.messageLog(cType.INFO,'File %s has been saved',filename);
	catch err
        log.printError(err.message);
        log.messageLog(cType.ERROR,'File %s could NOT be saved',filename);
    end
end