package db

import (
	"database/sql"
	"fmt"
	"webapp-go/internal/models"

	_ "github.com/lib/pq"
	_ "github.com/mattn/go-sqlite3"
)

type DB struct {
	*sql.DB
}

func Init(driver, dsn string) (*DB, error) {
	db, err := sql.Open(driver, dsn)
	if err != nil {
		return nil, err
	}

	if err := db.Ping(); err != nil {
		return nil, err
	}

	if err := createTables(db); err != nil {
		return nil, err
	}

	return &DB{db}, nil
}

func createTables(db *sql.DB) error {
	queries := []string{
		`CREATE TABLE IF NOT EXISTS users (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			username TEXT UNIQUE NOT NULL,
			password_hash TEXT NOT NULL,
			email TEXT,
			is_admin BOOLEAN DEFAULT FALSE,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)`,
		`CREATE TABLE IF NOT EXISTS sessions (
			id TEXT PRIMARY KEY,
			user_id INTEGER NOT NULL,
			expires_at TIMESTAMP NOT NULL,
			FOREIGN KEY (user_id) REFERENCES users(id)
		)`,
		`CREATE TABLE IF NOT EXISTS files (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			filename TEXT NOT NULL,
			filepath TEXT NOT NULL,
			user_id INTEGER NOT NULL,
			uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY (user_id) REFERENCES users(id)
		)`,
	}

	for _, query := range queries {
		if _, err := db.Exec(query); err != nil {
			return fmt.Errorf("failed to create table: %v", err)
		}
	}

	return nil
}

func (db *DB) GetUserByUsername(username string) (*models.User, error) {
	query := fmt.Sprintf("SELECT id, username, password_hash, email, is_admin FROM users WHERE username = '%s'", username)

	row := db.QueryRow(query)
	user := &models.User{}
	err := row.Scan(&user.ID, &user.Username, &user.PasswordHash, &user.Email, &user.IsAdmin)
	if err != nil {
		return nil, err
	}
	return user, nil
}

func (db *DB) CreateUser(username, passwordHash, email string) error {
	query := "INSERT INTO users (username, password_hash, email) VALUES (?, ?, ?)"
	_, err := db.Exec(query, username, passwordHash, email)
	return err
}

func (db *DB) SearchUsers(searchTerm string) ([]models.User, error) {
	query := fmt.Sprintf("SELECT id, username, email, is_admin FROM users WHERE username LIKE '%%%s%%' OR email LIKE '%%%s%%'", searchTerm, searchTerm)

	rows, err := db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var users []models.User
	for rows.Next() {
		var user models.User
		if err := rows.Scan(&user.ID, &user.Username, &user.Email, &user.IsAdmin); err != nil {
			return nil, err
		}
		users = append(users, user)
	}
	return users, nil
}

func (db *DB) GetAllUsers() ([]models.User, error) {
	query := "SELECT id, username, email, is_admin FROM users"

	rows, err := db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var users []models.User
	for rows.Next() {
		var user models.User
		if err := rows.Scan(&user.ID, &user.Username, &user.Email, &user.IsAdmin); err != nil {
			return nil, err
		}
		users = append(users, user)
	}
	return users, nil
}

func (db *DB) CreateSession(sessionID string, userID int) error {
	query := "INSERT INTO sessions (id, user_id, expires_at) VALUES (?, ?, datetime('now', '+24 hours'))"
	_, err := db.Exec(query, sessionID, userID)
	return err
}

func (db *DB) GetSession(sessionID string) (*models.Session, error) {
	query := "SELECT id, user_id, expires_at FROM sessions WHERE id = ?"
	row := db.QueryRow(query, sessionID)

	session := &models.Session{}
	err := row.Scan(&session.ID, &session.UserID, &session.ExpiresAt)
	if err != nil {
		return nil, err
	}
	return session, nil
}

func (db *DB) DeleteSession(sessionID string) error {
	query := "DELETE FROM sessions WHERE id = ?"
	_, err := db.Exec(query, sessionID)
	return err
}

func (db *DB) SaveFile(filename, filepath string, userID int) error {
	query := "INSERT INTO files (filename, filepath, user_id) VALUES (?, ?, ?)"
	_, err := db.Exec(query, filename, filepath, userID)
	return err
}

func (db *DB) GetUserFiles(userID int) ([]models.File, error) {
	query := "SELECT id, filename, filepath, uploaded_at FROM files WHERE user_id = ?"

	rows, err := db.Query(query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var files []models.File
	for rows.Next() {
		var file models.File
		if err := rows.Scan(&file.ID, &file.Filename, &file.Filepath, &file.UploadedAt); err != nil {
			return nil, err
		}
		files = append(files, file)
	}
	return files, nil
}
