Oracle SQL rearranger
===

The purpose of this tool is to take Oracle schema export 
(usually produced with Oracle SQL developer)
and rearrange/group statements in deterministic order 
for better visibility and easier side-by-side comparison.

Usage
---

The app expects single argument (path to an input file) 
and produces resulting file with the same name + `_sorted` suffix.

There are several options to start using the app:

- 🐳 if you have Docker installed, `cd` to the directory containing target input file 
  and execute ``docker run --rm -v`pwd`:`pwd` -w`pwd` ghcr.io/gavvvr/oracle-sql-rearranger $IN_FILE.sql``
- ☕️ If you have Java 11+ installed on your machine, you can run the app with `java -jar oracle-sql-rearranger.jar`. 
  The `jar` file can be obtained:
  - ⬇️ either by downloading it from [releases](https://github.com/gavvvr/oracle-sql-rearranger/releases) page
  - 👨‍💻 or by building it on your own with `mvn package -DskipTests` and locating the artifact in `target` folder

Supported statements
---

- DB links (`Create_database_linkContext`)
- Sequences (`Create_sequenceContext`)
- Types (`Create_typeContext`)
- Synonyms (some can be associated from corresponding tables) (`Create_synonymContext`)

- Functions (`Create_function_bodyContext`)
- Procedures (`Create_procedure_bodyContext`, `Procedure_callContext`)
- Packages (can be grouped with package bodies) (`Create_packageContext`, `Create_package_bodyContext`)

- Tables (`Create_tableContext`)
    - Comment (`Comment_on_tableContext`)
    - Column comments(`Comment_on_columnContext`)
    - Constraints and FKs (`Alter_tableContext`)
    - Indexes (can be grouped with associated table or view) (`Create_indexContext`, `Alter_indexContext`)
    - Triggers (can 100% be associated with tables) (`Create_triggerContext`, `Alter_triggerContext`)
- Views (`Create_viewContext`)
    - Comment (`Comment_on_tableContext`)
    - Column comments(`Comment_on_columnContext`)

- MView Logs (`Create_materialized_view_logContext`)
    - Comments (`Comment_on_mviewContext`)

If db object can be `GRANT`ed, then the grant statement (`Grant_statementContext`)
gets usually grouped with object definition.

Other statements get sorted by natural ordering.
