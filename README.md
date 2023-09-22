## Integrate with TAP

* Deploy the app (on TAP):
```
tanzu apps workload create realtimedemo-tap -f resources/tapworkloads/workload.yaml --yes
```

* Tail the logs of the main app:
```
tanzu apps workload tail realtimedemo-tap --since 64h
```

* Once deployment succeeds, get the URL for the main app:
```
tanzu apps workload get realtimedemo-tap     #should yield realtimedemo.default.<your-domain>
```

* To delete the app:
```
tanzu apps workload delete realtimedemo-tap --yes
```