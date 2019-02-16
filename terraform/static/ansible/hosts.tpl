[master]
master ansible_host=${ master }

[minion]
${ minions }

[kube-cluster:children]
master
minion