provider "google" {
  project     = "bootlabs-internal"
  region      = "us-central1"
}

resource "google_compute_instance" "tfansible" {
  name         = "terraform-ansible"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"

  tags = ["web"]

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  // Local SSD disk
  # scratch_disk {}

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    name     = "Terraform and Ansible Demo"
    ssh-keys = "${var.ssh_user}:${file("${var.public_key_path}")}"
  }

  metadata_startup_script = "echo hi > /test.txt"

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

  #############################################################################
  # This is the 'local exec' method.
  # Ansible runs from the same host you run Terraform from
  #############################################################################

  provisioner "remote-exec" {
    inline = ["echo 'Hello World'"]

    connection {
      type        = "ssh"
      host        = google_compute_instance.tfansible.network_interface.0.access_config.0.nat_ip
      user        = var.ssh_user
      private_key = file("${var.private_key_path}")
    }
  }

  # provisioner "local-exec" {
  #   command = "sleep 60; ansible-playbook -u '${var.ssh_user}' -i '${google_compute_instance.tfansible.network_interface.0.access_config.0.nat_ip},' --private-key ${var.private_key_path} ./ansible/httpd.yml"
  # }
}

#############################################################################
  # This is the 'remote exec' method.
  # Ansible runs on the target host.
  #############################################################################

  # provisioner "remote-exec" {
  #   inline = [
  #     "mkdir /home/${var.ssh_user}/files",
  #     "mkdir /home/${var.ssh_user}/ansible",
  #   ]
  #
  #   connection {
  #     type        = "ssh"
  #     user        = var.ssh_user
  #     host        = google_compute_instance.tfansible.network_interface.0.access_config.0.nat_ip
  #     private_key = file("${var.private_key_path}")
  #   }
  # }
  #
  # provisioner "file" {
  #   source      = "./ansible/httpd.yml"
  #   destination = "/home/${var.ssh_user}/ansible/httpd.yml"
  #
  #   connection {
  #     type        = "ssh"
  #     user        = var.ssh_user
  #     host        = google_compute_instance.tfansible.network_interface.0.access_config.0.nat_ip
  #     private_key = file("${var.private_key_path}")
  #   }
  # }
  #
  # provisioner "file" {
  #   source      = "./files/index.j2"
  #   destination = "/home/${var.ssh_user}/files/index.j2"
  #
  #   connection {
  #     type        = "ssh"
  #     user        = var.ssh_user
  #     host        = google_compute_instance.tfansible.network_interface.0.access_config.0.nat_ip
  #     private_key = file("${var.private_key_path}")
  #   }
  # }
  #
  # provisioner "remote-exec" {
  #   inline = [
  #     "sudo yum -y install ansible",
  #     "cd ansible; ansible-playbook -c local -i \"localhost,\" httpd.yml",
  #   ]
  #
  #   connection {
  #     type        = "ssh"
  #     user        = var.ssh_user
  #     host        = google_compute_instance.tfansible.network_interface.0.access_config.0.nat_ip
  #     private_key = file("${var.private_key_path}")
  #   }
  # }
  # Don't comment out this next line.
# }

resource "null_resource" "ansible_trigger" {

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = <<-EOT
      sleep 60;
      export ANSIBLE_HOST_KEY_CHECKING=False;
        ansible-playbook -u ${var.ssh_user} -i ${google_compute_instance.tfansible.network_interface.0.access_config.0.nat_ip}, --private-key ${var.private_key_path} ./ansible/httpd.yml
    EOT
  }

  depends_on = [google_compute_instance.tfansible]
}

resource "google_compute_firewall" "default" {
  name    = "web-firewall"
  network = "default"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
}
