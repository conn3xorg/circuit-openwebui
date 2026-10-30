variable "port" {
  type    = number
  default = 2222
}

# Example password only. Pass your own with -var or TF_VAR_ on a real host.
variable "admin_password" {
  type      = string
  default   = "correct-horse-battery"
  ephemeral = true
  sensitive = true
}

module "openwebui" {
  source = "../.."

  hosts                = { box = "127.0.0.1" }
  ssh_port             = var.port
  ssh_private_key_file = "./id_ed25519"
  ssh_known_hosts_file = "./known_hosts"

  admin_email    = "admin@example.com"
  admin_password = var.admin_password

  # Nothing listens here unless you add Ollama or start a stand-in; see the
  # README. Open WebUI starts either way.
  openai_base_url = "http://127.0.0.1:9099/v1"
  openai_api_key  = "sk-example"
}
