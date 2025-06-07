package main

import (
	"encoding/json"
	"log"
	"net/http"
	"sync"

	"github.com/gorilla/websocket"
)

// WebSocket upgrader
var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow all origins for now
	},
}

// WebSocket clients management
var (
	clients    = make(map[*websocket.Conn]bool)
	clientsMux sync.Mutex
)

func ProcessEvent(event Event) {
	eventJSON, err := json.Marshal(event)
	if err != nil {
		log.Printf("Error marshaling event to JSON: %v", err)
		return
	}
	log.Printf("Xử lý sự kiện: %s", string(eventJSON))

	// Send event to all connected WebSocket clients
	sendEventToClients(eventJSON)
}

// sendEventToClients sends the event JSON to all connected clients
func sendEventToClients(eventJSON []byte) {
	clientsMux.Lock()
	defer clientsMux.Unlock()

	for client := range clients {
		err := client.WriteMessage(websocket.TextMessage, eventJSON)
		if err != nil {
			log.Printf("Error sending event to client: %v", err)
			client.Close()
			delete(clients, client)
		}
	}
}

// HandleWebSocket handles WebSocket connections for the /events/ws endpoint
func HandleWebSocket(w http.ResponseWriter, r *http.Request) {
	ws, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("Error upgrading to WebSocket: %v", err)
		return
	}

	// Register new client
	clientsMux.Lock()
	clients[ws] = true
	clientsMux.Unlock()
	log.Printf("New WebSocket client connected. Total clients: %d", len(clients))

	// Keep connection alive and handle disconnection
	for {
		_, _, err := ws.ReadMessage()
		if err != nil {
			log.Printf("Error reading from WebSocket: %v", err)
			clientsMux.Lock()
			delete(clients, ws)
			clientsMux.Unlock()
			ws.Close()
			log.Printf("WebSocket client disconnected. Total clients: %d", len(clients))
			break
		}
	}
}
