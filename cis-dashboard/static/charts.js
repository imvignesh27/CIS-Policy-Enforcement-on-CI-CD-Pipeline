const ctx = document.getElementById('riskChart').getContext('2d');
const riskChart = new Chart(ctx, {
    type: 'doughnut',
    data: {
        labels: ['Risk', 'Remaining'],
        datasets: [{
            data: [{{ risk_score }}, 100 - {{ risk_score }}],
            backgroundColor: ['#ff4c4c', '#4caf50']
        }]
    },
    options: {
        responsive: true,
        plugins: {
            legend: { position: 'bottom' }
        }
    }
});
