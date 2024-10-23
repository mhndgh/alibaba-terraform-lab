provider "alicloud" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = var.region
}

resource "alicloud_vpc" "vpc" {
  vpc_name   = "lab"
  cidr_block = "10.0.0.0/8"
}

data "alicloud_zones" "avalible_zones" {
  available_resource_creation = "VSwitch"
}


resource "alicloud_vswitch" "public" {
  vswitch_name = "public"
  cidr_block   = "10.0.1.0/24"
  vpc_id       = alicloud_vpc.vpc.id
  zone_id      = data.alicloud_zones.avalible_zones.zones.0.id
}

resource "alicloud_security_group" "public_sg" {
  name        = "public"
  description = "public security group"
  vpc_id      = alicloud_vpc.vpc.id
}

resource "alicloud_security_group_rule" "allow_ssh" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = alicloud_security_group.public_sg.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_http" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "80/80"
  priority          = 1
  security_group_id = alicloud_security_group.public_sg.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_ecs_key_pair" "key" {
  key_pair_name = "key"
  key_file = "key.pem"
}

resource "alicloud_instance" "web" {
  availability_zone = data.alicloud_zones.avalible_zones.zones.0.id
  security_groups   = [alicloud_security_group.public_sg.id]

  # series III
  instance_type              = "ecs.g6.large"
  system_disk_category       = "cloud_essd"
  system_disk_size           = 40
  image_id                   = "ubuntu_24_04_x64_20G_alibase_20240812.vhd"
  instance_name              = "lab-nginx"
  vswitch_id                 = alicloud_vswitch.public.id
  internet_max_bandwidth_out = 100
  internet_charge_type       = "PayByTraffic"
  instance_charge_type       = "PostPaid"
  key_name                   = alicloud_ecs_key_pair.key.key_pair_name
  user_data                  = base64encode(file("nginx.sh"))
}

output "instance_ip_addr" {
  value = alicloud_instance.web.public_ip
}