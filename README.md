# olib_model - storing classes as json by reference

* Using the wonderful [json2object](https://github.com/elnabo/json2object) library to parse and write models to json.
* Using [utest](https://github.com/haxe-utest/utest) for testing.

This library allows for the serializing and deserializing of models, sometimes called definitions, and references to other models.

Why? Because sometimes you want to store objects as reference instead of nested json. And often, you don't want to manually deserialize your data to take this into account. This means not having to separate objects from their references, not having to manually build objects from json, then find the references. This library does it for you.

Models are stored by type and name in a dictionary. References to models are converted to string during serialization and back to references during deserialization.

It's better to show with examples.
```haxe
class Person extends olib.models.Model
{
    // public static final Type:String = "Person"; is auto-generated based on class name
    // public final type:String; is auto-generated, takes the value of static Type
    // public final name:String; is auto-generated
    public var age:Int;
    public var dog:Reference<Dog>;
}

class Dog extends olib.models.Model
{
    public var age:Int;
}

// create a person
var georges = new Person("Georges", 42, "charlie"); // optional arguments are auto-generated.
// name is not optional
// the dog charlie does not exist yet; but a reference to it now exists

Model.get("Person", "Georges") == georges;
Model.get(Person.Type, "Georges") == georges;
Model.get(georges.type, "Georges") == georges;

// create a dog
georges.dog.get() == null;
var charlie = new Dog("charlie", 3);
georges.dog.get() == charlie;

// serialize georges using auto json2object writer field
var georges_json = Person.write(georges);
// georges_json == {"type":"Person","name":"Georges","age":42,"dog":"charlie"}
// note that charlie is not serialized, only referenced

var charlie_json = Dog.write(charlie);
// charlie_json == {"type":"Dog","name":"charlie","age":3}

// deserialize georges
georges = Person.parse(georges_json);
georges == Model.get("Person", "Georges");

// v1.1.1: access a person through its class directly
georges = Person.get("Georges");

// deserialize charlie
charlie = Dog.parse(charlie_json);
charlie == Model.get("Dog", "charlie");

// v1.1.1: access a dog through its class directly
charlie = Dog.get("charlie");
```
## Installation
```bash
haxelib install olib_model
```

## Usage
All models must extend olib.models.Model. By doing this, those models gain special abilities from build macros.

Models have a `name:String` field that cannot be changed after instantiation. This is the unique key to reference them by.

Models also have a `type:String` field that cannot be changed after instantiation. This is the type of the model. It takes the value of the class' name, so a class `Person` will have a type of `"Person"`. It is also stored as a static `Type` field. The Type of a model can instead be manually set by declaring a metadata value with a different type name. In the following example, the Type of Person is "Human" instead of `"Person"`.
```haxe

@customTypeName("Human")
class Person extends olib.models.Model
{
    // public static final Type:String = "Human"; auto-generated, defaults to metadata value instead of class name
    // public final type:String = "Human"; auto-generated, same as static Type
    // public final name:String; auto-generated
    public var age:Int;
}
```
____

By default, when you instantiate two models of the same type and name, the second one overrides the first. You can change this behavior globally:
```haxe
Model.duplicateHandling = DuplicateHandling.Overwrite; // will overwrite the current model
Model.duplicateHandling = DuplicateHandling.Error; // will throw a ModelException
Model.duplicateHandling = DuplicateHandling.Ignore;	// will ignore the new model

// new in v1.1.1:
Model.duplicateHandling = DuplicateHandling.Custom;	// will execute custom logic to determine whether to keep or discard the new model
```

You can also overwrite the behavior per model. This is useful if you want to block a model type from being overwritten, for example:
```haxe
@duplicateHandling("Error")
class ImportantGameSetings extends Model
{
   // you wouldn't want a mod to overwrite your Settings model, so you can disable it here
}
```

In v1.1.1, you can execute custom DuplicateHandling logic per model, for example to only keep the latest version of two objects with the same name and type.
```haxe
@duplicateHandling("Custom")
class MyVersionnedModel extends Model
{
    public var version:Int;
    function onCustomDuplicateHandling(oldModel:Model):Bool
    {
        // if true, the new model will overwrite the old one, otherwise it will be discarded
        return oldModel.version < this.version;
    }
}
```

____

Models have [json2object](https://github.com/elnabo/json2object) parsers and writers as static fields. These are generated by build macros. You can use them to serialize and deserialize models. Have a read at the json2object documentation for more information.
```haxe
var georges = new Person("Georges", 42);
var georges_json = Person.write(georges);
var georges = Person.parse(georges_json);
// Do note here that the aforementionned duplicateHandling will apply here,
// and re-parsing georges can result in an error of
// Person was set to DuplicateHandling.Error via duplicateHandling("Error")
```

Note: In v1.0.0, you had to directly access the writer and parser using `Person.parser.parse` and `Person.writer.write`. This is still possible, but the static fields are now generated by build macros.

____

You can `peek` a json's type with `Model.peek(json_data)`. This will attempt to find a `"type": "value"` and return `"value"`. This is useful to determine the type of a serialized model before attempting to deserialize it.
```haxe
// load json from file
var json = sys.io.File.getContent("path/to/file.json");
// peek the type
var type = Model.peek(json);
switch (type)
{
    case Person.Type:
        var person = Person.parse(json);
    case _:
        trace("unknown type");
}
```

## References
A Reference is a special abstract type that is stored as a string in json format. It represents a named model. The Type Parameter is used to determine the type.
For example, by creating `var person:Reference<Person> = "Georges";`, the variable `person` has the value "Georges", but also has a special method `get():Person` that returns the Person named "Georges" if it exists, or null otherwise. When serialized, the json takes the form of `"person":"Georges"`. When deserialized, the json is converted to a `Reference<Person>` with the value "Georges".

You can use References in arrays with the form `Array<Reference<Person>>` or in other structures.

It is important to note that if you store a model within a model without using a Reference, the json output will be a nested json of the parent and child models. In other words:
```haxe
class Dog extends olib.models.Model
{
    public var age:Int;
}

var charlie = new Dog("charlie", 3);

class Person extends olib.models.Model
{
    public var name:String;
    public var age:Int;
    public var dog:Dog;
}

// output_json
'
{
    "type":"Person",
    "name":"Georges",
    "age":42,
    "dog":
    {
        "type":"Dog",
        "name":"charlie",
        "age":3
    }
}
'

class Person extends olib.models.Model
{
    public var name:String;
    public var age:Int;
    public var dog:Reference<Dog>;
}

// output_json
'
{
    "type":"Person",
    "name":"Georges",
    "age":42,
    "dog":"charlie"
}
'
```

## What else?
You can use models to store other models in a list. For example, without using a reference, you can have an array of models instead of a model per file.
```haxe
class PersonList extends olib.models.Model
{
    public var persons:Array<Person>;
}

// example json
'
{
    "name": "myPersonList",
    "type":"PersonList",
    "persons":
    [
        {
            ...
        },
        {
            ...
        }
    ]
}
'
```
Note that models are auto-added to the master dictionary `Model.all` when created or when deserialized.

You can have complex dependencies. A Starship can have a list of Weapons as references, and each Weapon has a list of values, but also a specific Projectile model as a reference.
```haxe
class Starship extends olib.models.Model
{
    public var name:String;
    public var weapons:Array<Reference<Weapon>>;
}

class Weapon extends olib.models.Model
{
    public var name:String;
    public var projectile:Reference<Projectile>;
    public var values:Array<Int>;
}

class Projectile extends olib.models.Model
{
    public var name:String;
    public var damage:Int;
}
```

Remember to use json2object's @:jignored metadata attribute to ignore fields that you don't want to serialize. For example, you may want to ignore the `values` field in the Weapon model.
```haxe
class Weapon extends olib.models.Model
{
    public var name:String;
    public var projectile:Reference<Projectile>;
    @:jignored public var values:Array<Int>;
}
// output_json
'
{
    "type":"Weapon",
    "name":"laser",
    "projectile":"laser",
}
'
```
## Example

Here's an example of how I handle my fonts in heaps.io.

```haxe
@customTypeName("font")
@duplicateHandling("Overwrite")
class FontAsset extends Model implements IAsset<Font>
{
    public var path:String;
    public var size:Int;

    @:jignored
    public var mod:Mod;

    @:jignored
    public var asset(default, null):BaseAsset<Font>;

    public function load():Void
    {
        asset = new BaseAsset();
        asset.load(mod.path + "/" + path);
    }

    public function build():Void
    {
        @:privateAccess asset.data = new BitmapFont(asset.rawData.entry).toSdfFont(size);
    }

    public function unload():Void
    {
        @:privateAccess asset.data = null;
        @:privateAccess asset.rawData = null;
    }

    public function getAsset():Font
    {
        if (asset == null || asset.rawData == null)
            load();
        if (asset.data == null)
            build();
        return asset.data;
    }
}
```

```json
{
    "type": "font",
    "name": "martius",
    "path": "assets/fonts/martius.fnt",
    "size": 64
}
```
And here is an example of a settings.json file for a game. Note how string enum abstracts are serialized as strings. If, for some reason, the settings fail would be corrupted or the user would like to reset all parameters, you can simply serialize a new instance and overwrite the json file.

```haxe
@customTypeName("settings")
class Settings extends Model
{
    static var instance:Settings;

    public var window:WindowSettings = new WindowSettings();

    public var enabledMods:Array<String> = [];

    public var sound:SoundSettings = new SoundSettings();

    public function new()
    {
        if (instance != null)
        {
            throw "Settings must be a singleton";
        }
        instance = this;
    }
}

class WindowSettings
{
    public function new() {}

    public var width:Int = 800;
    public var height:Int = 600;
    public var mode:WindowMode = WindowMode.Windowed;
}

enum abstract WindowMode(String)
{
    var Borderless = "borderless";
    var Windowed = "windowed";
    var Fullscreen = "fullscreen";
}

class SoundSettings
{
    public function new() {} // nothing here yet, but I'd expect music, effects, menu, master, etc.
}
```

```json
{
  "window": {
    "width": 2560,
    "height": 1440,
    "mode": "windowed"
  },
  "type": "settings",
  "name": "settings",
  "enabledMods": [
    "core"
  ]
}

```
