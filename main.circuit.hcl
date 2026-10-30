locals {
  image     = "ghcr.io/open-webui/open-webui:${var.openwebui_version}@${var.image_digest}"
  keys_file = "/etc/open-webui/keys.env"

  # A connection's model_ids is Open WebUI's own allow-list. Ollama's list
  # filters what Ollama reports; an OpenAI-compatible connection lists
  # exactly these IDs without asking the server.
  ollama_configs = length(var.ollama_models) > 0 ? { OLLAMA_API_CONFIGS = jsonencode({ "0" = { model_ids = var.ollama_models } }) } : {}
  openai_configs = length(var.openai_models) > 0 ? { OPENAI_API_CONFIGS = jsonencode({ "0" = { model_ids = var.openai_models } }) } : {}

  # Without a URL, a connection is turned off rather than left on Open
  # WebUI's defaults, which for OpenAI means api.openai.com.
  environment = merge(
    {
      HOST = var.listen_address
      PORT = tostring(var.port)

      ENABLE_SIGNUP               = tostring(var.enable_signup)
      DEFAULT_USER_ROLE           = var.default_user_role
      BYPASS_MODEL_ACCESS_CONTROL = tostring(var.share_models_with_all_users)
      ENABLE_COMMUNITY_SHARING    = "false"
      ENABLE_PERSISTENT_CONFIG    = tostring(var.persistent_config)

      # The image already sets the first three; they're here so the unit
      # says so, whatever a later image does.
      ANONYMIZED_TELEMETRY        = "false"
      DO_NOT_TRACK                = "true"
      SCARF_NO_ANALYTICS          = "true"
      ENABLE_VERSION_UPDATE_CHECK = "false"
      OFFLINE_MODE                = tostring(var.offline_mode)

      ENABLE_OLLAMA_API = tostring(var.ollama_base_url != null)
      ENABLE_OPENAI_API = tostring(var.openai_base_url != null)
    },
    var.ollama_base_url != null ? { OLLAMA_BASE_URL = var.ollama_base_url } : {},
    var.openai_base_url != null ? { OPENAI_API_BASE_URL = var.openai_base_url } : {},
    var.admin_email != null ? { WEBUI_ADMIN_EMAIL = var.admin_email, WEBUI_ADMIN_NAME = var.admin_name } : {},
    local.ollama_configs,
    local.openai_configs,
  )
}

# WEBUI_SECRET_KEY signs every session token. The first apply makes it on
# the host, so it's in neither the plan nor state, and creates keeps it from
# changing, which would sign everyone out.
circuit "keys" {
  hosts = var.hosts

  ssh {
    user             = var.ssh_user
    port             = var.ssh_port
    private_key_file = var.ssh_private_key_file
    known_hosts_file = var.ssh_known_hosts_file
    become           = var.ssh_become
  }

  step "dir" {
    directory {
      path  = "/etc/open-webui"
      owner = "root"
      group = "root"
      mode  = "0700"
    }
  }

  # 32 random bytes in hex: no characters an env file could misread.
  step "generate" {
    command {
      command = "umask 077 && printf 'WEBUI_SECRET_KEY=%s\\n' \"$(head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \\n')\" > ${local.keys_file}.new && mv ${local.keys_file}.new ${local.keys_file}"
      creates = local.keys_file
    }
  }
}

# Open WebUI runs from its official image as a Quadlet unit, on the host's
# network so it reaches an Ollama, LiteLLM or PostgreSQL that listens only on
# localhost. Its data lives in a named volume, which Podman fills from the
# image on first use; that's how the embedding model baked into the image
# ends up where OFFLINE_MODE looks for it.
module "podman" {
  source = "github.com/conn3xorg/circuit-podman?ref=v0.1.0"

  depends_on = [conn3x_command.keys__generate]

  hosts                = var.hosts
  ssh_user             = var.ssh_user
  ssh_port             = var.ssh_port
  ssh_private_key_file = var.ssh_private_key_file
  ssh_known_hosts_file = var.ssh_known_hosts_file
  ssh_become           = var.ssh_become

  containers = {
    open-webui = {
      image       = local.image
      volumes     = ["open-webui:/app/backend/data"]
      environment = local.environment
      extra       = ["Network=host", "EnvironmentFile=${local.keys_file}"]
    }
  }
  secrets = {
    open-webui = merge(
      var.environment,
      var.admin_password != null ? { WEBUI_ADMIN_PASSWORD = var.admin_password } : {},
      var.openai_api_key != null ? { OPENAI_API_KEY = var.openai_api_key } : {},
      var.database_url != null ? { DATABASE_URL = var.database_url } : {},
    )
  }
}

circuit "openwebui" {
  hosts = var.hosts

  ssh {
    user             = var.ssh_user
    port             = var.ssh_port
    private_key_file = var.ssh_private_key_file
    known_hosts_file = var.ssh_known_hosts_file
    become           = var.ssh_become
  }

  # The first start pulls a large image and runs the database migrations
  # before Open WebUI opens its port.
  step "ready" {
    depends_on = [module.podman]
    wait_for {
      port    = var.port
      timeout = "15m"
    }
  }
}
