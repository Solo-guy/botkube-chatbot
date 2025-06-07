package main

import (
	"database/sql"
	"errors"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/dgrijalva/jwt-go"
	_ "github.com/lib/pq"
	"gopkg.in/yaml.v2"
)

var JWTSecret = os.Getenv("JWT_SECRET")

type Claims struct {
	Username string `json:"username"`
	Role     string `json:"role"`
	jwt.StandardClaims
}

// Config định nghĩa cấu hình cho kết nối cơ sở dữ liệu và JWT
type AuthConfig struct {
	DBHost     string `yaml:"host"`
	DBPort     int    `yaml:"port"`
	DBUser     string `yaml:"user"`
	DBPassword string `yaml:"password"`
	DBName     string `yaml:"dbname"`
	JWTSecret  string `yaml:"jwtSecret"`
}

func loadAuthConfig() (*AuthConfig, error) {
	data, err := os.ReadFile("config.yaml")
	if err != nil {
		return nil, fmt.Errorf("Không thể đọc config.yaml: %v", err)
	}

	var config AuthConfig
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("Không thể phân tích config.yaml: %v", err)
	}
	return &config, nil
}

func ValidateUser(username string) (bool, string) {
	config, err := loadAuthConfig()
	if err != nil {
		log.Printf("Lỗi khi đọc cấu hình: %v", err)
		return false, ""
	}

	db, err := sql.Open("postgres", fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable", config.DBHost, config.DBPort, config.DBUser, config.DBPassword, config.DBName))
	if err != nil {
		log.Printf("Không thể kết nối tới CockroachDB: %v", err)
		return false, ""
	}
	defer db.Close()

	err = db.Ping()
	if err != nil {
		log.Printf("Không thể kiểm tra kết nối CockroachDB: %v", err)
		return false, ""
	}

	var role string
	err = db.QueryRow("SELECT role FROM users WHERE username = $1", username).Scan(&role)
	if err == sql.ErrNoRows {
		log.Printf("Không tìm thấy người dùng %s trong cơ sở dữ liệu", username)
		return false, ""
	}
	if err != nil {
		log.Printf("Lỗi khi truy vấn người dùng %s: %v", username, err)
		return false, ""
	}

	log.Printf("Đã xác thực người dùng %s với vai trò %s", username, role)
	return true, role
}

func GenerateJWT(username string) (string, error) {
	valid, role := ValidateUser(username)
	if !valid {
		return "", errors.New("Tên người dùng không hợp lệ. Vui lòng kiểm tra lại thông tin đăng nhập.")
	}

	claims := &Claims{
		Username: username,
		Role:     role,
		StandardClaims: jwt.StandardClaims{
			ExpiresAt: time.Now().Add(time.Hour * 24).Unix(),
			IssuedAt:  time.Now().Unix(),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signedToken, err := token.SignedString([]byte(JWTSecret))
	if err != nil {
		return "", fmt.Errorf("Không thể ký token JWT: %v", err)
	}

	log.Printf("Đã tạo token JWT cho người dùng %s", username)
	return signedToken, nil
}

func RefreshToken(tokenStr string) (string, error) {
	claims := &Claims{}
	token, err := jwt.ParseWithClaims(tokenStr, claims, func(token *jwt.Token) (interface{}, error) {
		return []byte(JWTSecret), nil
	})
	if err != nil || !token.Valid {
		return "", fmt.Errorf("Token không hợp lệ hoặc đã hết hạn. Vui lòng đăng nhập lại: %v", err)
	}

	// Kiểm tra xem token có gần hết hạn không (ví dụ: còn dưới 30 phút)
	if claims.ExpiresAt-time.Now().Unix() > 1800 {
		return "", errors.New("Token vẫn còn hiệu lực. Không cần gia hạn lúc này.")
	}

	// Gia hạn token với thời gian mới
	newClaims := &Claims{
		Username: claims.Username,
		Role:     claims.Role,
		StandardClaims: jwt.StandardClaims{
			ExpiresAt: time.Now().Add(time.Hour * 24).Unix(),
			IssuedAt:  time.Now().Unix(),
		},
	}

	newToken := jwt.NewWithClaims(jwt.SigningMethodHS256, newClaims)
	newSignedToken, err := newToken.SignedString([]byte(JWTSecret))
	if err != nil {
		return "", fmt.Errorf("Không thể ký token JWT mới: %v", err)
	}

	log.Printf("Đã gia hạn token JWT cho người dùng %s", claims.Username)
	return newSignedToken, nil
}
