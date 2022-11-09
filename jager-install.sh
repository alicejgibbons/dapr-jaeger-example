# Jaegar Tracing Installation instructions

# Install Dapr
helm repo add dapr https://dapr.github.io/helm-charts/
helm repo update
helm upgrade --install dapr dapr/dapr \
--version=1.9 \
--namespace dapr-system \
--create-namespace \
--wait


# Install Cert manager (a pre-requisite), docs: https://cert-manager.io/v1.6-docs/installation/kubectl/
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.6.3/cert-manager.yaml

# Install the Jager operator
kubectl create namespace observability
kubectl create -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.39.0/jaeger-operator.yaml -n observability # <2>
kubectl get deployment jaeger-operator -n observability 

# Apply operator config (dev/test)in default/default1 ns
kubectl apply -f deploy/jaeger-operator.yaml 
kubectl get jaeger

# Apply Dapr components, jaeger configuration and sample app
kubectl apply -f deploy/components
kubectl apply -f deploy 

# Get service IP and generate some traces
export REACT_FORM=$(kubectl get service/react-form -o jsonpath='{.status.loadBalancer.ingress[0].ip}') 
curl -s http://$REACT_FORM:80/publish -H Content-Type:application/json --data @message_a.json
curl -s http://$REACT_FORM:80/publish -H Content-Type:application/json --data @message_b.json
curl -s http://$REACT_FORM:80/publish -H Content-Type:application/json --data @message_c.json

# View traces in Jaeger dashboard
kubectl port-forward svc/jaeger-query 16686  

# Check the daprd logs to see the tracing config being loaded
kubectl logs csharp-subscriber-96ff9cd74-hmwnp -c daprd | grep config