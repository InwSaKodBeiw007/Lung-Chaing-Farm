// server.js
const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const JWT_SECRET = 'your_super_secret_jwt_key_change_this'; // IMPORTANT: Change this and store it securely!

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
    db.serialize(() => {
      // Create users table
      db.run(`CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL CHECK(role IN ('VILLAGER', 'USER')),
        farm_name TEXT,
        address TEXT,
        contact_info TEXT
      )`, (err) => {
        if (err) console.error('Error creating users table', err.message);
        else console.log('Users table is ready.');
      });

      // Create product_images table
      db.run(`CREATE TABLE IF NOT EXISTS product_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )`, (err) => {
        if (err) console.error('Error creating product_images table', err.message);
        else console.log('Product images table is ready.');
      });
      
      // Original products table creation
      db.run(`CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        stock REAL NOT NULL,
        imagePath TEXT
      )`, (err) => {
        if (err) {
          console.error('Error creating products table', err.message);
        } else {
          console.log('Products table schema is being checked/updated.');
          // Add new columns to products table if they don't exist
          const columns = [
            { name: 'owner_id', type: 'INTEGER' },
            { name: 'category', type: 'TEXT' },
            { name: 'low_stock_threshold', type: 'REAL DEFAULT 7' }
          ];

          db.all('PRAGMA table_info(products)', (err, existingColumns) => {
            if (err) {
              console.error('Error fetching products table info', err);
              return;
            }
            
            const existingColumnNames = existingColumns.map(c => c.name);
            
            columns.forEach(column => {
              if (!existingColumnNames.includes(column.name)) {
                db.run(`ALTER TABLE products ADD COLUMN ${column.name} ${column.type}`, (err) => {
                  if (err) {
                    console.error(`Error adding column ${column.name}`, err.message);
                  } else {
                    console.log(`Column ${column.name} added to products table.`);
                  }
                });
              }
            });
          });
        }
      });
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

// --- Auth API Endpoints ---

// POST: Register a new user
app.post('/auth/register', (req, res) => {
    const { email, password, role, farm_name, address, contact_info } = req.body;

    if (!email || !password || !role) {
        return res.status(400).json({ error: 'Email, password, and role are required.' });
    }
    if (role === 'VILLAGER' && !farm_name) {
        return res.status(400).json({ error: 'Farm name is required for villagers.' });
    }

    const salt = bcrypt.genSaltSync(10);
    const password_hash = bcrypt.hashSync(password, salt);

    const sql = `INSERT INTO users (email, password_hash, role, farm_name, address, contact_info)
                 VALUES (?, ?, ?, ?, ?, ?)`;
    const params = [email, password_hash, role, farm_name, address, contact_info];

    db.run(sql, params, function(err) {
        if (err) {
            return res.status(500).json({ error: 'Could not register user. Email might already be in use.' });
        }
        res.status(201).json({ id: this.lastID, message: 'User registered successfully.' });
    });
});

// POST: Login a user
app.post('/auth/login', (req, res) => {
    const { email, password } = req.body;
    if (!email || !password) {
        return res.status(400).json({ error: 'Email and password are required.' });
    }

    const sql = 'SELECT * FROM users WHERE email = ?';
    db.get(sql, [email], (err, user) => {
        if (err) {
            return res.status(500).json({ error: 'Server error.' });
        }
        if (!user) {
            return res.status(401).json({ error: 'Invalid credentials.' });
        }

        const isPasswordCorrect = bcrypt.compareSync(password, user.password_hash);
        if (!isPasswordCorrect) {
            return res.status(401).json({ error: 'Invalid credentials.' });
        }

        const token = jwt.sign({ id: user.id, role: user.role }, JWT_SECRET, { expiresIn: '1h' });
        res.json({ token, user: { id: user.id, email: user.email, role: user.role, farm_name: user.farm_name } });
    });
});

// --- Middleware to verify token ---
const verifyToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(403).json({ error: 'A token is required for authentication.' });
    }

    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        req.user = decoded;
    } catch (err) {
        return res.status(401).json({ error: 'Invalid Token.' });
    }
    return next();
};


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
