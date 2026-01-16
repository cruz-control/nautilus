# Change these to your cruzid
$NAME = "cruzid-desktop"
$POD_NAME = "cruzid-carla"
$CACHE_NAME = "cruzid-carla-cache"

# Ensure an argument was provided
if ($args.Count -lt 1) {
    Write-Host "Usage: script.ps1 [0|1|2]"
    exit 1
}

$mode = [int]$args[0]

if ($mode -eq 1) {
    kubectl delete deployment $NAME
    kubectl delete service $NAME
    kubectl delete ingress $NAME

} elseif ($mode -eq 0) {
    kubectl create -f storage.yml
    kubectl create -f cache.yml
    kubectl create -f desktop.yml
    kubectl create -f desktop-ingress.yml

} elseif ($mode -eq 2) {
    kubectl delete deployment $NAME
    kubectl delete service $NAME
    kubectl delete ingress $NAME
    kubectl delete pvc --now $POD_NAME
    kubectl delete pvc --now $CACHE_NAME

} else {
    Write-Host "Usage: script.ps1 [0|1|2]"
    exit 1
}
