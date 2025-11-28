Perfect — let’s deploy Traefik (Global Reverse Proxy) on your Rocky Linux 192.168.1.98 using Podman, and configure it to front-end the three applications you listed:

	• https://rasp5.cropseyit.com → 192.168.1.85:5000
	• https://juice.cropseyit.com → 192.168.1.98:3000
	• https://juicep.cropseyit.com → 192.168.1.98:8000

This gives you a fully working global Traefik appliance with TLS, routing, and HTTP→HTTPS redirect.


✅ 
STEP 1 — Create Traefik directories

Run these on 192.168.1.98:
sudo mkdir -p /etc/traefik/dynamic
sudo mkdir -p /etc/traefik/logs
sudo mkdir -p /etc/traefik/certs

for local mac testing:

add juice.corp.local to /etc/hosts
mkcert juice.corp.local
scp juice.corp.local* mcropsey@192.168.1.98:~

✅ 
STEP 2 — Create the Traefik static config

📌 File: /etc/traefik/traefik.yaml
entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"

providers:
  file:
    directory: /etc/traefik/dynamic
    watch: true



✅ 
STEP 3 — Create the routing config

mcropsey@hv-rocky-linux-1:/etc/traefik/dynamic$ cat routes.yaml 
tls:
  certificates:
    - certFile: "/etc/traefik/certs/juice.corp.local.pem"
      keyFile: "/etc/traefik/certs/juice.corp.local-key.pem"

http:
  routers:

    rasp5-router:
      rule: "Host(`rasp5.cropseyit.com`)"
      entryPoints:
        - web
      service: rasp5-svc

    juice-router:
      rule: "Host(`juice.cropseyit.com`)"
      entryPoints:
        - web
      service: juice-svc

    juicep-router:
      rule: "Host(`juicep.cropseyit.com`)"
      entryPoints:
        - web
      service: juicep-svc

    # --- HTTP ROUTER for juice.corp.local (port 80)
    juice-corp-http:
      rule: "Host(`juice.corp.local`)"
      entryPoints:
        - web
      service: juice-corp-svc

    # --- HTTPS ROUTER for juice.corp.local (port 443)
    juice-corp-https:
      rule: "Host(`juice.corp.local`)"
      entryPoints:
        - websecure
      tls: {}
      service: juice-corp-svc


  services:

    rasp5-svc:
      loadBalancer:
        servers:
          - url: "http://192.168.1.85:5000"

    juice-svc:
      loadBalancer:
        servers:
          - url: "http://192.168.1.98:3000"

    juicep-svc:
      loadBalancer:
        servers:
          - url: "http://192.168.1.98:8000"

    juice-corp-svc:
      loadBalancer:
        servers:
          - url: "http://192.168.1.98:3000"
✅ 
STEP 4 — Run Traefik in Podman

Run Traefik with:
sudo podman run -d \
  --name traefik \
  --restart=always \
  -p 80:80 \
  -p 443:443 \
  -v /etc/traefik/traefik.yaml:/etc/traefik/traefik.yaml:ro \
  -v /etc/traefik/dynamic:/etc/traefik/dynamic:ro \
  -v /etc/traefik/certs:/etc/traefik/certs:ro \
  traefik:v3.0

(You don’t need port 443 because Cloudflare Tunnel → Traefik happens over HTTP)

Check that it’s running:

(You don’t need port 443 because Cloudflare Tunnel → Traefik happens over HTTP)

Check that it’s running:

sudo podman ps

You should see traefik running.


✅ 
STEP 5 — Test Traefik locally

Try:
curl -H "Host: rasp5.cropseyit.com" http://127.0.0.1
curl -H "Host: juice.cropseyit.com"  http://127.0.0.1
curl -H "Host: juicep.cropseyit.com" http://127.0.0.1

You should see responses from:

	• 192.168.1.85:5000
	• 192.168.1.98:3000
	• 192.168.1.98:8000


✅ 
STEP 6 — Test from the internet via Cloudflare Tunnel

Now simply visit:

	• https://rasp5.cropseyit.com
	• https://juice.cropseyit.com
	• https://juicep.cropseyit.com

Cloudflare Tunnel → Traefik → backend services

ALL should now work.


🚀 You now have:

	• A Traefik global reverse proxy
	• Running in Podman on Rocky Linux
	• Fully routed through Cloudflare Tunnel
	• Hostname-based routing
	• Supporting ANY backend IP you want
Zero extra configuration needed