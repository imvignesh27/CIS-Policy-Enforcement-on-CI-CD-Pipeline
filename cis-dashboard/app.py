from flask import Flask, render_template
from parser import parse_compliance, parse_plan
from risk_model import calculate_risk

app = Flask(__name__)

@app.route('/')
def dashboard():
    plan_data = parse_plan('data/plan.json')
    compliance_data = parse_compliance('data/compliance-report.txt')
    risk_score, violations = calculate_risk(compliance_data)

    return render_template('dashboard.html',
                           risk_score=risk_score,
                           violations=violations,
                           resources=plan_data)

if __name__ == '__main__':
    app.run(debug=True)
