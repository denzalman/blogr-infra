#Terraform, Ansible and k8s infrastructure deployment

K8s: 1 master (t3.small) + 3 minions with app podes
Consul: 3 nodes cluster
Mysql: 1 master 1 slave with Percona
ELK: 3 instances (t3.medium)
Grafana: 1 instance
Prometheus: 1 instance
Haproxy: 1 instance for GRafana and Kibana
Jenkins: 1 instance

##### Invironment deployment instructions:
Check your default aws credentials in file ```~/.aws/credentials```
or run command ```aws configure```

```bash
git clone https://github.com/denzalman/blogr-infra.git
cd blogr-infra/terraform
terraform init
terraform plan
terraform apply --auto-approve
```

Make :coffee: or take :beer: with :pizza: and wait for output in terminal windows...

You will receive IP adresses of Blogr App, Consul, Grafana and Kibana web pages after 5-10 min.
1. Open any IP of consul web intrface from the list on port 8500 and wait until all is green.
2. After you can open Grafana IP on port 3000 and Kibana IP on prot 5601 
3. Grafana credentials: admin/password

#### Project Plan:

- [x] Create VPC and temporary network
- [x] Make simple blog app with python and flask (design needs to be improved later)
- [x] Build a docker image of Blogr app. (another project github.com/denzalman/blogr.git)
- [x] Make MySQL Instance with proper DB settings (--- still needs to be fixed)
- [x] Make Consul instances for service discovery
- [x] Make k8s cluster with 1 master and 2 minions
- [x] Setup Blogr app deployment with k8s
- [x] Make Jenkins instance provisioning
- [x] Connect EFS to Jenkins inst for jenkins_home 
- [x] Setup Jenkins pipline to work with github blogr app changes
- [ ] Build the monitoring environment (prometheus/grafana)
- [ ] Prometheus collector will find the application in consul and monitor it.
- [ ] Make and add to provisioning Grafana dashboard
- [ ] Build the monitoring environment (ELK)
- [ ] Add FileBeat agent to app instance deployment process
- [ ] Add relevant ELK settings and config files
- [ ] Change test security group to relevant ones. (at the end)
- [ ] Check and change dependencies of instances
- [ ] Add MySQL replica instance
- [ ] Add EFS storage for MySQL database
- [ ] Add HAproxy instances for some web interfaces
