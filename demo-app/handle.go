package function

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
)

// Body is a struct that represents the payload for our serverless function.
type Body struct {
	Name string `json:"name"`
}

// Handle an HTTP Request.
func Handle(ctx context.Context, res http.ResponseWriter, req *http.Request) {
	switch strings.ToLower(req.Method) {
	case "post":
		var body Body

		// if body is not able to be decoded, return an error
		if err := json.NewDecoder(req.Body).Decode(&body); err != nil {
			res.WriteHeader(http.StatusBadRequest)
			res.Write([]byte(fmt.Sprintf("unable to decode body - expect {\"name\": \"value\"} format\n")))

			return
		}

		// if name is not provided, return an error
		if body.Name == "" {
			res.WriteHeader(http.StatusBadRequest)
			res.Write([]byte(fmt.Sprintf("name missing from body - expect {\"name\": \"value\"} format\n")))

			return
		}

		// print the message and return a status ok
		res.WriteHeader(http.StatusOK)
		res.Write([]byte(fmt.Sprintf("v3----- hi, my name is: %s\n", body.Name)))
	default:
		res.WriteHeader(http.StatusInternalServerError)
		res.Write([]byte(fmt.Sprintf("method [%s] unimplemented\n", req.Method)))
	}
}
