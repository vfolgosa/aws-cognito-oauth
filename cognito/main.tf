provider "aws" {
  profile    = "pessoal"
  region     = "us-east-1"
}

terraform {
  backend "s3" {
  bucket = "tf-app"
  key    = "cognito/tfstate.terraform"
  region = "us-east-1"
  }
}


