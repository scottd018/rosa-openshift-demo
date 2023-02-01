package function

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// TestHandle ensures that Handle executes without error and returns the
// HTTP 200 status code indicating no errors.
func TestHandle(t *testing.T) {
	tests := []struct {
		name     string
		recorder *httptest.ResponseRecorder
		request  *http.Request
		status   int
	}{
		{
			name:     "ensure invalid method returns a 500 internal server error",
			recorder: httptest.NewRecorder(),
			request:  httptest.NewRequest("GET", "http://example.com/test", nil),
			status:   http.StatusInternalServerError,
		},
		{
			name:     "ensure valid method with no body returns a 400 bad request error",
			recorder: httptest.NewRecorder(),
			request:  httptest.NewRequest("POST", "http://example.com/test", nil),
			status:   http.StatusBadRequest,
		},
		{
			name:     "ensure valid method with with empty name value returns a 400 bad request error",
			recorder: httptest.NewRecorder(),
			request:  httptest.NewRequest("POST", "http://example.com/test", strings.NewReader(`{"name": ""}`)),
			status:   http.StatusBadRequest,
		},
		{
			name:     "ensure valid method with and body returns a 200 ok response",
			recorder: httptest.NewRecorder(),
			request:  httptest.NewRequest("POST", "http://example.com/test", strings.NewReader(`{"name": "dustin"}`)),
			status:   http.StatusOK,
		},
	}

	for _, test := range tests {
		Handle(context.Background(), test.recorder, test.request)
		res := test.recorder.Result()
		defer res.Body.Close()

		if res.StatusCode != test.status {
			t.Fatalf("expected status: %v, received status: %v", test.status, res.StatusCode)
		}
	}
}
