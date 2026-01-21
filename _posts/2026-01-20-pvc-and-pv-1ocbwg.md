<h1>PVC和PV</h1>
<h3>如何备份还原 pvc 和 pv，保证绑定关系不变，修改其中不可热更新的字段?</h3>
<p>第一步，备份 pvc 和 pv 如下：</p>
<p>pvc.yaml</p>
<pre><code class="language-yaml">apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  annotations:
    pv.kubernetes.io/bind-completed: &quot;yes&quot;
    pv.kubernetes.io/bound-by-controller: &quot;yes&quot;
    volume.beta.kubernetes.io/storage-provisioner: k8s-sigs.io/nfs-subdir-external-provisioner
    volume.kubernetes.io/storage-provisioner: k8s-sigs.io/nfs-subdir-external-provisioner
  creationTimestamp: &quot;2026-01-20T08:08:20Z&quot;
  finalizers:
  - kubernetes.io/pvc-protection
  name: ceshi
  namespace: inner-devops
  resourceVersion: &quot;574892949&quot;
  uid: 139c3768-5ecb-431d-96c9-45d497cafbb9
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: nfs-client
  volumeMode: Filesystem
  volumeName: pvc-139c3768-5ecb-431d-96c9-45d497cafbb9
status:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 10Gi
  phase: Bound
</code></pre>
<p>pv.yaml</p>
<pre><code class="language-yaml">apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {&quot;apiVersion&quot;:&quot;v1&quot;,&quot;kind&quot;:&quot;PersistentVolume&quot;,&quot;metadata&quot;:{&quot;annotations&quot;:{&quot;pv.kubernetes.io/provisioned-by&quot;:&quot;k8s-sigs.io/nfs-subdir-external-provisioner&quot;},&quot;creationTimestamp&quot;:&quot;2026-01-20T08:08:20Z&quot;,&quot;finalizers&quot;:[&quot;kubernetes.io/pv-protection&quot;],&quot;name&quot;:&quot;pvc-139c3768-5ecb-431d-96c9-45d497cafbb9&quot;,&quot;resourceVersion&quot;:&quot;574892947&quot;,&quot;uid&quot;:&quot;4c285797-a455-4a9b-9ef2-1726b57b2aaf&quot;},&quot;spec&quot;:{&quot;accessModes&quot;:[&quot;ReadWriteOnce&quot;],&quot;capacity&quot;:{&quot;storage&quot;:&quot;10Gi&quot;},&quot;nfs&quot;:{&quot;path&quot;:&quot;/data/nfs-data/inner-devops&quot;,&quot;server&quot;:&quot;10.200.1.130&quot;},&quot;persistentVolumeReclaimPolicy&quot;:&quot;Retain&quot;,&quot;storageClassName&quot;:&quot;nfs-client&quot;,&quot;volumeMode&quot;:&quot;Filesystem&quot;},&quot;status&quot;:{&quot;phase&quot;:&quot;Bound&quot;}}
    pv.kubernetes.io/bound-by-controller: &quot;yes&quot;
    pv.kubernetes.io/provisioned-by: k8s-sigs.io/nfs-subdir-external-provisioner
  creationTimestamp: &quot;2026-01-20T08:23:56Z&quot;
  finalizers:
  - kubernetes.io/pv-protection
  name: pvc-139c3768-5ecb-431d-96c9-45d497cafbb9
  resourceVersion: &quot;574896932&quot;
  uid: c1a1feb8-8645-44e3-8e33-0400711eccf5
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 10Gi
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: ceshi
    namespace: inner-devops
    resourceVersion: &quot;574896604&quot;
    uid: 7958680a-834f-4b11-9b8d-33b37b00d8ae
  nfs:
    path: /data/nfs-data/inner-devops
    server: 10.200.1.130
  persistentVolumeReclaimPolicy: Delete
  storageClassName: nfs-client
  volumeMode: Filesystem
status:
  phase: Bound
</code></pre>
<p>其中 <strong>最为重要的是 PV 文件中的 claimRef 字段，该字段是被 pvc 绑定后 pv 自动生成的字段</strong> ，所以如果保留该字段直接还原，即使 pvc 的名称一样，pv 也会认为自己没有被绑定处于 release 状态。删除该字段后还原该 pv，pv 的状态就处于 Available 状态。</p>
<p>另外 persistentVolumeReclaimPolicy 字段一般默认被设置成的 Delete，如果先创建 pv 会被控制器直接清理，这种情况可以有两种方法解决：</p>
<ol>
<li>先创建 pvc，未绑定前状态显示 lost，创建 pv 后显示 bound 状态</li>
<li>修改 persistentVolumeReclaimPolicy 字段为 Retain，不管创建顺序，未被绑定的 pv 显示为 Available 状态</li>
</ol>
<p>于是清理该字段后如下：</p>
<pre><code class="language-yaml">apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {&quot;apiVersion&quot;:&quot;v1&quot;,&quot;kind&quot;:&quot;PersistentVolume&quot;,&quot;metadata&quot;:{&quot;annotations&quot;:{&quot;pv.kubernetes.io/provisioned-by&quot;:&quot;k8s-sigs.io/nfs-subdir-external-provisioner&quot;},&quot;creationTimestamp&quot;:&quot;2026-01-20T08:08:20Z&quot;,&quot;finalizers&quot;:[&quot;kubernetes.io/pv-protection&quot;],&quot;name&quot;:&quot;pvc-139c3768-5ecb-431d-96c9-45d497cafbb9&quot;,&quot;resourceVersion&quot;:&quot;574892947&quot;,&quot;uid&quot;:&quot;4c285797-a455-4a9b-9ef2-1726b57b2aaf&quot;},&quot;spec&quot;:{&quot;accessModes&quot;:[&quot;ReadWriteOnce&quot;],&quot;capacity&quot;:{&quot;storage&quot;:&quot;10Gi&quot;},&quot;nfs&quot;:{&quot;path&quot;:&quot;/data/nfs-data/inner-devops&quot;,&quot;server&quot;:&quot;10.200.1.130&quot;},&quot;persistentVolumeReclaimPolicy&quot;:&quot;Retain&quot;,&quot;storageClassName&quot;:&quot;nfs-client&quot;,&quot;volumeMode&quot;:&quot;Filesystem&quot;},&quot;status&quot;:{&quot;phase&quot;:&quot;Bound&quot;}}
    pv.kubernetes.io/bound-by-controller: &quot;yes&quot;
    pv.kubernetes.io/provisioned-by: k8s-sigs.io/nfs-subdir-external-provisioner
  creationTimestamp: &quot;2026-01-20T08:23:56Z&quot;
  finalizers:
  - kubernetes.io/pv-protection
  name: pvc-139c3768-5ecb-431d-96c9-45d497cafbb9
  resourceVersion: &quot;574896932&quot;
  uid: c1a1feb8-8645-44e3-8e33-0400711eccf5
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 10Gi
  nfs:
    path: /data/nfs-data/inner-devops
    server: 10.200.1.130
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs-client
  volumeMode: Filesystem
status:
  phase: Bound
</code></pre>
