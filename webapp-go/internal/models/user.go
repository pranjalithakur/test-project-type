package models

import "time"

type User struct {
	ID           int       `json:"id"`
	Username     string    `json:"username"`
	PasswordHash string    `json:"-"` // Don't expose in JSON
	Email        string    `json:"email"`
	IsAdmin      bool      `json:"is_admin"`
	CreatedAt    time.Time `json:"created_at"`
}

type Session struct {
	ID        string    `json:"id"`
	UserID    int       `json:"user_id"`
	ExpiresAt time.Time `json:"expires_at"`
}

type File struct {
	ID         int       `json:"id"`
	Filename   string    `json:"filename"`
	Filepath   string    `json:"filepath"`
	UserID     int       `json:"user_id"`
	UploadedAt time.Time `json:"uploaded_at"`
}
