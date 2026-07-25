from pathlib import Path

def parse_schema_and_table() -> dict :
    """
    Parsing schemas under jobs/ and tables under schemas/
    Schemas must contain at least one dir
    Tables must contain exactly one .sql and one .yaml file
    Outputs dict containing schemas and list of tables on it
    """

    jobs_dir = Path(__file__).resolve().parents[2] / "jobs"

    if not jobs_dir.exists():
        raise RuntimeError(f"Jobs directory not found.")

    schemas = sorted(
        (d for d in jobs_dir.iterdir() if d.is_dir()),
        key=lambda p: p.name
    )
    
    schemas_and_tables = {
        "schemas_and_table": {}
    }

    if not schemas:
        raise RuntimeError("No schema found. Please add a schema to run the DAG.")

    for schema in schemas:       
        # print(f"Schema: {schema.name}")
        schemas_and_tables["schemas_and_table"][schema.name] = []
        tables = sorted(
            (t for t in schema.iterdir() if t.is_dir()),
            key=lambda p: p.name
        )

        if not tables:
            raise RuntimeError(f"No table found under schema '{schema.name}'. Please add table before running DAG")
        
        for table in tables:
            files = [f for f in table.iterdir() if f.is_file()]
            sql_files = [f for f in files if f.suffix == ".sql"]
            yaml_files = [f for f in files if f.suffix in (".yaml", ".yml")]

            if len(sql_files) != 1:
                raise RuntimeError(
                    f"Table '{table.name}' under schema '{schema.name}' must contain exactly one SQL model. "
                    f"Found {len(sql_files)}."
                )
            
            if len(yaml_files) != 1:
                raise RuntimeError(
                    f"Table '{table.name}' under schema '{schema.name}' must contain exactly one YAML config. "
                    f"Found {len(yaml_files)}."
                )   

            schemas_and_tables["schemas_and_table"][schema.name].append(table.name)

    return schemas_and_tables

print(parse_schema_and_table())

