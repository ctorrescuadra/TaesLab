classdef (Sealed) cViewTable < cTaesLab
%cViewTable - Display a cTable in a GUI window using a uitable widget.
%   cViewTable renders a cTable object as an interactive uitable inside a
%   figure window.  It is invoked by the ShowTable base function when the
%   GUI view option (cType.TableView.GUI) is selected.
%
%   Usage follows a two-step pattern:
%     1. Construct with a cTable object.  The constructor pre-computes the
%        window size and position from the table dimensions and the screen
%        size, formats the data, and creates a hidden figure.
%     2. Call showTable to create the uitable inside the figure and make
%        the window visible.
%
%   Window sizing is platform-aware: slightly different scale factors are
%   applied for MATLAB and Octave to account for differences in default
%   font metrics and widget spacing.
%
%   cViewTable Methods:
%     cViewTable - Pre-compute layout and create the hidden figure
%     showTable  - Populate the uitable and make the window visible
%
%   See also cTable, ShowTable, cType.TableView
%
	properties (Access=private)
		hf			% Figure handle (created hidden, made visible by showTable)
		colWidth 	% Width of columns (cell array of pixel values)
		descr      	% Table description (used as figure window title)
		data       	% Formatted cell data (from tbl.formatData)
		rowNames   	% Row names
		colNames   	% Column names (excludes the first header entry)
		format     	% Column format codes (from cType.colType)
		fontname   	% Font name for uitable text
		fontsize   	% Font size for uitable text
	end

	methods 
		function obj=cViewTable(tbl)
		%cViewTable - Pre-compute layout and create the hidden figure
		%   Extracts display data from the cTable object, computes the optimal
		%   window size (capped at 80 % of the screen in each dimension and
		%   centred on screen), and creates a hidden figure ready for
		%   showTable to populate.  Platform-specific scale factors are applied
		%   automatically for MATLAB and Octave.
		%
		%   Syntax:
		%     obj = cViewTable(tbl)
		%
		%   Input Arguments:
		%     tbl - cTable (or subclass) object to display.  The constructor
		%           reads RowNames, ColNames, NrOfRows, column widths, column
		%           format codes, description label, and formatted cell data.
		%
		%   Output Arguments:
		%     obj - cViewTable object.  Call obj.showTable() to render it.
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
		%showTable - Populate the uitable and make the window visible
		%   Creates a uitable that fills the figure, populates it with the
		%   data pre-computed by the constructor, then sets the figure
		%   visibility to 'on'.  Separating creation (constructor) from
		%   display (this method) allows the caller to show the window only
		%   after all layout work is complete, avoiding a blank-window flash.
		%
		%   Syntax:
		%     obj.showTable()
		%
		%   Example:
		%     vt = cViewTable(tbl);
		%     vt.showTable();
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