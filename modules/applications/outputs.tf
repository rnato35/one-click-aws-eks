# Outputs for Applications Module

output "nginx_sample_namespace" {
  description = "Namespace where nginx-sample is deployed"
  value       = helm_release.nginx_sample.namespace
}

output "nginx_sample_release_name" {
  description = "Helm release name for nginx-sample"
  value       = helm_release.nginx_sample.name
}

output "nginx_sample_chart_version" {
  description = "Chart version of nginx-sample"
  value       = helm_release.nginx_sample.version
}


output "apps_namespace" {
  description = "Name of the applications namespace"
  value       = "apps"
}

output "kubectl_commands" {
  description = "Useful kubectl commands for accessing applications"
  value = {
    get_nginx_pods     = "kubectl get pods -n apps -l app.kubernetes.io/name=nginx-sample"
    get_nginx_service  = "kubectl get svc -n apps nginx-sample"
    get_nginx_ingress  = "kubectl get ingress -n apps nginx-sample"
    port_forward_nginx = "kubectl port-forward -n apps svc/nginx-sample 8080:80"
    nginx_logs         = "kubectl logs -n apps deployment/nginx-sample -f"
  }
}

# Output for cleanup dependency
output "app_cleanup_id" {
  description = "ID of the app cleanup resource for dependency management"
  value       = null_resource.app_cleanup.id
}