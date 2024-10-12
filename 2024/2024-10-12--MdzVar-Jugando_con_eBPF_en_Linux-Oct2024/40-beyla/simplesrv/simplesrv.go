package main

import (
	"log"
	"math/rand"
	"net/http"
	"strconv"
	"strings"
	"time"
)

const (
	argForceReturnCode = "force_ret"
	argForceDelay      = "force_delay"
)

func handleRequest(rw http.ResponseWriter, req *http.Request) {
	log.Println("received request", req.RequestURI)

	// Initialize delay
	var delay time.Duration

	// Check if it's the /api/orders path
	if strings.HasPrefix(req.URL.Path, "/api/orders") {
		// Random delay between 1 and 3 seconds for /api/orders
		delay = time.Duration(2000+rand.Intn(3001)) * time.Millisecond
	}
	// For other paths, use the force_delay parameter if provided
	if d, err := strconv.Atoi(req.URL.Query().Get(argForceDelay)); err == nil {
		delay += time.Duration(d) * time.Millisecond
	} else {
		// Default delay between 0 and 500ms for other paths
		delay += time.Duration(rand.Intn(501)) * time.Millisecond
	}

	// Apply the delay
	time.Sleep(delay)

	// Handle forced response code
	retCode := http.StatusOK
	if r, err := strconv.Atoi(req.URL.Query().Get(argForceReturnCode)); err == nil {
		retCode = r
	}

	log.Printf("Responding to %s with status %d after %v delay", req.URL.Path, retCode, delay)
	rw.WriteHeader(retCode)
}

func main() {
	// Seed the random number generator
	rand.Seed(time.Now().UnixNano())

	log.Println("Listening on http://localhost:8080")
	log.Fatal(http.ListenAndServe(":8080", http.HandlerFunc(handleRequest)))
}
