output "address" {
  value = "${aws_elb.web.dns_name}"
}

output "public_key" {
  value = "${tls_private_key.webkey.public_key_pem}"
}

output "private_key" {
  value = "${tls_private_key.webkey.private_key_pem}"
}