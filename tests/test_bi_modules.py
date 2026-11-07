"""Portable execution checks. Native BigQuery integration remains a separate gate."""
from pathlib import Path
import re
import json
import hashlib
import lkml
import sys
import unittest
import duckdb
import sqlglot
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from model_tools import ROOT, load_views, dependency_order, render_sql, validate
from build_regression import build


class BusinessIntelligenceTests(unittest.TestCase):
    def test_existing_interfaces_are_unchanged(self):
        baseline=json.loads((ROOT/'tests/compatibility.json').read_text())
        for name,expected in baseline['files'].items():
            self.assertEqual(hashlib.sha256((ROOT/name).read_bytes()).hexdigest(),expected,name)
        model=lkml.load((ROOT/'gamepulse.model.lkml').read_text())
        current={e['name']:e for e in model['explores']}
        for name,expected in baseline['explores'].items():
            self.assertEqual(current[name],expected,name)
        for key,value in baseline['model_settings'].items():
            self.assertEqual(model[key],value,key)

    def test_model_and_dashboard_references(self):
        validate()

    def test_live_model_regressions(self):
        db = duckdb.connect()
        # BigQuery expands UNNEST structs into columns; DuckDB requires an
        # explicit record alias. All data values come from the native fixture.
        script = build()
        raw_statement = script.split(';', 1)[0]
        raw_statement = raw_statement.replace('SELECT * FROM UNNEST([', 'SELECT '+','.join('unnest.'+n for n in ['event_id','game_name','user_id','sec','event_name','amount','revision'])+' FROM UNNEST([')
        sql = self.portable(raw_statement)
        db.execute(sql)
        statements = script[len(script.split(';', 1)[0]) + 1:]
        assertions = []
        for statement in statements.split(';'):
            statement = statement.strip()
            if not statement:
                continue
            if statement.startswith('ASSERT '):
                match = re.fullmatch(r"ASSERT (.*) AS '([^']*)'", statement, re.S)
                self.assertIsNotNone(match, statement)
                expression, label = match.groups()
                assertions.append((label, 'SELECT ' + expression))
            else:
                db.execute(self.portable(statement))
        for label, query in assertions:
            with self.subTest(assertion=label):
                self.assertTrue(db.execute(self.portable(query)).fetchone()[0], label)
        self.assertGreaterEqual(len(assertions), 25)
        db.close()

    @staticmethod
    def portable(sql):
        # SQL dialect adaptations only; project runtime remains BigQuery.
        sql = re.sub(r' LIMIT 1\)', ')', sql)
        sql = re.sub(r'APPROX_TOP_COUNT\((\w+),1\)\[OFFSET\(0\)\]\.value', r'MODE(\1)', sql)
        return sqlglot.transpile(sql, read='bigquery', write='duckdb')[0]


if __name__ == '__main__':
    unittest.main()
