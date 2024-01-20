package olib.models.tests;

import olib.models.tests.Examples.ArrayReferenceExample;
import olib.models.tests.Examples.ReferenceExample;
import json2object.JsonParser;
import haxe.Json;
import utest.Assert;
import olib.models.tests.Examples.SimpleExample;
import olib.models.tests.Examples.OverridenTypeExample;

class Tests extends utest.Test
{
    var simpleExampleJSON:String = '
    {
        "name": "example-a",
        "type": "SimpleExample",
        "myStringValue": "hello world",
        "myIntValue": 25
    }
    ';

    function testDictAccess()
    {
        var example = new SimpleExample("example-a", 25, "hello world");
        Assert.equals(Model.all.get("SimpleExample").get("example-a"), example);
    }

    function testTypeField()
    {
        var example = new SimpleExample("example-a", 25, "hello world");
        Assert.equals("SimpleExample", example.type);
        Assert.equals(example.type, SimpleExample.TYPE);
    }

    function testTypeOverride()
    {
        var example = new OverridenTypeExample("example-a");
        Assert.equals("OverridenTypeExample", example.type);
        Assert.isTrue(Model.all.get("OverridenTypeExample").exists("example-a"));
    }

    function testJsonDeserialization()
    {
        // var example:SimpleExample = parser.fromJson(simpleExampleJSON);
        var example:SimpleExample = SimpleExample.fromJson(simpleExampleJSON);
        Assert.equals("example-a", example.name);
        Assert.equals(25, example.myIntValue);
        Assert.equals("hello world", example.myStringValue);
        Assert.isTrue(Model.all.get("SimpleExample").exists("example-a"));
    }

    function testJsonSerialization()
    {
        var example = new SimpleExample("example-a", 25, "hello world");
        var json = example.toJson();
        var parsed = Json.parse(json);
        Assert.equals("example-a", parsed.name);
        Assert.equals(25, parsed.myIntValue);
        Assert.equals("hello world", parsed.myStringValue);
    }

    function testReference()
    {
        var parent = new ReferenceExample("example-a");
        var child = new SimpleExample("example-b", 25, "hello world");
        parent.myReference = "example-b";
        Assert.equals("SimpleExample", parent.myReference.getType());
        Assert.equals("example-b", parent.myReference);
    }

    function testArrayReferences()
    {
        var parent = new ArrayReferenceExample("example-a");
        for (i in 0...10)
        {
            var child = new SimpleExample("example-b-" + i, 25, "hello world");
            parent.myReferences.push("example-b-" + i);
        }

        Assert.contains("example-b-0", parent.myReferences);
        Assert.contains("example-b-1", parent.myReferences);
        Assert.contains("example-b-2", parent.myReferences);
        Assert.contains("example-b-3", parent.myReferences);
        Assert.contains("example-b-4", parent.myReferences);
        Assert.contains("example-b-5", parent.myReferences);
        Assert.contains("example-b-6", parent.myReferences);
        Assert.contains("example-b-7", parent.myReferences);
        Assert.contains("example-b-8", parent.myReferences);
        Assert.contains("example-b-9", parent.myReferences);
    }

    function testReferenceParsing()
    {
        var parent = new ReferenceExample("example-a");
        var child = new SimpleExample("example-b", 25, "hello world");
        parent.myReference = "example-b";
        var serialized = parent.toJson();
        var secondParent = ReferenceExample.fromJson(serialized);
        Assert.equals(child, secondParent.myReference.get());
    }

    function testArrayReferencesParsing()
    {
        var parent = new ArrayReferenceExample("example-a");
        for (i in 0...10)
        {
            var child = new SimpleExample("example-b-" + i, 25, "hello world");
            parent.myReferences.push("example-b-" + i);
        }

        var serialized = parent.toJson();
        var secondParent = ArrayReferenceExample.fromJson(serialized);
        Assert.equals(10, secondParent.myReferences.length);
        Assert.contains("example-b-0", secondParent.myReferences);
        Assert.contains("example-b-1", secondParent.myReferences);
        Assert.contains("example-b-2", secondParent.myReferences);
        Assert.contains("example-b-3", secondParent.myReferences);
        Assert.contains("example-b-4", secondParent.myReferences);
        Assert.contains("example-b-5", secondParent.myReferences);
        Assert.contains("example-b-6", secondParent.myReferences);
        Assert.contains("example-b-7", secondParent.myReferences);
        Assert.contains("example-b-8", secondParent.myReferences);
        Assert.contains("example-b-9", secondParent.myReferences);
    }
}
