import requests

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

def send_slack_alert(risk_score, categorized):
    webhook_url = 'https://hooks.slack.com/services/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'  # Replace with your actual webhook
    critical = categorized.get("Critical", [])

    if risk_score >= 70 or len(critical) > 0:
        message = f"*🚨 CIS Compliance Alert*\nRisk Score: {risk_score}/100\n"
        if critical:
            message += f"*Critical Violations:* {len(critical)}\n"
            for v in critical[:5]:
                message += f"• {v}\n"
        else:
            message += "No critical violations, but overall risk is high.\n"

        requests.post(webhook_url, json={"text": message})
