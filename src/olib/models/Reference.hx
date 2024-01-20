package olib.models;

import hxjsonast.Json;
import olib.models.Model;

typedef ModelStruct =
{
    public var name(default, null):String;
    public var type(default, null):String;
}

@:genericBuild(olib.models.Macros.referenceMacro())
class Reference<T:ModelStruct> {}
