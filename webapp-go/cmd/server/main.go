package main

import (
	"log"
	"net/http"
	"os"
	"webapp-go/internal/config"
	"webapp-go/internal/db"
	"webapp-go/internal/http/router"
	"webapp-go/internal/security"

	_ "github.com/lib/pq"
	_ "github.com/mattn/go-sqlite3"
)

func main() {
	// Load configuration
	cfg, err := config.Load("config/app.yaml")
	if err != nil {
		log.Printf("Failed to load config: %v, using defaults", err)
		cfg = &config.Config{
			Port:     "8080",
			DBDriver: "sqlite3",
			DBDSN:    "vulnerable.db",
		}
	}

	// Initialize database
	database, err := db.Init(cfg.DBDriver, cfg.DBDSN)
	if err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}
	defer database.Close()

	// Initialize session store
	sessionStore := security.NewSessionStore()

	// Setup router
	r := router.Setup(database, sessionStore)

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = cfg.Port
	}

	log.Printf("Starting server on port %s", port)
	if err := http.ListenAndServe(":"+port, r); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
