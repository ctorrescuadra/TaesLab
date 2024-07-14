classdef (Sealed) cBuildHTML < cStatusLogger
% cBuildHTML convert cTable object into HTML files
%   If a cTableIndexobject is provided create a index table
%   which indicate where are saved the HTML files of the cResultInfo tables. 
%   Methods:
%       obj=cBuildHTML(tbl,folder)
%       obj.showTable
%       log=obj.saveTable(filename)
%
    properties (Access=private)
        head    % HTML head
        body    % HTML body
        isIndexTable % tbl is a index table
    end
    methods
        function obj=cBuildHTML(tbl,folder)
        % Build an instance ob the object
        %   Input:
        %       tbl - cTable object to convert
        %    folder - Folder where the files will be save if tbl is a cTableIndex
        % 
            obj=obj@cStatusLogger(cType.VALID);
            if ~isValidTable(tbl)
                obj.messageLog(cType.ERROR,'Invalid input argument');
                return
            end
            obj.isIndexTable=isa(tbl,'cTableIndex') && (nargin==2);
            obj.head=cBuildHTML.buildHead(tbl);
            if obj.isIndexTable
                obj.body=cBuildHTML.buildIndexBody(tbl,folder);
            else
                obj.body=cBuildHTML.buildTableBody(tbl);
            end
            obj.status=true;
        end

        function res=getMarkupHTML(obj)
        % Get the HTML text of the table
            res=[obj.head,obj.body];
        end

        function showTable(obj)
        % Show a normal table in the web browser
            if obj.isIndexTable
                return
            end
            html=['text://',obj.getMarkupHTML];
            web(html)
        end

        function log=saveTable(obj,filename)
        % Save the table into a HTML file
            log=cStatusLogger(cType.VALID);
            html=[obj.head obj.body];
            try
                fId=fopen(filename,'wt');
                fprintf(fId,'%s',html);
                fclose(fId);
            catch err
                log.messageLog(cType.ERROR,err.message);
                log.messageLog(cType.ERROR,'File %s could NOT be saved',filename);
            end
        end
    end

    methods(Static,Access=private)
        function res=buildHead(tbl)
        % Build the head of the HTML file
            path=fileparts(mfilename('fullpath'));
            cssfile=fullfile(path,cType.CSSFILE);
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
        % Build the body of the HTML file of a normal table
            cols=cell(1,tbl.NrOfCols);
            rows=cell(1,tbl.NrOfRows);
            % Body and Table head
            res=sprintf('\t<body>\n');
            res=[res,sprintf('\t\t<h3>\n')];
            res=[res,sprintf('\t\t\t%s [%s]\n',tbl.Description,tbl.State)];
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
            res=[res,sprintf('\t</body>\n')];
            res=[res,sprintf('</html>\n')];
        end

        function res=buildIndexBody(tbl,folder)
        % Build the body of the HTML file of a index table
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