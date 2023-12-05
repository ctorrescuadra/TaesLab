function generateHTML(tbl)
    fId=fopen("prueba.html","w+");
    fprintf(fId,'<html>\n');
    fprintf(fId,'\t<head>\n');
    fprintf(fId,'\t\t<link rel="stylesheet" type="text/css" href="styles.css"/>\n'); 
	fprintf(fId,'\t</head>\n');
    fprintf(fId,'\t<body>\n');
    fprintf(fId,'\t\t<h3>\n');
    fprintf(fId,'\t\t\t%s\n',tbl.Description);
    fprintf(fId,'\t\t</h3>\n');
    fprintf(fId,'\t\t<table>\n');
    fprintf(fId,'\t\t\t<thead>\n');
    fcol=[1,tbl.getColumnFormat];
    data=tbl.formatData;
    for j=1:tbl.NrOfCols
        if fcol(j)==cType.ColumnFormat.CHAR
            label='<th>';
        else
            label='<th class="num">';
        end
        fprintf(fId,'\t\t\t\t%s%s</th>\n',label,tbl.ColNames{j});
    end
    fprintf(fId,'\t\t\t</thead>\n');
    for i=1:tbl.NrOfRows
        fprintf(fId,'\t\t\t<tr>\n');
        fprintf(fId,'\t\t\t\t<td>%s</td>\n',tbl.RowNames{i});
        for j=2:tbl.NrOfCols
            if fcol(j)==cType.ColumnFormat.CHAR
                label='<td>';
            else
                label='<td class="num">';
            end
            fprintf(fId,'\t\t\t\t%s%s</td>\n',label,data{i,j-1});
        end
        fprintf(fId,'\t\t\t</tr>\n');     
    end
    fprintf(fId,'\t\t</table>\n');
    fprintf(fId,'\t</body>\n');
    fprintf(fId,'</html>\n');

end