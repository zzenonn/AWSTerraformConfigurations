provider "aws" {
  region  = var.region
  profile = var.profile
  default_tags {
    tags = {
      auto-delete = "no",
      auto-stop = "no"
    }
  }
}

module "network" {
  source       = "../../modules/infrastructure/network"
  project_name = var.project_name
  environment  = var.environment
  db_port      = var.db_port
  networks     = var.networks
}

module "instances" {
  source                = "../../modules/infrastructure/instances"
  project_name          = module.network.project_name
  environment           = module.network.environment
  db_port               = module.network.db_port
  vpc                   = module.network.vpc
  private_subnets       = module.network.private_subnets
  public_subnets        = module.network.public_subnets
  db_subnets            = module.network.db_subnets
  db_subnet_group       = module.network.db_subnet_group
  bastion_instance_type = "c5.4xlarge"
  bastion_user_data     = <<-EOF
    #cloud-config
    packages:
      - git
      - autoconf
      - automake
      - make
      - gcc-c++
      - pcre-devel
      - zlib-devel
      - libmemcached-devel
      - libevent-devel
      - openssl-devel
      - wget
      - tar
    
    runcmd:
      - git clone https://github.com/RedisLabs/memtier_benchmark.git /tmp/memtier_benchmark
      - cd /tmp/memtier_benchmark && autoreconf -ivf && ./configure && make && make install
      - cd /tmp && wget http://download.redis.io/redis-stable.tar.gz
      - tar xzf redis-stable.tar.gz
      - cd redis-stable && make && make install
    EOF
}