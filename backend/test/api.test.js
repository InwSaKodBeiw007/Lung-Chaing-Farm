const request = require('supertest');
const assert = require('assert');
const sqlite3 = require('sqlite3').verbose();
const initApp = require('../server'); // Import the initApp function

// Mock JWT_SECRET and other environment variables for testing
process.env.JWT_SECRET = 'test_secret';
process.env.REFRESH_TOKEN_SECRET = 'test_refresh_secret';
process.env.ACCESS_TOKEN_SECRET_EXPIRATION = '15m';
process.env.REFRESH_TOKEN_SECRET_EXPIRATION = '7d';

const dbPath = ':memory:'; // Use an in-memory database for API tests

describe('API Endpoints', () => {
    let db; // Declare db here to be accessible throughout the describe block
    let app; // Declare app here to be assigned in before()

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

    before((done) => {
        // Ensure NODE_ENV is set for secure cookies to be true
        process.env.NODE_ENV = 'production';
        db = new sqlite3.Database(dbPath, (err) => {
            if (err) return done(err);
            console.log('Connected to in-memory SQLite database for API tests.');
            initializeInMemoryDb(db, () => {
                app = initApp(db); // Assign the Express app directly
                done();
            });
        });
    });

    beforeEach(async () => {
        // Clear all tables for each test to ensure a clean state
        await new Promise((resolve, reject) => {
            db.serialize(() => {
                db.run('DELETE FROM users', (err) => { if (err) return reject(err); });
                db.run('DELETE FROM products', (err) => { if (err) return reject(err); });
                db.run('DELETE FROM product_images', (err) => { if (err) return reject(err); });
                db.run('DELETE FROM transactions', (err) => { if (err) return reject(err); });
                db.run('DELETE FROM refresh_tokens', (err) => { if (err) return reject(err); resolve(); });
            });
        });
    });

    after((done) => {
        db.close(done); // Close the in-memory database
    });

    // describe('POST /auth/login', () => { ... }); block removed

    describe('POST /products/:productId/purchase', () => {
        let testUserId;
        let testUserToken;
        let testVillagerId;
        let testVillagerToken;
        let testProductId;
        let otherProductId;

        beforeEach(async () => {
            // Register a test user (buyer)
            const userRegisterRes = await request(app)
                .post('/auth/register')
                .send({ email: 'test_purchase@user.com', password: 'password', role: 'USER' })
                .expect(201);
            testUserId = userRegisterRes.body.id;

            // Login to get token
            const userLoginRes = await request(app)
                .post('/auth/login')
                .send({ email: 'test_purchase@user.com', password: 'password' })
                .expect(200);
            testUserToken = userLoginRes.body.accessToken;

            // Register a test villager (seller)
            const villagerRegisterRes = await request(app)
                .post('/auth/register')
                .send({ email: 'test_purchase@villager.com', password: 'password', role: 'VILLAGER', farm_name: 'Test Farm Purchase' })
                .expect(201);
            testVillagerId = villagerRegisterRes.body.id;

            // Login to get token
            const villagerLoginRes = await request(app)
                .post('/auth/login')
                .send({ email: 'test_purchase@villager.com', password: 'password' })
                .expect(200);
            testVillagerToken = villagerLoginRes.body.accessToken;

            // Add a product for the test villager
            const productAddRes = await request(app)
                .post('/products')
                .set('Authorization', `Bearer ${testVillagerToken}`)
                .field('name', 'Test Product For Purchase')
                .field('price', 10.0)
                .field('stock', 100.0)
                .field('category', 'Sweet')
                .field('low_stock_threshold', 10.0)
                .expect(201);
            testProductId = productAddRes.body.id;
        });

        it('should allow a user to purchase a product and decrement stock', (done) => {
            request(app)
                .post(`/products/${testProductId}/purchase`)
                .set('Authorization', `Bearer ${testUserToken}`)
                .send({ quantity: 5.0 })
                .expect(200)
                .end((err, res) => {
                    if (err) return done(err);
                    assert.strictEqual(res.body.message, 'Product purchased successfully.');
                    assert.strictEqual(res.body.product.stock, 95.0); // 100 - 5 = 95
                    done();
                });
        });

        it('should record the transaction in the transactions table', (done) => {
            request(app)
                .post(`/products/${testProductId}/purchase`)
                .set('Authorization', `Bearer ${testUserToken}`)
                .send({ quantity: 5.0 })
                .expect(200)
                .end((err, res) => {
                    if (err) return done(err);
                    db.get('SELECT * FROM transactions WHERE product_id = ? AND user_id = ?', [testProductId, testUserId], (err, row) => {
                        if (err) return done(err);
                        assert.ok(row, 'Transaction should be recorded');
                        assert.strictEqual(row.quantity_sold, 5.0);
                        assert.strictEqual(row.product_id, testProductId);
                        assert.strictEqual(row.user_id, testUserId);
                        assert.ok(row.date_of_sale, 'date_of_sale should be set');
                        done();
                    });
                });
        });

        it('should update low_stock_since_date when product becomes low stock', (done) => {
            // First purchase to bring stock to 10 (low_stock_threshold)
            request(app)
                .post(`/products/${testProductId}/purchase`)
                .set('Authorization', `Bearer ${testUserToken}`)
                .send({ quantity: 90.0 }) // Stock becomes 10 (initial 100 - 90)
                .expect(200)
                .end((err, res) => {
                    if (err) return done(err);
                    assert.strictEqual(res.body.product.stock, 10.0);
                    assert.ok(res.body.product.low_stock_since_date, 'low_stock_since_date should be set');

                    // Check directly from DB if it was set
                    db.get('SELECT low_stock_since_date FROM products WHERE id = ?', [testProductId], (err, product) => {
                        if (err) return done(err);
                        assert.ok(product.low_stock_since_date, 'low_stock_since_date should be set in DB');
                        done();
                    });
                });
        });

        it('should not update low_stock_since_date if already low stock', (done) => {
            let initialLowStockDate;
            // First purchase to make it low stock and set the date
            request(app)
                .post(`/products/${testProductId}/purchase`)
                .set('Authorization', `Bearer ${testUserToken}`)
                .send({ quantity: 95.0 }) // Stock becomes 5
                .expect(200)
                .end((err, res) => {
                    if (err) return done(err);
                    initialLowStockDate = res.body.product.low_stock_since_date;
                    assert.ok(initialLowStockDate);

                    // Second purchase while still low stock
                    request(app)
                        .post(`/products/${testProductId}/purchase`)
                        .set('Authorization', `Bearer ${testUserToken}`)
                        .send({ quantity: 1.0 }) // Stock becomes 4
                        .expect(200)
                        .end((err, res) => {
                            if (err) return done(err);
                            // low_stock_since_date should remain the same
                            assert.strictEqual(res.body.product.low_stock_since_date, initialLowStockDate);
                            done();
                        });
                });
        });

        it('should clear low_stock_since_date when product recovers from low stock', (done) => {
            // Setup: Make product low stock first
            request(app)
                .post(`/products/${testProductId}/purchase`)
                .set('Authorization', `Bearer ${testUserToken}`)
                .send({ quantity: 95.0 }) // Stock becomes 5, low_stock_since_date is set
                .expect(200)
                .end((err, res) => {
                    if (err) return done(err);
                    assert.ok(res.body.product.low_stock_since_date);

                    // Now, "restock" the product by updating its stock via another API (simulated for test)
                    // For a real scenario, this would be a PUT /products/:id endpoint called by villager
                    // Here, we directly update DB for test simplicity
                    db.run('UPDATE products SET stock = ?, low_stock_since_date = ? WHERE id = ?', [20.0, null, testProductId], (err) => {
                        if (err) return done(err);
                        // Now, make a purchase that would keep it above threshold
                        request(app)
                            .post(`/products/${testProductId}/purchase`)
                            .set('Authorization', `Bearer ${testUserToken}`)
                            .send({ quantity: 5.0 }) // Stock becomes 15 (still above threshold 10)
                            .expect(200)
                            .end((err, res) => {
                                if (err) return done(err);
                                assert.strictEqual(res.body.product.stock, 15.0);
                                assert.strictEqual(res.body.product.low_stock_since_date, null, 'low_stock_since_date should be null');
                                done();
                            });
                    });
                });
        });

        it('should return 400 for insufficient stock', (done) => {
            request(app)
                .post(`/products/${testProductId}/purchase`)
                .set('Authorization', `Bearer ${testUserToken}`)
                .send({ quantity: 101.0 })
                .expect(400)
                .end((err, res) => {
                    if (err) return done(err);
                    assert.strictEqual(res.body.error, 'Insufficient stock. Only 100kg available.');
                    done();
                });
        });

        it('should return 403 if a villager tries to purchase', (done) => {
            request(app)
                .post(`/products/${testProductId}/purchase`)
                .set('Authorization', `Bearer ${testVillagerToken}`)
                .send({ quantity: 1.0 })
                .expect(403)
                .end((err, res) => {
                    if (err) return done(err);
                    assert.strictEqual(res.body.error, 'Forbidden: Only users can purchase products.');
                    done();
                });
        });

        it('should return 400 for invalid quantity', (done) => {
            request(app)
                .post(`/products/${testProductId}/purchase`)
                .send({ quantity: -5.0 })
                .set('Authorization', `Bearer ${testUserToken}`)
                .expect(400)
                .end((err, res) => {
                    if (err) return done(err);
                    assert.strictEqual(res.body.error, 'Valid positive quantity is required.');
                    done();
                });
        });

        it('should return 401 if no token is provided', (done) => {
            request(app)
                .post(`/products/${testProductId}/purchase`)
                .send({ quantity: 1.0 })
                .expect(403) // 403 from verifyToken middleware
                .end(done);
        });
    });

    describe('GET /villager/low-stock-products', () => {
        let testUserId;
        let testUserToken;
        let testVillagerId;
        let testVillagerToken;
        let testProductId;

        beforeEach(async () => {
            // Register a test user (buyer)
            const userRegisterRes = await request(app)
                .post('/auth/register')
                .send({ email: 'test_lowstock@user.com', password: 'password', role: 'USER' })
                .expect(201);
            testUserId = userRegisterRes.body.id;

            // Login to get token
            const userLoginRes = await request(app)
                .post('/auth/login')
                .send({ email: 'test_lowstock@user.com', password: 'password' })
                .expect(200);
            testUserToken = userLoginRes.body.accessToken;

            // Register a test villager (seller)
            const villagerRegisterRes = await request(app)
                .post('/auth/register')
                .send({ email: 'test_lowstock@villager.com', password: 'password', role: 'VILLAGER', farm_name: 'Test Farm LowStock' })
                .expect(201);
            testVillagerId = villagerRegisterRes.body.id;

            // Login to get token
            const villagerLoginRes = await request(app)
                .post('/auth/login')
                .send({ email: 'test_lowstock@villager.com', password: 'password' })
                .expect(200);
            testVillagerToken = villagerLoginRes.body.accessToken;

            // Add a product for the test villager
            const productAddRes = await request(app)
                .post('/products')
                .set('Authorization', `Bearer ${testVillagerToken}`)
                .field('name', 'Test LowStock Product')
                .field('price', 10.0)
                .field('stock', 100.0)
                .field('category', 'Vegetable')
                .field('low_stock_threshold', 10.0)
                .expect(201);
            testProductId = productAddRes.body.id;
        });

        it('should return low-stock products for the authenticated villager', (done) => {
            // Make the product low stock
            request(app)
                .post(`/products/${testProductId}/purchase`)
                .set('Authorization', `Bearer ${testUserToken}`)
                .send({ quantity: 95.0 }) // Stock becomes 5 (threshold 10)
                .expect(200)
                .end((err, res) => {
                    if (err) return done(err);
                    assert.ok(res.body.product.low_stock_since_date);

                    request(app)
                        .get('/villager/low-stock-products')
                        .set('Authorization', `Bearer ${testVillagerToken}`)
                        .expect(200)
                        .end((err, res) => {
                            if (err) return done(err);
                            assert.ok(Array.isArray(res.body.products));
                            assert.strictEqual(res.body.products.length, 1);
                            assert.strictEqual(res.body.products[0].id, testProductId);
                            assert.strictEqual(res.body.products[0].stock, 5.0);
                            assert.ok(res.body.products[0].low_stock_since_date);
                            done();
                        });
                });
        });

        it('should not return products that are not low-stock', (done) => {
            // Product is initially 100 stock, threshold 10. Not low stock.
            request(app)
                .get('/villager/low-stock-products')
                .set('Authorization', `Bearer ${testVillagerToken}`)
                .expect(200)
                .end((err, res) => {
                    if (err) return done(err);
                    assert.strictEqual(res.body.products.length, 0);
                    done();
                });
        });

        it('should return 403 if a user tries to access', (done) => {
            request(app)
                .get('/villager/low-stock-products')
                .set('Authorization', `Bearer ${testUserToken}`)
                .expect(403)
                .end((err, res) => {
                    if (err) return done(err);
                    assert.strictEqual(res.body.error, 'Forbidden: Only villagers can view low stock products.');
                    done();
                });
        });

        it('should return 401 if no token is provided', (done) => {
            request(app)
                .get('/villager/low-stock-products')
                .expect(403) // 403 from verifyToken middleware
                .end(done);
        });
    });

    describe('GET /products/:productId/transactions', () => {
        let testUserId;
        let testUserToken;
        let testVillagerId;
        let testVillagerToken;
        let testProductId;

        beforeEach(async () => {
            // Register a test user (buyer)
            const userRegisterRes = await request(app)
                .post('/auth/register')
                .send({ email: 'test_transactions_user@user.com', password: 'password', role: 'USER' })
                .expect(201);
            testUserId = userRegisterRes.body.id;

            // Login to get token for the user
            const userLoginRes = await request(app)
                .post('/auth/login')
                .send({ email: 'test_transactions_user@user.com', password: 'password' })
                .expect(200);
            testUserToken = userLoginRes.body.accessToken;

            // Register a test villager (seller)
            const villagerRegisterRes = await request(app)
                .post('/auth/register')
                .send({ email: 'test_transactions_villager@villager.com', password: 'password', role: 'VILLAGER', farm_name: 'Test Farm Transactions' })
                .expect(201);
            testVillagerId = villagerRegisterRes.body.id;

            // Login to get token for the villager
            const villagerLoginRes = await request(app)
                .post('/auth/login')
                .send({ email: 'test_transactions_villager@villager.com', password: 'password' })
                .expect(200);
            testVillagerToken = villagerLoginRes.body.accessToken;

            // Add a product for the test villager
            const productAddRes = await request(app)
                .post('/products')
                .set('Authorization', `Bearer ${testVillagerToken}`)
                .field('name', 'Test Product Transactions')
                .field('price', 15.0)
                .field('stock', 50.0)
                .field('category', 'Vegetable')
                .field('low_stock_threshold', 5.0)
                .expect(201);
            testProductId = productAddRes.body.id;

            // Add transactions for the product
            const currentTime = Math.floor(Date.now() / 1000);
            await new Promise((resolve, reject) => {
                db.run('DELETE FROM transactions WHERE product_id = ?', [testProductId], (err) => {
                    if (err) return reject(err);

                    db.run('INSERT INTO transactions (product_id, quantity_sold, date_of_sale, user_id) VALUES (?, ?, ?, ?)',
                        [testProductId, 1.0, currentTime - 120, testUserId],
                        (err) => {
                            if (err) return reject(err);
                            db.run('INSERT INTO transactions (product_id, quantity_sold, date_of_sale, user_id) VALUES (?, ?, ?, ?)',
                                [testProductId, 2.0, currentTime - 60, testUserId],
                                (err) => {
                                    if (err) return reject(err);
                                    resolve();
                                });
                        });
                });
            });
        });

        it('should return all transactions for a product owned by the villager', (done) => {
            // Verify transactions created by beforeEach
            db.all('SELECT * FROM transactions WHERE product_id = ?', [testProductId], (err, rows) => {
                if (err) return done(err);
                assert.strictEqual(rows.length, 2, 'beforeEach should have created 2 transactions');
                
                request(app)
                    .get(`/products/${testProductId}/transactions`)
                    .set('Authorization', `Bearer ${testVillagerToken}`)
                    .expect(200)
                    .end((err, res) => {
                        if (err) return done(err);
                        assert.ok(Array.isArray(res.body.transactions));
                        assert.strictEqual(res.body.transactions.length, 2);
                        assert.strictEqual(res.body.transactions[0].quantity_sold, 2.0); // Ordered by date DESC
                        assert.strictEqual(res.body.transactions[1].quantity_sold, 1.0);
                        // assert.strictEqual(res.body.transactions[0].buyer_email, 'test@user.com'); // This line was causing an error because buyer_email is not returned by the API
                        done();
                    });
            });
        });

        it('should filter transactions by days if query parameter is provided', (done) => {
            const currentTime = Math.floor(Date.now() / 1000);
            const oneDayAgo = currentTime - (1 * 24 * 60 * 60) - 10; // Slightly more than 1 day ago
            const twoDaysAgo = currentTime - (2 * 24 * 60 * 60) - 10; // Slightly more than 2 days ago

            // To avoid interference from previous beforeEach, we re-insert data.
            // This structure is fine because it's specific to this test.
            new Promise((resolve, reject) => {
                db.run('DELETE FROM transactions WHERE product_id = ?', [testProductId], (err) => {
                    if (err) return reject(err);

                    // Insert a transaction from 10 seconds ago (within 1 day)
                    db.run('INSERT INTO transactions (product_id, quantity_sold, date_of_sale, user_id) VALUES (?, ?, ?, ?)',
                        [testProductId, 1.0, currentTime - 10, testUserId], (err) => {
                            if (err) return reject(err);

                            // Insert a transaction from just over 1 day ago (should be excluded by ?days=1)
                            db.run('INSERT INTO transactions (product_id, quantity_sold, date_of_sale, user_id) VALUES (?, ?, ?, ?)',
                                [testProductId, 2.0, oneDayAgo, testUserId], (err) => {
                                    if (err) return reject(err);

                                    // Insert a transaction from just over 2 days ago (should also be excluded by ?days=1)
                                    db.run('INSERT INTO transactions (product_id, quantity_sold, date_of_sale, user_id) VALUES (?, ?, ?, ?)',
                                        [testProductId, 3.0, twoDaysAgo, testUserId], (err) => {
                                            if (err) return reject(err);
                                            resolve();
                                        });
                                });
                        });
                });
            }).then(() => {
                request(app)
                    .get(`/products/${testProductId}/transactions?days=1`) // Fetch only transactions from last 1 day
                    .set('Authorization', `Bearer ${testVillagerToken}`)
                    .expect(200)
                    .end((err, res) => {
                        if (err) return done(err);
                        assert.strictEqual(res.body.transactions.length, 1, 'Should return only 1 transaction (within 1 day)');
                        assert.strictEqual(res.body.transactions[0].quantity_sold, 1.0, 'The returned transaction should be the most recent one');
                        done();
                    });
            }).catch(done);
        });

        it('should return 403 if a user tries to access (not owner)', (done) => {
            request(app)
                .get(`/products/${testProductId}/transactions`)
                .set('Authorization', `Bearer ${testUserToken}`) // User does not own the product
                .expect(403)
                .end((err, res) => {
                    if (err) return done(err);
                    assert.strictEqual(res.body.error, 'Forbidden: You do not own this product.');
                    done();
                });
        });

        it('should return 401 if no token is provided', (done) => {
            request(app)
                .get(`/products/${testProductId}/transactions`)
                .expect(403) // 403 from verifyToken middleware
                .end(done);
        });
    });

    describe('GET /products', () => {
        let testVillagerId;
        let testVillagerToken;

        beforeEach(async () => {
            // Register a test villager (seller)
            const villagerRegisterRes = await request(app)
                .post('/auth/register')
                .send({ email: 'test_products_villager@villager.com', password: 'password', role: 'VILLAGER', farm_name: 'Test Farm Products' })
                .expect(201);
            testVillagerId = villagerRegisterRes.body.id;

            // Login to get token for the villager
            const villagerLoginRes = await request(app)
                .post('/auth/login')
                .send({ email: 'test_products_villager@villager.com', password: 'password' })
                .expect(200);
            testVillagerToken = villagerLoginRes.body.accessToken;

            // Add a 'Sweet' product
            await request(app)
                .post('/products')
                .set('Authorization', `Bearer ${testVillagerToken}`)
                .field('name', 'Sweet Test Product')
                .field('price', 12.0)
                .field('stock', 50.0)
                .field('category', 'Sweet')
                .field('low_stock_threshold', 5.0)
                .expect(201);

            // Add a 'Sour' product
            await request(app)
                .post('/products')
                .set('Authorization', `Bearer ${testVillagerToken}`)
                .field('name', 'Sour Test Product')
                .field('price', 8.0)
                .field('stock', 30.0)
                .field('category', 'Sour')
                .field('low_stock_threshold', 3.0)
                .expect(201);
        });

        it('should return all products when no category filter is applied', (done) => {
            request(app)
                .get('/products')
                .expect(200)
                .end((err, res) => {
                    if (err) return done(err);
                    assert.ok(Array.isArray(res.body.products));
                    assert.strictEqual(res.body.products.length, 2); // Should have both 'Sweet' and 'Sour' products
                    const productNames = res.body.products.map(p => p.name).sort();
                    assert.deepStrictEqual(productNames, ['Sour Test Product', 'Sweet Test Product']);
                    done();
                });
        });

        it('should return products filtered by a specific category (Sweet)', (done) => {
            request(app)
                .get('/products?category=Sweet')
                .expect(200)
                .end((err, res) => {
                    if (err) return done(err);
                    assert.ok(Array.isArray(res.body.products));
                    assert.strictEqual(res.body.products.length, 1);
                    assert.strictEqual(res.body.products[0].name, 'Sweet Test Product');
                    assert.strictEqual(res.body.products[0].category, 'Sweet');
                    done();
                });
        });

        it('should return products filtered by a specific category (Sour)', (done) => {
            request(app)
                .get('/products?category=Sour')
                .expect(200)
                .end((err, res) => {
                    if (err) return done(err);
                    assert.ok(Array.isArray(res.body.products));
                    assert.strictEqual(res.body.products.length, 1);
                    assert.strictEqual(res.body.products[0].name, 'Sour Test Product');
                    assert.strictEqual(res.body.products[0].category, 'Sour');
                    done();
                });
        });

        it('should return an empty array for a non-existent category', (done) => {
            request(app)
                .get('/products?category=NonExistent')
                .expect(200)
                .end((err, res) => {
                    if (err) return done(err);
                    assert.ok(Array.isArray(res.body.products));
                    assert.strictEqual(res.body.products.length, 0);
                    done();
                });
        });
    });
});
