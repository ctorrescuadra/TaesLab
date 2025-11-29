classdef (Sealed) cBuildHTML < cMessageLogger
%cBuildHTML - Convert a cTable object into HTML files.
%   If a cTableIndex object is provided it create a HTML index page,
%   which links HTML files of the cResultInfo tables. If a cTable object is
%   provided it create a HTML page with the table.
%
%cBuildHTML methods:
%   cBuildHTML    - Build an instance of the object
%   getMarkupHTML - Get the text string with the HTML page
%   showTable     - Show the table in the default web browser
%   saveTable     - Save the HTML table created by the object
%
%   See also cTable
%
    properties (Access=private)
        head         % HTML head
        body         % HTML body
        isIndexTable % tbl is a index table
    end
    
    methods
        function obj=cBuildHTML(tbl,folder)
        %cBuildHTML - Build an instance of the object
        %   Syntax:
        %     obj = cBuildHTML(tbl)
        %     obj = cBuildHTML(index_table, folder)
        %   Input Arguments:
        %     tbl - cTable object to convert
        %     folder - Folder name where the files will be save if tbl is a cTableIndex
        %   Output Arguments:
        %     obj - cBuildHTML object
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
        %getMarkupHTML - Get the HTML text of the table
        %   Syntax:
        %     res = obj.getMarkupHTML
        %   Output Arguments:
        %     res - text string with the HTML page
        %
            res=[obj.head,obj.body];
        end

        function showTable(obj)
        %showTable - Show a normal table in the web browser
        %   Syntax:
        %     obj.showTable
        %  
            if obj.isIndexTable
                return
            end
            html=['text://',obj.getMarkupHTML];
            web(html)
        end

        function log=saveTable(obj,filename)
        %saveTable - Save the table into a HTML file
        %   Syntax:
        %     log = obj.saveTable(filename)
        %   Input Arguments:
        %     filename - name of the file with html extension
        %   Output Arguments:
        %     log - cMessageLogger object with status and messages
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
        %buildHead - Build the HTML head of a table
        %   Syntax:
        %     res = cBuildHTML.buildHead(tbl)
        %   Input Arguments:
        %     tbl - cTable object
        %   Output Arguments:
        %     res - text string with the HTML head
        %
            cssfile=fullfile(cType.ClassesPath,cType.CSSFILE);
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
        %buoldTableBody - Build the HTML body of a normal table
        %   Syntax:
        %     res = cBuildHTML.buildTableBody(tbl)
        %   Input Arguments:
        %     tbl - cTable object
        %   Output Arguments:
        %     res - text string with the HTML body
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
        %buildIndexBody - Build the HTML body a index table
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