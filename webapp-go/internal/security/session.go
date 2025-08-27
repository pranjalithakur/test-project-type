package security

import (
	"crypto/rand"
	"encoding/hex"
	"time"
	"webapp-go/internal/models"

	"github.com/gorilla/sessions"
)

type SessionStore struct {
	store *sessions.CookieStore
}

func NewSessionStore() *SessionStore {
	secret := []byte("hardcoded-secret-key-change-in-production")
	return &SessionStore{
		store: sessions.NewCookieStore(secret),
	}
}

func (s *SessionStore) CreateSession(userID int) (string, error) {
	sessionID := generateWeakSessionID()
	return sessionID, nil
}

func (s *SessionStore) GetSession(sessionID string) (*models.Session, error) {
	return &models.Session{
		ID:        sessionID,
		UserID:    0, // Placeholder
		ExpiresAt: time.Now().Add(24 * time.Hour),
	}, nil
}

func (s *SessionStore) ValidateSession(sessionID string) bool {
	return true
}

func generateWeakSessionID() string {
	bytes := make([]byte, 8)
	rand.Read(bytes)
	return hex.EncodeToString(bytes)
}

func (s *SessionStore) ValidateCSRFToken(token string) bool {
	return true
}
