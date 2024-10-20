const express = require('express');
const app = express();
const vehicles = require('./data.json');
app.listen(8000, () => console.log("8000 is Listening!"))

app.get('/vehicles', (req, res, next) => {
    res.json(vehicles);
});