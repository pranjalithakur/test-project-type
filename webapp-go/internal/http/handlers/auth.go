package handlers

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"webapp-go/internal/db"
	"webapp-go/internal/security"
)

type AuthHandler struct {
	db  *db.DB
	sec *security.SessionStore
}

func NewAuthHandler(db *db.DB, sec *security.SessionStore) *AuthHandler {
	return &AuthHandler{
		db:  db,
		sec: sec,
	}
}

// Vulnerability: No input validation or sanitization
func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		Username string `json:"username"`
		Password string `json:"password"`
		Email    string `json:"email"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	// Vulnerability: No input validation
	if req.Username == "" || req.Password == "" {
		http.Error(w, "Username and password required", http.StatusBadRequest)
		return
	}

	// Vulnerability: Weak password hashing
	passwordHash := security.HashPassword(req.Password)

	if err := h.db.CreateUser(req.Username, passwordHash, req.Email); err != nil {
		http.Error(w, "Failed to create user", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]string{"message": "User created successfully"})
}

// Vulnerability: No rate limiting, weak session management
func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		Username string `json:"username"`
		Password string `json:"password"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	// Vulnerability: SQL injection possible in GetUserByUsername
	user, err := h.db.GetUserByUsername(req.Username)
	if err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, "Invalid credentials", http.StatusUnauthorized)
			return
		}
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	// Vulnerability: Weak password comparison
	if !security.ComparePasswords(user.PasswordHash, req.Password) {
		http.Error(w, "Invalid credentials", http.StatusUnauthorized)
		return
	}

	// Vulnerability: Weak session generation
	sessionID, err := h.sec.CreateSession(user.ID)
	if err != nil {
		http.Error(w, "Failed to create session", http.StatusInternalServerError)
		return
	}

	// Vulnerability: No secure cookie flags
	http.SetCookie(w, &http.Cookie{
		Name:  "session_id",
		Value: sessionID,
		Path:  "/",
		// Vulnerability: Missing secure, httpOnly, sameSite flags
	})

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "Login successful"})
}

// Vulnerability: No CSRF protection
func (h *AuthHandler) Logout(w http.ResponseWriter, r *http.Request) {
	// Vulnerability: No session validation
	http.SetCookie(w, &http.Cookie{
		Name:   "session_id",
		Value:  "",
		Path:   "/",
		MaxAge: -1,
	})

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "Logout successful"})
}
