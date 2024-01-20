package olib.models;

@:autoBuild(olib.models.Macros.addTypeField())
@:autoBuild(olib.models.Macros.addPublicFieldInitializers())
@:autoBuild(olib.models.Macros.addJsonParser())
@:autoBuild(olib.models.Macros.addJsonWriter())
class Model
{
    public static final all:Map<String, Map<String, Model>> = new Map<String, Map<String, Model>>();

    public static function registerInstance(type:String, instance:Model):Void
    {
        if (!all.exists(type))
        {
            all.set(type, new Map<String, Model>());
        }
        all.get(type).set(instance.name, instance);
    }

    public static function getInstance(type:String, name:String):Model
    {
        if (!all.exists(type))
        {
            return null;
        }
        return all.get(type).get(name);
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
