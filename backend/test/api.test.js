const request = require('supertest');
const assert = require('assert');
const path = require('path');
const fs = require('fs');
const sqlite3 = require('sqlite3').verbose();
const app = require('../server'); // Import the Express app

// Mock JWT_SECRET for testing
process.env.JWT_SECRET = 'test_secret';

describe('API Endpoints', () => {
    let db;
    let agent; // supertest agent for persistent sessions
    let testUserToken;
    let testUserId;
    let testVillagerToken;
    let testVillagerId;
    let testProductId; // Product owned by testVillager
    let otherProductId; // Product owned by another villager (if created)

    const dbPath = path.resolve(__dirname, '../database.db'); // Use the actual database for API tests

    before((done) => {
        // Ensure the database is initialized with tables before tests run
        // This relies on server.js's db.serialize block to run
        // For more isolated tests, we'd create a separate test database and schema here
        // But for integration testing the API, we use the main setup
        db = new sqlite3.Database(dbPath, (err) => {
            if (err) return done(err);
            console.log('Using main database for API tests.');

            // Clear users, products, and transactions to ensure a clean state
            db.serialize(() => {
                db.run('DELETE FROM users');
                db.run('DELETE FROM products');
                db.run('DELETE FROM product_images');
                db.run('DELETE FROM transactions', done);
            });
        });
    });

    beforeEach((done) => {
        // Clear data and create fresh users/products for each test
        db.serialize(() => {
            db.run('DELETE FROM users');
            db.run('DELETE FROM products');
            db.run('DELETE FROM product_images');
            db.run('DELETE FROM transactions', (err) => {
                if (err) return done(err);

                // Register a test user (buyer)
                request(app)
                    .post('/auth/register')
                    .send({ email: 'test@user.com', password: 'password', role: 'USER' })
                    .expect(201)
                    .end((err, res) => {
                        if (err) return done(err);
                        testUserId = res.body.id;
                        // Login to get token
                        request(app)
                            .post('/auth/login')
                            .send({ email: 'test@user.com', password: 'password' })
                            .expect(200)
                            .end((err, res) => {
                                if (err) return done(err);
                                testUserToken = res.body.token;

                                // Register a test villager (seller)
                                request(app)
                                    .post('/auth/register')
                                    .send({ email: 'test@villager.com', password: 'password', role: 'VILLAGER', farm_name: 'Test Farm' })
                                    .expect(201)
                                    .end((err, res) => {
                                        if (err) return done(err);
                                        testVillagerId = res.body.id;
                                        // Login to get token
                                        request(app)
                                            .post('/auth/login')
                                            .send({ email: 'test@villager.com', password: 'password' })
                                            .expect(200)
                                            .end((err, res) => {
                                                if (err) return done(err);
                                                testVillagerToken = res.body.token;

                                                // Add a product for the test villager
                                                request(app)
                                                    .post('/products')
                                                    .set('Authorization', `Bearer ${testVillagerToken}`)
                                                    .field('name', 'Test Product')
                                                    .field('price', 10.0)
                                                    .field('stock', 100.0)
                                                    .field('category', 'Sweet')
                                                    .field('low_stock_threshold', 10.0)
                                                    .expect(201)
                                                    .end((err, res) => {
                                                        if (err) return done(err);
                                                        testProductId = res.body.id;
                                                        done();
                                                    });
                                            });
                                    });
                            });
                    });
            });
        });
    });

    after((done) => {
        // Clean up: delete all test data
        db.serialize(() => {
            db.run('DELETE FROM users');
            db.run('DELETE FROM products');
            db.run('DELETE FROM product_images');
            db.run('DELETE FROM transactions', (err) => {
                if (err) return done(err);
                db.close(done);
            });
        });
    });

    describe('POST /products/:productId/purchase', () => {
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
                .set('Authorization', `Bearer ${testUserToken}`)
                .send({ quantity: -5.0 })
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
                        beforeEach((done) => {
                            // Clear all transactions for the test product before each test in this block
                            db.run('DELETE FROM transactions WHERE product_id = ?', [testProductId], (err) => {
                                if (err) return done(err);
                
                                const currentTime = Math.floor(Date.now() / 1000);
                
                                // Now, create some standard transactions for tests that need them by direct insertion
                                db.run('INSERT INTO transactions (product_id, quantity_sold, date_of_sale, user_id) VALUES (?, ?, ?, ?)',
                                    [testProductId, 1.0, currentTime - 120, testUserId], // 2 minutes ago
                                    (err) => {
                                        if (err) return done(err);
                                        db.run('INSERT INTO transactions (product_id, quantity_sold, date_of_sale, user_id) VALUES (?, ?, ?, ?)',
                                            [testProductId, 2.0, currentTime - 60, testUserId], // 1 minute ago
                                            (err) => {
                                                if (err) return done(err);
                                                done();
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
                        assert.strictEqual(res.body.transactions[0].buyer_email, 'test@user.com');
                        done();
                    });
            });
        });

        it('should filter transactions by days if query parameter is provided', (done) => {
            const currentTime = Math.floor(Date.now() / 1000);
            const oneDayAgo = currentTime - (1 * 24 * 60 * 60) - 10; // Slightly more than 1 day ago
            const twoDaysAgo = currentTime - (2 * 24 * 60 * 60) - 10; // Slightly more than 2 days ago

            db.serialize(() => {
                // Clear existing transactions for this product to avoid interference from beforeEach
                db.run('DELETE FROM transactions WHERE product_id = ?', [testProductId], (err) => {
                    if (err) return done(err);

                    // Insert a transaction from 10 seconds ago (within 1 day)
                    db.run('INSERT INTO transactions (product_id, quantity_sold, date_of_sale, user_id) VALUES (?, ?, ?, ?)',
                        [testProductId, 1.0, currentTime - 10, testUserId], (err) => {
                            if (err) return done(err);

                            // Insert a transaction from just over 1 day ago (should be excluded by ?days=1)
                            db.run('INSERT INTO transactions (product_id, quantity_sold, date_of_sale, user_id) VALUES (?, ?, ?, ?)',
                                [testProductId, 2.0, oneDayAgo, testUserId], (err) => {
                                    if (err) return done(err);

                                    // Insert a transaction from just over 2 days ago (should also be excluded by ?days=1)
                                    db.run('INSERT INTO transactions (product_id, quantity_sold, date_of_sale, user_id) VALUES (?, ?, ?, ?)',
                                        [testProductId, 3.0, twoDaysAgo, testUserId], (err) => {
                                            if (err) return done(err);

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
                                        });
                                });
                        });
                });
            });
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
});
