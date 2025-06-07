package main

import (
	"encoding/json"
	"testing"
)

func TestEventStruct(t *testing.T) {
	event := Event{
		Type:      "create",
		Resource:  "pod",
		Name:      "test-pod",
		Namespace: "default",
		Cluster:   "test-cluster",
	}

	// Test JSON marshaling
	data, err := json.Marshal(event)
	if err != nil {
		t.Fatalf("Failed to marshal event to JSON: %v", err)
	}

	// Test JSON unmarshaling
	var decodedEvent Event
	err = json.Unmarshal(data, &decodedEvent)
	if err != nil {
		t.Fatalf("Failed to unmarshal event from JSON: %v", err)
	}

	if decodedEvent.Type != event.Type {
		t.Errorf("Expected Type %s, got %s", event.Type, decodedEvent.Type)
	}
	if decodedEvent.Resource != event.Resource {
		t.Errorf("Expected Resource %s, got %s", event.Resource, decodedEvent.Resource)
	}
	if decodedEvent.Name != event.Name {
		t.Errorf("Expected Name %s, got %s", event.Name, decodedEvent.Name)
	}
	if decodedEvent.Namespace != event.Namespace {
		t.Errorf("Expected Namespace %s, got %s", event.Namespace, decodedEvent.Namespace)
	}
	if decodedEvent.Cluster != event.Cluster {
		t.Errorf("Expected Cluster %s, got %s", event.Cluster, decodedEvent.Cluster)
	}
}
