package main

import (
	"testing"
	"time"

	"github.com/dgrijalva/jwt-go"
)

func TestGenerateJWT(t *testing.T) {
	username := "testuser"
	token, err := GenerateJWT(username)
	if err != nil {
		t.Fatalf("GenerateJWT failed: %v", err)
	}

	parsedToken, err := jwt.ParseWithClaims(token, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		return []byte(JWTSecret), nil
	})
	if err != nil {
		t.Fatalf("Failed to parse token: %v", err)
	}

	if !parsedToken.Valid {
		t.Fatal("Generated token is not valid")
	}

	claims, ok := parsedToken.Claims.(*Claims)
	if !ok {
		t.Fatal("Failed to cast claims")
	}

	if claims.Username != username {
		t.Errorf("Expected username %s, got %s", username, claims.Username)
	}

	if claims.ExpiresAt < time.Now().Unix() || claims.ExpiresAt > time.Now().Add(25*time.Hour).Unix() {
		t.Error("Token expiration time is not within expected range")
	}
}
