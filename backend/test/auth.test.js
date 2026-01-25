// backend/test/auth.test.js
const request = require('supertest');
const assert = require('assert');
const sqlite3 = require('sqlite3').verbose();
const initApp = require('../server'); // Import the initApp function

// Mock JWT_SECRET and other environment variables for testing
process.env.JWT_SECRET = 'test_secret';
process.env.REFRESH_TOKEN_SECRET = 'test_refresh_secret';
process.env.ACCESS_TOKEN_SECRET_EXPIRATION = '15m';
process.env.REFRESH_TOKEN_SECRET_EXPIRATION = '7d';
process.env.NODE_ENV = 'production'; // Ensure secure cookies are tested

const dbPath = ':memory:'; // Use an in-memory database for API tests

// Helper function to initialize the in-memory database schema
const initializeInMemoryDb = (database, callback) => {
    database.serialize(() => {
        database.run(`CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            role TEXT NOT NULL CHECK(role IN ('VILLAGER', 'USER')),
            farm_name TEXT,
            address TEXT,
            contact_info TEXT
        )`, (err) => {
            if (err) return callback(err);
        });

        database.run(`CREATE TABLE IF NOT EXISTS product_images (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER NOT NULL,
            image_path TEXT NOT NULL,
            FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
        )`, (err) => {
            if (err) return callback(err);
        });

        database.run(`CREATE TABLE IF NOT EXISTS transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER NOT NULL,
            quantity_sold REAL NOT NULL,
            date_of_sale INTEGER NOT NULL, -- Unix timestamp
            user_id INTEGER NOT NULL, -- The user who bought the product
            FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )`, (err) => {
            if (err) return callback(err);
        });

        database.run(`CREATE TABLE IF NOT EXISTS refresh_tokens (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            token_hash TEXT NOT NULL UNIQUE,
            jti TEXT NOT NULL UNIQUE,
            expires_at INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )`, (err) => {
            if (err) return callback(err);
        });

        // Initial products table creation
        database.run(`CREATE TABLE IF NOT EXISTS products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            price REAL NOT NULL,
            stock REAL NOT NULL,
            imagePath TEXT
        )`, (err) => {
            if (err) {
                return callback(err);
            } else {
                // Add new columns to products table if they don't exist
                const columns = [
                    { name: 'owner_id', type: 'INTEGER' },
                    { name: 'category', type: 'TEXT NOT NULL DEFAULT "Uncategorized"' },
                    { name: 'low_stock_threshold', type: 'REAL DEFAULT 7' },
                    { name: 'low_stock_since_date', type: 'INTEGER' }
                ];

                database.all('PRAGMA table_info(products)', (err, existingColumns) => {
                    if (err) {
                        return callback(err);
                    }

                    const existingColumnNames = existingColumns.map(c => c.name);

                    let pendingMigrations = columns.filter(column => !existingColumnNames.includes(column.name));
                    if (pendingMigrations.length > 0) {
                        let completedMigrations = 0;
                        pendingMigrations.forEach(column => {
                            database.run(`ALTER TABLE products ADD COLUMN ${column.name} ${column.type}`, (err) => {
                                if (err) {
                                    console.error(`Error adding column ${column.name}`, err.message);
                                    return callback(err);
                                }
                                completedMigrations++;
                                if (completedMigrations === pendingMigrations.length) {
                                    callback();
                                }
                            });
                        });
                    } else {
                        callback();
                    }
                });
            }
        });
    });
};

describe('Auth Endpoints (Isolated)', () => {
    let db;
    let app; // Declare app here to be assigned in before()

    before((done) => {
        db = new sqlite3.Database(dbPath, (err) => {
            if (err) return done(err);
            console.log('Connected to in-memory SQLite database for Auth tests.');
            initializeInMemoryDb(db, () => {
                app = initApp(db); // Initialize app with the in-memory database
                done();
            });
        });
    });

    after((done) => {
        db.close(done); // Close the in-memory database
    });

    describe('POST /auth/register', () => {
        beforeEach(async () => {
            // Clear all tables for each test to ensure a clean state
            await new Promise((resolve, reject) => {
                db.serialize(() => {
                    db.run('DELETE FROM users', (err) => { if (err) return reject(err); });
                    db.run('DELETE FROM refresh_tokens', (err) => { if (err) return reject(err); resolve(); });
                });
            });
        });
        it('should register a new user', (done) => {
            request(app)
                .post('/auth/register')
                .send({ email: 'isolated_test@user.com', password: 'password', role: 'USER' })
                .expect(201)
                .end((err, res) => {
                    if (err) return done(err);
                    assert.strictEqual(res.body.message, 'User registered successfully.');
                    done();
                });
        });

        it('should not register a user with an existing email', async () => {
            // First, register the user successfully within this test case
            await request(app)
                .post('/auth/register')
                .send({ email: 'isolated_duplicate@user.com', password: 'password', role: 'USER' })
                .expect(201);

            // Then, attempt to register the same user again and expect a 500
            await request(app)
                .post('/auth/register')
                .send({ email: 'isolated_duplicate@user.com', password: 'password', role: 'USER' })
                .expect(500) // Expecting 500 for unique constraint violation
                .then(res => {
                    assert.ok(res.body.error.includes('Email might already be in use.'), 'Error message should indicate existing email');
                });
        });
    });

    describe('POST /auth/login', () => {
        beforeEach(async () => {
            // Clear all tables for each test to ensure a clean state
            await new Promise((resolve, reject) => {
                db.serialize(() => {
                    db.run('DELETE FROM users', (err) => { if (err) return reject(err); });
                    db.run('DELETE FROM refresh_tokens', (err) => { if (err) return reject(err); resolve(); });
                });
            });

            await request(app)
                .post('/auth/register')
                .send({ email: 'isolated_login@user.com', password: 'password', role: 'USER' })
                .expect(201);
        });

        it('should return accessToken and set refreshToken cookie on successful login', (done) => {
            request(app)
                .post('/auth/login')
                .send({ email: 'isolated_login@user.com', password: 'password' })
                .expect(200)
                .end((err, res) => {
                    if (err) return done(err);

                    assert.ok(res.body.accessToken, 'Should return an access token');
                    assert.ok(res.headers['set-cookie'], 'Should set a Set-Cookie header');
                    const refreshTokenCookie = res.headers['set-cookie'].find(cookie => cookie.startsWith('refreshToken='));
                    assert.ok(refreshTokenCookie, 'Should set a refreshToken cookie');
                    assert.ok(refreshTokenCookie.includes('HttpOnly'), 'Refresh token cookie should be HttpOnly');
                    assert.ok(refreshTokenCookie.includes('Secure'), 'Refresh token cookie should be Secure');

                    // Minimal check for refresh token storage
                    const refreshTokenValue = refreshTokenCookie.split(';')[0].split('refreshToken=')[1];
                    const decodedRefreshToken = require('jsonwebtoken').decode(refreshTokenValue); // Decode to get jti

                    db.get('SELECT jti FROM refresh_tokens WHERE jti = ?', [decodedRefreshToken.jti], (dbErr, row) => {
                        if (dbErr) return done(dbErr);
                        assert.ok(row, 'Refresh token should be stored in the database');
                        done();
                    });
                });
        });

        it('should return 401 for unmatched email or password', (done) => {
            request(app)
                .post('/auth/login')
                .send({ email: 'nonexistent@user.com', password: 'password' })
                .expect(401)
                .end((err, res) => {
                    if (err) return done(err);
                    assert.strictEqual(res.body.error, 'Unmatched email or password.');
                    done();
                });
        });

        it('should return 401 for invalid credentials', (done) => {
            request(app)
                .post('/auth/login')
                .send({ email: 'isolated_login@user.com', password: 'wrongpassword' })
                .expect(401)
                .end((err, res) => {
                    if (err) return done(err);
                    assert.strictEqual(res.body.error, 'Invalid credentials.');
                    done();
                });
        });
    });
});
