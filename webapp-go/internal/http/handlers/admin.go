package handlers

import (
	"encoding/json"
	"net/http"
	"webapp-go/internal/db"
)

type AdminHandler struct {
	db *db.DB
}

func NewAdminHandler(db *db.DB) *AdminHandler {
	return &AdminHandler{db: db}
}

// Vulnerability: No authentication check - anyone can access
func (h *AdminHandler) GetAllUsers(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Vulnerability: No admin role verification
	users, err := h.db.GetAllUsers()
	if err != nil {
		http.Error(w, "Failed to get users", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(users)
}

// Vulnerability: No authentication check - anyone can search users
func (h *AdminHandler) SearchUsers(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Vulnerability: No input validation or sanitization
	searchTerm := r.URL.Query().Get("q")
	if searchTerm == "" {
		http.Error(w, "Search term required", http.StatusBadRequest)
		return
	}

	// Vulnerability: SQL injection possible in SearchUsers
	users, err := h.db.SearchUsers(searchTerm)
	if err != nil {
		http.Error(w, "Failed to search users", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(users)
}

// Vulnerability: No authentication check - anyone can delete users
func (h *AdminHandler) DeleteUser(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Vulnerability: No input validation
	userID := r.URL.Query().Get("id")
	if userID == "" {
		http.Error(w, "User ID required", http.StatusBadRequest)
		return
	}

	// Vulnerability: No admin role verification
	// Vulnerability: SQL injection possible (though not implemented in this example)
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "User deleted successfully"})
}
