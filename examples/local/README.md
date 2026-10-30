# Local example

Applies circuit-openwebui to a throwaway Rocky Linux 10 container with systemd. You need Conn3x and Podman.

Open WebUI runs under Podman inside that container, so the host container is privileged, which is simplest with rootful Podman. On a Mac, use the Podman machine's root connection. On Linux, use `sudo podman`:

```sh
export CONTAINER_CONNECTION=podman-machine-default-root   # macOS
export PODMAN="sudo podman"                               # Linux
./up.sh
conn3x init
conn3x apply
conn3x plan
```

The first apply takes a few minutes, most of it pulling Open WebUI's image, which is about 1.6 GB compressed; give the Podman machine 10 GB of free disk. The second plan says `No changes.` The example's admin password is a default in `main.tf`, which you'd never keep on a real host.

Open WebUI listens on `127.0.0.1:8080` inside the container. To ask it something, use the `curl` in its own image:

```sh
ssh -p 2222 -i id_ed25519 -o UserKnownHostsFile=known_hosts root@127.0.0.1 \
  podman exec open-webui curl -s http://127.0.0.1:8080/health
```

The answer is `{"status":true}`. Sign in as the admin the same way:

```sh
ssh -p 2222 -i id_ed25519 -o UserKnownHostsFile=known_hosts root@127.0.0.1 \
  podman exec open-webui curl -s -H 'Content-Type: application/json' \
  -d '{"email":"admin@example.com","password":"correct-horse-battery"}' \
  http://127.0.0.1:8080/api/v1/auths/signin
```

There's no Ollama here. The example points Open WebUI's OpenAI connection at `127.0.0.1:9099`, where CI starts a small stand-in server that lists one model; see `.github/workflows/ci.yml`. Until something listens there, Open WebUI's model list is empty, which is fine for trying the sign-in and sign-up rules. To chat for real, add [circuit-ollama](https://github.com/conn3xorg/circuit-ollama) to `main.tf` with a small model, such as `qwen2.5:0.5b`.

`up.sh` listens on `127.0.0.1:2222`. Set `PORT` to use another port, and pass the same port to Conn3x with `-var port=PORT`. Set `CONTAINERFILE` to test another distro, such as one of the images in Conn3x's `test/images`, which CI uses.

`./down.sh` removes the container, its volumes, the key and the state.
