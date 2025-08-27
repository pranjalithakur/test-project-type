package handlers

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"webapp-go/internal/db"
)

type FileHandler struct {
	db          *db.DB
	uploadDir   string
	maxFileSize int64
}

func NewFileHandler(db *db.DB) *FileHandler {
	return &FileHandler{
		db:          db,
		uploadDir:   "uploads/",
		maxFileSize: 10 * 1024 * 1024, // 10MB
	}
}

// Vulnerability: Path traversal, no file type validation, no size limits enforced
func (h *FileHandler) UploadFile(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Vulnerability: No authentication check
	// Vulnerability: No file size limit enforcement
	file, header, err := r.FormFile("file")
	if err != nil {
		http.Error(w, "Failed to get file", http.StatusBadRequest)
		return
	}
	defer file.Close()

	// Vulnerability: No file type validation
	// Vulnerability: Path traversal possible via filename
	filename := header.Filename
	if filename == "" {
		http.Error(w, "No filename provided", http.StatusBadRequest)
		return
	}

	// Vulnerability: No sanitization of filename
	// Vulnerability: Path traversal possible
	filepath := filepath.Join(h.uploadDir, filename)

	// Create upload directory if it doesn't exist
	if err := os.MkdirAll(h.uploadDir, 0755); err != nil {
		http.Error(w, "Failed to create upload directory", http.StatusInternalServerError)
		return
	}

	// Create the file
	dst, err := os.Create(filepath)
	if err != nil {
		http.Error(w, "Failed to create file", http.StatusInternalServerError)
		return
	}
	defer dst.Close()

	// Copy file content
	if _, err := io.Copy(dst, file); err != nil {
		http.Error(w, "Failed to save file", http.StatusInternalServerError)
		return
	}

	// Vulnerability: No user ID validation - hardcoded to 1
	userID := 1
	if err := h.db.SaveFile(filename, filepath, userID); err != nil {
		http.Error(w, "Failed to save file info", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]string{
		"message":  "File uploaded successfully",
		"filename": filename,
	})
}

// Vulnerability: Path traversal, no access control
func (h *FileHandler) DownloadFile(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Vulnerability: No authentication check
	// Vulnerability: Path traversal possible via filename parameter
	filename := r.URL.Query().Get("file")
	if filename == "" {
		http.Error(w, "Filename required", http.StatusBadRequest)
		return
	}

	// Vulnerability: No path sanitization
	// Vulnerability: Path traversal possible
	filepath := filepath.Join(h.uploadDir, filename)

	// Vulnerability: No access control - can download any file
	// Vulnerability: Path traversal can access files outside upload directory
	file, err := os.Open(filepath)
	if err != nil {
		http.Error(w, "File not found", http.StatusNotFound)
		return
	}
	defer file.Close()

	// Set content type
	w.Header().Set("Content-Type", "application/octet-stream")
	w.Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=%s", filename))

	// Copy file to response
	io.Copy(w, file)
}

// Vulnerability: No access control - can list any user's files
func (h *FileHandler) ListFiles(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Vulnerability: No authentication check
	// Vulnerability: No user ID validation - hardcoded to 1
	userID := 1

	files, err := h.db.GetUserFiles(userID)
	if err != nil {
		http.Error(w, "Failed to get files", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(files)
}

// Vulnerability: Path traversal, no access control
func (h *FileHandler) DeleteFile(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Vulnerability: No authentication check
	// Vulnerability: Path traversal possible via filename parameter
	filename := r.URL.Query().Get("file")
	if filename == "" {
		http.Error(w, "Filename required", http.StatusBadRequest)
		return
	}

	// Vulnerability: No path sanitization
	// Vulnerability: Path traversal possible
	filepath := filepath.Join(h.uploadDir, filename)

	// Vulnerability: No access control - can delete any file
	// Vulnerability: Path traversal can delete files outside upload directory
	if err := os.Remove(filepath); err != nil {
		http.Error(w, "Failed to delete file", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "File deleted successfully"})
}
