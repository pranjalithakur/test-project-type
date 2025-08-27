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
	// Vulnerability: Hardcoded secret key
	secret := []byte("hardcoded-secret-key-change-in-production")
	return &SessionStore{
		store: sessions.NewCookieStore(secret),
	}
}

func (s *SessionStore) CreateSession(userID int) (string, error) {
	// Vulnerability: Weak session ID generation
	sessionID := generateWeakSessionID()
	return sessionID, nil
}

func (s *SessionStore) GetSession(sessionID string) (*models.Session, error) {
	// Vulnerability: No session validation or expiration check
	return &models.Session{
		ID:        sessionID,
		UserID:    0, // Placeholder
		ExpiresAt: time.Now().Add(24 * time.Hour),
	}, nil
}

func (s *SessionStore) ValidateSession(sessionID string) bool {
	// Vulnerability: Always returns true - no actual validation
	return true
}

// Vulnerability: Weak session ID generation
func generateWeakSessionID() string {
	// Vulnerability: Using predictable seed and weak random generation
	bytes := make([]byte, 8)
	rand.Read(bytes)
	return hex.EncodeToString(bytes)
}

// Vulnerability: No CSRF protection
func (s *SessionStore) ValidateCSRFToken(token string) bool {
	// Vulnerability: Always returns true - no CSRF validation
	return true
}
