resource "google_compute_global_address" "lb_ip" {
  name = "smart-construction-lb-ip"
}

resource "google_compute_instance_group" "app_group" {
  name      = "smart-construction-app-group"
  zone      = var.zone
  instances = google_compute_instance.app[*].id

  named_port {
    name = "http"
    port = 80
  }
}

resource "google_compute_health_check" "http_hc" {
  name                = "smart-construction-http-hc"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = 80
    request_path = "/"
  }
}

resource "google_compute_backend_service" "app_backend" {
  name                  = "smart-construction-backend"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 30
  health_checks         = [google_compute_health_check.http_hc.id]

  backend {
    group           = google_compute_instance_group.app_group.id
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

resource "google_compute_url_map" "url_map" {
  name            = "smart-construction-url-map"
  default_service = google_compute_backend_service.app_backend.id
}

resource "google_compute_managed_ssl_certificate" "ssl_cert" {
  name = "smart-construction-ssl-cert"

  managed {
    domains = ["${google_compute_global_address.lb_ip.address}.sslip.io"]
  }
}

resource "google_compute_target_https_proxy" "https_proxy" {
  name             = "smart-construction-https-proxy"
  url_map          = google_compute_url_map.url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.ssl_cert.id]
}

resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
  name                  = "smart-construction-https-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.https_proxy.id
  ip_address            = google_compute_global_address.lb_ip.address
}

resource "google_compute_url_map" "http_redirect" {
  name = "smart-construction-http-redirect"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "smart-construction-http-proxy"
  url_map = google_compute_url_map.http_redirect.id
}

resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  name                  = "smart-construction-http-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_target_http_proxy.http_proxy.id
  ip_address            = google_compute_global_address.lb_ip.address
}
