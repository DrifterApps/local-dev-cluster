output "cert_content" {
  value = data.local_file.cert_file.content_base64
}
output "key_content" {
  value = data.local_file.key_file.content_base64
}
