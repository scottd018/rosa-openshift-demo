package main

import (
	"fmt"
	"net/http"
	"os"
)

const (
	readFile = "/tmp/message.txt"
)

// status represents the /status endpoint for the app
func status(w http.ResponseWriter, req *http.Request) {
	fmt.Fprintf(w, "ok\n")
}

// read represents a demo to read data from the app.  in this case,
// we are simply ready a file at a location.  if the file does not exist
// or it is empty, a message is returned.
func read(w http.ResponseWriter, req *http.Request) {
	_, err := os.Stat(readFile)
	if os.IsNotExist(err) {
		fmt.Fprintf(w, "oh no!  your data is missing!\n")
	} else {
		content, err := os.ReadFile(readFile)
		if err != nil {
			fmt.Fprintf(w, "500 internal server error\n")
		} else {
			stringContent := string(content)
			if stringContent == "\n" {
				fmt.Fprintf(w, "oh no!  your data is missing!\n")
			} else {
				fmt.Fprintf(w, string(content))
			}
		}
	}
}

func main() {
	http.HandleFunc("/status", status)
	http.HandleFunc("/read", read)

	http.ListenAndServe(":8080", nil)
}
