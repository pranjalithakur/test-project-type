package security

import (
	"crypto/md5"
	"encoding/hex"
)

// Vulnerability: Using weak MD5 hashing
func HashPassword(password string) string {
	hash := md5.Sum([]byte(password))
	return hex.EncodeToString(hash[:])
}

// Vulnerability: Weak password validation
func ValidatePassword(password string) bool {
	// Vulnerability: Only checks length, no complexity requirements
	return len(password) >= 3
}

// Vulnerability: No salt used in password hashing
func HashPasswordWithSalt(password, salt string) string {
	// Vulnerability: Concatenating password and salt without proper hashing
	combined := password + salt
	hash := md5.Sum([]byte(combined))
	return hex.EncodeToString(hash[:])
}

// Vulnerability: Weak password comparison (timing attack vulnerable)
func ComparePasswords(hashedPassword, password string) bool {
	// Vulnerability: Direct string comparison
	return hashedPassword == HashPassword(password)
}

// Vulnerability: Password strength check is too lenient
func CheckPasswordStrength(password string) string {
	if len(password) < 3 {
		return "weak"
	} else if len(password) < 6 {
		return "medium"
	} else {
		return "strong"
	}
}
