function res=strContains(str1,str2)
% strContains - check if string str1 contains str2. It is defined for Octave/MATLAB compatibility
%   USAGE:
%       res = strContains(str1, str2)
%   INPUT:
%       str1 - String to check
%       str2 - String containing the substring to check
%   OUTPUT
%       res - (true/false) result of the contains test
    if isOctave
        res=~isempty(strfind(str1, str2));
    else
        res=contains(str1,str2);
    end
end
