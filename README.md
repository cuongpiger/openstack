###### [_↩ Back to `main` branch_](https://github.com/cuongpiger/openstack)

|#|Command|Description|Note|
|-|-|-|-|
|1|`openstack server add port <server> <port>`|Add port to server||
|2|`openstack image create --disk-format qcow2 --container-format bare --public --file <PATH_TO_QCOW2_FILE> <IMAGE_NAME>`|Create a Glance image||
|3|`openstack stack update --rollback enabled --existing --wait $STACK_IDENT`|Stack rollback update with UUID or name.|`$STACK_IDENT` can be stack UUID or stack name|

# 1. Magnum

|#|Command|Description|Note|
|-|-|-|-|
|1|`openstack coe nodegroup create --merge-labels --node-count 1 --labels kube_tag=$KUBE_TAG $CLUSTER_UUID $NODEGROUP_NAME`|Add nodegroup with specific K8s version.||
