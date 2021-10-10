{ pkgs, imageNameWithTag, deploymentEnv }:
let
  isProd = deploymentEnv == "prod";

  appName = if isProd then "coder" else "coder-${deploymentEnv}";
  fileBrowserConfigName = if isProd then "file-browser-nginx-config" else "file-browser-nginx-${deploymentEnv}-config";
  ingressName = if isProd then "ingress" else "ingress-${deploymentEnv}";
  ingressHostname = if isProd then "dev" else "dev-${deploymentEnv}";
in
pkgs.writeText "dev_env_deployment.yaml" ''
  apiVersion: v1
  kind: Service
  metadata:
    name: ${appName}-service
    namespace: dev
  spec:
    type: ClusterIP
    selector:
      app: ${appName}
    clusterIP: None
    ports:
    - name: coder
      port: 8080
      targetPort: http-port
    - name: file-browser
      port: 80
      targetPort: file-browser
    - name: web-dev
      port: 8888
      targetPort: dev-port
  ---
  apiVersion: v1
  kind: ServiceAccount
  metadata:
    name: coder-service-account
    namespace: dev
  ---
  apiVersion: rbac.authorization.k8s.io/v1
  kind: ClusterRoleBinding
  metadata:
    name: coder-service-account
  roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: cluster-admin
  subjects:
    - kind: ServiceAccount
      name: coder-service-account
      namespace: dev
  ---
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: ${appName}
    namespace: dev
  spec:
    replicas: 1
    selector:
      matchLabels:
        app: ${appName}
    template:
      metadata:
        labels:
          app: ${appName}
      spec:
        serviceAccountName: coder-service-account
        nodeSelector:
          beta.kubernetes.io/arch: amd64
        containers:
        - name: coder
          image: ${imageNameWithTag}
          imagePullPolicy: Always
          resources:
            requests:
              cpu: "2"
              memory: 5Gi
            limits:
              cpu: "10"
              memory: 20Gi
          env:
          - name: PASSWORD
            valueFrom:
              secretKeyRef:
                name: coder-password
                key: coder-password
          volumeMounts:
          - name: dev-data
            mountPath: /root/project
          - name: ssh-key
            mountPath: /tmp/secrets/ssh
          - name: cache-ssh-host-key
            mountPath: /tmp/secrets/cache_ssh_host_key
          ports:
          - name: http-port
            containerPort: 8080
          - name: dev-port
            containerPort: 8888
        - name: file-browser
          image: nginx:mainline-alpine
          args:
          - ash
          - -c
          - cp /tmp/nginx-config/nginx.conf /etc/nginx/nginx.conf && nginx -g 'daemon off;'
          volumeMounts:
          - name: dev-data
            mountPath: /www/data
          - name: nginx-config
            mountPath: /tmp/nginx-config
          ports:
          - name: file-browser
            containerPort: 80
        volumes:
        - name: dev-data
          persistentVolumeClaim:
            claimName: dev-data-pvc
        - name: ssh-key
          secret:
            secretName: git-ssh-key
        - name: cache-ssh-host-key
          secret:
            secretName: cache-ssh-host-key
        - name: nginx-config
          configMap:
            name: ${fileBrowserConfigName}
  ---
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: ${fileBrowserConfigName}
    namespace: dev
  data:
    nginx.conf: |
      user  nginx;
      worker_processes  1;

      error_log  /var/log/nginx/error.log warn;
      pid        /var/run/nginx.pid;

      events {
        worker_connections  1024;
      }
      http {
        server {
          root /www/data;

          location / {
            types {
              video/webm webm;
            }

            autoindex on;
          }
        }
      }
  ---
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: ${ingressName}
    namespace: dev
  spec:
    ingressClassName: internal
    rules:
    - host: ${ingressHostname}.lan
      http:
        paths:
        - pathType: Prefix
          path: "/"
          backend:
            service:
              name: ${appName}-service
              port:
                number: 8080
    - host: files.${ingressHostname}.lan
      http:
        paths:
        - pathType: Prefix
          path: "/"
          backend:
            service:
              name: ${appName}-service
              port:
                number: 80
    - host: web.${ingressHostname}.lan
      http:
        paths:
        - pathType: Prefix
          path: "/"
          backend:
            service:
              name: ${appName}-service
              port:
                number: 8888
  ---
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: ${ingressName}-external
    namespace: dev
  spec:
    ingressClassName: external
    tls:
    - hosts:
      - ${ingressHostname}.jali-clarke.ca
      secretName: jali-clarke-ca
    rules:
    - host: ${ingressHostname}.jali-clarke.ca
      http:
        paths:
        - pathType: Prefix
          path: "/"
          backend:
            service:
              name: ${appName}-service
              port:
                number: 8080
''
