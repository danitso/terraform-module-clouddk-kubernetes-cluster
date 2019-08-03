resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "ca" {
    is_ca_certificate     = true
    key_algorithm         = "RSA"
    private_key_pem       = tls_private_key.ca.private_key_pem
    validity_period_hours = 175320

    allowed_uses = [
        "cert_signing",
        "crl_signing",
        "digital_signature",
        "key_agreement",
        "key_encipherment",
        "ocsp_signing",
        "server_auth",
        "client_auth",
    ]

    subject {
        common_name         = "Kubernetes"
        country             = "DK"
        organization        = "Danitso"
        organizational_unit = "Kubernetes"
        locality            = "Copenhagen"
    }
}
