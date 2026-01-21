const assert = require('assert');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');

describe('Database Schema', () => {
    let db;
    const testDbPath = path.resolve(__dirname, '../test_database.db'); // Use a separate test database

    beforeEach((done) => {
        // Delete test database if it exists
        if (fs.existsSync(testDbPath)) {
            fs.unlinkSync(testDbPath);
        }

        db = new sqlite3.Database(testDbPath, (err) => {
            if (err) return done(err);

            db.serialize(() => {
                // Mimic server.js setup for users and product_images tables
                db.run(`CREATE TABLE IF NOT EXISTS users (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    email TEXT UNIQUE NOT NULL,
                    password_hash TEXT NOT NULL,
                    role TEXT NOT NULL CHECK(role IN ('VILLAGER', 'USER')),
                    farm_name TEXT,
                    address TEXT,
                    contact_info TEXT
                )`);
                db.run(`CREATE TABLE IF NOT EXISTS product_images (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    product_id INTEGER NOT NULL,
                    image_path TEXT NOT NULL,
                    FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
                )`);

                // Create products table with initial columns
                db.run(`CREATE TABLE IF NOT EXISTS products (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    price REAL NOT NULL,
                    stock REAL NOT NULL,
                    owner_id INTEGER,
                    category TEXT,
                    low_stock_threshold REAL DEFAULT 7
                )`, () => {
                    // Add low_stock_since_date column using ALTER TABLE
                    db.run(`ALTER TABLE products ADD COLUMN low_stock_since_date INTEGER`, (err) => {
                        if (err && !err.message.includes('duplicate column name')) {
                            console.warn('Error adding low_stock_since_date column (might already exist):', err.message);
                        }

                        // Create transactions table
                        db.run(`CREATE TABLE IF NOT EXISTS transactions (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            product_id INTEGER NOT NULL,
                            quantity_sold REAL NOT NULL,
                            date_of_sale INTEGER NOT NULL,
                            user_id INTEGER NOT NULL,
                            FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
                            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
                        )`, done);
                    });
                });
            });
        });
    });

    afterEach((done) => {
        db.close((err) => {
            if (err) return done(err);
            if (fs.existsSync(testDbPath)) {
                fs.unlinkSync(testDbPath); // Clean up test database
            }
            done();
        });
    });

    it('should have the low_stock_since_date column in the products table', (done) => {
        db.get("PRAGMA table_info(products)", (err, row) => {
            if (err) return done(err);
            db.all("PRAGMA table_info(products)", (err, columns) => {
                if (err) return done(err);
                const columnNames = columns.map(col => col.name);
                assert.ok(columnNames.includes('low_stock_since_date'), 'products table should have low_stock_since_date column');
                done();
            });
        });
    });

    it('should have the transactions table', (done) => {
        db.get("SELECT name FROM sqlite_master WHERE type='table' AND name='transactions'", (err, row) => {
            if (err) return done(err);
            assert.ok(row, 'transactions table should exist');
            done();
        });
    });

    it('transactions table should have correct columns', (done) => {
        db.all("PRAGMA table_info(transactions)", (err, columns) => {
            if (err) return done(err);
            const columnNames = columns.map(col => col.name);
            assert.ok(columnNames.includes('product_id'), 'transactions table should have product_id column');
            assert.ok(columnNames.includes('quantity_sold'), 'transactions table should have quantity_sold column');
            assert.ok(columnNames.includes('date_of_sale'), 'transactions table should have date_of_sale column');
            assert.ok(columnNames.includes('user_id'), 'transactions table should have user_id column');
            done();
        });
    });
});
