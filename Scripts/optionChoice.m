function [iopt,otext] = optionChoice(text, options,default_value)
% optionChoice - Interactive option choose.
%  Ask a question "text" with several "options".
%  INPUT:
%   text - Question text
%   options - cell text array with options to check
%   default_value [optional] - value selected if no choice is made
%  OUTPUT:
%   iopt - option number choose
%   otext - option text
%
	if nargin<2
		error('Usage optionChoice(text,options,[default_value])');
	end
    if ~iscell(options)
        error('Options must be a cell array');
    end
    if (nargin==2) || isempty(default_value)
        default_value=1;
    end
    N=length(options);
    disp(text);
    for i=1:N
        display([num2str(i),'. ',options{i}]);
    end
    text_choice=['Choose option [',num2str(default_value),']: '];
    iopt=input(text_choice);
    if isempty(iopt) || ~ismember(iopt,1:N) 
        iopt=default_value;
    end
    otext=options{iopt};
end

