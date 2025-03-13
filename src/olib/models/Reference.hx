package olib.models;

import hxjsonast.Json;
import olib.models.Model;

typedef ModelStruct =
{
    public var name(default, null):String;
    public var type(default, null):String;
}

/**
 * A reference to a model. This is used to store a reference to a model as a name in string format in JSON.
 * The default behavior of nested classes is to serialize the entire structure, which is not always desirable.
 * Using a reference allows you to store a reference to a model by name while the type is stored in the class definition as Type Parameter T, and then retrieve the model by name later.
**/
@:genericBuild(olib.models.Macros.referenceMacro())
class Reference<T:ModelStruct> {}
