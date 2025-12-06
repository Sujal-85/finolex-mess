const mongoose = require('mongoose');
const MenuItem = require('./models/MenuItem');
require('dotenv').config();

const menuItems = [];

const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

// Helper to add item for specific days
const addItem = (name, description, price, category, mealType, isVeg, targetDays, calories) => {
    targetDays.forEach(day => {
        menuItems.push({
            name,
            description,
            price,
            category,
            mealType,
            isVeg,
            day,
            calories
        });
    });
};

// Breakfast
addItem('Poha', 'Flattened rice with onions', 20, 'Breakfast', 'breakfast', true, ['Monday', 'Wednesday', 'Friday'], 180);
addItem('Upma', 'Semolina porridge', 20, 'Breakfast', 'breakfast', true, ['Tuesday', 'Thursday', 'Saturday'], 200);
addItem('Idli Sambar', 'Steamed rice cakes', 30, 'Breakfast', 'breakfast', true, days, 150);
addItem('Medu Vada', 'Crispy lentil donuts', 35, 'Breakfast', 'breakfast', true, ['Sunday'], 300);

// Lunch
addItem('Veg Thali', 'Chapati, Rice, Dal, Bhaji', 60, 'Lunch', 'lunch', true, days, 600);
addItem('Egg Thali', 'Chapati, Rice, Egg Curry', 80, 'Lunch', 'lunch', false, ['Wednesday', 'Friday', 'Sunday'], 700);
addItem('Chicken Thali', 'Chapati, Rice, Chicken Curry', 120, 'Lunch', 'lunch', false, ['Sunday'], 850);

// Snacks
addItem('Vada Pav', 'Mumbai burger', 15, 'Snacks', 'snacks', true, days, 250);
addItem('Samosa', 'Fried pastry', 15, 'Snacks', 'snacks', true, ['Monday', 'Wednesday', 'Friday'], 200);

// Dinner
addItem('Veg Pulao', 'Spiced rice with veg', 50, 'Dinner', 'dinner', true, ['Monday', 'Tuesday', 'Thursday', 'Saturday'], 400);
addItem('Dal Khichdi', 'Rice and lentils', 50, 'Dinner', 'dinner', true, ['Wednesday', 'Friday', 'Sunday'], 350);
addItem('Chapati Bhaji', '3 Chapatis with curry', 50, 'Dinner', 'dinner', true, days, 450);

mongoose.connect(process.env.MONGODB_URI || "mongodb+srv://finolex:finolex_canteen@mess.dqhbzlz.mongodb.net/finolex_canteen?appName=Mess", {
    useNewUrlParser: true,
    useUnifiedTopology: true,
})
    .then(async () => {
        console.log('Connected to MongoDB');

        try {
            // Clear existing items
            await MenuItem.deleteMany({});
            console.log('Cleared existing menu items');

            // Insert new items
            await MenuItem.insertMany(menuItems);
            console.log(`Seeded ${menuItems.length} menu items successfully`);

            process.exit(0);
        } catch (error) {
            console.error('Error seeding data:', error);
            process.exit(1);
        }
    })
    .catch((err) => {
        console.error('MongoDB connection error:', err);
        process.exit(1);
    });
