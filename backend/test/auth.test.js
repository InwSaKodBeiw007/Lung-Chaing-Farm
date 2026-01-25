// backend/test/auth.test.js
const request = require('supertest');
const assert = require('assert');
const path = require('path');
const sqlite3 = require('sqlite3').verbose();
const app = require('../server'); // Import the Express app

// Mock JWT_SECRET and other environment variables for testing
process.env.JWT_SECRET = 'test_secret';
process.env.REFRESH_TOKEN_SECRET = 'test_refresh_secret';
process.env.ACCESS_TOKEN_SECRET_EXPIRATION = '15m';
process.env.REFRESH_TOKEN_SECRET_EXPIRATION = '7d';
process.env.NODE_ENV = 'production'; // Ensure secure cookies are tested

describe('Auth Endpoints (Isolated)', () => {
    let db;
    const dbPath = path.resolve(__dirname, '../database.db');

    before((done) => {
        db = new sqlite3.Database(dbPath, (err) => {
            if (err) return done(err);
            db.serialize(() => {
                db.run('DELETE FROM users');
                db.run('DELETE FROM refresh_tokens', done);
            });
        });
    });

    after((done) => {
        db.serialize(() => {
            db.run('DELETE FROM users');
            db.run('DELETE FROM refresh_tokens', done);
        });
    });

    describe('POST /auth/register', () => {
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

        it('should not register a user with an existing email', (done) => {
            request(app)
                .post('/auth/register')
                .send({ email: 'isolated_test@user.com', password: 'password', role: 'USER' })
                .expect(500) // Expecting 500 for unique constraint violation
                .end((err, res) => {
                    if (err) return done(err);
                    assert.ok(res.body.error.includes('Email might already be in use.'), 'Error message should indicate existing email');
                    done();
                });
        });
    });

    describe('POST /auth/login', () => {
        beforeEach((done) => {
            db.run('DELETE FROM users');
            db.run('DELETE FROM refresh_tokens', (err) => {
                if (err) return done(err);
                request(app)
                    .post('/auth/register')
                    .send({ email: 'isolated_login@user.com', password: 'password', role: 'USER' })
                    .expect(201)
                    .end(done);
            });
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
