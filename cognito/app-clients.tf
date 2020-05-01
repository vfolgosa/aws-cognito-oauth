# Criar os app clients
resource "aws_cognito_user_pool_client" "app-client-1" {
  name = "app-client-1"
  supported_identity_providers = ["COGNITO"]
  allowed_oauth_flows_user_pool_client = "true"
  allowed_oauth_flows = ["client_credentials"]
  generate_secret = "true"
  allowed_oauth_scopes = ["cadastro-api/create", "cadastro-api/list"]  
  user_pool_id = aws_cognito_user_pool.app-user-pool.id
  depends_on = [aws_cognito_resource_server.app-resources]
}

resource "aws_cognito_user_pool_client" "app-client-2" {
  name = "app-client-2"
  supported_identity_providers = ["COGNITO"]
  allowed_oauth_flows_user_pool_client = "true"
  allowed_oauth_flows = ["client_credentials"]
  generate_secret = "true"
  allowed_oauth_scopes = ["cadastro-api/delete"]  
  user_pool_id = aws_cognito_user_pool.app-user-pool.id
  depends_on = [aws_cognito_resource_server.app-resources]
}