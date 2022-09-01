variable "token" {
  description = "Yandex Cloud security OAuth token"
  default     = "nope"
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID where resources will be created"
  default     = "enter your folder id"
}

variable "cloud_id" {
  description = "Yandex Cloud ID where resources will be created"
  default     = "there is cloud id"
}

variable "private_key_path" {
  description = "Path to ssh private key, which would be used to access workers"
  default     = "~/.ssh/id_rsa"
}

variable "public_key_path" {
  description = "Path to ssh public key"
  default     = "~/.ssh/id_rsa.pub"
}

variable "user" {
  type = string
  default = "vm1-1"
}

variable "password" {
  type = string
  default  = "in password"
}