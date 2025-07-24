# Login Feature Design

This document outlines the design and architecture of the login feature for the Code on Cloud environment.

## 1. Architecture

The login system uses a **Reverse Proxy** pattern. Nginx acts as the gatekeeper in front of the `ttyd` terminal service and a dedicated Node.js login server.

## 2. Authentication Flow

1.  When a user accesses the service, Nginx intercepts the request.
2.  If the user is not authenticated (i.e., no valid session cookie), they are redirected to a custom HTML login page.
3.  This login page is served by a small Node.js (Express) application.
4.  The user submits their credentials (currently hardcoded as `admin`/`password`).
5.  The Node.js server validates the credentials, and if successful, sets an HTTP-only cookie to establish a session.
6.  The user is then redirected back to the main application.
7.  Nginx now sees the valid session cookie and proxies the user's request to the `ttyd` service, granting them access to the terminal.

## 3. Component Breakdown

*   **Nginx**: Manages all incoming traffic, routes users based on authentication status, and handles SSL termination (if configured).
*   **Node.js/Express Server**: A lightweight server responsible only for displaying the login form and validating user credentials.
*   **ttyd**: The core terminal service, configured to only accept internal traffic from the Nginx proxy, preventing direct access.