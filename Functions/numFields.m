function res=numFields(s)
% numFields returns the number of fields of a structure (Octave/Matlab compatibility)
%   USAGE:
%       res=numFields(s)
%   INPUT:
%       s - data structure
%   OUTPUT:
%       res - nunber of fields of the structure
    if ~isstruct(s)
        res=0;
    else
        res=numel(fieldnames(s));
    end
end