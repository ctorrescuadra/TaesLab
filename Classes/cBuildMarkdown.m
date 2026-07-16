classdef (Sealed) cBuildMarkdown < cMessageLogger
%cBuildMarkdown - Convert a cTable object into a Markdown table.
%   cBuildMarkdown generates GitHub-Flavored Markdown (GFM) table syntax
%   from a cTable object.  The constructor parses the table and pre-builds
%   the four fragments (header, separator, body, caption) that are
%   assembled on demand by getMarkdownCode.
%
%   The generated Markdown follows this structure:
%
%     **Description (State)**          <- bold caption (if description exists)
%                                          or plain table name otherwise
%
%     | col1  | col2  | col3  |        <- header row
%     | :---- | ----: | :---- |        <- separator row with alignment
%     | row1  | val   | val   |        <- data rows
%     | row2  | val   | val   |
%
%   Column alignment in the separator row:
%     ':---'  (left-aligned)  for character/string columns
%     '---:'  (right-aligned) for numeric columns
%
%   Column widths are derived from the cTable object so that columns
%   align consistently across header and data rows.
%
%   cBuildMarkdown Methods:
%     cBuildMarkdown  - Construct an instance from a cTable object
%     getMarkdownCode - Return the complete Markdown table as a char string
%     saveTable       - Write the Markdown code to a file
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
        %cBuildMarkdown - Construct an instance from a cTable object
        %   Parses the cTable object and builds the four internal Markdown
        %   fragments stored as private properties:
        %     header    - pipe-delimited row of column names
        %     separator - pipe-delimited alignment row (':---' or '---:')
        %     body      - cell array of pipe-delimited data rows
        %     caption   - bold description label, or plain table name if
        %                 the table has no description
        %   Column widths and format codes are taken from the cTable object
        %   to ensure consistent alignment across header and data rows.
        %   The object status is set to false when tbl is not a cTable.
        %
        %   Syntax:
        %     obj = cBuildMarkdown(tbl)
        %
        %   Input Arguments:
        %     tbl - cTable (or subclass) object to convert to Markdown.
        %
        %   Output Arguments:
        %     obj - cBuildMarkdown object.  Use isValid(obj) to confirm
        %           successful construction before calling other methods.
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
        %getMarkdownCode - Return the complete Markdown table as a char string
        %   Assembles the four pre-built fragments into the full Markdown
        %   block in the order: caption, header, separator, body rows,
        %   followed by a trailing newline.
        %   The caption is omitted when it is empty.
        %
        %   Syntax:
        %     res = obj.getMarkdownCode()
        %
        %   Output Arguments:
        %     res - Char string containing the complete Markdown table,
        %           ready to be embedded in a .md document or displayed
        %           inline.  Returns cType.EMPTY_CHAR if the object is
        %           empty.
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

        function log=saveTable(obj,filename)
        %saveTable - Write the Markdown table code to a file
        %   Opens filename for writing in text mode, writes the full
        %   Markdown string produced by getMarkdownCode, and closes the
        %   file.  All I/O errors are caught and reported through the
        %   returned cMessageLogger rather than propagated as exceptions.
        %
        %   Syntax:
        %     log = obj.saveTable(filename)
        %
        %   Input Arguments:
        %     filename - Path to the output file.  Should use the .md
        %                extension.  The file is created or overwritten.
        %
        %   Output Arguments:
        %     log - cMessageLogger with the operation status.  Check
        %           log.status to verify whether the file was saved.
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