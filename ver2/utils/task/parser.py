from pathlib import Path
import re

def handle_empty_schemas_and_table():
    jobs_dir = Path(__file__).resolve().parents[2] / "jobs"
    if not jobs_dir.exists():
        raise RuntimeError(f"Jobs directory not found.")
    # print('jobs/ OK')
    schemas = sorted(
        (d for d in jobs_dir.iterdir() if d.is_dir()),
        key=lambda p: p.name
    )
    if not schemas:
        raise RuntimeError("No schema found. Please add a schema to run the DAG.")
    for schema in schemas: 
        print(f"Found schema '{schema.name}'")   
        tables = sorted(
            (t for t in schema.iterdir() if t.is_dir()),
            key=lambda p: p.name
        )
        if not tables:
            raise RuntimeError(f"No table found under schema '{schema.name}'. Please add table before running DAG")
        for table in tables:
            print(f"Found table '{table.name}'")  
            # print(table.name)
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
            
def parse_schema_and_table() -> dict :
    """
    Parsing schema names under jobs/ and parsing table names under schema
    Schemas must contain at least one dir
    Tables must contain exactly one .sql and one .yaml file
    Outputs dict containing schemas and list of tables on it
    """

    jobs_dir = Path(__file__).resolve().parents[2] / "jobs"

    schemas = sorted(
        (d for d in jobs_dir.iterdir() if d.is_dir()),
        key=lambda p: p.name
    )
    
    schemas_and_tables = {
        "schemas_and_table": {}
    }

    for schema in schemas:       
        # print(f"Schema: {schema.name}")
        schemas_and_tables["schemas_and_table"][schema.name] = []
        tables = sorted(
            (t for t in schema.iterdir() if t.is_dir()),
            key=lambda p: p.name
        )
        for table in tables:
            schemas_and_tables["schemas_and_table"][schema.name].append(table.name)

    return schemas_and_tables

def parse_table_names_from_sql_query(sql_query_path):
    """ 
    Parsing table names from sql_query_path
    Should ignore any reference to raw datas, as those tables will be executed first
    """
    read_sql_file_as_text = sql_query_path.read_text(encoding="utf-8")
    matches = re.findall(r"\{\{\s*(.*?)\s*\}\}", read_sql_file_as_text)
    return matches

# def parse_sql_query_from_sql_query(sql_query):
#     return(sql_query)
#     # ini buat bersihin format {{}} terus output file .sql aja

# def get_table_dependencies():
#     jobs_dir = Path(__file__).resolve().parents[2] / "jobs"
#     schemas = sorted(
#         (d for d in jobs_dir.iterdir() if d.is_dir()),
#         key=lambda p: p.name
#     )
#     for schema in schemas:   
#         tables = sorted(
#             (t for t in schema.iterdir() if t.is_dir()),
#             key=lambda p: p.name
#         )
#         for tables 
        

import re
path = Path(__file__).resolve().parents[2] / "jobs" / "schema_1" / "table_1" / "query.sql"
# sql = path.read_text(encoding="utf-8")
# matches = re.findall(r"\{\{\s*(.*?)\s*\}\}", sql)
# print(matches)

# handle_empty_schemas_and_table()

parse_table_names_from_sql_query(path)