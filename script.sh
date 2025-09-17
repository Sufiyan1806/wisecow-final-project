#!/bin/bash

# This script will install tools, clean, create, build, and deploy the wisecow application.

# --- PREPARATION: INSTALL KUBECTL and MINIKUBE ---
echo "--- Step 0: Checking for required tools ---"
# Check for and install kubectl if not found
if ! command -v kubectl &> /dev/null
then
    echo "kubectl not found. Installing..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
fi

# Check for and install minikube if not found
if ! command -v minikube &> /dev/null
then
    echo "minikube not found. Installing..."
    curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube /usr/local/bin/
fi
echo "--- Tools are ready. ---"


# 1. Create a brand new, clean project folder in your home directory
echo "--- Step 1: Creating clean project folder ---"
cd ~
rm -rf wisecow-final-project
mkdir wisecow-final-project
cd wisecow-final-project

# 2. Create the wisecow.sh script with the correct content
echo "--- Step 2: Creating wisecow.sh ---"
cat <<'EOF' > wisecow.sh
#!/bin/bash
set -e

# Ensure fortune binary path is included
export PATH=$PATH:/usr/games

SRVPORT=4499
for cmd in fortune cowsay nc; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: Required command '$cmd' is not installed." >&2
        exit 1
    fi
done
echo "Wisdom served on port $SRVPORT..."
while true; do
    QUOTE=$(/usr/games/fortune)
    RESPONSE=$(cowsay "$QUOTE")
    printf "HTTP/1.1 200 OK\n\n<pre>%s</pre>" "$RESPONSE" | nc -lk $SRVPORT
done
EOF

# 3. Create the Dockerfile with the correct content
echo "--- Step 3: Creating Dockerfile ---"
cat <<'EOF' > Dockerfile
FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive

# Enable universe repo and install dependencies
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository universe && \
    apt-get update && \
    apt-get install -y cowsay fortune-mod netcat-openbsd && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY wisecow.sh /app/wisecow.sh
RUN chmod +x /app/wisecow.sh
EXPOSE 4499
CMD ["bash", "-c", "/app/wisecow.sh"]
EOF

# 4. Create the deployment.yaml with the correct content
echo "--- Step 4: Creating deployment.yaml ---"
cat <<'EOF' > deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wisecow-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: wisecow
  template:
    metadata:
      labels:
        app: wisecow
    spec:
      containers:
      - name: wisecow-container
        image: wisecow:1.0
        imagePullPolicy: Never
        ports:
        - containerPort: 4499
EOF

# 5. Create the service.yaml with the correct content
echo "--- Step 5: Creating service.yaml ---"
cat <<'EOF' > service.yaml
apiVersion: v1
kind: Service
metadata:
  name: wisecow-service
spec:
  type: NodePort
  selector:
    app: wisecow
  ports:
    - protocol: TCP
      port: 80
      targetPort: 4499
      nodePort: 30080
EOF

# 6. Make the wisecow.sh script executable
chmod +x wisecow.sh

# 7. Start Minikube
echo "--- Step 7: Starting Minikube... ---"
minikube start

# 8. Connect terminal to Minikube's internal Docker
echo "--- Step 8: Connecting to Minikube's Docker environment... ---"
eval $(minikube -p minikube docker-env)

# 9. Build the image directly inside Minikube
echo "--- Step 9: Building the Docker image... ---"
docker build -t wisecow:1.0 .

# 10. Deploy the application to Kubernetes
echo "--- Step 10: Deploying to Kubernetes... ---"
kubectl apply -f deployment.yaml -f service.yaml

echo "--- Deployment complete! Checking status... ---"
kubectl get pods

