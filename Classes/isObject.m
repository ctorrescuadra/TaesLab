function test=isObject(obj,class)
    %isObject - Check is a cTaesLab object belong to a specific class
    %
    %  Syntax:
    %     isObject(obj,class)
    %  Input Argument:
    %     obj   - cTaesLab object
    %     class - name of the class (char array)
    %
        test = isa(obj,class) && isValid(obj);
    end