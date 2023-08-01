# stubby-dnsmasq-docker

This is a **quick and dirty** implementation of a containerized dns/dhcp server to move away from pihole on bare metal and use nextdns instead; also to allow me to have redundant servers easily set.

Stubby acts as a local DNS stub resolver using DoT to connect to nextdns and Dnsmasq is used as a dhcp server & dns cache. Both packages are compiled from source using the latest version at the time of publishing.

I depend on the network of the host machine to handle exposing ports from the container, this is because I don't expect to have port conflicts and also because I can rely on the firewall settings of the host to secure my container's networking.

**Some config files are set just as placeholders**, so trying to run the container without proper replacements is not expected to work. The files that might be changed are:

- `stubby.yml`
- and the ones located at `etc-dnsmasq.d`

Since this is for personal use and more importantly, because I'm lazy, a proper image is not expected to be supplied anytime soon.

## Usage

```bash
docker compose up -d
```
