function res = askQuestion( text, default_value )
% question - Input yes or not question (Matlab /Octave compatibility)
% INPUT:
%   text - question to ask
%   default_value [optional] - value selected if no choice is made
% OUTPUT:
%   res - answer to the question (true/false)
%
    if (nargin<2) || isempty(default_value)
        default_value = 'N';
    end
    text=[text, ' (Y/N)? [',default_value,']: '];
    yn=input(text,'s');
    if isempty(yn)
        yn=default_value;
    end
    res=strcmpi(yn,'Y');   
end

