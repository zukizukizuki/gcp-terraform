module "gce_start_stop" {
  source               = "./module/function"
  project              = "my first project"
  is_secure            = false
}