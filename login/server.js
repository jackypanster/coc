const express = require('express');
const bodyParser = require('body-parser');
const cookieParser = require('cookie-parser');
const path = require('path');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();
const port = 3000;

// Hardcoded credentials
const USERNAME = 'admin';
const PASSWORD = 'password';

// Session storage with timestamps (in production, use Redis or database)
const activeSessions = new Map(); // sessionId -> { createdAt, lastAccess }

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
        // Generate a unique session ID
        const sessionId = Date.now().toString() + Math.random().toString(36);
        const now = Date.now();
        activeSessions.set(sessionId, {
            createdAt: now,
            lastAccess: now
        });
        
        // Set a session-only cookie (no maxAge = expires when browser closes)
        res.cookie('auth', sessionId, { 
            httpOnly: true,
            sameSite: 'strict',
            secure: false, // Set to true in production with HTTPS
            // No maxAge means session cookie - expires when browser closes
        });
        res.redirect('/');
    } else {
        res.redirect('/login');
    }
});

// Middleware to check for authentication
app.use((req, res, next) => {
    const sessionId = req.cookies.auth;
    
    // Check if session exists and is valid
    if (sessionId && activeSessions.has(sessionId)) {
        const session = activeSessions.get(sessionId);
        const now = Date.now();
        const sessionAge = now - session.createdAt;
        const lastAccessAge = now - session.lastAccess;
        
        // Session expires after 5 minutes of creation OR 2 minutes of inactivity
        if (sessionAge > 300000 || lastAccessAge > 120000) {
            // Session expired, remove it
            activeSessions.delete(sessionId);
            res.clearCookie('auth');
            res.redirect('/login');
            return;
        }
        
        // Update last access time
        session.lastAccess = now;
        next();
    } else {
        // Clear invalid cookie
        res.clearCookie('auth');
        res.redirect('/login');
    }
});

// Add logout endpoint for security
app.post('/logout', (req, res) => {
    const sessionId = req.cookies.auth;
    if (sessionId) {
        activeSessions.delete(sessionId);
        res.clearCookie('auth');
    }
    res.redirect('/login');
});

// Clean up expired sessions every 30 seconds
setInterval(() => {
    const now = Date.now();
    let cleanedCount = 0;
    
    for (const [sessionId, session] of activeSessions.entries()) {
        const sessionAge = now - session.createdAt;
        const lastAccessAge = now - session.lastAccess;
        
        // Remove sessions older than 5 minutes or inactive for 2 minutes
        if (sessionAge > 300000 || lastAccessAge > 120000) {
            activeSessions.delete(sessionId);
            cleanedCount++;
        }
    }
    
    if (cleanedCount > 0) {
        console.log(`Cleaned up ${cleanedCount} expired sessions`);
    }
}, 30000); // 30 seconds

// Create proxy to ttyd
const ttydProxy = createProxyMiddleware({
    target: 'http://127.0.0.1:7681',
    changeOrigin: true,
    ws: true, // Enable WebSocket proxying
    onProxyReq: (proxyReq, req, res) => {
        // Add authentication header for ttyd
        proxyReq.setHeader('X-WEBAUTH-USER', 'admin');
    }
});

// Protected route that proxies to ttyd
app.use('/', ttydProxy);

app.listen(port, () => {
    console.log(`Login server listening at http://localhost:${port}`);
});
