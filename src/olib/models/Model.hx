package olib.models;

import haxe.Exception;

@:autoBuild(olib.models.Macros.addNameAndTypeField())
@:autoBuild(olib.models.Macros.addPublicFieldInitializers())
@:autoBuild(olib.models.Macros.addJsonParser())
@:autoBuild(olib.models.Macros.addJsonWriter())
class Model
{
    public static final all:Map<String, Map<String, Model>> = new Map<String, Map<String, Model>>();
    public static var duplicateHandling:DuplicateHandling = DuplicateHandling.Overwrite;

    public static function register(type:String, instance:Model, ?altDuplicateHandling):Void
    {
        var currDuplicateHandling:DuplicateHandling = duplicateHandling;
        if (altDuplicateHandling != null)
        {
            currDuplicateHandling = altDuplicateHandling;
        }
        switch (currDuplicateHandling)
        {
            case DuplicateHandling.Overwrite:

            case DuplicateHandling.Ignore:
                if (exists(type, instance.name))
                {
                    return;
                }

            case DuplicateHandling.Error:
                if (exists(type, instance.name))
                {
                    throw new ModelException("Duplicate model: " + type + " " + instance.name);
                }
        }
        if (!all.exists(type))
        {
            all.set(type, new Map<String, Model>());
        }
        all.get(type).set(instance.name, instance);
    }

    public static function get<T:Model>(type:String, name:String):T
    {
        if (!all.exists(type))
        {
            return null;
        }
        return cast all.get(type).get(name);
    }

    public static function exists(type:String, name:String):Bool
    {
        if (!all.exists(type))
        {
            return false;
        }
        return all.get(type).exists(name);
    }

    public static function peek(json:String):String
    {
        var obj:Dynamic = haxe.Json.parse(json);
        var type:String = null;
        try
        {
            type = obj.type;
        }
        catch (e:Dynamic)
        {
            return null;
        }
        return type;
    }

    public var name(default, null):String;
}

enum DuplicateHandling
{
    Overwrite;
    Ignore;
    Error;
}

class ModelException extends Exception {}
