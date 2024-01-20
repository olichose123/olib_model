package olib.models.tests;

import olib.models.Model;
import json2object.JsonParser;
import json2object.JsonWriter;

class Examples {}

class SimpleExample extends Model
{
    public var myStringValue:String;
    public var myIntValue:Int;
}

class OverridenTypeExample extends Model
{
    public static final TYPE:String = "OverridenTypeExample";
}

class ReferenceExample extends Model
{
    public var myReference:Reference<SimpleExample>;
}

class ArrayReferenceExample extends Model
{
    public var myReferences:Array<Reference<SimpleExample>> = [];
}
