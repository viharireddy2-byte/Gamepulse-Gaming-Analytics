"""Development-only model inspection and regression compilation; no runtime server."""
from pathlib import Path
import copy
import json
import re
import lkml
import yaml
import sqlglot

ROOT = Path(__file__).resolve().parents[1]
FIELD_KINDS = ('dimensions', 'measures', 'parameters', 'filters', 'dimension_groups')


def load_views():
    raw = {}
    for path in sorted(ROOT.rglob('*.lkml')):
        for view in lkml.load(path.read_text()).get('views', []):
            if view['name'] in raw:
                raise ValueError('Duplicate view: ' + view['name'])
            raw[view['name']] = view
    resolved = {}

    def resolve(name, stack=()):
        if name in stack:
            raise ValueError('Inheritance cycle: ' + name)
        if name in resolved:
            return resolved[name]
        own = copy.deepcopy(raw[name])
        bases = own.get('extends__all', [])
        merged = {}
        for group in bases:
            for parent in group:
                base = resolve(parent, stack + (name,))
                for key, value in base.items():
                    if key in FIELD_KINDS:
                        merged.setdefault(key, []).extend(copy.deepcopy(value))
                    else:
                        merged[key] = copy.deepcopy(value)
        for key, value in own.items():
            if key in FIELD_KINDS:
                fields = {f['name']: f for f in merged.get(key, [])}
                fields.update({f['name']: f for f in value})
                merged[key] = list(fields.values())
            else:
                merged[key] = value
        resolved[name] = merged
        return merged

    for name in raw:
        resolve(name)
    return resolved


def fields(view):
    out = {}
    for kind in FIELD_KINDS:
        for field in view.get(kind, []):
            if kind != 'dimension_groups':
                out[field['name']] = (kind, field)
            elif field.get('type') == 'time':
                for frame in field.get('timeframes', []):
                    out[field['name'] + '_' + frame] = (kind, field)
            else:
                for interval in field.get('intervals', []):
                    out[interval + 's_' + field['name']] = (kind, field)
    return out


def render_sql(name, views=None, parameters=None):
    views = views or load_views()
    view = views[name]
    sql = view['derived_table']['sql']
    sql = re.sub(r'\$\{(\w+)\.SQL_TABLE_NAME\}', lambda m: 'fixture_' + m[1], sql)
    sql = sql.replace('`gamepulse.raw_events`', 'fixture_raw')
    sql = re.sub(r'{% condition \w+ %}.*?{% endcondition %}', 'TRUE', sql, flags=re.S)
    defaults = {p['name']: p.get('default_value') for p in view.get('parameters', [])}
    defaults.update(parameters or {})

    def parameter(match):
        value = defaults[match[1]]
        if value is None:
            raise ValueError('Parameter needs a default: ' + match[1])
        return "'" + str(value).replace("'", "''") + "'"

    return re.sub(r'{% parameter (\w+) %}', parameter, sql)


def measure_sql(view_name, field_name, alias='t', overrides=None):
    """Expand simple standalone view metrics for regression assertions, not Looker SQL."""
    view = load_views()[view_name]
    lookup = fields(view)
    params = {p['name']: p.get('default_value') for p in view.get('parameters', [])}
    params.update(overrides or {})

    def expand(name, stack=()):
        if name in stack:
            raise ValueError('Field cycle: ' + name)
        kind, field = lookup[name]
        sql = field.get('sql', '${TABLE}.' + field['name']).replace('${TABLE}', alias)
        if kind == 'dimension_groups':
            if name.endswith('_date'):
                sql = 'DATE(' + sql + ')'
        sql = re.sub(r'\$\{(\w+)\}', lambda m: '(' + expand(m[1], stack + (name,)) + ')', sql)
        sql = re.sub(r'{% parameter (\w+) %}', lambda m: str(params[m[1]]), sql)
        if kind == 'measures':
            typ = field['type']
            sql = {'sum': lambda: 'SUM(' + sql + ')',
                   'count': lambda: 'COUNT(*)',
                   'count_distinct': lambda: 'COUNT(DISTINCT ' + sql + ')',
                   'average': lambda: 'AVG(' + sql + ')',
                   'median': lambda: 'PERCENTILE_CONT(' + sql + ',0.5) OVER()',
                   'max': lambda: 'MAX(' + sql + ')',
                   'min': lambda: 'MIN(' + sql + ')'}.get(typ, lambda: sql)()
        return sql

    return expand(field_name)


def dependency_order(views=None):
    views = views or load_views()
    ordered = []

    def visit(name, stack=()):
        if name in ordered:
            return
        if name in stack:
            raise ValueError('PDT dependency cycle: ' + name)
        for dep in re.findall(r'\$\{(\w+)\.SQL_TABLE_NAME\}', views[name]['derived_table']['sql']):
            visit(dep, stack + (name,))
        ordered.append(name)

    for name in views:
        visit(name)
    return ordered


def validate():
    views = load_views()
    for name, view in views.items():
        for ref in re.findall(r'\$\{([^}]+)\}', json.dumps(view)):
            if ref == 'TABLE':
                continue
            target, field = ref.split('.', 1) if '.' in ref else (name, ref)
            if target not in views:
                raise ValueError('Missing view ' + ref)
            if field != 'SQL_TABLE_NAME' and field not in fields(views[target]):
                raise ValueError('Missing field ' + name + ': ' + ref)
        sqlglot.parse_one(render_sql(name, views), read='bigquery')
    model = lkml.load((ROOT / 'gamepulse.model.lkml').read_text())
    explores = {e['name'] for e in model['explores']}
    dashboards = list((ROOT / 'lookml_dashboards').glob('*.lookml'))
    for path in dashboards:
        for dashboard in yaml.safe_load(path.read_text()):
            for element in dashboard['elements']:
                if element['explore'] not in explores:
                    raise ValueError('Missing explore: ' + element['explore'])
                for ref in element['fields'] + list(element.get('listen', {}).values()) + element.get('pivots', []):
                    target, field = ref.split('.', 1)
                    if field not in fields(views[target]):
                        raise ValueError('Missing dashboard field ' + ref)
    for path in (ROOT / 'sql').glob('*.sql'):
        script = re.sub(r"ASSERT (.*?) AS '[^']*';", r'SELECT (\1);', path.read_text(), flags=re.S)
        sqlglot.parse(script, read='bigquery')
    dependency_order(views)
    print(f'PASS: {len(views)} views, {len(dashboards)} dashboards, references and SQL syntax')


if __name__ == '__main__':
    validate()
