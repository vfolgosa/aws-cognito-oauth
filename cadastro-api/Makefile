.PHONY: test clean

test: deploy.done
	curl -fsSL -D - "$$(terraform output url)?name=Lambda"

clean:
	terraform destroy
	rm -f init.done deploy.done cadastro.zip cadastro

init.done:
	terraform init
	touch $@

deploy.done: init.done main.tf cadastro.zip
	terraform apply
	touch $@

cadastro.zip: cadastro
	zip $@ $<

cadastro: cadastro.go
	go get .
	GOOS=linux GOARCH=amd64 go build -mod=mod -o $@