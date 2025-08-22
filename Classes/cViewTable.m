classdef (Sealed) cViewTable < cMessageLogger
%cViewTable - Show a result table using a GUI (uitable)
% 	called by showTable/cTable method with GUI option
% 
%   cViewTable Methods:
%     showTable - show the table on a uitable
%
%   See also cTable
%
	properties (Access=private)
		hf			% uifigure object
		colWidth 	% Width of columns
		descr      	% Table description
		data       	% Table data
		rowNames   	% Rows names
		colNames   	% Columns names
		format     	% Data format
		fontname   	% Font Name
		fontsize   	% Font Size
	end

	methods 
		function obj=cViewTable(tbl)
		%cViewTable - object constructor
		%   Syntax:
		%     obj = cViewTable(tbl)
		%   Input Argument:
		%	  tbl - cResultTable object
		%
			% Parameters depending of software platform
			if isOctave
				param=struct('ColumnScale',8,'RowWidth',21,'xMin',160,...
					'xScale',0.8,'yScale',0.8,'xoffset',4,'yoffset',2,...
					'FontName','Verdana','FontSize',8);
			else
				param=struct('ColumnScale',8,'RowWidth',23,'xMin',160,...
					'xScale',0.8,'yScale',0.8,'xoffset',12,'yoffset',2,...
					'FontName','Verdana','FontSize',8);
			end
			% Set object properties
			obj.rowNames=tbl.RowNames;
			obj.colNames=tbl.ColNames(2:end);
			tmp=[cType.colType(tbl.getColumnFormat)];
			obj.format=tmp(2:end);
			obj.fontname=param.FontName;
			obj.fontsize=param.FontSize;
			wcol=param.ColumnScale*tbl.getColumnWidth;
			% Set the window size and position
			ss=get(groot,'ScreenSize');
			xs=min(param.xScale*ss(3),sum(wcol)+param.xoffset);
			ys=max(tbl.NrOfRows,2)*param.RowWidth;
			xsize=max(param.xMin,xs);
			ysize=min(param.yScale*ss(4),ys+param.yoffset);	
			xpos=(ss(3)-xsize)/2;
			ypos=(ss(4)-ysize)/2;
			obj.colWidth=num2cell(wcol(2:end));
			obj.descr=tbl.getDescriptionLabel; 
            obj.data=tbl.formatData;
			obj.hf=figure('visible','off','menubar','none','toolbar','none',...
				'name',obj.descr,'numbertitle','off',...
				'position',[xpos,ypos,xsize,ysize]);
		end

		function showTable(obj)
		% Shows the table values in a uitable object
		%   Syntax:
		%     obj.showTable
		%   Example
		%     vt = cViewTable(tbl)
		%     vt.showTable;
		%
			uitable (obj.hf, 'Data', obj.data,...
				'RowName', obj.rowNames, 'ColumnName', obj.colNames,...
				'ColumnWidth',obj.colWidth,...
				'ColumnFormat',obj.format,...
				'FontName',obj.fontname,'FontSize',obj.fontsize,...
				'Units', 'normalized','Position',[0,0,1,1]);
			set(obj.hf,'visible','on');
		end
	end
end