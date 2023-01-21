provider "docker" {}
provider "random" {}

resource "random_integer" "port" {
  min = 8000
  max = 8099
}

locals {
  host_lb_port = (var.k3d_host_lb_port != "" ? var.k3d_host_lb_port : random_integer.port.result)
}

resource "k3d_cluster" "clusters" {
  for_each = toset(var.k3d_cluster_name)
  
  name    = each.key
  servers = var.server_count
  agents  = var.agent_count

  image = "rancher/k3s:${var.k3s_version}"

  kube_api {
    host      = "${each.key}-cluster.127.0.0.1.nip.io"
    host_ip   = var.k3d_cluster_ip
    host_port = var.k3d_cluster_port
  }

  volume {
    source      = "${path.cwd}/manifests/traefik-config.yaml"
    destination = "/var/lib/rancher/k3s/server/manifests/traefik-config.yaml"
    node_filters = [
      "server:0",
      "agent:*",
    ]
  }

  volume {
    source      = "${path.cwd}/manifests/portainer.deployment.yaml"
    destination = "/var/lib/rancher/k3s/server/manifests/portainer.deployment.yaml"
    node_filters = [
      "server:0",
      "agent:*",
    ]
  }

  port {
    host_port      = local.host_lb_port
    container_port = var.k3d_cluster_lb_port
    node_filters = [
      "loadbalancer",
    ]
  }

  port {
    host_port      = var.k3d_host_mysql_port
    container_port = var.k3d_cluster_mysql_port
    node_filters = [
      "loadbalancer",
    ]
  }

  kubeconfig {
    update_default_kubeconfig = true
    switch_current_context    = true
  }
}

resource "time_sleep" "wait_60_seconds" {
  depends_on = [k3d_cluster.clusters]
  create_duration = "60s"
}

resource "null_resource" "patch_traefik" {
  triggers = {
    always_run = timestamp()
  }
  depends_on = [time_sleep.wait_60_seconds]
  for_each = toset(var.k3d_cluster_name)
  provisioner "local-exec" {
    command = <<EOT
      kubectl config set-cluster ${each.key}
      kubectl patch svc traefik -n kube-system -p '{"spec": {"ports": [{"name": "mysql", "port": 3306, "targetPort": 3306, "protocol": "TCP"}]}}'
    EOT
  }
}
