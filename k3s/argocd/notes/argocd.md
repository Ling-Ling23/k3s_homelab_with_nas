# anually trigger ArgoCD to sync/update the trilium helm deployment with the new config.
    kubectl annotate application trilium -n argocd argocd.argoproj.io/refresh=hard
    argocd app sync trilium --force
    Or via kubectl rollout restart after ArgoCD syncs:
        kubectl rollout restart deployment -n trilium