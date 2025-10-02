classdef (Sealed) cBuildLaTeX < cMessageLogger
%cBuildLaTeX - Convert cTable object into a LaTeX code table.
%   The LaTeX code includes:
%    - table environment
%    - booktabs package
%    - tabular column aligment
%    - Column Names as header
%    - Row Names and Data as body
%    - Table Description as caption code
%    - Table name as label code
% 
%   cBuildLaTeX constructor:
%     obj = cBuildLaTeX(tbl)
%
%   cBuildLateX methods:
%     getLaTeXcode - Get a string with the LaTeX code
%     saveTable    - Save the table into a tex file
%
%   See also cTable
%
    properties(Access=private)
        tabular  % tablular code - column aligment  
        header   % header code - Colnames
        body     % body code - data 
        caption  % caption code - table description 
        label    % label code - table name
    end

    methods
        function obj=cBuildLaTeX(tbl)
        %cBuildLaTex - Create an instance of the class
        %   Syntax:
        %     obj = cBuildLaTeX(tbl)
        %   Input Argument:
        %     tbl - cTable object
        %   Output Argument:
        %     obj - cBuildLaTeX object
        %
            if ~isObject(tbl,'cTable')
                obj.messageLog(cType.ERROR,cMessages.InvalidArgument);
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
            obj.body=arrayfun(@(i) sprintf('\t\t%s\n',[strjoin(fdata(i,:),' & '),'\\']),1:N,'UniformOutput',false);
        end

        function res=getLaTeXcode(obj)
        %getLaTeXcode - Get the LaTeX code as string
        %   Syntax:
        %     res=obj.getLaTeXcode()
        %   Output Argument:
        %     res - text string with the LaTeX code
        %
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
        %saveTable - Save the table as LaTeX code into filename
        %   Syntax:
        %     log=obj.saveTable(filename);
        %   Input Arguments:
        %     filename - Name of the file
        %   Output Arguments:
        %     log - cMessageLogger object with status and messages
            log=cMessageLogger;
            try
                fId = fopen (filename, 'wt');
                fprintf(fId,'%s',obj.getLaTeXcode);
                fclose(fId);
            catch err
                log.message(err.message);
                log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
            end
        end
    end
end