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

@customTypeName("OverridenTypeExample")
class OverridenTypeExample extends Model {}

class ReferenceExample extends Model
{
    public var myReference:Reference<SimpleExample>;
}

class ArrayReferenceExample extends Model
{
    public var myReferences:Array<Reference<SimpleExample>> = [];
}

@duplicateHandling("Error")
class ErrorOnDuplicateExample extends Model {}
