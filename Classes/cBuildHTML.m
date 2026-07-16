classdef (Sealed) cBuildHTML < cMessageLogger
%cBuildHTML - Convert a cTable or cTableIndex object into an HTML document.
%   cBuildHTML operates in two modes depending on the type of table passed
%   to the constructor:
%
%   Normal table mode  (cTable input):
%     Generates a self-contained HTML page containing a single styled
%     table.  The page embeds the project CSS from the config folder so
%     it renders consistently without external resources.
%
%   Index table mode  (cTableIndex input + folder argument):
%     Generates an HTML index page whose rows link to the individual HTML
%     files of the tables listed in the cTableIndex.  Each link points to
%     <folder>/<RowName>.html and opens in a new browser tab.
%
%   In both modes the resulting HTML string is available via getMarkupHTML.
%   Normal tables can additionally be previewed in the system browser with
%   showTable, or written to disk with saveTable.
%
%   cBuildHTML Methods:
%     cBuildHTML    - Construct an instance from a cTable or cTableIndex
%     getMarkupHTML - Return the complete HTML document as a char string
%     showTable     - Preview the table in the default web browser
%     saveTable     - Write the HTML document to a file
%
%   See also cTable, cTableIndex, cResultInfo
%
    properties (Access=private)
        head         % HTML head
        body         % HTML body
        isIndexTable % tbl is a index table
    end
    
    methods
        function obj=cBuildHTML(tbl,folder)
        %cBuildHTML - Construct an instance from a cTable or cTableIndex object
        %   Validates the input, determines the operating mode, and builds
        %   the HTML head and body strings that compose the final document.
        %   The object status is set to false when tbl is not a cTable.
        %
        %   Syntax:
        %     obj = cBuildHTML(tbl)
        %     obj = cBuildHTML(tbl, folder)
        %
        %   Input Arguments:
        %     tbl    - cTable (or subclass) object to render as HTML.
        %              When tbl is a cTableIndex and folder is provided,
        %              index mode is activated (see class description).
        %     folder - (optional) Relative or absolute folder path used to
        %              build the href links in index mode.  Ignored when
        %              tbl is not a cTableIndex.
        %
        %   Output Arguments:
        %     obj    - cBuildHTML object.  Use isValid(obj) to confirm
        %              successful construction before calling other methods.
        %
            if ~isObject(tbl,'cTable')
                obj.messageLog(cType.ERROR,cMessages.InvalidArgument);
                return
            end
            obj.isIndexTable=isa(tbl,'cTableIndex') && (nargin==2);
            obj.head=cBuildHTML.buildHead(tbl);
            if obj.isIndexTable
                obj.body=cBuildHTML.buildIndexBody(tbl,folder);
            else
                obj.body=cBuildHTML.buildTableBody(tbl);
            end
        end

        function res=getMarkupHTML(obj)
        %getMarkupHTML - Return the complete HTML document as a char string
        %   Concatenates the pre-built head and body sections into a full
        %   HTML document (<!DOCTYPE html> ... </html>) ready for display
        %   or file output.
        %
        %   Syntax:
        %     res = obj.getMarkupHTML()
        %
        %   Output Arguments:
        %     res - Char string containing the complete HTML document.
        %
            res=[obj.head,obj.body];
        end

        function showTable(obj)
        %showTable - Preview the table in the default web browser
        %   Passes the HTML document to MATLAB's web() function using the
        %   'text://' protocol so the browser renders the content directly
        %   without writing a file to disk.
        %   This method is a no-op when the object was constructed in index
        %   table mode (cTableIndex input), because index pages require
        %   file-based links that cannot be resolved from an inline string.
        %
        %   Syntax:
        %     obj.showTable()
        %
            if obj.isIndexTable
                return
            end
            html=['text://',obj.getMarkupHTML];
            web(html)
        end

        function log=saveTable(obj,filename)
        %saveTable - Write the HTML document to a file
        %   Opens filename for writing in text mode, writes the full HTML
        %   string, and closes the file.  All I/O errors are caught and
        %   reported through the returned cMessageLogger rather than
        %   propagated as exceptions.
        %
        %   Syntax:
        %     log = obj.saveTable(filename)
        %
        %   Input Arguments:
        %     filename - Path to the output file, including the .html
        %                extension.  The file is created or overwritten.
        %
        %   Output Arguments:
        %     log - cMessageLogger with the operation status.  Check
        %           log.status to verify whether the file was saved.
        %
            log=cMessageLogger();
            try
                fId=fopen(filename,'wt');
                fprintf(fId,'%s',obj.getMarkupHTML);
                fclose(fId);
            catch err
                log.messageLog(cType.ERROR,err.message);
                log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
            end
        end
    end

    methods(Static,Access=private)
        function res=buildHead(tbl)
        %buildHead - Build the HTML <head> section for a table document
        %   Reads the project CSS file from the config folder (cType.ConfigPath)
        %   and embeds it inline in a <style> block so the resulting HTML
        %   is self-contained and renders without external dependencies.
        %
        %   Syntax:
        %     res = cBuildHTML.buildHead(tbl)
        %
        %   Input Arguments:
        %     tbl - cTable object whose Name property is used as the
        %           document <title>.
        %
        %   Output Arguments:
        %     res - Char string with the complete <!DOCTYPE html><html><head>
        %           block, ready to be prepended to a body section.
        %
            cssfile=fullfile(cType.ConfigPath,cType.CSSFILE);
            csstext=fileread(cssfile);
            res = '<!DOCTYPE html>';
            res=[res,sprintf('\n<html>\n')];
            res=[res,sprintf('\t<head>\n')];
            res=[res,sprintf('\t\t<title>%s</title>\n',tbl.Name)];
            res=[res,sprintf('\t\t<style>\n')];
            res=[res,sprintf('%s',csstext)];
            res=[res,sprintf('\t\t</style>\n')];
            res=[res,sprintf('\t</head>\n')];
        end

        function res=buildTableBody(tbl)
        %buildTableBody - Build the HTML <body> section for a normal data table
        %   Renders the table title (via tbl.getDescriptionLabel), column
        %   headers, and all data rows into an HTML <table> element.
        %   Numeric columns receive the CSS class "num" for right-aligned
        %   formatting; character columns are rendered without a class.
        %   Cell data is obtained through tbl.formatData, which applies
        %   the column-specific format strings defined in the cTable object.
        %
        %   Syntax:
        %     res = cBuildHTML.buildTableBody(tbl)
        %
        %   Input Arguments:
        %     tbl - cTable object (cTableCell, cTableMatrix, etc.) to render.
        %
        %   Output Arguments:
        %     res - Char string with the complete <body>...</body></html> block.
        %
            cols=cell(1,tbl.NrOfCols);
            rows=cell(1,tbl.NrOfRows);
            % Body and Table head
            res=sprintf('\t<body>\n');
            res=[res,sprintf('\t\t<h3>\n')];
            res=[res,sprintf('\t\t\t%s\n',tbl.getDescriptionLabel)];
            res=[res,sprintf('\t\t</h3>\n')];
            res=[res,sprintf('\t\t<table>\n')];
            res=[res,sprintf('\t\t\t<thead>\n')];
            % Table Header
            fcol=tbl.getColumnFormat;
            data=tbl.formatData;
            for j=1:tbl.NrOfCols
                if fcol(j)==cType.ColumnFormat.CHAR
                    label='<th>';
                else
                    label='<th class="num">';
                end
                cols{j}=sprintf('\t\t\t\t%s%s</th>\n',label,tbl.ColNames{j});
            end
            res=[res,[cols{:}]];
            res=[res,sprintf('\t\t\t</thead>\n')];
            % Rows entries
            for i=1:tbl.NrOfRows
                rows{i}=sprintf('\t\t\t<tr>\n');
                rows{i}=[rows{i},sprintf('\t\t\t\t<td>%s</td>\n',tbl.RowNames{i})];
                for j=2:tbl.NrOfCols
                    if fcol(j)==cType.ColumnFormat.CHAR
                        label='<td>';
                    else
                        label='<td class="num">';
                    end
                    cols{j-1}=sprintf('\t\t\t\t%s%s</td>\n',label,data{i,j-1});
                end
                rows{i}=[rows{i},[cols{1:end-1}]];
                rows{i}=[rows{i},sprintf('\t\t\t</tr>\n')];     
            end
            res=[res,[rows{:}]];
            % Close the HTML labels
            res=[res,sprintf('\t\t</table>\n')];
            res=[res,sprintf('\t<br>')];
            res=[res,sprintf('\t</body>\n')];
            res=[res,sprintf('</html>\n')];
        end

        function res=buildIndexBody(tbl,folder)
        %buildIndexBody - Build the HTML <body> section for an index table
        %   Renders the cTableIndex as an HTML table where each row name
        %   becomes a hyperlink pointing to <folder>/<RowName>.html.
        %   Links are set to open in a new browser tab (target="_blank").
        %   The two data columns from tbl.formatData are appended to each
        %   row after the link cell.
        %
        %   Syntax:
        %     res = cBuildHTML.buildIndexBody(tbl, folder)
        %
        %   Input Arguments:
        %     tbl    - cTableIndex object providing row names, column names,
        %              and formatted cell data.
        %     folder - Relative or absolute folder path prepended to each
        %              row name to form the href URL.
        %
        %   Output Arguments:
        %     res - Char string with the complete <body>...</body></html> block.
        %
            cols=cell(1,tbl.NrOfCols);
            rows=cell(1,tbl.NrOfRows);
            % Body and table head
            res=sprintf('\t<body>\n');
            res=[res,sprintf('\t\t<h3>\n')];
            res=[res,sprintf('\t\t\t%s\n',tbl.Description)];
            res=[res,sprintf('\t\t</h3>\n')];
            res=[res,sprintf('\t\t<table>\n')];
            res=[res,sprintf('\t\t\t<thead>\n')];
            data=tbl.formatData;
            % Table header
            for j=1:tbl.NrOfCols
                cols{j}=sprintf('\t\t\t\t<th>%s</th>\n',tbl.ColNames{j});
            end
            res=[res,[cols{:}]];
            res=[res,sprintf('\t\t\t</thead>\n')];
            % Rows entries
            for i=1:tbl.NrOfRows
                url=[folder,filesep,tbl.RowNames{i},'.html'];
                tIndex=['<a href="',url,'" target="_blank">',tbl.RowNames{i},'</a>'];
                rows{i}=sprintf('\t\t\t<tr>\n');
                rows{i}=[rows{i},sprintf('\t\t\t\t<td>\n')];
                rows{i}=[rows{i},sprintf('\t\t\t\t\t%s\n',tIndex)];
                rows{i}=[rows{i},sprintf('\t\t\t\t</td>\n')];
                rows{i}=[rows{i},sprintf('\t\t\t\t<td>%s</td>\n',data{i,1})];
                rows{i}=[rows{i},sprintf('\t\t\t\t<td>%s</td>\n',data{i,2})];
                rows{i}=[rows{i},sprintf('\t\t\t</tr>\n')];     
            end
            res=[res,[rows{:}]];
            % Close the HTML labels
            res=[res,sprintf('\t\t</table>\n')];
            res=[res,sprintf('\t</body>\n')];
            res=[res,sprintf('</html>\n')];
        end
    end    
end