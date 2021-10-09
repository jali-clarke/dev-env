{ pkgs }:
let
  nixDockerImage = "nixos/nix:2.3.12";
in
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
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: dev-env-cache-sshd-config
    namespace: dev
  data:
    sshd_config: |
      PasswordAuthentication yes
      PermitRootLogin yes
      PermitUserEnvironment yes
    startup.sh: |
      #!/bin/bash -e
      echo -ne "$PASSWORD\n$PASSWORD" | passwd root
      mkdir -p /root/.ssh
      echo "PATH=$PATH" >> /root/.ssh/environment
      chown root:root /var/empty
      mkdir -p /etc/ssh
      ssh-keygen -A
      exec `which sshd` -D -p 22 -f /sshd_config_mnt/sshd_config
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
          image: ${nixDockerImage}
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
        - name: nix-serve
          image: ${nixDockerImage}
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
          image: ${nixDockerImage}
          imagePullPolicy: IfNotPresent
          command:
          - nix-shell
          - -p
          - openssh
          - --run
          args:
          - "bash /sshd_config_mnt/startup.sh"
          env:
          - name: PASSWORD
            valueFrom:
              secretKeyRef:
                name: coder-password
                key: coder-password
          ports:
          - name: ssh
            containerPort: 22
          volumeMounts:
          - name: nix-store
            mountPath: /nix/store
          - name: sshd-config
            mountPath: /sshd_config_mnt
        volumes:
        - name: nix-store
          emptyDir: {}
        - name: sshd-config
          configMap:
            name: dev-env-cache-sshd-config
''
