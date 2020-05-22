#!/usr/bin/node

/**
 * This server script is purely for testing purposes
 */
const express = require('express');
const app = express();

app.use(express.static(__dirname + '/www'));

app.listen(5000, () => console.log('Node.js web server at port 5000 is running...'));
