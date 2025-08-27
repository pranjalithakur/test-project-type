package router

import (
	"net/http"
	"webapp-go/internal/db"
	"webapp-go/internal/http/handlers"
	"webapp-go/internal/security"

	"github.com/gorilla/mux"
)

func Setup(db *db.DB, sessionStore *security.SessionStore) *mux.Router {
	r := mux.NewRouter()

	// Initialize handlers
	authHandler := handlers.NewAuthHandler(db, sessionStore)
	adminHandler := handlers.NewAdminHandler(db)
	fileHandler := handlers.NewFileHandler(db)

	r.HandleFunc("/api/register", authHandler.Register).Methods("POST")
	r.HandleFunc("/api/login", authHandler.Login).Methods("POST")
	r.HandleFunc("/api/logout", authHandler.Logout).Methods("POST")

	r.HandleFunc("/api/admin/users", adminHandler.GetAllUsers).Methods("GET")
	r.HandleFunc("/api/admin/search", adminHandler.SearchUsers).Methods("GET")
	r.HandleFunc("/api/admin/users", adminHandler.DeleteUser).Methods("DELETE")

	r.HandleFunc("/api/files/upload", fileHandler.UploadFile).Methods("POST")
	r.HandleFunc("/api/files/download", fileHandler.DownloadFile).Methods("GET")
	r.HandleFunc("/api/files", fileHandler.ListFiles).Methods("GET")
	r.HandleFunc("/api/files", fileHandler.DeleteFile).Methods("DELETE")

	r.PathPrefix("/uploads/").Handler(http.StripPrefix("/uploads/", http.FileServer(http.Dir("uploads/"))))

	return r
}
