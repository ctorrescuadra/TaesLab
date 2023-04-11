function res=fileChoice(text,default_filename)
% fileChoice - Interactive file choice for scripts
%  INPUT:
%	text - text to prompt
%	default_filename - file name is none is selected
%  OUTPUT:
%	res - file name
%   
    narginchk(1,2);
    if (nargin<2) || isempty(default_filename)
        default_filename=strcat(cType.RESULT_FILE,'.xlsx');
    end
    text=[text, ' [',default_filename,']',': '];
    sn=input(text,'s');
    if isempty(sn)
        res=default_filename;
    else
        res=sn;
    end
end