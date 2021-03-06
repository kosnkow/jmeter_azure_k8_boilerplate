#!/usr/bin/env bash
#Create multiple Jmeter namespaces on an existing kuberntes cluster
#Started On January 23, 2018
#On azure master node is not accessible directly as per https://stackoverflow.com/questions/48143225/master-node-on-aks-cluster

setVARS() {
  working_dir=$(pwd)/../config/deployments
  tmp_dir=$(pwd)/../tmp
  tenant=$1
}

checkKubectl(){
  echo
  echo "Checking if kubectl is present"
  if ! hash kubectl 2>/dev/null; then
    echo "'kubectl' was not found in PATH"
    echo "Kindly ensure that you can acces an existing kubernetes cluster via kubectl"
    exit
  fi
  kubectl version --short
}
setKubernetesNamespace(){
  echo
  echo "Current list of namespaces on the kubernetes cluster:"
  kubectl get namespaces | grep -v NAME | awk '{print $1}'
  echo
  if [ -n "$tenant" ]; then
    echo  "Using namespace: $tenant"
  else
    echo "Enter the name of the new tenant unique name, this will be used to create the namespace"
    read tenant
    echo
  fi
  #Check If namespace exists
  kubectl get namespace $tenant >/dev/null 2>&1

  if [ $? -eq 0 ]; then
    echo "Namespace $tenant already exists, please select a unique name"
    echo "Current list of namespaces on the kubernetes cluster"
    sleep 2

    kubectl get namespaces | grep -v NAME | awk '{print $1}'
    exit 1
  fi
  echo
}
createNamespace(){
  echo
  echo "Creating Namespace: $tenant"
  kubectl create namespace $tenant
  echo "Namespace $tenant has been created"
  echo
}
createSlaves(){
  echo "Creating Jmeter slave nodes"
  nodes=$(kubectl get no | egrep -v "master|NAME" | wc -l)
  echo
  echo "Number of worker nodes on this cluster is" $nodes
  echo
  #echo "Creating $nodes Jmeter slave replicas and service"
  echo
  kubectl create -n $tenant -f $working_dir/jmeter_slaves_deploy.yaml
  kubectl create -n $tenant -f $working_dir/jmeter_slaves_svc.yaml
}

createMaster(){
  echo "Creating Jmeter Master"
  kubectl create -n $tenant -f $working_dir/jmeter_master_configmap.yaml
  kubectl create -n $tenant -f $working_dir/jmeter_master_deploy.yaml
}

printObjects(){
  echo "Printout of the $tenant Objects"
  echo
  kubectl get -n $tenant all
  echo namespace = $tenant >$tmp_dir/tenant_export
}

setVARS $1
checkKubectl
setKubernetesNamespace
createNamespace
createSlaves
createMaster
printObjects




