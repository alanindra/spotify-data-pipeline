import parser
from pathlib import Path

def get_tables_and_dependencies() -> dict:
    """ 
    Getting list of tables, and its dependencies
    Stored in dict like the following example"
    graph = {
        "table_1": ["upstream_1", "upstream_2"],
        "table_2": ["upstream_1", "upstream_3"],
        "table_3": []
    }
    """
    jobs_dir = Path(__file__).resolve().parents[2] / "jobs"    
    
    tables_and_dependencies= {
        "tables_and_dependencies": {}
    }

    schemas = sorted(
        (d for d in jobs_dir.iterdir() if d.is_dir()),
        key=lambda p: p.name
    )
    for schema in schemas:  
        # print(schema.name)
        tables = sorted(
            (t for t in schema.iterdir() if t.is_dir()),
            key=lambda p: p.name
        )
        for table in tables:
            # print(table.name)
            # tables_and_dependencies["tables_and_dependencies"][table.name] = []
            for file in table.iterdir():
                if file.suffix == ".sql":
                    sql_query_path = Path(__file__).resolve().parents[2] / "jobs" / schema.name / table.name / file.name
                    # print(sql_query_path)
                    # print(file.name)
                    dependencies = parser.parse_table_names_from_sql_query(sql_query_path)
                    tables_and_dependencies["tables_and_dependencies"][f'{schema.name}.{table.name}'] = dependencies

    return tables_and_dependencies

def resolve_dependency(tables_and_dependencies_list) -> list :
    """
    For the list_tables_and_dependencies, it should be a dict like this:
    graph = {
        "table_1": ["upstream_1", "upstream_2"],
        "table_2": ["upstream_1", "upstream_3"],
        "table_3": []
    }
    """
    
    executed = []

    while len(executed) < len(tables_and_dependencies_list):
        print(f"utils.task.dependency_resolver – Table with known dependency so far: {executed}")
        is_resolved = False
        for table, dependencies in tables_and_dependencies_list.items():
            if table in executed:
                continue
            print(f"utils.task.dependency_resolver – Checking dependency for table '{table}'...")
            if all(dep in executed for dep in dependencies):
                print(f"utils.task.dependency_resolver – Dependency found for table '{table}'")
                executed.append(table)
                is_resolved = False
            else:
                print(f"utils.task.dependency_resolver – Table '{table}' is waiting for dependencies for following tables: '{dependencies}'")
        if not is_resolved:
            table_keys = set(tables_and_dependencies_list.keys())
            missing_tables = []
            for table, dependencies in tables_and_dependencies_list.items():
                for dep in dependencies:
                    if dep not in table_keys:
                        missing_tables.append((table, dep))
            raise RuntimeError(f"utils.task.dependency_resolver – Cannot resolve dependency. Check for missing or circular dependencies. Unresolved tables and dependencies: {missing_tables}")

    print("utils.task.dependency_resolver – All dependencies for all tables found")
    print(f"utils.task.dependency_resolver – Table execution order: {executed}")

    return executed

tables_and_dependencies_list = get_tables_and_dependencies()
resolve_dependency(tables_and_dependencies_list["tables_and_dependencies"])
