from __future__ import annotations

import json
import sys
from pathlib import Path

try:
    from jsonschema.validators import validator_for
except ModuleNotFoundError:
    print("jsonschema dependency is unavailable", file=sys.stderr)
    raise SystemExit(3)


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: Validate-ResearchRoutingSchema.py SCHEMA INSTANCE", file=sys.stderr)
        return 2
    try:
        schema = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8-sig"))
        instance = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8-sig"))
        validator_type = validator_for(schema)
        validator_type.check_schema(schema)
        errors = sorted(validator_type(schema).iter_errors(instance), key=lambda e: list(e.absolute_path))
    except Exception as exc:
        print(f"schema validation setup failed: {exc}", file=sys.stderr)
        return 2
    if errors:
        for error in errors[:20]:
            path = ".".join(str(part) for part in error.absolute_path) or "<root>"
            print(f"{path}: {error.message}", file=sys.stderr)
        return 1
    print("ROUTING_JSON_SCHEMA_PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())