function res=folderChoice(text,default_folder)
% fileChoice - Interactive folder choice for scripts
%  INPUT:
%	text - text to prompt
%	default_folder - file name is none is selected
%  OUTPUT:
%	res - file name
%   
    narginchk(1,2);
    if (nargin<2) || isempty(default_folder)
        default_filename='.';
    end
    text=[text, ' [',default_filename,']',': '];
    sn=input(text,'s');
    if isempty(sn)
        res=default_filename;
    else
        res=sn;
    end
end