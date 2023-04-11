classdef cViewTable < cStatusLogger
% cViewTable view individual tables in uitable windows
% It is used as interface of cTableResult by means of function:
% 	viewTable(tbl,state)
% Methods:
% 	obj=cViewTable(tbl,state)
%   obj.showTable
	properties (Access=private)
		xpos       % X coordinates for position
		ypos       % Y coordinates for position
		xsize      % X window size
		ysize      % Y window size
		wcols      % Width of columns
		descr      % Table description
		data       % Table data
		rowNames   % Rows names
		colNames   % Columns names
		format     % Data format
		fontname   % Font Name
		fontsize   % Font Size
	end

	methods 
		function obj=cViewTable(tbl,state)
		% cViewTable - object constructor
		% 	Input:
		%	 tbl - cResultTable object
		%    state - Thermoeconomic state name
			obj=obj@cStatusLogger(cType.VALID);
			if nargin==1
				state='';
			end
			% Parameters depending of software platform
			if isOctave
				param=struct('ColumnWidth',80,'RowWidth',20,...
					'xScale',0.8,'yScale',0.8,'xoffset',10,...
					'FontName','Consolas','FontSize',10);
			else
				param=struct('ColumnWidth',80,'RowWidth',23,...
				'xScale',0.8,'yScale',0.8,'xoffset',10,...
				'FontName','FixedWidth','FontSize',12);
			end
			% Set object properties
			obj.descr=[tbl.Description,' [',state,'] ']; 
			% Set the window size and position
			ss=get(groot,'ScreenSize');
			obj.xsize=min(param.xScale*ss(3),tbl.NrOfCols*param.ColumnWidth-param.xoffset);
			obj.ysize=min(param.yScale*ss(4),(tbl.NrOfRows+2)*param.RowWidth);
			obj.xpos=(ss(3)-obj.xsize)/2;
			obj.ypos=(ss(4)-obj.ysize)/2;
			obj.wcols=repmat({param.ColumnWidth},1,tbl.NrOfCols);
			obj.data=tbl.formatData;
			obj.rowNames=tbl.RowNames;
			obj.colNames=tbl.ColNames(2:end);
			obj.format=tbl.getColumnFormat;
			obj.fontname=param.FontName;
			obj.fontsize=param.FontSize;
		end

		function showTable(obj)
		% showTable shows the table values in a uitable object
			if isOctave
                obj.showTable_OC;
            else
                obj.showTable_ML;
			end
		end
	end

	methods(Access = private)
		function showTable_ML(obj)
			h=uifigure('menubar','none','toolbar','none','name',obj.descr, ...
				'numbertitle','off',...
				'position',[obj.xpos,obj.ypos,obj.xsize,obj.ysize]);
   			uitable (h, 'Data', obj.data,...
				'RowName', obj.rowNames, 'ColumnName', obj.colNames,...
				'ColumnWidth',obj.wcols,...
				'ColumnFormat',obj.format,...
				'FontName',obj.fontname,'FontSize',obj.fontsize,...
				'Units', 'normalized','Position',[0,0,1,1]);
		end

		function showTable_OC(obj)
			h=figure('menubar','none','toolbar','none','name',obj.descr, ...
				'numbertitle','off',...
				'position',[obj.xpos,obj.ypos,obj.xsize,obj.ysize]);
   			uitable (h, 'Data', obj.data, ...
				'RowName', obj.rowNames, 'ColumnName', obj.colNames,...
				'ColumnWidth',obj.wcols,...
				'ColumnFormat',obj.format,...
				'FontName',obj.fontname,'FontSize',obj.fontsize,...
				'units', 'normalized','position',[0,0,1,1]);
		end
	end
end