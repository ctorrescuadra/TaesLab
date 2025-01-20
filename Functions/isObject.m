function res=isObject(obj,class)
    %isObject - Check is a cTaesLab object belong to a specific class
    %
    %   Syntax:
    %     res = isObject(obj,class)
    %
    %   Input Argument:
    %     obj   - cTaesLab object
    %     class - name of the class (char array)
    %  
    %   Output Argument:
    %     res - true | false
        res = isValid(obj) && isa(obj,class);
    end