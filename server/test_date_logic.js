const storedDate = new Date("2025-12-01T00:00:00.000Z");
const newDateString = "2025-12-01"; // What seemingly comes from req.body

console.log("Stored:", storedDate.toISOString(), storedDate.getTime());
console.log("New:", new Date(newDateString).toISOString(), new Date(newDateString).getTime());

if (new Date(newDateString).getTime() !== storedDate.getTime()) {
    console.log("Dates are DIFFERENT - Update Triggered");
} else {
    console.log("Dates are SAME - Update Skipped");
}

// Test with different date
const changedDateString = "2026-01-01";
console.log("\nChanging to:", changedDateString);
if (new Date(changedDateString).getTime() !== storedDate.getTime()) {
    console.log("Dates are DIFFERENT - Update Triggered");
} else {
    console.log("Dates are SAME - Update Skipped");
}
