const axios = require('axios');

async function testDeletePlan() {
    const planId = '69566b240710bc56ceeae162'; // ID of Test Setup Plan
    try {
        console.log(`Deleting Plan ${planId}...`);
        const res = await axios.delete(`http://localhost:4000/plans/${planId}`);
        console.log('Response:', res.data);
    } catch (err) {
        console.error('Error:', err.message);
        if (err.response) console.error(err.response.data);
    }
}

testDeletePlan();
