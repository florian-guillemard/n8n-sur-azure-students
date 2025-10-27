# CI/CD Simple pour n8n

## 🚀 Comment ça marche

### CI (Validation)
- Se déclenche automatiquement sur chaque push
- Valide la syntaxe Terraform

### CD (Déploiement)
- Se déclenche automatiquement sur push vers `main`
- Déploie n8n sur Azure

## ⚙️ Configuration requise

### 1. Créer un Service Principal Azure

```bash
az login
az ad sp create-for-rbac \
  --name "github-actions-n8n" \
  --role contributor \
  --scopes /subscriptions/VOTRE_SUBSCRIPTION_ID \
  --sdk-auth
```

Copier le JSON généré.

### 2. Ajouter les secrets GitHub

Dans votre repo GitHub : **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

**Secrets requis:**

| Nom | Description | Exemple |
|-----|-------------|---------|
| `AZURE_CREDENTIALS` | JSON du Service Principal | `{"clientId": "xxx", ...}` |
| `N8N_PASSWORD` | Mot de passe n8n | `MonMotDePasse123!` |

### 3. C'est tout ! 🎉

Push vers `main` et votre n8n sera déployé automatiquement.

## 📋 Commandes utiles

```bash
# Voir les workflows
gh run list

# Voir les logs d'un workflow
gh run view --log

# Déclencher manuellement (si besoin)
gh workflow run cd-deploy.yml
```

## 🔍 Vérifier le déploiement

Après le déploiement, l'URL sera affichée dans les logs GitHub Actions.

```bash
# Voir les ressources créées
az resource list --resource-group rg-n8n-prod --output table
```
