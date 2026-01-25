// server.js
require('dotenv').config(); // Load environment variables from .env file

const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const cors = require('cors');
const multer = require('multer');
const cookieParser = require('cookie-parser');
const path = require('path');
const fs = require('fs');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid'); // Import UUID for jti generation
const { sendLowStockEmail } = require('./email_service'); // Import email service

const JWT_SECRET = process.env.JWT_SECRET; // Load from environment variables
const REFRESH_TOKEN_SECRET = process.env.REFRESH_TOKEN_SECRET || JWT_SECRET; // Use a separate secret for refresh tokens if available

// Helper function to generate a unique JWT ID (JTI)
const generateJti = () => uuidv4();

// Helper function to hash a token
const hashToken = (token) => {
  const crypto = require('crypto');
  return crypto.createHash('sha256').update(token).digest('hex');
};

// Helper function to convert expiration string (e.g., '15m', '7d') to seconds
const convertExpiresInToSeconds = (expiresInString) => {
  const value = parseInt(expiresInString);
  if (expiresInString.endsWith('m')) {
    return value * 60;
  } else if (expiresInString.endsWith('h')) {
    return value * 60 * 60;
  } else if (expiresInString.endsWith('d')) {
    return value * 24 * 60 * 60;
  }
  return value; // Assume it's already in seconds if no unit
};

// Export a function that initializes the app and optionally uses an injected database
function initApp(injectedDb) {
  const app = express();
  const port = 3000;

  // Use CORS for all origins, as requested.
  app.use(cors());
  app.use(express.json());
  app.use(cookieParser());

  let db; // Database instance for the app

  if (injectedDb) {
    db = injectedDb; // Use the injected database for testing
    console.log('Using injected SQLite database.');
  } else {
    // --- Database Setup (for production/development) ---
    const dbPath = path.resolve(__dirname, 'database.db');
    db = new sqlite3.Database(dbPath, (err) => {
      if (err) {
        console.error('Error opening database', err.message);
      } else {
        console.log('Connected to the SQLite database.');
        // This block still needs to run for non-injected DBs to create tables
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

          // Create transactions table
          db.run(`CREATE TABLE IF NOT EXISTS transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER NOT NULL,
            quantity_sold REAL NOT NULL,
            date_of_sale INTEGER NOT NULL, -- Unix timestamp
            user_id INTEGER NOT NULL, -- The user who bought the product
            FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
          )`, (err) => {
            if (err) console.error('Error creating transactions table', err.message);
            else console.log('Transactions table is ready.');
          });

          // Create refresh_tokens table
          db.run(`CREATE TABLE IF NOT EXISTS refresh_tokens (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            token_hash TEXT NOT NULL UNIQUE,
            jti TEXT NOT NULL UNIQUE,
            expires_at INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
          )`, (err) => {
            if (err) console.error('Error creating refresh_tokens table', err.message);
            else console.log('Refresh tokens table is ready.');
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
                { name: 'category', type: 'TEXT NOT NULL DEFAULT "Uncategorized"' },
                { name: 'low_stock_threshold', type: 'REAL DEFAULT 7' },
                { name: 'low_stock_since_date', type: 'INTEGER' }
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
  }


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

    db.run(sql, params, function (err) {
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
        return res.status(401).json({ error: 'Unmatched email or password.' });
      }

      const isPasswordCorrect = bcrypt.compareSync(password, user.password_hash);
      if (!isPasswordCorrect) {
        return res.status(401).json({ error: 'Invalid credentials.' });
      }

      // Generate short-lived Access Token
      const accessToken = jwt.sign({ email: user.email, role: user.role }, JWT_SECRET, { expiresIn: process.env.ACCESS_TOKEN_SECRET_EXPIRATION || '15m' });

      // Generate long-lived Refresh Token with jti
      const jti = generateJti();
      const refreshTokenExpiresIn = process.env.REFRESH_TOKEN_SECRET_EXPIRATION || '7d';
      const refreshToken = jwt.sign({ email: user.email, role: user.role, jti: jti }, REFRESH_TOKEN_SECRET, { expiresIn: refreshTokenExpiresIn });

      // Hash Refresh Token for storage
      const hashedRefreshToken = hashToken(refreshToken);
      // Calculate expiration in seconds for database storage
      const refreshTokenExpiresAt = Math.floor(Date.now() / 1000) + convertExpiresInToSeconds(refreshTokenExpiresIn);
      const currentTime = Math.floor(Date.now() / 1000);

      // Store Refresh Token details in the database
      db.run(
        'INSERT INTO refresh_tokens (user_id, token_hash, jti, expires_at, created_at) VALUES (?, ?, ?, ?, ?)',
        [user.id, hashedRefreshToken, jti, refreshTokenExpiresAt, currentTime],
        (insertErr) => {
          if (insertErr) {
            console.error('Error storing refresh token:', insertErr.message);
            return res.status(500).json({ error: 'Failed to store refresh token.' });
          }

          // Set Refresh Token as an HttpOnly, Secure cookie
          res.cookie('refreshToken', refreshToken, {
            httpOnly: true,
            secure: process.env.NODE_ENV === 'production', // Use secure cookies in production
            maxAge: convertExpiresInToSeconds(refreshTokenExpiresIn) * 1000, // Convert to milliseconds
            sameSite: 'Lax', // Protect against CSRF attacks
          });
          res.json({ accessToken, user: { farm_name: user.farm_name } });
        }
      );
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
      // Fetch the full user object from the database to get the user's integer ID
      db.get('SELECT id, email, role, farm_name FROM users WHERE email = ?', [decoded.email], (err, user) => {
        if (err || !user) {
          return res.status(401).json({ error: 'User not found or database error.' });
        }
        req.user = user; // Attach the full user object with id, email, role, etc.
        return next();
      });
    } catch (err) {
      return res.status(401).json({ error: 'Invalid Token.' });
    }
  };


  // --- Product API Endpoints ---

  // GET: Fetch low-stock products for the authenticated Villager (Protected, Villager Only)
  app.get('/villager/low-stock-products', verifyToken, (req, res) => {
    // Only villagers can access this endpoint
    if (req.user.role !== 'VILLAGER') {
      return res.status(403).json({ error: 'Forbidden: Only villagers can view low stock products.' });
    }

    const villagerId = req.user.id;

    const sql = `
          SELECT
              p.id,
              p.name,
              p.price,
              p.stock,
              p.category,
              p.low_stock_threshold,
              p.low_stock_since_date,
              p.owner_id,
              u.farm_name,
              GROUP_CONCAT(pi.image_path) AS image_urls
        FROM products p
        JOIN users u ON p.owner_id = u.id
        LEFT JOIN product_images pi ON p.id = pi.product_id
        WHERE p.owner_id = ? AND p.stock <= p.low_stock_threshold
        GROUP BY p.id
        ORDER BY p.low_stock_since_date ASC;
    `;

    db.all(sql, [villagerId], (err, rows) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }

      const products = rows.map(row => ({
        id: row.id,
        name: row.name,
        price: row.price,
        stock: row.stock,
        category: row.category,
        low_stock_threshold: row.low_stock_threshold,
        low_stock_since_date: row.low_stock_since_date,
        owner_id: row.owner_id,
        farm_name: row.farm_name,
        image_urls: row.image_urls ? row.image_urls.split(',') : [],
      }));

      res.json({ products });
    });
  });

  // GET: Fetch all products with owner and image info
  app.get('/products', (req, res) => {
    const { category } = req.query; // Extract category from query parameters
    let sql = `
    SELECT
      p.id,
      p.name,
      p.price,
      p.stock,
      p.category,
      p.low_stock_threshold,
      p.owner_id,
      u.farm_name,
      GROUP_CONCAT(pi.image_path) AS image_path -- Use GROUP_CONCAT here directly
    FROM products p
    JOIN users u ON p.owner_id = u.id
    LEFT JOIN product_images pi ON p.id = pi.product_id
  `;
    const params = [];

    if (category) {
      sql += ` WHERE p.category = ?`;
      params.push(category);
    }

    sql += ` GROUP BY p.id ORDER BY p.id DESC;`; // Group by product ID for image_urls

    db.all(sql, params, (err, rows) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }

      const products = rows.map(row => ({
        id: row.id,
        name: row.name,
        price: row.price,
        stock: row.stock,
        category: row.category,
        low_stock_threshold: row.low_stock_threshold,
        owner_id: row.owner_id,
        farm_name: row.farm_name,
        image_urls: row.image_path ? row.image_path.split(',') : [], // Split GROUP_CONCAT result
      }));

      res.json({ products });
    });
  });

  // POST: Add a new product (Protected, Villager Only)
  app.post('/products', verifyToken, upload.array('images', 5), (req, res) => {
    // Role check
    if (req.user.role !== 'VILLAGER') {
      return res.status(403).json({ error: 'Forbidden: Only villagers can add products.' });
    }

    const { name, price, stock, category, low_stock_threshold } = req.body;
    const owner_id = req.user.id;

    if (!name || price === undefined || stock === undefined) {
      return res.status(400).json({ error: 'Missing required fields: name, price, stock' });
    }

    const productSql = 'INSERT INTO products (name, price, stock, owner_id, category, low_stock_threshold) VALUES (?, ?, ?, ?, ?, ?)';
    db.run(productSql, [name, price, stock, owner_id, category, low_stock_threshold], function (err) {
      if (err) {
        return res.status(500).json({ error: err.message });
      }

      const productId = this.lastID;

      // Handle multiple images
      if (req.files) {
        const imageSql = 'INSERT INTO product_images (product_id, image_path) VALUES (?, ?)';
        const imageStmt = db.prepare(imageSql);
        for (const file of req.files) {
          const imagePath = `uploads/${file.filename}`;
          imageStmt.run(productId, imagePath);
        }
        imageStmt.finalize((err) => {
          if (err) {
            return res.status(500).json({ error: 'Failed to save product images.' });
          }
          res.status(201).json({ id: productId, message: 'Product added successfully with images.' });
        });
      } else {
        res.status(201).json({ id: productId, message: 'Product added successfully without images.' });
      }
    });
  });

  // POST: Purchase a product (Protected, User Only)
  app.post('/products/:productId/purchase', verifyToken, (req, res) => {
    // Only regular users (buyers) can purchase
    if (req.user.role !== 'USER') {
      return res.status(403).json({ error: 'Forbidden: Only users can purchase products.' });
    }

    const productId = req.params.productId;
    const { quantity } = req.body;
    const userId = req.user.id;

    if (!quantity || typeof quantity !== 'number' || quantity <= 0) {
      return res.status(400).json({ error: 'Valid positive quantity is required.' });
    }

    db.get('SELECT id, stock, low_stock_threshold, low_stock_since_date, owner_id FROM products WHERE id = ?', [productId], (err, product) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      if (!product) {
        return res.status(404).json({ error: 'Product not found.' });
      }
      if (product.stock < quantity) {
        return res.status(400).json({ error: `Insufficient stock. Only ${product.stock}kg available.` });
      }

      // Begin transaction for atomicity
      db.serialize(() => {
        db.run('BEGIN TRANSACTION;');

        const newStock = product.stock - quantity;
        const currentTime = Math.floor(Date.now() / 1000); // Unix timestamp

        // Update product stock and low_stock_since_date
        db.run(
          'UPDATE products SET stock = ?, low_stock_since_date = ? WHERE id = ?',
          [
            newStock,
            (newStock <= product.low_stock_threshold && product.low_stock_since_date === null)
              ? currentTime // Set if newly low-stock
              : (newStock > product.low_stock_threshold)
                ? null // Clear if recovered
                : product.low_stock_since_date, // Keep existing if already low and still low
            productId
          ],
          function (err) {
            if (err) {
              db.run('ROLLBACK;');
              return res.status(500).json({ error: 'Error during stock update.' });
            }

            // Record transaction
            db.run(
              'INSERT INTO transactions (product_id, quantity_sold, date_of_sale, user_id) VALUES (?, ?, ?, ?)',
              [productId, quantity, currentTime, userId],
              function (err) {
                if (err) {
                  db.run('ROLLBACK;');
                  return res.status(500).json({ error: 'Error during transaction recording.' });
                }

                db.run('COMMIT;', (commitErr) => {
                  if (commitErr) {
                    return res.status(500).json({ error: 'Error committing transaction.' });
                  }

                  // Fetch updated product info to send in response
                  db.get('SELECT name, stock, low_stock_threshold, low_stock_since_date FROM products WHERE id = ?', [productId], (err, updatedProduct) => {
                    if (err) {
                      return res.status(500).json({ error: 'Error fetching updated product info.' });
                    }
                    let responsePayload = {
                      message: 'Product purchased successfully.',
                      product: {
                        id: productId,
                        name: updatedProduct.name,
                        stock: updatedProduct.stock,
                        low_stock_threshold: updatedProduct.low_stock_threshold,
                        low_stock_since_date: updatedProduct.low_stock_since_date
                      }
                    };
                    // Optionally add low stock alert to response if villager needs immediate feedback
                    if (updatedProduct.stock <= updatedProduct.low_stock_threshold) {
                      responsePayload.lowStockAlert = true;
                    }
                    res.status(200).json(responsePayload);
                  });
                });
              }
            );
          }
        );
      });
    });
  });

  // PUT: Update a product (Protected, Owner Only)
  app.put('/products/:id', verifyToken, upload.array('images'), (req, res) => {
    const { name, price, stock, category, low_stock_threshold, existing_image_urls } = req.body;
    const productId = req.params.id;
    const userId = req.user.id;
    let imagesToKeep = [];
    if (existing_image_urls) {
      try {
        imagesToKeep = JSON.parse(existing_image_urls);
      } catch (e) {
        console.error('Failed to parse existing_image_urls:', e);
        return res.status(400).json({ error: 'Invalid format for existing_image_urls.' });
      }
    }

    // First, verify ownership
    db.get('SELECT owner_id FROM products WHERE id = ?', [productId], (err, product) => {
      if (err) {
        return res.status(500).json({ error: 'Database error.' });
      }
      if (!product) {
        return res.status(404).json({ error: 'Product not found.' });
      }
      if (product.owner_id !== userId) {
        return res.status(403).json({ error: 'Forbidden: You do not own this product.' });
      }

      // --- Handle Image Updates ---
      db.all('SELECT id, image_path FROM product_images WHERE product_id = ?', [productId], (err, currentImages) => {
        if (err) {
          return res.status(500).json({ error: 'Error fetching current images.' });
        }

        const currentImagePaths = currentImages.map(img => img.image_path);
        const imagesToDelete = currentImagePaths.filter(path => !imagesToKeep.includes(path));

        // Delete images that are no longer kept
        imagesToDelete.forEach(imagePath => {
          fs.unlink(path.join(__dirname, imagePath), (unlinkErr) => {
            if (unlinkErr) console.error('Error deleting old image file:', unlinkErr);
          });
          db.run('DELETE FROM product_images WHERE image_path = ?', [imagePath], (dbErr) => {
            if (dbErr) console.error('Error deleting image from DB:', dbErr);
          });
        });

        // Add new images
        if (req.files && req.files.length > 0) {
          const imageSql = 'INSERT INTO product_images (product_id, image_path) VALUES (?, ?)';
          const imageStmt = db.prepare(imageSql);
          for (const file of req.files) {
            const imagePath = `uploads/${file.filename}`;
            imageStmt.run(productId, imagePath);
          }
          imageStmt.finalize();
        }

        // --- Update Product Fields ---
        const fields = [];
        const params = [];
        if (name !== undefined) {
          fields.push('name = ?');
          params.push(name);
        }
        if (price !== undefined) {
          fields.push('price = ?');
          params.push(price);
        }
        if (stock !== undefined) {
          fields.push('stock = ?');
          params.push(stock);
        }
        if (category !== undefined) {
          fields.push('category = ?');
          params.push(category);
        }
        if (low_stock_threshold !== undefined) {
          fields.push('low_stock_threshold = ?');
          params.push(low_stock_threshold);
        }

        if (fields.length === 0 && (!req.files || req.files.length === 0) && imagesToDelete.length === 0) {
          return res.status(400).json({ error: 'No fields or images to update provided.' });
        }

        if (fields.length > 0) {
          params.push(productId);
          const sql = `UPDATE products SET ${fields.join(', ')} WHERE id = ?`;

          db.run(sql, params, function (err) {
            if (err) {
              return res.status(500).json({ error: err.message });
            }

            // After successful product field update, fetch the latest product info
            // to determine low stock status for the response.
            const fetchUpdatedProductSql = `
                          SELECT p.name, p.stock, p.low_stock_threshold, u.email, u.farm_name
                          FROM products p
                          JOIN users u ON p.owner_id = u.id
                          WHERE p.id = ?`;
            db.get(fetchUpdatedProductSql, [productId], (fetchErr, updatedProductInfo) => {
              if (fetchErr) {
                console.error('Error fetching updated product info:', fetchErr);
                // Proceed with a generic success response if fetching fails
                return res.json({ message: 'Product updated successfully.' });
              }

              let responsePayload = { message: 'Product updated successfully.' };
              if (updatedProductInfo && updatedProductInfo.stock <= updatedProductInfo.low_stock_threshold) {
                if (updatedProductInfo.email) {
                  // sendLowStockEmail(
                  //     updatedProductInfo.email,
                  //     updatedProductInfo.farm_name,
                  //     updatedProductInfo.name,
                  //     updatedProductInfo.stock,
                  //     updatedProductInfo.low_stock_threshold
                  // );
                } else {
                  console.warn(`Product owner ${updatedProductInfo.email} has no email to send low stock alert to.`);
                }

                responsePayload = {
                  message: 'Product updated successfully.',
                  lowStockAlert: true,
                  productName: updatedProductInfo.name,
                  currentStock: updatedProductInfo.stock,
                  threshold: updatedProductInfo.low_stock_threshold
                };
              }
              return res.json(responsePayload);
            });
          });
        } else {
          // If only images were updated, then directly respond.
          // We should also re-fetch productInfo here if image changes could affect low stock.
          // For simplicity now, assuming image changes don't affect low stock status directly.
          res.json({ message: 'Product images updated successfully.' });
        }
      });
    });
  });

  // DELETE: Remove a product (Protected, Owner Only)
  app.delete('/products/:id', verifyToken, (req, res) => {
    const productId = req.params.productId;
    const userId = req.user.id;

    // First, verify ownership
    db.get('SELECT owner_id FROM products WHERE id = ?', [productId], (err, product) => {
      if (err) {
        return res.status(500).json({ error: 'Database error.' });
      }
      if (!product) {
        return res.status(404).json({ error: 'Product not found.' });
      }
      if (product.owner_id !== userId) {
        return res.status(403).json({ error: 'Forbidden: You do not own this product.' });
      }

      // Get all image paths for the product to delete the files
      db.all('SELECT image_path FROM product_images WHERE product_id = ?', [productId], (err, images) => {
        if (err) {
          return res.status(500).json({ error: 'Could not fetch product images.' });
        }

        // Delete image files from the filesystem
        images.forEach(image => {
          fs.unlink(path.join(__dirname, image.image_path), (unlinkErr) => {
            if (unlinkErr) console.error('Error deleting image file:', unlinkErr);
          });
        });

        // Delete the product and its image records from the database
        db.serialize(() => {
          db.run('DELETE FROM product_images WHERE product_id = ?', [productId], (err) => {
            if (err) return res.status(500).json({ error: 'Could not delete product images.' });
          });
          db.run('DELETE FROM products WHERE id = ?', [productId], function (err) {
            if (err) return res.status(500).json({ error: 'Could not delete product.' });
            res.json({ message: 'Product deleted successfully.' });
          });
        });
      });
    });
  });



  // GET: Fetch a single product by ID with owner and image info
  app.get('/products/:id', (req, res) => {
    const productId = req.params.id;
    const sql = `
      SELECT
        p.id,
        p.name,
        p.price,
        p.stock,
        p.category,
        p.low_stock_threshold,
        p.owner_id,
        u.farm_name,
        GROUP_CONCAT(pi.image_path) AS image_urls
      FROM products p
      JOIN users u ON p.owner_id = u.id
      LEFT JOIN product_images pi ON p.id = pi.product_id
      WHERE p.id = ?
      GROUP BY p.id;
    `;

    db.get(sql, [productId], (err, row) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      if (!row) {
        return res.status(404).json({ error: 'Product not found.' });
      }

      // Process image_urls from GROUP_CONCAT
      const product = {
        id: row.id,
        name: row.name,
        price: row.price,
        stock: row.stock,
        category: row.category,
        low_stock_threshold: row.low_stock_threshold,
        owner_id: row.owner_id,
        farm_name: row.farm_name,
        image_urls: row.image_urls ? row.image_urls.split(',') : [],
      };

      res.json({ product });
    });
  });

  // GET: Fetch sales transaction history for a specific product (Protected, Owner Only)
  app.get('/products/:productId/transactions', verifyToken, (req, res) => {
    const productId = req.params.productId;
    const { days } = req.query; // Optional query parameter for filtering by days
    const userId = req.user.id;

    // First, verify ownership
    db.get('SELECT owner_id FROM products WHERE id = ?', [productId], (err, product) => {
      if (err) {
        return res.status(500).json({ error: 'Database error.' });
      }
      if (!product) {
        return res.status(404).json({ error: 'Product not found.' });
      }
      if (product.owner_id !== userId) {
        return res.status(403).json({ error: 'Forbidden: You do not own this product.' });
      }

      let sql = `
            SELECT
                t.id,
                t.product_id,
                t.quantity_sold,
                t.date_of_sale,
                t.user_id,
                u.email AS buyer_email
            FROM transactions t
            JOIN users u ON t.user_id = u.id
            WHERE t.product_id = ?
        `;
    const params = [productId];

    if (days && !isNaN(parseInt(days))) {
      const timeAgo = Math.floor(Date.now() / 1000) - (parseInt(days) * 24 * 60 * 60);
      sql += ` AND t.date_of_sale >= ?`;
      params.push(timeAgo);
    }

    sql += ` ORDER BY t.date_of_sale DESC;`;

    db.all(sql, params, (err, transactions) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json({ transactions });
    });
  });
});

  // --- Server Start ---
  // If no injectedDb is provided, start the server
  if (!injectedDb) {
    app.listen(port, '0.0.0.0', () => {
      console.log(`Server running at http://0.0.0.0:${port}/`);
    });
  }

  return app;
}

module.exports = initApp;