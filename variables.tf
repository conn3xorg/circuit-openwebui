variable "hosts" {
  type        = any
  description = "Hosts to configure: a map of names to addresses, or to host objects with an address and optional host_key, user, port, private_key_file or jump_hosts."
}

variable "ssh_user" {
  type        = string
  default     = "root"
  description = "User to log in as."
}

variable "ssh_port" {
  type        = number
  default     = 22
  description = "SSH port."
}

variable "ssh_private_key_file" {
  type        = string
  default     = null
  description = "Path to a private key. When null, Conn3x uses the SSH agent."
}

variable "ssh_known_hosts_file" {
  type        = string
  default     = null
  description = "known_hosts file to check host keys against. When null, ~/.ssh/known_hosts."
}

variable "ssh_become" {
  type        = bool
  default     = false
  description = "Run commands as root through sudo."
}

variable "openwebui_version" {
  type        = string
  default     = "v0.12.5"
  description = "Tag of the ghcr.io/open-webui/open-webui image, such as \"v0.12.5\". Change image_digest with it."

  validation {
    condition     = can(regex("^[A-Za-z0-9_][A-Za-z0-9_.-]*$", var.openwebui_version))
    error_message = "openwebui_version must be an image tag, such as \"v0.12.5\"."
  }
}

variable "image_digest" {
  type        = string
  default     = "sha256:03443b8de6b617da9d900edd09b4bf1cb0ddbfdcba6afb42c548336a0b821ded"
  description = "Digest of the image for openwebui_version, such as \"sha256:0344...\". Podman pulls by the digest, so a tag that moves upstream can't change what runs."

  validation {
    condition     = can(regex("^sha256:[a-f0-9]{64}$", var.image_digest))
    error_message = "image_digest must be a sha256 digest, such as \"sha256:\" followed by 64 hex digits."
  }
}

variable "listen_address" {
  type        = string
  default     = "127.0.0.1"
  description = "Address Open WebUI listens on. The default keeps it on the host for a reverse proxy in front; \"0.0.0.0\" listens on every address."

  validation {
    condition     = can(cidrhost("${var.listen_address}/${strcontains(var.listen_address, ":") ? 128 : 32}", 0))
    error_message = "listen_address must be an IPv4 or IPv6 address, such as \"127.0.0.1\"."
  }
}

variable "port" {
  type        = number
  default     = 8080
  description = "Port Open WebUI listens on."

  validation {
    condition     = var.port >= 1 && var.port <= 65535 && floor(var.port) == var.port
    error_message = "port must be a whole number from 1 to 65535."
  }
}

variable "admin_email" {
  type        = string
  default     = null
  description = "Email of the first admin account, which Open WebUI creates at startup when it has no users yet. Set it with admin_password."

  validation {
    condition     = var.admin_email == null || can(regex("^[^\\s@]+@[^\\s@]+$", var.admin_email))
    error_message = "admin_email must be an email address, such as \"you@example.com\"."
  }
}

variable "admin_password" {
  type        = string
  default     = null
  ephemeral   = true
  sensitive   = true
  description = "Password of the first admin account. It reaches the host in a root-only file and never the plan or state."

  validation {
    condition     = (var.admin_password == null) == (var.admin_email == null)
    error_message = "Set admin_email and admin_password together, or neither."
  }

  validation {
    condition     = var.admin_password == null || (length(coalesce(var.admin_password, "x")) >= 8 && !strcontains(coalesce(var.admin_password, ""), "\n"))
    error_message = "admin_password must be at least 8 characters on one line."
  }
}

variable "admin_name" {
  type        = string
  default     = "Admin"
  description = "Display name of the first admin account."
}

variable "enable_signup" {
  type        = bool
  default     = false
  description = "Let people create their own accounts from the sign-in page. New accounts get default_user_role."
}

variable "default_user_role" {
  type        = string
  default     = "pending"
  description = "Role of an account someone creates for themselves: \"pending\" waits for an admin to approve it, \"user\" can chat straight away."

  validation {
    condition     = contains(["pending", "user"], var.default_user_role)
    error_message = "default_user_role must be \"pending\" or \"user\"."
  }
}

variable "share_models_with_all_users" {
  type        = bool
  default     = false
  description = "Show every model to every user. When false, a user sees only the models an admin has given them, or their group, access to."
}

variable "ollama_base_url" {
  type        = string
  default     = "http://127.0.0.1:11434"
  description = "Address of the Ollama server, such as circuit-ollama's default \"http://127.0.0.1:11434\". When null, Open WebUI's Ollama connection is turned off."

  validation {
    condition     = var.ollama_base_url == null || can(regex("^https?://[^\\s/]+(/[^\\s]*)?$", var.ollama_base_url))
    error_message = "ollama_base_url must be an http or https URL, such as \"http://127.0.0.1:11434\"."
  }
}

variable "ollama_models" {
  type        = list(string)
  default     = []
  nullable    = false
  description = "Ollama models Open WebUI offers, by full name and tag, such as [\"qwen2.5:0.5b\"]. When empty, every model Ollama has."
}

variable "openai_base_url" {
  type        = string
  default     = null
  description = "Address of an OpenAI-compatible API, such as a LiteLLM gateway at \"http://127.0.0.1:4000/v1\". When null, the OpenAI connection is turned off."

  validation {
    condition     = var.openai_base_url == null || can(regex("^https?://[^\\s/]+(/[^\\s]*)?$", var.openai_base_url))
    error_message = "openai_base_url must be an http or https URL, such as \"http://127.0.0.1:4000/v1\"."
  }
}

variable "openai_api_key" {
  type        = string
  default     = null
  ephemeral   = true
  sensitive   = true
  description = "API key for openai_base_url. It reaches the host in a root-only file and never the plan or state."

  validation {
    condition     = var.openai_api_key == null || !strcontains(coalesce(var.openai_api_key, ""), "\n")
    error_message = "openai_api_key must be on one line."
  }
}

variable "openai_models" {
  type        = list(string)
  default     = []
  nullable    = false
  description = "Model IDs Open WebUI offers from openai_base_url, such as [\"gpt-4o-mini\"]. Open WebUI lists exactly these without asking the server. When empty, whatever the server lists."
}

variable "database_url" {
  type        = string
  default     = null
  ephemeral   = true
  sensitive   = true
  description = "PostgreSQL connection URL, such as \"postgresql://openwebui:PASSWORD@127.0.0.1:5432/openwebui\". When null, Open WebUI uses SQLite in its volume. It reaches the host in a root-only file and never the plan or state."

  validation {
    condition     = var.database_url == null || (can(regex("^postgres(ql)?://", coalesce(var.database_url, "x"))) && !strcontains(coalesce(var.database_url, ""), "\n"))
    error_message = "database_url must be a postgres:// or postgresql:// URL on one line."
  }
}

variable "persistent_config" {
  type        = bool
  default     = false
  description = "Let settings changed in the admin panel outlive a restart. When false, every start takes them from this circuit again."
}

variable "offline_mode" {
  type        = bool
  default     = true
  description = "Set Open WebUI's OFFLINE_MODE: no model downloads from Hugging Face, no version checks and no pip installs for tools. The image already holds the default embedding and speech models."
}

variable "environment" {
  type        = map(string)
  default     = {}
  ephemeral   = true
  sensitive   = true
  nullable    = false
  description = "More of Open WebUI's environment variables, such as { WEBUI_URL = \"https://chat.example.com\", ENABLE_ADMIN_CHAT_ACCESS = \"false\" }. They go in the same root-only file as the passwords and never reach the plan or state."

  validation {
    condition     = alltrue([for k, v in var.environment : can(regex("^[A-Za-z_][A-Za-z0-9_]*$", k)) && !strcontains(v, "\n")])
    error_message = "environment maps variable names, such as WEBUI_URL, to values on one line."
  }

  validation {
    condition     = length(setintersection(keys(var.environment), ["HOST", "PORT", "WEBUI_SECRET_KEY", "WEBUI_ADMIN_EMAIL", "WEBUI_ADMIN_PASSWORD", "WEBUI_ADMIN_NAME", "ENABLE_SIGNUP", "DEFAULT_USER_ROLE", "BYPASS_MODEL_ACCESS_CONTROL", "ENABLE_PERSISTENT_CONFIG", "OFFLINE_MODE", "OLLAMA_BASE_URL", "OLLAMA_API_CONFIGS", "ENABLE_OLLAMA_API", "OPENAI_API_BASE_URL", "OPENAI_API_KEY", "OPENAI_API_CONFIGS", "ENABLE_OPENAI_API", "DATABASE_URL", "ENABLE_COMMUNITY_SHARING", "ANONYMIZED_TELEMETRY", "DO_NOT_TRACK", "SCARF_NO_ANALYTICS", "ENABLE_VERSION_UPDATE_CHECK"])) == 0
    error_message = "Set these with their own inputs: HOST, PORT, the WEBUI_ADMIN_ variables, ENABLE_SIGNUP, DEFAULT_USER_ROLE, BYPASS_MODEL_ACCESS_CONTROL, ENABLE_PERSISTENT_CONFIG, OFFLINE_MODE, the Ollama and OpenAI connection, and DATABASE_URL. WEBUI_SECRET_KEY is generated on the host. Community sharing, telemetry and the version check stay off."
  }
}
