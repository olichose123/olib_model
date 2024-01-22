package olib.models.tests;

import olib.models.Model.ModelException;
import olib.models.Model.DuplicateHandling;
import olib.models.tests.Examples.ArrayReferenceExample;
import olib.models.tests.Examples.ReferenceExample;
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

    function setup()
    {
        Model.duplicateHandling = DuplicateHandling.Overwrite;
    }

    function testDictAccess()
    {
        var example = new SimpleExample("example-a", 25, "hello world");
        Assert.equals(Model.get("SimpleExample", "example-a"), example);
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
        var example:SimpleExample = SimpleExample.parser.fromJson(simpleExampleJSON);
        Assert.equals("example-a", example.name);
        Assert.equals(25, example.myIntValue);
        Assert.equals("hello world", example.myStringValue);
        Assert.isTrue(Model.all.get("SimpleExample").exists("example-a"));
    }

    function testJsonSerialization()
    {
        var example = new SimpleExample("example-a", 25, "hello world");
        var json = SimpleExample.writer.write(example);
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

        for (i in 0...10)
        {
            Assert.equals("example-b-" + i, parent.myReferences[i]);
        }
    }

    function testReferenceParsing()
    {
        var parent = new ReferenceExample("example-a");
        var child = new SimpleExample("example-b", 25, "hello world");
        parent.myReference = "example-b";
        var serialized = ReferenceExample.writer.write(parent);
        var secondParent = ReferenceExample.parser.fromJson(serialized);
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

        var serialized = ArrayReferenceExample.writer.write(parent);
        var secondParent = ArrayReferenceExample.parser.fromJson(serialized);
        Assert.equals(10, secondParent.myReferences.length);
        for (i in 0...10)
        {
            Assert.contains("example-b-" + i, secondParent.myReferences);
        }
    }

    function testPeek():Void
    {
        #if sys
        var json = sys.io.File.getContent("examples/simple-example-a.json");
        Assert.equals(SimpleExample.TYPE, Model.peek(json));
        #else
        Assert.equals(SimpleExample.TYPE, Model.peek(simpleExampleJSON));
        #end
    }

    function testGlobalDuplicateHandling()
    {
        Model.duplicateHandling = DuplicateHandling.Overwrite;
        var exampleA = new SimpleExample("example-a", 25, "hello world");

        var exampleB = new SimpleExample("example-a", 25, "hello world2");
        var testExample:SimpleExample = Model.get("SimpleExample", "example-a");
        Assert.equals("hello world2", testExample.myStringValue);

        Model.duplicateHandling = DuplicateHandling.Ignore;
        var exampleD = new SimpleExample("example-a", 25, "hello world3");
        testExample = Model.get("SimpleExample", "example-a");
        Assert.equals("hello world2", testExample.myStringValue);

        Model.duplicateHandling = DuplicateHandling.Error;
        try
        {
            var exampleE = new SimpleExample("example-a", 25, "hello world4");
            Assert.fail("Should have thrown an error");
        }
        catch (e:ModelException) {}
    }
}
