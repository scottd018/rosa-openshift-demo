clean:
	rm -rf demo

create: clean
	func create -l go demo

write-code:
	@cp snippets/handle.go.txt demo/handle.go
	@cp snippets/handle_test.go.txt demo/handle_test.go

test:
	cd demo && go test

build:
	func build -p demo

run:
	func run -p demo --build=false

test-curl-bad:
	curl -X GET localhost:8080

test-curl-good:
	curl -X POST localhost:8080 -d '{"name": "chicka chicka slim shady"}'
