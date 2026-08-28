<#
  Déploiement PWA Kivoo vers Vercel (projet EXISTANT, sans le recréer).

  Usage :
    .\deploy-web.ps1              # build web + déploiement production
    .\deploy-web.ps1 -SkipBuild   # redéploie le build existant (build\web)

  Une seule fois avant la première utilisation :
    vercel login                                     # auth navigateur
    cd deploy\kivoo-web
    vercel link --yes --project <nom-de-votre-projet>   # ex: kivoo-web
#>
param([switch]$SkipBuild)

$ErrorActionPreference = 'Stop'
$root   = $PSScriptRoot
$build  = Join-Path $root 'build\web'
$deploy = Join-Path $root 'deploy\kivoo-web'

# 0. Pré-requis : CLI Vercel installé
if (-not (Get-Command vercel -ErrorAction SilentlyContinue)) {
  Write-Host '❌ CLI Vercel introuvable. Installez-le avec : npm install -g vercel' -ForegroundColor Red
  exit 1
}

# 1. Build Flutter web + service worker PWA
if (-not $SkipBuild) {
  Write-Host '🔨 Build web (release)...' -ForegroundColor Cyan
  flutter build web --release --no-wasm-dry-run
  if ($LASTEXITCODE -ne 0) { Write-Host '❌ Échec du build Flutter.' -ForegroundColor Red; exit 1 }
  # Flutter 3.44 génère un service worker vide (déprécié) -> on met le nôtre
  Copy-Item (Join-Path $root 'web\sw.js') (Join-Path $build 'flutter_service_worker.js') -Force
  Write-Host '✅ Build OK' -ForegroundColor Green
}

# 2. Le dossier de déploiement existe-t-il ? (créé au premier lancement)
New-Item $deploy -ItemType Directory -Force | Out-Null

# 3. Le dossier est-il lié au projet Vercel ?
if (-not (Test-Path (Join-Path $deploy '.vercel\project.json'))) {
  Write-Host '❌ Dossier non lié au projet Vercel. À faire UNE seule fois :' -ForegroundColor Red
  Write-Host '   vercel login' -ForegroundColor Yellow
  Write-Host "   cd $deploy" -ForegroundColor Yellow
  Write-Host '   vercel link --yes --project <nom-de-votre-projet>' -ForegroundColor Yellow
  exit 1
}

# 4. Synchroniser build\web -> deploy\kivoo-web (préserve le lien .vercel)
Get-ChildItem $deploy -Exclude '.vercel' | Remove-Item -Recurse -Force
Copy-Item (Join-Path $build '*') $deploy -Recurse -Force
# Le .map ne sert qu'au debug local : inutile sur Vercel (gagne ~3 Mo d'upload)
Remove-Item (Join-Path $deploy 'main.dart.js.map') -ErrorAction SilentlyContinue

# 5. Déployer en production (depuis le dossier LIÉ => même projet, même URL)
Write-Host '🚀 Déploiement Vercel (production)...' -ForegroundColor Cyan
Push-Location $deploy
vercel deploy --prod --yes
$code = $LASTEXITCODE
Pop-Location
exit $code
