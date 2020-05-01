# POC AWS Api Gateway + Cognito + Oauth2 #


### Requisitos ###

* Terraform 1.12+
* Go 1.14
* aws cli com um profile configurado.

## Utilização


1 - Clonar o projeto.
2 - Rodar o terraform para criação das configurações e app-clients do cognito
    
```bash
cd cognito
AWS_PROFILE=<aws_profile> terraform init
AWS_PROFILE=<aws_profile> terraform apply
```

3 - Rodar o make para criação do api-gataway e lambda de testes.

```bash
cd cadastro-api
AWS_PROFILE=<aws_profile> make

