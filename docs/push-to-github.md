# Push the README Package from VS Code

## 1. Copy the package into the repository

Extract this package. Copy these items into:

```text
C:\Users\ejk52\azure-ad-domain-consolidation
```

Copy or merge:

```text
README.md
docs\
screenshots\
scripts\
```

Do not replace your Terraform files.

## 2. Open the repository in VS Code

```powershell
code C:\Users\ejk52\azure-ad-domain-consolidation
```

## 3. Review the repository

From the VS Code terminal:

```powershell
Set-Location C:\Users\ejk52\azure-ad-domain-consolidation

git status --short
git diff -- README.md
```

Open the Markdown preview:

```text
Ctrl+Shift+V
```

Confirm that:

- All diagrams render.
- Screenshot paths work.
- No password, MFA code, private key, or Terraform state is present.
- The README correctly states that final Azure teardown is pending.

## 4. Stage only the intended files

```powershell
git add README.md docs screenshots scripts

git status --short
git diff --cached --stat
```

Do not stage:

```text
terraform.tfstate
terraform.tfstate.backup
terraform.tfvars
*.rdp
PES keys
installer files
private evidence folders
```

## 5. Commit

```powershell
git commit -m "Document Azure AD consolidation and hybrid identity lab"
```

## 6. Push

Confirm the branch:

```powershell
git branch --show-current
git remote -v
```

Push the current branch:

```powershell
git push
```

## 7. Validate GitHub

Open the repository page and confirm:

- README appears on the repository landing page.
- Mermaid/Graphviz diagrams and screenshots load.
- No broken relative links exist.
- The repository is public only after the content review is complete.

## 8. After Azure teardown

Update the README cleanup section, then commit again:

```powershell
git add README.md
git commit -m "Record final Azure lab teardown"
git push
```
