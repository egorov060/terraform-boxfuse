terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = "y0_AgAAAABjv7fsAATuwQAAAADNd1PsLO8otNcKSu-8ypOLZddyTkPTeQs"
  cloud_id  = "b1g9q49j8o9p8fdicr7g"
  folder_id = "b1gphfspgsih2mk1gt8o"
  zone      = "ru-central1-a"
}

####


resource "yandex_iam_service_account" "sa" {
  folder_id = "b1gphfspgsih2mk1gt8o"
  name      = "tf-test-sa"
}

// Grant permissions
resource "yandex_resourcemanager_folder_iam_member" "sa-editor" {
  folder_id = "b1gphfspgsih2mk1gt8o"
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

// Create Static Access Keys
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "static access key for object storage"
}

// Use keys to create bucket
resource "yandex_storage_bucket" "test" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket = "tf-test-bucket-egorov060"
}


######
#####

resource "yandex_compute_instance" "vm-1" {
  name = "build"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "data.yandex_compute_image.ubuntu-20-04.id"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    user-data = "${file("/home/vm1/terraform-boxfuse/meta_build.txt")}"
  }

#################

provisioner "remote-exec" {
    inline = [
      "sudo apt update",
	  "sudo apt install maven openjdk-8-jdk git awscli -y",
      "git clone https://github.com/boxfuse/boxfuse-sample-java-war-hello.git",
      "mvn package -f /home/vm1-1/boxfuse-sample-java-war-hello",
      "aws --profile default configure set aws_access_key_id ${yandex_iam_service_account_static_access_key.sa-static-key.access_key}",
      "aws --profile default configure set aws_secret_access_key ${yandex_iam_service_account_static_access_key.sa-static-key.secret_key}",
      "aws --endpoint-url=https://storage.yandexcloud.net/ s3 cp  /home/vm1-1/boxfuse-sample-java-war-hello/target/hello-1.0.war s3://tf-test-bucket-egorov060/"

    ]
	connection {
      type = "ssh"
      user = "vm1-1"
      private_key = file("~/.ssh/id_rsa")
      host = "${yandex_compute_instance.vm-1.network_interface.0.nat_ip_address}"
    }
  }

##############



}

resource "yandex_compute_instance" "vm-2" {
  name = "prod"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "data.yandex_compute_image.ubuntu-20-04.id"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    user-data = "${file("/home/vm1/terraform-boxfuse/meta_prod.txt")}"
  }
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["10.128.0.0/24"]
}


output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.ip_address
}

output "internal_ip_address_vm_2" {
  value = yandex_compute_instance.vm-2.network_interface.0.ip_address
}


output "external_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}

output "external_ip_address_vm_2" {
  value = yandex_compute_instance.vm-2.network_interface.0.nat_ip_address
}

