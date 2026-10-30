output "service" {
  description = "The systemd service that runs Open WebUI on each host."
  value       = "open-webui.service"
}

output "image" {
  description = "The Open WebUI image the hosts run."
  value       = local.image
}

output "volume" {
  description = "The Podman volume holding Open WebUI's data: the SQLite database, uploaded files and the vector store. Back it up."
  value       = "open-webui"
}

output "keys_file" {
  description = "File on each host holding the generated WEBUI_SECRET_KEY."
  value       = local.keys_file
}
