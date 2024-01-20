# v1.0.0
2024-01-22
---
* Replace support for declaring `Model.TYPE` manually with metadata value `@:customTypeName("MyTypeName")`
* Add Duplicate Handling feature to overwrite, ignore or throw an error if two models of the same type and name are created
* Add a per-model Duplicate Handling feature, using metadata variable `@:duplicateHandling("Error")`, `@:duplicateHandling("Ignore")` or `@:duplicateHandling("Overwrite")`.
* Rename static variable `Model.TYPE` to `Model.Type`

# v0.1.0
2024-01-20
---
* Initial release
