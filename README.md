# olib_model - storing classes as json by reference

This library allows for the serializing and deserializing of models, sometimes called definitions, and references to other models.

Models are stored by type and name in a dictionary. References to models are converted to string during serialization and back to references during deserialization.



It's better to show with examples.
```haxe
class Person extends olib.models.Model
{
    // public static final TYPE:String = "Person"; is auto-generated
    // public var type:String; is auto-generated
    // public var name:String; is auto-generated
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
// the dog charlie does not exist yet; but a reference to it exists

Model.getInstance("Person", "Goerges") == georges;

// create a dog
var charlie = new Dog("charlie", 3);
georges.dog.get() == charlie;

// serialize georges using auto json2object writer field
var georges_json = Person.writer.write(georges);
// georges_json == {"type":"Person","name":"Georges","age":42,"dog":"charlie"}
var charlie_json = Dog.writer.write(charlie);
// charlie_json == {"type":"Dog","name":"charlie","age":3}

// deserialize georges
georges = Person.parser.fromJson(georges_json);
georges == Model.getInstance("Person", "Georges");

// deserialize charlie
charlie = Dog.parser.fromJson(charlie_json);
charlie == Model.getInstance("Dog", "charlie");
```
## Installation
`haxelib install olib_model`

## Usage
All models must extend olib.models.Model. By doing this, those models gain special abilities from build macros.

Models have a `name:String` field that cannot be changed after instantiation. This is the unique key to reference them by.

Models also have a `type:String` field that cannot be changed after instantiation. This is the type of the model. It is also stored as a static `TYPE` field.
