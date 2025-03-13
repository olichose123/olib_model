package olib.models;

import haxe.Exception;

/**
 * Base class for all models. Models are used to store data as JSON and provide serialization/deserialization functions.
 * Models can be registered and retrieved by type and name.
 * A model should extend Model and can implement any interface. A class should only inherit directly from Model,
 * and not from another class that inherits from Model.
**/
@:autoBuild(olib.models.Macros.addNameAndTypeField())
@:autoBuild(olib.models.Macros.addPublicFieldInitializers())
@:autoBuild(olib.models.Macros.addJsonParser())
@:autoBuild(olib.models.Macros.addJsonWriter())
@:autoBuild(olib.models.Macros.addParserFunction())
@:autoBuild(olib.models.Macros.addWriterFunction())
@:autoBuild(olib.models.Macros.addGetFunction())
class Model
{
    /**
     * A map of all registered models. Access using the type of the model (usually MyModelClass.Type or myModelInstance.type).
     * See also Model.get and Model.getAll.
    **/
    public static final all:Map<String, Map<String, Model>> = new Map<String, Map<String, Model>>();

    /**
     * The duplicate handling behavior when registering a model with the same type and name as an existing model.
     * Default is DuplicateHandling.Overwrite.
     *
     * - DuplicateHandling.Overwrite: Overwrite the existing model with the new model.
     *   Call the onOverwrite function of the new model and the onOverwritten function of the old model.
     * - DuplicateHandling.Ignore: Ignore the new model and keep the existing model.
     * - DuplicateHandling.Error: Throw an error when a duplicate model is registered. Used when duplicates should not exist.
     * - DuplicateHandling.Custom: Call the onCustomDuplicateHandling function of the existing model.
     *   If it returns false, ignore the new model, otherwise overwrite the old model.
    **/
    public static var duplicateHandling:DuplicateHandling = DuplicateHandling.Overwrite;

    /**
     * Register a new or existing model. This function is usually called automatically when deserializing a model or
     * instantiating a new one.
     * @param type
     * @param instance
     * @param altDuplicateHandling an alternative duplicateHandling behavior fetched from metadata when the model is auto-registered.
     * @throws ModelException if a duplicate model is already registered and duplicateHandling is set to DuplicateHandling.Error.
    **/
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
                if (exists(type, instance.name))
                {
                    get(type, instance.name).onOverwritten(instance);
                    instance.onOverwrite(get(type, instance.name));
                }

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

            case DuplicateHandling.Custom:
                if (exists(type, instance.name))
                {
                    if (!instance.onCustomDuplicateHandling(get(type, instance.name)))
                    {
                        return;
                    }
                }
        }
        if (!all.exists(type))
        {
            all.set(type, new Map<String, Model>());
        }
        all.get(type).set(instance.name, instance);
        instance.onRegister();
    }

    /**
     * Get all models of a certain type.
     * @param type
     * @return an iterator of all models of the specified type.
    **/
    public static function getAll<T:Model>(type:String):Iterator<T>
    {
        if (!all.exists(type))
        {
            return [].iterator();
        }
        return cast all.get(type).iterator();
    }

    /**
     * Get a model by type and name.
     * @param type
     * @param name
     * @return the model if it exists, otherwise null.
    **/
    public static function get<T:Model>(type:String, name:String):T
    {
        if (!all.exists(type))
        {
            return null;
        }
        return cast all.get(type).get(name);
    }

    /**
     * Remove a model by type and name.
     * @param type
     * @param name
     * @return true if the model was removed, false if it did not exist.
    **/
    public static function remove(type:String, name:String):Bool
    {
        if (!all.exists(type))
        {
            return false;
        }
        return all.get(type).remove(name);
    }

    /**
     * Check if a model exists by type and name.
     * @param type
     * @param name
     * @return true if the model exists, false if it does not.
    **/
    public static function exists(type:String, name:String):Bool
    {
        if (!all.exists(type))
        {
            return false;
        }
        return all.get(type).exists(name);
    }

    /**
     * Deserializes a json string and checks the type field.
     * Used to determine the type of a model. You can then use this to parse the json string into the correct model.
     * @param json
     * @return the type field of the json string, or null if it does not exist.
    **/
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

    /**
     * The name of the model instance. Two models of the same type and name are considered duplicates.
    **/
    public var name(default, null):String;

    /**
     * Callback when the model is registered, whether on instantiation or deserialization.
    **/
    function onRegister():Void
    {
        //
    }

    /**
     * Callback when a model is about to overwrite another model of the same type and name.
     * @param oldModel the model about to be overwritten.
    **/
    function onOverwrite(oldModel:Model):Void
    {
        //
    }

    /**
     * Callback when a model is about to be overwritten by another model of the same type and name.
     * @param newModel
    **/
    function onOverwritten(newModel:Model):Void
    {
        //
    }

    /**
     * Callback when a model is about to overwrite another model of the same type and name, but the duplicateHandling is set to DuplicateHandling.Custom.
     * Return false to ignore the new model, true to overwrite the old model with the new model.
     * @param oldModel the model about to be overwritten.
     * @return true to overwrite the old model, false to ignore the new model.
    **/
    function onCustomDuplicateHandling(oldModel:Model):Bool
    {
        return true;
    }
}

enum DuplicateHandling
{
    Overwrite;
    Ignore;
    Error;
    Custom;
}

class ModelException extends Exception {}
