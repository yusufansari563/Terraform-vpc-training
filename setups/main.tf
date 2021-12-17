
provider "aws" {
  profile    = "default"
  region     = "us-east-2"
}

module "demo_server" {
  source        = "../modules/webserver"
  region        = "us-east-2"
  instance_type = "t2.micro"
  ami           = "ami-03a0c45ebc70f98ea"
  server_name   = "web_server"
  zone          = "us-east-2a"
}
