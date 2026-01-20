// server.js
const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
const port = 3000;

// Use CORS for all origins, as requested.
app.use(cors());
app.use(express.json());

// --- Database Setup ---
const dbPath = path.resolve(__dirname, 'database.db');
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('Error opening database', err.message);
  } else {
    console.log('Connected to the SQLite database.');
    // Create the products table if it doesn't exist
    db.run(`CREATE TABLE IF NOT EXISTS products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      price REAL NOT NULL,
      stock REAL NOT NULL,
      imagePath TEXT
    )`, (err) => {
      if (err) {
        console.error('Error creating table', err.message);
      } else {
        console.log('Products table is ready.');
      }
    });
  }
});

// --- Image Upload Setup ---
const uploadDir = 'uploads';
// Create the uploads directory if it doesn't exist
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir);
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    // Create a unique filename to prevent overwrites
    cb(null, `${Date.now()}-${file.originalname}`);
  }
});

const upload = multer({ storage: storage });

// Make the 'uploads' directory statically accessible
// This allows the frontend to request images via a URL
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));


// --- Basic Routes (for testing) ---
app.get('/', (req, res) => {
  res.send('Lung Chaing Farm Backend is running!');
});

// --- Product API Endpoints ---

// GET: Fetch all products
app.get('/products', (req, res) => {
  db.all('SELECT * FROM products ORDER BY id DESC', [], (err, rows) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json({ products: rows });
  });
});

// POST: Add a new product
app.post('/products', upload.single('image'), (req, res) => {
  const { name, price, stock } = req.body;
  const imagePath = req.file ? `uploads/${req.file.filename}` : null;

  if (!name || price === undefined || stock === undefined) {
    return res.status(400).json({ error: 'Missing required fields: name, price, stock' });
  }

  const sql = 'INSERT INTO products (name, price, stock, imagePath) VALUES (?, ?, ?, ?)';
  db.run(sql, [name, price, stock, imagePath], function(err) {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.status(201).json({ id: this.lastID, name, price, stock, imagePath });
  });
});

// PUT: Update a product (e.g., for selling)
// We'll focus on just updating stock for now.
app.put('/products/:id', (req, res) => {
    const { stock } = req.body;

    if (stock === undefined) {
        return res.status(400).json({ error: 'Missing required field: stock' });
    }

    const sql = 'UPDATE products SET stock = ? WHERE id = ?';
    db.run(sql, [stock, req.params.id], function(err) {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }
        if (this.changes === 0) {
            return res.status(404).json({ error: 'Product not found' });
        }
        res.json({ message: 'Product stock updated successfully' });
    });
});


// DELETE: Remove a product
app.delete('/products/:id', (req, res) => {
  // First, get the image path to delete the file
  db.get('SELECT imagePath FROM products WHERE id = ?', [req.params.id], (err, row) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    if (row && row.imagePath) {
      // Delete the associated image file
      fs.unlink(path.join(__dirname, row.imagePath), (unlinkErr) => {
        // Log error but don't block deletion of DB record
        if (unlinkErr) console.error('Error deleting image file:', unlinkErr);
      });
    }

    // Then, delete the database record
    const sql = 'DELETE FROM products WHERE id = ?';
    db.run(sql, [req.params.id], function(err) {
      if (err) {
        res.status(500).json({ error: err.message });
        return;
      }
      if (this.changes === 0) {
        return res.status(404).json({ error: 'Product not found' });
      }
      res.json({ message: 'Product deleted successfully' });
    });
  });
});



// --- Server Start ---
// Listen on 0.0.0.0 to be accessible from other devices on the network
app.listen(port, '0.0.0.0', () => {
  console.log(`Server running at http://0.0.0.0:${port}/`);
});

module.exports = app;
