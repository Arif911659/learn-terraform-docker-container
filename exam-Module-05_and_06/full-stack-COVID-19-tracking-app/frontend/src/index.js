import React from 'react';
import { createRoot } from 'react-dom/client'; // Import createRoot from react-dom/client
import App from './App'; // Ensure this path matches the location of your App.js file
import './index.css'; // Optional: Add your CSS if you have any

const container = document.getElementById('root'); // Get the root container
const root = createRoot(container); // Create a root

root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
