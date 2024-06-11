classdef (Sealed) cBuildLaTeX < cStatusLogger
% cBuildHTML convert cTable object into HTML files
%   If a cTableIndexobject is provided create a index table
%   which indicate where are saved the HTML files of the cResultInfo tables. 
%   Methods:
%       obj=cBuildLaTeX(tbl)
%       obj.printTable(fId)
%       log=obj.saveTable(filename)
%
    properties(Access=private)
        tabular  % tablular code - column aligment  
        header   % header code - Colnames
        body     % body code -data 
        caption  % caption code -table description 
        label    % label code - table name
    end

    methods
        function obj=cBuildLaTeX(tbl)
        % Create an instance of the class
        %   Input:
        %       tbl - cTable object

            obj=obj@cStatusLogger(cType.VALID);
            if ~isa(tbl,'cTable')
                obj.messageLog(cType.ERROR,'Invalid input argument');
                return
            end
            N=tbl.NrOfRows;
            M=tbl.NrOfCols;
            wc=tbl.getColumnWidth;
            fc=tbl.getColumnFormat;
            fdata=[tbl.RowNames',tbl.formatData];
            fcols=cell(1,M);
            % Get formatted data and column Aligment
            colAlign=[repmat('l',1,M)];
            for j=1:M
                if fc(j)==cType.ColumnFormat.NUMERIC
                    colAlign(j)='r';
                    fmt=['%',num2str(wc(j)),'s'];
                    fcols{j}=sprintf(fmt,tbl.ColNames{j});
                else
                    fmt=['%-',num2str(wc(j)),'s'];
                    fcols{j}=sprintf(fmt,tbl.ColNames{j});
                    tmp=fdata(:,j);
                    fdata(:,j)=cellfun(@(x) sprintf(fmt,x),tmp,'UniformOutput',false);
                end
            end
            % Get dinamic text from table
            obj.tabular=['\begin{tabular}{',colAlign,'}'];
            obj.header=[strjoin(fcols,' & '),'\\'];
            obj.caption=['\caption{',tbl.getDescriptionLabel,'}'];
            obj.label=['\label{tab:',tbl.Name,'}'];
            val=cell(N,1);
            for i=1:tbl.NrOfRows
                val{i}=sprintf('\t\t%s\n',[strjoin(fdata(i,:),' & '),'\\']);
            end
            obj.body=val;
        end

        function res=getLaTeXcode(obj)
        % Get the latex code as string
            res=sprintf('%s\n','\begin{table}[H]');
            res=[res,sprintf('%s\n',obj.caption)];
            res=[res,sprintf('%s\n',obj.label)];
            res=[res,sprintf('\t%s\n',obj.tabular)];
            res=[res,sprintf('\t\t%s\n','\toprule')];
            res=[res,sprintf('\t\t%s\n',obj.header)];
            res=[res,sprintf('\t\t%s\n','\midrule')];
            res=[res,[obj.body{:}]];
            res=[res,sprintf('\t\t%s\n','\bottomrule')];
            res=[res,sprintf('\t%s\n','\end{tabular}')];
            res=[res,sprintf('%s\n\n','\end{table}')];
        end

        function log=saveTable(obj,filename)
        % Save the table as LaTeX code into filename
        %   Usage:
        %       obj.exportTable(filename);
        %   Input:
        %       filename - Name of the file
            log=cStatusLogger;
            try
                fId = fopen (filename, 'wt');
                fprintf(fId,'%s',obj.getLaTeXcode);
                fclose(fId);
            catch err
                log.message(err.message);
                log.messageLog(cType.ERROR,'File %s could NOT be saved',filename);
            end
        end
    end
end