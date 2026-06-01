module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.37.2"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true
  enable_irsa                              = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = merge(
    {
      cpu = {
        instance_types = var.cpu_instance_types
        desired_size   = var.cpu_desired
        min_size       = var.cpu_min
        max_size       = var.cpu_max
      }
    },
    var.gpu ? {
      gpu = {
        ami_type       = "AL2_x86_64_GPU"
        instance_types = var.gpu_instance_types
        desired_size   = 1
        min_size       = 0
        max_size       = 1
        taints = {
          gpu = {
            key    = "nvidia.com/gpu"
            value  = "true"
            effect = "NO_SCHEDULE"
          }
        }
      }
    } : {}
  )
}
