package olib.models;

import olib.macros.MacroUtil;
import haxe.macro.ExprTools;
import haxe.Exception;
import haxe.macro.Type.FieldAccess;
import haxe.macro.Expr;
import haxe.macro.Expr.FunctionArg;
import haxe.macro.Expr.Field;
import haxe.macro.Context;

using haxe.macro.ComplexTypeTools;
using haxe.macro.TypeTools;
using StringTools;

class Macros
{
    @:persistent
    private static var counter = 0;

    macro public static function addPublicFieldInitializers():Array<Field>
    {
        // Initial fields get
        var fields = Context.getBuildFields();
        var type = Context.toComplexType(Context.getLocalType());

        var constructor:Field = null;

        var initializableFields:Array<Field> = [];

        // find constructor
        for (field in fields)
        {
            switch (field.name)
            {
                case 'new':
                    constructor = field;
                    fields.remove(constructor);
                case _:
                    if (field.access.length == 1 && field.access.contains(APublic))
                        initializableFields.push(field);
            }
        }

        var constructor_exprs:Array<Expr> = [];
        var constructor_args:Array<FunctionArg> = [];

        initializableFields.sort(function(a, b):Int
        {
            var aa = a.name.toLowerCase();
            var bb = b.name.toLowerCase();
            if (aa < bb)
                return -1;
            if (aa > bb)
                return 1;
            return 0;
        });

        for (field in initializableFields)
        {
            var fname:String = field.name;
            switch (field.kind)
            {
                case FVar(t, e):
                    constructor_exprs.push(macro
                        {
                            if ($i{fname} != null)
                                this.$fname = cast $i{fname};
                        });
                    constructor_args.push({
                        name: field.name,
                        type: t,
                        opt: true,
                    });
                case _:
            }
        }

        if (constructor == null)
        {
            constructor = {
                name: 'new',
                access: [APublic],
                pos: Context.currentPos(),
                kind: FFun({
                    args: constructor_args,
                    expr: macro $b{constructor_exprs},
                    ret: macro :Void
                })
            };
        }
        else
        {
            switch (constructor.kind)
            {
                case FFun(f):
                    constructor_exprs.insert(0, f.expr);
                    f.args.concat(constructor_args);
                    f.expr = macro $b{constructor_exprs};
                case _:
            }
        }

        // add fields to array
        fields.push(constructor);

        // return fields
        return fields;
    }

    macro public static function addTypeField():Array<Field>
    {
        // Initial fields get
        var fields = Context.getBuildFields();
        var type = Context.toComplexType(Context.getLocalType());

        // build or create constructor
        var constructor:Field = null;

        // find constructor
        for (field in fields)
        {
            switch (field.name)
            {
                case 'new':
                    constructor = field;
                    fields.remove(constructor);
            }
        }

        var constructor_exprs:Array<Expr> = [
            macro
            {
                this.name = name;
                Model.registerInstance(this.type, this);
            }
        ];

        // search for an existing static final field named Type
        var typeStaticField:Field = null;
        for (field in fields)
        {
            switch (field.name)
            {
                case 'TYPE':
                    typeStaticField = field;
                case _:
            }
        }

        // get type name
        var typeName:String;
        switch (type)
        {
            case TPath(typePath):
                if (typePath.sub != null)
                {
                    typeName = typePath.sub;
                }
                else
                {
                    typeName = typePath.name;
                }
            case _:
        }

        if (typeStaticField == null)
        {
            var typeStaticField:Field = {
                name: 'TYPE',
                access: [APublic, AStatic, AFinal],
                pos: Context.currentPos(),
                kind: FVar(macro :String, macro $v{typeName})
            };
            fields.push(typeStaticField);
        }
        else
        {
            // find default value of typeStaticField
            switch (typeStaticField.kind)
            {
                case FVar(t, e):
                    switch (e.expr)
                    {
                        case EConst(CString(s)):
                            typeName = s;
                        case _:
                    }
                case _:
            }
        }

        // create field
        var typeField:Field = {
            name: 'type',
            access: [APublic],
            pos: Context.currentPos(),
            kind: FProp("default", "null", macro :String, macro $v{typeName})
        };

        // add expression to constructor
        var nameArg:FunctionArg = {name: "name", type: macro :String, opt: false};

        if (constructor == null)
        {
            constructor = {
                name: 'new',
                access: [APublic],
                pos: Context.currentPos(),
                kind: FFun({
                    args: [nameArg],
                    expr: macro $b{constructor_exprs},
                    ret: macro :Void
                })
            };
        }
        else
        {
            switch (constructor.kind)
            {
                case FFun(f):
                    constructor_exprs.insert(0, f.expr);
                    f.expr = macro $b{constructor_exprs};
                    f.args.insert(0, nameArg);
                case _:
                    throw "Constructor is not a function";
            }
        }

        // add fields to array
        fields.push(constructor);
        fields.push(typeField);

        // return fields
        return fields;
    }

    macro public static function addJsonParser():Array<Field>
    {
        // Initial fields
        var fields = Context.getBuildFields();
        var type = Context.toComplexType(Context.getLocalType());

        var parserField:Field = null;
        for (field in fields)
        {
            switch (field.name)
            {
                case 'parser':
                    if (field.access.contains(AStatic) && field.access.contains(AFinal))
                        parserField = field;
                case _:
            }
        }
        if (parserField == null)
        {
            throw new Exception("No parser field found. A static final json2object.JsonParser parser field must be declared.");
        }

        // create json parser
        var parser:Field = {
            name: "fromJson",
            access: [APublic, AStatic],
            pos: Context.currentPos(),
            kind: FFun({
                args: [{name: "json", type: macro :String, opt: false}],
                expr: macro
                {
                    return parser.fromJson(json);
                },
                ret: macro :$type
            })
        }

        fields.push(parser);
        // return fields
        return fields;
    }

    macro public static function addJsonWriter():Array<Field>
    {
        // Initial fields
        var fields = Context.getBuildFields();
        var type = Context.getLocalType();
        var complexType = Context.toComplexType(type);

        var writerField:Field = null;
        for (field in fields)
        {
            switch (field.name)
            {
                case 'writer':
                    if (field.access.contains(AStatic) && field.access.contains(AFinal))
                        writerField = field;
                case _:
            }
        }
        if (writerField == null)
        {
            throw new Exception("No writer field found. A static final json2object.JsonWriter writer field must be declared.");
        }

        // create json parser
        var serializer:Field = {
            name: "toJson",
            access: [APublic],
            pos: Context.currentPos(),
            kind: FFun({
                args: [],
                expr: macro
                {
                    return writer.write(this);
                },
                ret: macro :String
            })
        }

        fields.push(serializer);
        // return fields
        return fields;
    }

    macro public static function referenceMacro2():ComplexType
    {
        // Initial fields
        var fields = Context.getBuildFields();
        var type = Context.toComplexType(Context.getLocalType());
        // get type parameter
        var modelType:ComplexType = null;
        switch (type)
        {
            case TPath(p):
                switch (p.params[0])
                {
                    case TPType(t):
                        modelType = t;
                    case _:
                }
            case _:
        }
        var model_type = modelType.toType();
        if (model_type == null)
        {
            return null;
        }
        var model_type_field = TypeTools.findField(model_type.getClass(), "TYPE", true);
        var type_value:String;
        switch (model_type_field.expr().expr)
        {
            case TConst(c):
                switch (c)
                {
                    case TString(s):
                        type_value = s;
                    case _:
                }
            case _:
        }
        // add type field to reference
        var typeField:Field = {
            name: 'type',
            access: [AStatic],
            pos: Context.currentPos(),
            kind: FVar(macro :String, macro $v{type_value})
        };
        fields.push(typeField);
        return null;
    }

    macro public static function referenceMacro():ComplexType
    {
        // Initial fields
        var fields = Context.getBuildFields();
        var type = Context.toComplexType(Context.getLocalType());

        // get type parameter
        var tparamCT = MacroUtil.getTypeParameter(type, 0);
        var tname = tparamCT.toString().replace(".", "_");
        var tparam = tparamCT.toType();
        var tclass = MacroUtil.getTypeClass(tparam);
        var typeField = TypeTools.findField(tclass, "TYPE", true);
        var typeValue:String;
        switch (typeField.expr().expr)
        {
            case TConst(c):
                switch (c)
                {
                    case TString(s):
                        typeValue = s;
                    case _:
                }
            case _:
        }
        var name = "Reference_" + tname + "_" + counter++;
        Context.defineType({
            pos: Context.currentPos(),
            pack: [],
            name: name,
            kind: TDAbstract(macro :String),
            fields: [
                {
                    pos: Context.currentPos(),
                    name: "new",
                    access: [APublic],
                    kind: FFun({
                        ret: null,
                        expr: macro this = value,
                        args: [{name: "value", type: macro :String, opt: false}],
                    })
                },
                {
                    pos: Context.currentPos(),
                    name: "getType",
                    access: [APublic],
                    kind: FFun({
                        ret: macro :String,
                        expr: macro return $v{typeValue},
                        args: [],
                    })
                },
                {
                    pos: Context.currentPos(),
                    name: "get",
                    access: [APublic],
                    kind: FFun({
                        ret: macro :$tparamCT,
                        expr: macro return cast olib.models.Model.getInstance($v{typeValue}, this),
                        args: [],
                    })
                }
            ]
        });

        return TPath({pack: [], name: name});
    }
}
