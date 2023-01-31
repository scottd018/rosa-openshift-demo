package function

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"strings"
)

const (
	readFile = "/tmp/message.txt"
)

// Handle an HTTP Request.
func Handle(ctx context.Context, res http.ResponseWriter, req *http.Request) {
	_, err := os.Stat(readFile)
	if os.IsNotExist(err) {
		fmt.Fprintf(res, "oh no!  your data is missing!\n")
	} else {
		content, err := os.ReadFile(readFile)
		if err != nil {
			fmt.Fprintf(res, "500 internal server error\n")
		} else {
			stringContent := string(content)
			if stringContent == "\n" {
				fmt.Fprintf(res, "oh no!  your data is missing!\n")
			} else {
				fmt.Fprintf(res, string(content))
			}
		}
	}

	fmt.Println("Received request")
	fmt.Println(prettyPrint(req))      // echo to local output
	fmt.Fprintf(res, prettyPrint(req)) // echo to caller
}

func prettyPrint(req *http.Request) string {
	b := &strings.Builder{}
	fmt.Fprintf(b, "%v %v %v %v\n", req.Method, req.URL, req.Proto, req.Host)
	for k, vv := range req.Header {
		for _, v := range vv {
			fmt.Fprintf(b, "  %v: %v\n", k, v)
		}
	}

	if req.Method == "POST" {
		req.ParseForm()
		fmt.Fprintln(b, "Body:")
		for k, v := range req.Form {
			fmt.Fprintf(b, "  %v: %v\n", k, v)
		}
	}

	return b.String()
}
