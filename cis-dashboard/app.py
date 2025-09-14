def categorize_violation(v):
    v = v.lower()
    if "public" in v or "0.0.0.0/0" in v or "*" in v or "mfa" in v:
        return "Critical", 5
    elif "encryption" in v or "cloudtrail" in v or "admin" in v:
        return "High", 4
    elif "monitoring" in v or "tags" in v or "unused" in v:
        return "Medium", 2
    else:
        return "Low", 1

def calculate_risk(violations):
    categorized = {"Critical": [], "High": [], "Medium": [], "Low": []}
    total_score = 0

    for v in violations:
        category, score = categorize_violation(v)
        categorized[category].append(v)
        total_score += score

    normalized = min(total_score, 100)
    category_counts = {k: len(v) for k, v in categorized.items()}
    return normalized, categorized, category_counts
