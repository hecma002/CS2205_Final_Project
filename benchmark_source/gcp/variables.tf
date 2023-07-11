variable "project" {
  default = "benchmark-int1405413550"
}

variable "credentials_file" {
  default = "credentials.json"
}

variable "region" {
  default = "asia-southeast1"
}

variable "zone" {
  default = "asia-southeast1-b"
}

variable "instances_type" {
  type = list(string)
  default = ["e2-standard-8","e2-standard-2",  "e2-standard-4","n2-standard-2", "n2-standard-8", "n2-standard-4","n1-custom-2-8192", "n1-custom-8-32768", "n1-custom-4-16384","c2-standard-8","c2-standard-4"]

}
