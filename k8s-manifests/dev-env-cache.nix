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
      PasswordAuthentication no
      PermitRootLogin yes
      PermitUserEnvironment yes
    startup.sh: |
      #!/bin/bash -e
      echo -ne "$PASSWORD\n$PASSWORD" | passwd root
      
      mkdir -p /root/.ssh
      cat /ssh_key_mnt/id_rsa.pub >> /root/.ssh/authorized_keys
      chmod 600 /root/.ssh/authorized_keys
      echo "PATH=$PATH" >> /root/.ssh/environment
      
      chown root:root /var/empty
      
      mkdir -p /etc/ssh
      cp /ssh_host_key_mnt/* /etc/ssh
      chmod 600 /etc/ssh/ssh_host_rsa_key
      chmod 644 /etc/ssh/ssh_host_rsa_key.pub

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
          - "rsync --info=progress2 -auvz /nix/ /to-populate-nix"
          ports:
          - name: http
            containerPort: 80
          volumeMounts:
          - name: nix-dir
            mountPath: /to-populate-nix
        containers:
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
          - name: nix-dir
            mountPath: /nix
          - name: sshd-config
            mountPath: /sshd_config_mnt
          - name: ssh-key
            mountPath: /ssh_key_mnt
          - name: ssh-host-key
            mountPath: /ssh_host_key_mnt
        volumes:
        - name: nix-dir
          emptyDir: {}
        - name: ssh-key
          secret:
            secretName: git-ssh-key
        - name: ssh-host-key
          secret:
            secretName: cache-ssh-host-key
        - name: sshd-config
          configMap:
            name: dev-env-cache-sshd-config
''
