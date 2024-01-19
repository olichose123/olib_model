package olib.models;

import hxjsonast.Json;
import olib.models.Model;

typedef ModelStruct =
{
    public var name(default, null):String;
    public var type(default, null):String;
}

// @:genericBuild(olib.models.Macros.referenceMacro())
class Reference<T:ModelStruct>
{
    public var name:String;
    @:jignored public var instance:T;

    public function new(instance:T, name:String = null)
    {
        this.instance = instance;
        if (instance != null)
        {
            this.name = instance.name;
        }
        else
        {
            this.name = name;
        }
    }

    public function toString():String
    {
        return name;
    }

    public function resolve():Void
    {
        // instance = cast Model.getInstance(this.type, name);
    }
}
