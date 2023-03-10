terraform {
  # required_version = ">= 0.12"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }
}

resource "null_resource" "create_certs" {
  provisioner "local-exec" {
    command = <<EOT
      mkdir ${path.module}/.certs
      cd ${path.module}/.certs
      mkcert ${var.domain} "*.${var.domain}" localhost 127.0.0.1 ::1
    EOT
  }
}

data "local_file" "cert_file" {
  depends_on = [null_resource.create_certs]
  filename = "${path.module}/.certs/${var.domain}+4.pem"
}

data "local_file" "key_file" {
  depends_on = [null_resource.create_certs]
  filename = "${path.module}/.certs/${var.domain}+4-key.pem"
}
