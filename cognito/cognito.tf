
# Criar o user pool
resource "aws_cognito_user_pool" "app-user-pool" {
  name = "app-user-pool"
}

# Criar o dominio
resource "aws_cognito_user_pool_domain" "app-test" {
  domain       = "app-auth-teste"
  user_pool_id = aws_cognito_user_pool.app-user-pool.id
  
}

#Criar o resource server com os escopos para autorização
resource "aws_cognito_resource_server" "app-resources" {
  identifier = "cadastro-api"
  name       = "cadastro-api"

  scope {
    scope_name        = "create"
    scope_description = "Criação de registros"
  }
  
  scope {
    scope_name        = "list"
    scope_description = "Listagem de registros"
  }

  scope {
    scope_name        = "delete"
    scope_description = "Exclusão de registros"
  }

  user_pool_id = aws_cognito_user_pool.app-user-pool.id

  
}