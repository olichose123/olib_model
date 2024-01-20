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
        try
        {
            constructor = MacroUtil.getFieldByName(fields, "new");
            fields.remove(constructor);
        }
        catch (e:MacroException) {}

        var initializableFields:Array<Field> = MacroUtil.filterFieldsByAccess(fields, [APublic], [AStatic, AFinal, APrivate, AOverride]);
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
            for (arg in constructor_args)
                MacroUtil.addArgumentToFunction(constructor, arg);
            for (expr in constructor_exprs)
                MacroUtil.addExpressionToFunction(constructor, expr);
        }

        // add fields to array
        fields.push(constructor);

        // return fields
        return fields;
    }

    macro public static function addNameAndTypeField():Array<Field>
    {
        // Initial fields get
        var fields = Context.getBuildFields();
        var type = Context.toComplexType(Context.getLocalType());

        var constructor:Field = null;
        try
        {
            constructor = MacroUtil.getFieldByName(fields, "new");
            fields.remove(constructor);
        }
        catch (e:MacroException) {}

        var constructor_exprs:Array<Expr> = [
            macro
            {
                this.name = name;
                Model.register(this.type, this);
            }
        ];

        // search for an existing static final field named Type
        var typeStaticField:Field = null;
        try
        {
            typeStaticField = MacroUtil.getFieldByName(fields, "TYPE");
            fields.remove(typeStaticField);
        }
        catch (e:MacroException) {}
        var typeName:String = MacroUtil.getTypeName(type);

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
            MacroUtil.addArgumentToFunction(constructor, nameArg, true);
            for (expr in constructor_exprs)
                MacroUtil.addExpressionToFunction(constructor, expr);
        }

        // add fields to array
        fields.push(constructor);
        fields.push(typeField);

        // return fields
        return fields;
    }

    macro public static function addJsonParser():Array<Field>
    {
        var fields = Context.getBuildFields();
        var type = Context.toComplexType(Context.getLocalType());

        var parserField:Field = {
            name: "parser",
            access: [APublic, AStatic, AFinal],
            pos: Context.currentPos(),
            kind: FVar(macro :json2object.JsonParser<$type>, macro new json2object.JsonParser<$type>())
        };
        fields.push(parserField);

        return fields;
    }

    macro public static function addJsonWriter():Array<Field>
    {
        var fields = Context.getBuildFields();
        var type = Context.toComplexType(Context.getLocalType());

        var writerField:Field = {
            name: "writer",
            access: [APublic, AStatic, AFinal],
            pos: Context.currentPos(),
            kind: FVar(macro :json2object.JsonWriter<$type>, macro new json2object.JsonWriter<$type>())
        };
        fields.push(writerField);

        return fields;
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
            kind: TDAbstract(macro :String, [AbFrom(macro :String), AbTo(macro :String)]),
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
                        expr: macro return cast olib.models.Model.get($v{typeValue}, this),
                        args: [],
                    })
                }
            ]
        });

        return TPath({pack: [], name: name});
    }
}
