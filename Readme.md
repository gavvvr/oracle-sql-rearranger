Oracle SQL rearranger
===

The purpose of this tool is to take Oracle schema export 
(usually produced with Oracle SQL developer)
and rearrange/group statements 
for better visibility and easier comparison.

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

change
