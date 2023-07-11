variable "server_ami" {
    type = string
    default = "ami-0adfdaea54d40922b"
    # Reference about ami ID on https://wiki.centos.org/Cloud/AWS
}



variable "instances_type" {
  type = list(string)
  default = ["t2.large","t2.xlarge",  "t3.large", "t3.xlarge", "t3a.large", "t3a.xlarge", "m4.large","m4.xlarge", "m5.large","m5.xlarge","m5a.large","m5a.xlarge", "c4.large","c4.xlarge","c5.large","c5.xlarge","c5a.large","c5a.xlarge"]
#   default = ["t3.large"]

}

variable "region" {
    default = "ap-southeast-1"
}

variable "profile" {
    default = "benchmark-user"
}
