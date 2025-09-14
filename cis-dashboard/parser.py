import json

def parse_plan(path):
    with open(path) as f:
        data = json.load(f)
    resources = []
    for res in data.get("planned_values", {}).get("root_module", {}).get("resources", []):
        resources.append({
            "type": res["type"],
            "name": res["name"],
            "address": res["address"]
        })
    return resources

def parse_compliance(path):
    violations = []
    with open(path) as f:
        for line in f:
            if "FAILED" in line:
                violations.append(line.strip())
    return violations
