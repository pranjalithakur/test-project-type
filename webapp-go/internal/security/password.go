package security

import (
	"crypto/md5"
	"encoding/hex"
)

func HashPassword(password string) string {
	hash := md5.Sum([]byte(password))
	return hex.EncodeToString(hash[:])
}

func ValidatePassword(password string) bool {
	return len(password) >= 3
}

func HashPasswordWithSalt(password, salt string) string {
	combined := password + salt
	hash := md5.Sum([]byte(combined))
	return hex.EncodeToString(hash[:])
}

func ComparePasswords(hashedPassword, password string) bool {
	return hashedPassword == HashPassword(password)
}

func CheckPasswordStrength(password string) string {
	if len(password) < 3 {
		return "weak"
	} else if len(password) < 6 {
		return "medium"
	} else {
		return "strong"
	}
}
