classdef (Sealed) cBuildLaTeX < cMessageLogger
%cBuildLaTeX - Convert a cTable object into a LaTeX table environment.
%   cBuildLaTeX generates self-contained LaTeX code for a single table.
%   The constructor parses the cTable object and pre-builds the five LaTeX
%   fragments (tabular spec, header, body, caption, label) that are
%   assembled on demand by getLaTeXcode.
%
%   The generated code uses the following LaTeX conventions:
%     - table environment with [H] placement (requires float package)
%     - \caption and \label placed before the tabular block
%     - \begin{tabular}{...} with per-column alignment:
%         'l' (left)  for character/string columns
%         'r' (right) for numeric columns
%     - Horizontal rules from the booktabs package:
%         \toprule above the header row
%         \midrule between header and data rows
%         \bottomrule below the last data row
%     - Column names as the header row
%     - Row names as the first cell of each data row
%     - Table description as the \caption text
%     - Table name as the \label key (prefixed with "tab:")
%
%   Required LaTeX packages in the document preamble:
%     \usepackage{booktabs}
%     \usepackage{float}
%
%   cBuildLaTeX Methods:
%     cBuildLaTeX  - Construct an instance from a cTable object
%     getLaTeXcode - Return the complete LaTeX table as a char string
%     saveTable    - Write the LaTeX code to a .tex file
%
%   See also cTable, cBuildHTML, cBuildMarkdown
%
    properties(Access=private)
        tabular  % tabular code - column alignment  
        header   % header code - Colnames
        body     % body code - data 
        caption  % caption code - table description 
        label    % label code - table name
    end

    methods
        function obj=cBuildLaTeX(tbl)
        %cBuildLaTeX - Construct an instance from a cTable object
        %   Parses the cTable object and builds the five internal LaTeX
        %   fragments stored as private properties:
        %     tabular  - column-alignment spec string for \begin{tabular}{...}
        %     header   - header row with column names, separated by " & "
        %     body     - cell array of formatted data rows
        %     caption  - \caption{...} line using the table description
        %     label    - \label{tab:<name>} line using the table name
        %   Column widths and format codes are taken from the cTable object
        %   to ensure consistent alignment between the header and data rows.
        %   The object status is set to false when tbl is not a cTable.
        %
        %   Syntax:
        %     obj = cBuildLaTeX(tbl)
        %
        %   Input Arguments:
        %     tbl - cTable (or subclass) object to convert to LaTeX.
        %
        %   Output Arguments:
        %     obj - cBuildLaTeX object.  Use isValid(obj) to confirm
        %           successful construction before calling other methods.
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
        %getLaTeXcode - Return the complete LaTeX table as a char string
        %   Assembles the five pre-built fragments into a full LaTeX
        %   table environment ready for inclusion in a .tex document:
        %
        %     \begin{table}[H]
        %       \caption{...}   \label{tab:...}
        %       \begin{tabular}{alignment}
        %         \toprule
        %         header row
        %         \midrule
        %         data rows
        %         \bottomrule
        %       \end{tabular}
        %     \end{table}
        %
        %   Syntax:
        %     res = obj.getLaTeXcode()
        %
        %   Output Arguments:
        %     res - Char string containing the complete LaTeX table block,
        %           including a trailing blank line after \end{table}.
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
        %saveTable - Write the LaTeX table code to a file
        %   Opens filename for writing in text mode, writes the full LaTeX
        %   string produced by getLaTeXcode, and closes the file.  All I/O
        %   errors are caught and reported through the returned cMessageLogger
        %   rather than propagated as exceptions.
        %
        %   Syntax:
        %     log = obj.saveTable(filename)
        %
        %   Input Arguments:
        %     filename - Path to the output file.  Should use the .tex
        %                extension.  The file is created or overwritten.
        %
        %   Output Arguments:
        %     log - cMessageLogger with the operation status.  Check
        %           log.status to verify whether the file was saved.
        %
            log=cMessageLogger();
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