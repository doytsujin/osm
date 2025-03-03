package crdconversion

import (
	"net/http"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
)

// serveRetryPolicyConversion servers endpoint for the converter defined as convertRetryPolicy function.
func serveRetryPolicyConversion(w http.ResponseWriter, r *http.Request) {
	serve(w, r, convertRetryPolicy)
}

// convertRetryPolicy contains the business logic to convert retries.policy.openservicemesh.io CRD
// Example implementation reference : https://github.com/kubernetes/kubernetes/blob/release-1.22/test/images/agnhost/crd-conversion-webhook/converter/example_converter.go
func convertRetryPolicy(Object *unstructured.Unstructured, toVersion string) (*unstructured.Unstructured, metav1.Status) {
	convertedObject := Object.DeepCopy()
	fromVersion := Object.GetAPIVersion()

	if toVersion == fromVersion {
		return nil, statusErrorWithMessage("RetryPolicy: conversion from a version to itself should not call the webhook: %s", toVersion)
	}

	log.Debug().Msg("RetryPolicy: successfully converted object")
	return convertedObject, statusSucceed()
}
