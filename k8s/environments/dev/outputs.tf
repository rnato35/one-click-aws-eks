output "observability_test_release_name" {
  description = "Name of the observability test Helm release"
  value       = helm_release.observability_test.name
}

output "observability_test_namespace" {
  description = "Namespace where observability test is deployed"
  value       = helm_release.observability_test.namespace
}

output "observability_test_status" {
  description = "Status of the observability test Helm release"
  value       = helm_release.observability_test.status
}

output "apps_namespace_name" {
  description = "Name of the apps namespace"
  value       = kubernetes_namespace.apps.metadata[0].name
}