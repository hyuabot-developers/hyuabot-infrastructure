import re
import unittest
from pathlib import Path


DATABASE_DIR = Path(__file__).resolve().parents[1]
BASE_SCHEMA_PATH = DATABASE_DIR / "create_database.sql"
MIGRATION_PATH = DATABASE_DIR / "migrations" / "20261004_redesign.sql"
CLEANUP_SQL_PATH = DATABASE_DIR / "manual_cleanup" / "remove_special_day.sql"

CREATE_TABLE = re.compile(
    r"create\s+table\s+if\s+not\s+exists\s+(\w+)\s*\((.*?)\n\);",
    re.IGNORECASE | re.DOTALL,
)
CREATE_INDEX = re.compile(
    r"create\s+index\s+if\s+not\s+exists\s+(\w+)\s+on\s+(\w+)\s*\(([^;]+)\);",
    re.IGNORECASE | re.DOTALL,
)
ADD_COLUMN = re.compile(
    r"alter\s+table\s+(\w+)\s+add\s+column\s+if\s+not\s+exists\s+"
    r"(\w+)\s+([^;]+);",
    re.IGNORECASE,
)
EXPECTED_ADDED_TABLES = {
    "bus_location",
    "bus_route_station",
    "subway_alert",
    "subway_station_facility",
    "subway_train_delay",
}
EXPECTED_ADDED_COLUMNS = {
    ("bus_realtime", "current_stop_name"),
    ("bus_realtime", "plate_no"),
    ("bus_realtime", "crowded"),
    ("bus_realtime", "state_code"),
    ("reading_room", "unable_message"),
    ("subway_realtime", "arrival_message"),
    ("subway_realtime", "arrival_message_detail"),
    ("subway_realtime", "remaining_seconds"),
    ("subway_realtime", "arrival_code"),
}
EXPECTED_ADDED_INDEXES = {"idx_subway_alert_route"}


def normalized(sql: str) -> str:
    return re.sub(r"\s+", " ", sql).strip().lower()


def table_definitions(sql: str) -> dict[str, str]:
    return {name.lower(): body for name, body in CREATE_TABLE.findall(sql)}


def index_definitions(sql: str) -> dict[str, tuple[str, str]]:
    return {
        name.lower(): (table.lower(), normalized(columns))
        for name, table, columns in CREATE_INDEX.findall(sql)
    }


class RedesignMigrationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.base_schema = BASE_SCHEMA_PATH.read_text()
        cls.migration = MIGRATION_PATH.read_text()

    def test_all_migration_ddl_is_guarded_for_repeat_application(self) -> None:
        create_table_count = len(
            re.findall(r"\bcreate\s+table\b", self.migration, re.IGNORECASE)
        )
        create_index_count = len(
            re.findall(r"\bcreate\s+index\b", self.migration, re.IGNORECASE)
        )
        alter_table_count = len(
            re.findall(r"\balter\s+table\b", self.migration, re.IGNORECASE)
        )

        self.assertEqual(
            create_table_count,
            len(CREATE_TABLE.findall(self.migration)),
        )
        self.assertEqual(
            create_index_count,
            len(CREATE_INDEX.findall(self.migration)),
        )
        self.assertEqual(
            alter_table_count,
            len(ADD_COLUMN.findall(self.migration)),
        )
        self.assertRegex(
            self.migration,
            r"(?is)^\s*begin\s*;.*\bcommit\s*;\s*$",
        )
        self.assertNotRegex(
            self.migration,
            r"(?i)\b(drop|truncate|rename)\s+(table|column|index)\b",
        )
        statements = [
            statement.strip()
            for statement in re.sub(r"--[^\n]*", "", self.migration).split(";")
        ]
        statements = [statement for statement in statements if statement]
        allowed_statements = (
            re.compile(r"(?is)^begin$"),
            re.compile(r"(?is)^commit$"),
            re.compile(
                r"(?is)^alter\s+table\s+\w+\s+add\s+column\s+"
                r"if\s+not\s+exists\s+\w+\s+.+$"
            ),
            re.compile(
                r"(?is)^create\s+table\s+if\s+not\s+exists\s+"
                r"\w+\s*\(.+\)$"
            ),
            re.compile(
                r"(?is)^create\s+index\s+if\s+not\s+exists\s+"
                r"\w+\s+on\s+\w+\s*\(.+\)$"
            ),
        )
        self.assertTrue(
            all(
                any(
                    pattern.fullmatch(statement)
                    for pattern in allowed_statements
                )
                for statement in statements
            ),
            "The migration contains a statement outside the repeat-safe "
            "additive DDL allowlist",
        )

    def test_migration_tables_match_the_fresh_database_schema(self) -> None:
        migration_tables = table_definitions(self.migration)
        base_tables = table_definitions(self.base_schema)

        self.assertEqual(set(migration_tables), EXPECTED_ADDED_TABLES)
        self.assertTrue(migration_tables)
        for table_name, migration_body in migration_tables.items():
            self.assertIn(
                table_name,
                base_tables,
                f"{table_name} is absent from create_database.sql",
            )
            self.assertEqual(
                normalized(migration_body),
                normalized(base_tables[table_name]),
                f"{table_name} differs between the migration and "
                "create_database.sql",
            )

    def test_migration_columns_match_the_fresh_database_schema(self) -> None:
        base_tables = table_definitions(self.base_schema)
        additions = ADD_COLUMN.findall(self.migration)

        actual_columns = {
            (table.lower(), column.lower())
            for table, column, _ in additions
        }
        self.assertEqual(actual_columns, EXPECTED_ADDED_COLUMNS)
        self.assertTrue(additions)
        for table_name, column_name, migration_declaration in additions:
            self.assertIn(
                table_name.lower(),
                base_tables,
                f"{table_name} is absent from create_database.sql",
            )
            declarations = [
                line.strip().rstrip(",")
                for line in base_tables[table_name.lower()].splitlines()
                if re.match(
                    rf"\s*{re.escape(column_name)}\s+",
                    line,
                    re.IGNORECASE,
                )
            ]
            self.assertEqual(
                len(declarations),
                1,
                f"Expected one {table_name}.{column_name} in "
                "create_database.sql",
            )
            base_declaration = re.sub(
                rf"^{re.escape(column_name)}\s+",
                "",
                declarations[0],
                flags=re.IGNORECASE,
            )
            self.assertEqual(
                normalized(migration_declaration),
                normalized(base_declaration),
                f"{table_name}.{column_name} differs between the migration "
                "and create_database.sql",
            )

    def test_migration_indexes_match_the_fresh_database_schema(self) -> None:
        migration_indexes = index_definitions(self.migration)
        base_indexes = index_definitions(self.base_schema)

        self.assertEqual(set(migration_indexes), EXPECTED_ADDED_INDEXES)
        self.assertTrue(migration_indexes)
        for index_name, definition in migration_indexes.items():
            self.assertIn(
                index_name,
                base_indexes,
                f"{index_name} is absent from create_database.sql",
            )
            self.assertEqual(
                definition,
                base_indexes[index_name],
                f"{index_name} differs between the migration and "
                "create_database.sql",
            )

    def test_special_day_cleanup_is_separate_and_limited(self) -> None:
        cleanup = CLEANUP_SQL_PATH.read_text()
        statements = [
            statement.strip()
            for statement in re.sub(r"--[^\n]*", "", cleanup).split(";")
        ]
        statements = [normalized(statement) for statement in statements if statement.strip()]

        self.assertNotIn("special_day", self.migration.lower())
        self.assertNotIn("special_day", self.base_schema.lower())
        self.assertEqual(
            statements,
            [
                "begin",
                "delete from holiday_sync_state where source = 'kasi_special'",
                "drop table if exists special_day",
                "commit",
            ],
        )
        self.assertNotRegex(cleanup, r"(?i)\bcascade\b")


if __name__ == "__main__":
    unittest.main()
