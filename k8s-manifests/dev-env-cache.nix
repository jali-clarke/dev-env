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
    - name: ssh
      port: 22
      targetPort: ssh
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
        initContainers:
        - name: nix-pre-populate
          image: nixos/nix:2.3.12
          imagePullPolicy: IfNotPresent
          command:
          - nix-shell
          - -p
          - rsync
          - --run
          args:
          - "rsync --info=progress2 -auvz /nix/store/ /to-populate-nix/store"
          ports:
          - name: http
            containerPort: 80
          volumeMounts:
          - name: nix-store
            mountPath: /to-populate-nix/store
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
          - "nix-serve -p 80"
          ports:
          - name: http
            containerPort: 80
          volumeMounts:
          - name: nix-store
            mountPath: /nix/store
        - name: sshd
          image: sickp/alpine-sshd:7.9
          imagePullPolicy: IfNotPresent
          env:
          - name: SSH_ENABLE_ROOT
            value: "true"
          ports:
          - name: ssh
            containerPort: 22
          volumeMounts:
          - name: nix-store
            mountPath: /nix/store
        volumes:
        - name: nix-store
          emptyDir: {}
''
