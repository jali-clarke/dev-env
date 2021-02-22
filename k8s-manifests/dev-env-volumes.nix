{pkgs}:
pkgs.writeText "dev_env_volumes.yaml" ''
  apiVersion: v1
  kind: Namespace
  metadata:
    name: dev
  ---
  apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: dev-data-pv
  spec:
    capacity:
      storage: 100Gi
    accessModes:
    - ReadWriteMany
    storageClassName: dev-data
    nfs:
      path: /mnt/storage/k8s_drive/dev
      server: 192.168.0.103
  ---
  kind: PersistentVolumeClaim
  apiVersion: v1
  metadata:
    name: dev-data-pvc
    namespace: dev
  spec:
    accessModes:
    - ReadWriteMany
    resources:
      requests:
        storage: 100Gi
    storageClassName: dev-data
''
