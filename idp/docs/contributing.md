# Contributing to the IDP

## Adding a New Golden Path Template

1. Copy an existing template: `cp -r golden-paths/nodejs-service golden-paths/my-new-service`
2. Update `Chart.yaml` and `values.yaml`
3. Add Backstage scaffolder template at `golden-paths/my-new-service/template.yaml`
4. Add to `backstage-app/app-config.yaml` catalog locations
5. Open PR — CI will validate the Helm chart and Kyverno policies

## Adding a Crossplane Composition

1. Define your XRD in `crossplane/compositions/`
2. Test locally: `kubectl apply -f crossplane/compositions/your-xrd.yaml`
3. Create an example claim in `crossplane/claims/example-*.yaml`
4. Document in `docs/`

## Modifying Kyverno Policies

⚠️ Be careful — policies in `enforce` mode block deployments.

1. Always test in `audit` mode first (change `validationFailureAction: audit`)
2. Test against existing resources: `kyverno apply policies/your-policy.yaml --resource path/to/resource.yaml`
3. Switch back to `enforce` and open PR

## Running Tests Locally

```bash
# Validate all YAML
find . -name "*.yaml" | xargs kubeconform -strict -summary

# Lint Helm charts
helm lint golden-paths/nodejs-service/template

# Test Kyverno policies
kyverno apply policies/ --resource golden-paths/nodejs-service/template/templates/deployment.yaml
```
