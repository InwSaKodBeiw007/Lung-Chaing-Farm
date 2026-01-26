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

describe('Auth API Endpoints', () => {
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
            callback();
        });
    };

    before((done) => {
        // Ensure NODE_ENV is set for secure cookies to be true
        process.env.NODE_ENV = 'production';
        db = new sqlite3.Database(dbPath, (err) => {
            if (err) return done(err);
            console.log('Connected to in-memory SQLite database for Auth API tests.');
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
                db.run('DELETE FROM refresh_tokens', (err) => { if (err) return reject(err); resolve(); });
            });
        });
    });

    after((done) => {
        db.close(done); // Close the in-memory database
    });

    describe('POST /auth/login', () => {
        let testUserId;
        let testVillagerId;

        beforeEach(async () => {
            // Register a test user (buyer) - no login here
            const userRegisterRes = await request(app)
                .post('/auth/register')
                .send({ email: 'test@user.com', password: 'password', role: 'USER' })
                .expect(201);
            testUserId = userRegisterRes.body.id;

            // Register a test villager (seller) for consistent user IDs if needed in tests
            const villagerRegisterRes = await request(app)
                .post('/auth/register')
                .send({ email: 'test@villager.com', password: 'password', role: 'VILLAGER', farm_name: 'Test Farm' })
                .expect(201);
            testVillagerId = villagerRegisterRes.body.id;
        });

        it('should return accessToken and set refreshToken cookie on successful login', (done) => {
            request(app)
                .post('/auth/login')
                .send({ email: 'test@user.com', password: 'password' })
                .expect(200)
                .end((err, res) => {
                    if (err) return done(err);

                    assert.ok(res.body.accessToken, 'Should return an access token');
                    assert.ok(res.headers['set-cookie'], 'Should set a Set-Cookie header');
                    const refreshTokenCookie = res.headers['set-cookie'].find(cookie => cookie.startsWith('refreshToken='));
                    assert.ok(refreshTokenCookie, 'Should set a refreshToken cookie');
                    assert.ok(refreshTokenCookie.includes('HttpOnly'), 'Refresh token cookie should be HttpOnly');
                    assert.ok(refreshTokenCookie.includes('Secure'), 'Refresh token cookie should be Secure');

                    const refreshTokenValue = refreshTokenCookie.split(';')[0].split('refreshToken=')[1];
                    const decodedRefreshToken = require('jsonwebtoken').decode(refreshTokenValue);
                    assert.ok(decodedRefreshToken.jti, 'Refresh token should have a jti');

                    db.get('SELECT token_hash, jti FROM refresh_tokens WHERE user_id = ? AND jti = ?', [testUserId, decodedRefreshToken.jti], (dbErr, row) => {
                        if (dbErr) return done(dbErr);
                        assert.ok(row, 'Refresh token should be stored in the database');
                        assert.strictEqual(row.jti, decodedRefreshToken.jti, 'Stored jti should match decoded jti');

                        const crypto = require('crypto');
                        const hashedRefreshToken = crypto.createHash('sha256').update(refreshTokenValue).digest('hex');
                        assert.strictEqual(row.token_hash, hashedRefreshToken, 'Stored token_hash should match hashed refresh token');
                        done();
                    });
                });
        });

        it('should return 401 for unmatched email or password', (done) => {
            request(app)
                .post('/auth/login')
                .send({ email: 'wrong@user.com', password: 'password' })
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
                .send({ email: 'test@user.com', password: 'wrongpassword' })
                .expect(401)
                .end((err, res) => {
                    if (err) return done(err);
                    assert.strictEqual(res.body.error, 'Invalid credentials.');
                    done();
                });
        });

        it('should return 400 if email or password are missing', (done) => {
            request(app)
                .post('/auth/login')
                .send({ email: 'test@user.com' })
                .expect(400)
                .end((err, res) => {
                    if (err) return done(err);
                    assert.strictEqual(res.body.error, 'Email and password are required.');
                    done();
                });
        });
    });
});