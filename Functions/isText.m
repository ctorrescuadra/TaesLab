function res=isText(text)
% isText check if text is a char array or a string
%  	OUTPUT:
%		res - (true/false) 
	res=isstring(text) || ischar(text);
return
