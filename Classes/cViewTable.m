classdef cViewTable < cStatusLogger
% cViewTable view individual tables in uitable windows
% It is used as interface of cTableResult by means of function:
% 	viewTable(tbl,state)
% Methods:
% 	obj=cViewTable(tbl,state)
%   obj.showTable
	properties (Access=private)
		xpos       	% X coordinates for position
		ypos       	% Y coordinates for position
		xsize      	% X window size
		ysize      	% Y window size
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
		% cViewTable - object constructor
		% 	Input:
		%	 tbl - cResultTable object
		%    state - Thermoeconomic state name
			obj=obj@cStatusLogger(cType.VALID);
			% Parameters depending of software platform
			if isOctave
				param=struct('ColumnScale',8,'RowWidth',20,'xMin',240,...
					'xScale',0.8,'yScale',0.8,'xoffset',10,'yoffset',10,...
					'FontName','Consolas','FontSize',10);
			else
				param=struct('ColumnScale',8,'RowWidth',23,'xMin',240,...
				'xScale',0.8,'yScale',0.8,'xoffset',12,'yoffset',23,...
				'FontName','FixedWidth','FontSize',12);
			end
			% Set object properties
			obj.rowNames=tbl.RowNames;
			obj.colNames=tbl.ColNames(2:end);
			obj.format=tbl.getColumnFormat;
			obj.fontname=param.FontName;
			obj.fontsize=param.FontSize;
			wcol=param.ColumnScale*tbl.getColumnWidth;
			% Set the window size and position
			ss=get(groot,'ScreenSize');
			xs=min(param.xScale*ss(3),sum(wcol)+param.xoffset);
			obj.xsize=max(param.xMin,xs);
			obj.ysize=min(param.yScale*ss(4),(tbl.NrOfRows+1)*param.RowWidth+param.yoffset);	
			obj.xpos=(ss(3)-obj.xsize)/2;
			obj.ypos=(ss(4)-obj.ysize)/2;
			obj.colWidth=num2cell(wcol(2:end));
			if isa(tbl,'cTableResult')
			    obj.descr=[tbl.Description,' [',tbl.State,'] ']; 
                obj.data=tbl.formatData;
            else
                obj.descr=tbl.Description; 
                obj.data=tbl.Data;
			end
		end

		function showTable(obj)
		% showTable shows the table values in a uitable object		function showTable_ML(obj)
			h=uifigure('menubar','none','toolbar','none','name',obj.descr, ...
				'numbertitle','off',...
				'position',[obj.xpos,obj.ypos,obj.xsize,obj.ysize]);
			uitable (h, 'Data', obj.data,...
				'RowName', obj.rowNames, 'ColumnName', obj.colNames,...
				'ColumnWidth',obj.colWidth,...
				'ColumnFormat',obj.format,...
				'FontName',obj.fontname,'FontSize',obj.fontsize,...
				'Units', 'normalized','Position',[0,0,1,1]);
		end
	end
end