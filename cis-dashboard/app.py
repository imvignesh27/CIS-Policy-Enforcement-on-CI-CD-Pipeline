from flask import Flask, render_template
from parser import parse_plan, parse_compliance
from risk_model import calculate_risk, send_slack_alert

app = Flask(__name__)

@app.route('/')
def dashboard():
    plan_data = parse_plan('data/plan.json')
    violations = parse_compliance('data/compliance-report.txt')
    risk_score, categorized, category_counts = calculate_risk(violations)

    send_slack_alert(risk_score, categorized)  # Trigger alert if needed

    return render_template('dashboard.html',
                           risk_score=risk_score,
                           categorized=categorized,
                           category_counts=category_counts,
                           resources=plan_data)

if __name__ == '__main__':
    app.run(debug=True)
