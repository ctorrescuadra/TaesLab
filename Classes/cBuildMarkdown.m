classdef (Sealed) cBuildMarkdown < cMessageLogger
%cBuildMarkdown - Convert cTable object into a Markdown code table.
%   The Markdown code includes:
%    - Table header with column names
%    - Table separator row with alignment
%    - Table body with row names and data
%    - Optional table caption/description
%    - Proper column alignment (left, center, right)
%
%   cBuildMarkdown methods:
%     cBuildMarkdown    - Create an instance of the class
%     getMarkdownCode   - Get a string with the Markdown code
%     saveTable         - Save the table into a markdown file
%
%   See also cTable, cBuildLaTeX, cBuildHTML
%
    properties(Access=private)
        header      % header code - column names
        separator   % separator code - alignment definition
        body        % body code - data rows
        caption     % caption code - table description
    end

    methods
        function obj=cBuildMarkdown(tbl)
        %cBuildMarkdown - Create an instance of the class
        %   Syntax:
        %     obj = cBuildMarkdown(tbl)
        %   Input Arguments:
        %     tbl - cTable object
        %   Output Arguments:
        %     obj - cBuildMarkdown object
        %
            if ~isObject(tbl,'cTable')
                obj.messageLog(cType.ERROR,cMessages.InvalidArgument);
                return
            end
            % Initialize variables
            N=tbl.NrOfRows;
            M=tbl.NrOfCols;
            fc=tbl.getColumnFormat;
            wc=tbl.getColumnWidth;
            fdata=[tbl.RowNames',tbl.formatData];
            fcols = cell(1, M);
            separators = cell(1, M);
            obj.body = cell(N, 1);
            % Build headers and separator depending column type
            for j=1:M
                dash=repmat('-',1,wc(j)-1);
                % Right align for numeric / left align for text
                if fc(j)==cType.ColumnFormat.NUMERIC  
                    fmt=['%',num2str(wc(j)),'s'];
                    separators{j} = [dash,':']; 
                else
                    fmt=['%-',num2str(wc(j)),'s'];
                    separators{j} = [':',dash];
                    tmp=fdata(:,j);
                    fdata(:,j)=cellfun(@(x) sprintf(fmt,x),tmp,'UniformOutput',false);
                end
                fcols{j}=sprintf(fmt,tbl.ColNames{j});
            end
            obj.header = ['| ', strjoin(fcols, ' | '), ' |'];
            obj.separator = ['| ', strjoin(separators, ' | '), ' |'];          
            % Build body rows
            for i=1:N
                rowData = fdata(i,:);
                obj.body{i} = ['| ', strjoin(rowData, ' | '), ' |',newline];
            end            
            % Build caption if description exists
            if ~isempty(tbl.Description)
                obj.caption = ['**', tbl.getDescriptionLabel, '**'];
            else
                obj.caption = tbl.Name;
            end
        end

        function res=getMarkdownCode(obj)
        %getMarkdownCode - Get the Markdown code as string
        %   Syntax:
        %     res=obj.getMarkdownCode()
        %   Output Arguments:
        %     res - text string with the Markdown code
        %
            res = cType.EMPTY_CHAR;         
            % Add caption if it exists
            if ~isempty(obj.caption)
                res = [res, obj.caption, newline, newline];
            end           
            % Add header
            res = [res, obj.header, newline];
            % Add separator
            res = [res, obj.separator, newline];
            % Add body rows
            res=[res,[obj.body{:}]];
            % Add final newline
            res = [res, newline];
        end

        function showTable(obj)
        %saveTable - Show the table as Markdown code
        %   Syntax:
        %     showTable(obj);
        %
            disp(obj.getMarkdownCode);
        end

        function log=saveTable(obj,filename)
        %saveTable - Save the table as Markdown code into filename
        %   Syntax:
        %     log=obj.saveTable(filename);
        %   Input Arguments:
        %     filename - Name of the file (should have .md extension)
        %   Output Arguments:
        %     log - cMessageLogger object with status and messages
        %
            log=cMessageLogger();
            try
                fId = fopen(filename, 'wt');
                fprintf(fId,'%s',obj.getMarkdownCode);
                fclose(fId);
            catch err
                log.messageLog(cType.ERROR,err.message);
                log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
            end
        end
    end
end