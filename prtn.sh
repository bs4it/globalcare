docker run -d \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/docker/volumes:/var/lib/docker/volumes \
  -v /:/host \
  -v portainer_agent_data:/data \
  --restart always \
  -e EDGE=1 \
  -e EDGE_ID=e16f5d1b-5b68-4997-a936-81c32f5482be \
  -e EDGE_KEY=aHR0cHM6Ly9wcnRuci5iczRpdC5jb20uYnI6NTQ5NDN8cHJ0bnIuYnM0aXQuY29tLmJyOjgwMDB8SU42RHBpSHduK0N3Y0dvcmlUMTZvVVRjODQrSFFGSVl1elZPZ1lraEhscz18ODk \
  -e EDGE_INSECURE_POLL=1 \
  --name portainer_edge_agent \
  portainer/agent:2.19.1
