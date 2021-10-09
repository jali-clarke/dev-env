{ pkgs }:
pkgs.writeText "dev_env_cache.yaml" ''
  apiVersion: v1
  kind: Service
  metadata:
    name: dev-env-cache
    namespace: dev
  spec:
    type: ClusterIP
    selector:
      app: dev-env-cache
    clusterIP: None
    ports:
    - name: http
      port: 80
      targetPort: http
  ---
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: dev-env-cache
    namespace: dev
  spec:
    replicas: 1
    selector:
      matchLabels:
        app: dev-env-cache
    template:
      metadata:
        labels:
          app: dev-env-cache
      spec:
        nodeSelector:
          beta.kubernetes.io/arch: amd64
        containers:
        - name: nix
          image: nixos/nix:2.3.12
          imagePullPolicy: IfNotPresent
          command:
          - nix-shell
          - -p
          - nix-serve
          - --run
          args:
          - "nix-serve -p 5000"
          ports:
          - name: http
            containerPort: 5000
''
