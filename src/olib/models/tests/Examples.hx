package olib.models.tests;

import olib.models.Model;
import json2object.JsonParser;
import json2object.JsonWriter;

class Examples {}

class SimpleExample extends Model
{
    // static final parser = new JsonParser<SimpleExample>();
    // static final writer = new JsonWriter<SimpleExample>();
    public var myStringValue:String;
    public var myIntValue:Int;
}

class OverridenTypeExample extends Model
{
    // static final parser = new JsonParser<OverridenTypeExample>();
    // static final writer = new JsonWriter<OverridenTypeExample>();
    public static final TYPE:String = "OverridenTypeExample";
}

class ReferenceExample extends Model
{
    // static final parser = new JsonParser<ReferenceExample>();
    // static final writer = new JsonWriter<ReferenceExample>();
    // @:jcustomparse(olib.models.Reference.customParse)
    // @:jcustomwrite(olib.models.Reference.customWrite)
    public var myReference:Reference<SimpleExample>;
}
