#!/bin/bash

aws eks update-kubeconfig --region ap-northeast-2 --name dongdorrong-eks-pxd24W1T

curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/install/iam_policy.json

aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json

eksctl create iamserviceaccount --cluster=dongdorrong-eks-pxd24W1T --namespace=kube-system --name=aws-load-balancer-controller --role-name "AmazonEKSLoadBalancerControllerRole" --attach-policy-arn=arn:aws:iam::252462902626:policy/AWSLoadBalancerControllerIAMPolicy --approve

helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=dongdorrong-eks-pxd24W1T --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller

kubectl get deployment -n kube-system aws-load-balancer-controller