# Publish the initialized repository to GitHub

GitHub repository names use a URL-safe slug. Create an **empty private** repository under `JTDingwall` named:

`herring-x-ebird-version-2`

Do not initialize it with a README, licence, or `.gitignore`; those files already exist here.

## From the Git bundle

```bash
git clone herring-x-ebird-version-2.bundle herring-x-ebird-version-2
cd herring-x-ebird-version-2
git remote remove origin
git remote add origin git@github.com:JTDingwall/herring-x-ebird-version-2.git
git push -u origin main
```

## From the source archive

```bash
unzip herring-x-ebird-version-2-source.zip -d herring-x-ebird-version-2
cd herring-x-ebird-version-2
git init -b main
git add .
git commit -m "Initialize metadata-first multi-model herring x eBird v2"
git remote add origin git@github.com:JTDingwall/herring-x-ebird-version-2.git
git push -u origin main
```

After the remote exists, the connected GitHub tools can read and update it directly.
