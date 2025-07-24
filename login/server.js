const express = require('express');
const bodyParser = require('body-parser');
const cookieParser = require('cookie-parser');
const path = require('path');

const app = express();
const port = 3000;

// Hardcoded credentials
const USERNAME = 'admin';
const PASSWORD = 'password';

app.use(bodyParser.urlencoded({ extended: true }));
app.use(cookieParser());

// Serve the login page
app.get('/login', (req, res) => {
    res.sendFile(path.join(__dirname, 'login.html'));
});

// Handle login form submission
app.post('/login', (req, res) => {
    const { username, password } = req.body;
    if (username === USERNAME && password === PASSWORD) {
        // Set a cookie to remember the user
        res.cookie('auth', 'true', { maxAge: 900000, httpOnly: true });
        res.redirect('/');
    } else {
        res.redirect('/login');
    }
});

// Middleware to check for authentication
app.use((req, res, next) => {
    if (req.cookies.auth === 'true') {
        next();
    } else {
        res.redirect('/login');
    }
});

// Protected route that will be proxied to ttyd
app.get('/', (req, res) => {
    res.setHeader('X-WEBAUTH-USER', 'admin');
    res.send('Authentication successful. Redirecting to ttyd...');
});

app.listen(port, () => {
    console.log(`Login server listening at http://localhost:${port}`);
});
