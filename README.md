# aws-private-subnet-access
### Acesso a EC2 e RDS em Subnets Privadas na AWS

## EC2 Instance Connect Endpoint:  
(NÃO necessita ter Nat Gateway)  

### Na AWS:  
> ### Criação do Security Groups: 
>
> *Entrar em EC2/Security Groups e colocar as opções abaixo:*
> #### Security Groups 01:  
> **Name:** SG-ConnectEndpoint  
> **Inbound:** Podemos deixar sem nada  
> **Outbound:** Port 22  
> **Destination:** SG-EC2instance  
> **Description:** Permite SSH indo para o SG-EC2instance
>
> #### Security Groups 02:
> **Name:** SG-EC2instance  
> **Inbound:** Port: 22  
> **Source:** SG-ConnectEndpoint  
> **Description:** Permite SSH vindo do SG-ConnectEndpoint  
> 
> **Outbound:** Type: All traffic  
> **Destination:** CIDR IPv4 da VPC  
> **Description:** Permite toda saida para o CIDR da VPC
>
### Criar uma instância EC2 com um par de chave.pem e anexar o security group criado acima: SG-EC2instance

*(Pode ser Amazon Linux ou Ubuntu)*  

> ### Criação do Endpoint:
>
> *Entrar em VPC/Endpoint e colocar as opções abaixo:*  
> **Name:** EC2-Instance-Connect-Endpoint  
> **Type:** EC2-Instance-Connect-Endpoint  
> **Network:** Escolher a VPC  
> **Security groups:** SG-ConnectEndpoint  
> **Subnet:** Escolher uma subnet privada (Servirá para acessar qualquer subnet)  

### No ambiente on-premisse: 
 
***Usar o terminal de sua preferência***  

**Instalar o AWS CLI:**
```ini
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**EC2 Instance Connect Endpoint:** Somente UMA única conexão, sem precisar da chave.pem  
*Obs.: Troque o "id-da-EC2" e "usuário" pelo seu*
```ini
aws ec2-instance-connect ssh --instance-id <id-da-EC2> --os-user <usuário> --connection-type eice
```

**Conexão única:** Somente UMA única conexão, usando open-tunnel  
*Obs.: Troque o "key-pair.pem", "usuário" e "id-da-EC2" pelo seu*

```ini
ssh -i <key-pair.pem> <usuário-da-ec2>@<id-da-ec2> -o ProxyCommand='aws ec2-instance-connect open-tunnel --instance-id %h'
```

**Conexão múltipla:** O terminal tem que ficar aberto:  
*Poderá ser usado para acessar EC2 ou RDS. Para EC2, usar outro terminal ou o MobaXterm por exemplo e para o RDS, seguir as configurações do PGAdmin abaixo ou outro software de sua preferência.*  

*Obs.: Troque o "id-da-EC2" pela sua*  

```ini
aws ec2-instance-connect open-tunnel --instance-id <id-da-EC2> --local-port 5555
```

> **Configurando o PGAdmin para acesso ao RDS:**  
> **Aba Connection:**  
> **Hostname/Address:** Endpoint-do-RDS  
> **Port:** 5432  
> **username:** Usuário do banco  
> **Aba SSH Tunnel:**  
> **Tunnel Host:** localhost  
> **Tunnel Port:** 5555  
> **Authentication:** Identity  
> **Identity File:** Caminho da chave.pem  

**Para acesso a banco de dados usando a EC2 como ponte:**  
*Obs.: Troque o "key-pair.pem", "usuário", "id-da-EC2" e "Endpoint-do-RDS" pelo seu*
```ini
ssh -i <key-pair.pem> <usuário-da-ec2>@<id-da-ec2> -NL 5432:Endpoint-do-RDS:5432 -o ProxyCommand='aws ec2-instance-connect open-tunnel --instance-id %h'
```
> **Configurando o PGAdmin para acesso ao RDS:**  
> **Aba Connection:**  
> **Hostname/Address:** localhost  
> **Port:** 5432  
> **username:** Usuário do banco  
> *Não precisa usar a aba SSH Tunnel*  

**RemoteSSH no VSCode:**  
**Caso queira acessar uma instância através do VSCode:**  
*Instale a extensão RemoteSSH no VSCode e depois crie o arquivo de configuração:*  
- Clique no canto direito em Open a Remote Windows, depois em Connect Host, por último em configure SSH Hosts e cole o comando abaixo:  

```ini
Host AWS-EC2
 HostName <id-da-ec2>
 User <usuário-da-ec2>
 IdentityFile <caminho-da-chave.pem>
 ProxyCommand aws ec2-instance-connect open-tunnel --instance-id <id-da-ec2> --region <sua-regiao>
```  
## Session Manager  
(Necessário ter Nat Gateway ou criar Endpoints AWS PrivateLink)

### Na AWS:  

**Criar uma Role:**

*Entrar em IAM/Roles e criar com as opções abaixo:*  
**Name:** EC2_SSM_Role  
**Trusted entity type:** AWS Service  
**Use Case:** EC2 Role for AWS Systems Manager  
*A policy já vem anexada*  
**Policy Name:** AmazonSSMManagedInstanceCore  

**Criar uma instância EC2 e anexar a IAM Role acima: EC2_SSM_Role**  

### No ambiente on-premisse:  

***Usar o terminal de sua preferência***  

**Instalar o AWS CLI:**
```ini
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
``` 
**Instalar o Plugin do Session Manager no Linux:**
```ini
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
sudo dpkg -i session-manager-plugin.deb
``` 
**Instalar o Plugin do Session Manager no Windows:**
```ini
https://s3.amazonaws.com/session-manager-downloads/plugin/latest/windows/SessionManagerPluginSetup.exe
``` 
**Para verificar se o plugin foi instalado, tanto para Linux, quanto para Windows:**
```ini
session-manager-plugin
```

**Para acessar a EC2 diretamente (Windows ou Linux):**  
*Obs.: Troque o "id-da-EC2" pela sua*
```ini
aws ssm start-session --target <id-da-EC2>  
```

**Usando PortForwardingSession (Windows ou Linux):** O terminal tem que ficar aberto:  
*Poderá ser usado para acessar EC2 ou RDS, porém usa tunel SSH para chegar ao RDS (duplo tunel). Para EC2, abrir outro terminal ou o MobaXterm, para o RDS, seguir as configurações do PGAdmin abaixo ou outro software de sua preferência.*  

*Troque o "id-da-EC2" e "5555"
```ini
aws ssm start-session \
    --target <id-da-EC2> \
    --document-name AWS-StartPortForwardingSession \
    --parameters '{"portNumber":["22"], "localPortNumber":["5555"]}'
```

> **Configurando o PGAdmin para acesso ao RDS:**  
> **Aba Connection:**  
> **Hostname/Address:** Endpoint-do-RDS  
> **Port:** 5432  
> **username:** Usuário do banco  
> **Aba SSH Tunnel:**  
> **Tunnel Host:** localhost  
> **Tunnel Port:** 5555  
> **Authentication:** Identity  
> **Identity File:** Caminho da chave.pem  

**Usando PortForwardingSessionToRemoteHost:** O terminal tem que ficar aberto:  
*Usa o EC2 somente como PONTE e NÃO utiliza SSH para se conectar ao RDS, faz um túnel direto.*  

*Troque o "id-da-EC2", "endpoint-do-banco" e "5555"*
```ini
aws ssm start-session \
    --target <id-da-EC2> \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters '{"host":["endpoint-do-banco"],"portNumber":["5432"], "localPortNumber":["5555"]}'
```

> **Configurando o PGAdmin para acesso ao RDS:**  
> **Aba Connection:**  
> **Hostname/Address:** localhost  
> **Port:** 5555  
> **username:** Usuário do banco  
> *Não precisa usar a aba SSH Tunnel* 