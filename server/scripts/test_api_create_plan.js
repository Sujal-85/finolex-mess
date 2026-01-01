const axios = require('axios');

async function testCreatePlan() {
    try {
        console.log('Creating Test Plan...');
        const res = await axios.post('http://localhost:4000/plans', {
            name: 'Test Setup Plan',
            price: 100,
            active: true,
            type: 'monthly',
            startDate: '2026-03-01',
            endDate: '2026-03-31'
        });
        console.log('Response:', res.data);
    } catch (err) {
        console.error('Error:', err.message);
        if (err.response) console.error(err.response.data);
    }
}

testCreatePlan();
