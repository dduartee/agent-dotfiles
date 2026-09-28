<#
.SYNOPSIS
  sessao.ps1 — ground truth da sessão OpenCode (Windows / PowerShell).

.DESCRIPTION
  Descobre o ambiente em runtime; NÃO assume path nem SO:
    1. binário: $env:OPENCODE_BIN -> `opencode` no PATH
    2. banco:   $env:OPENCODE_DB  -> `opencode debug paths` (chave `db`)
    3. sessão:  -SessionId -> $env:OPENCODE_SESSION_ID -> /api/session/active -> diretório -> list
    4. fonte:   `opencode session export` (JSON portátil) -> fallback sqlite3 (se instalado)

  Saída: cabeçalho, RASTROS DE PENDÊNCIA (leads) e TRANSCRIPT, com redação de
  formas-de-credencial. Fonte preferida é o export: não requer sqlite3 nem jq.

.EXAMPLE
  pwsh -File sessao.ps1
  pwsh -File sessao.ps1 -SessionId ses_xxx
#>
#Requires -Version 5.1
[CmdletBinding()]
param(
  [Parameter(Position = 0)][string]$SessionId,
  [int]$MaxChars = 1200
)

$ErrorActionPreference = 'Stop'

function Fail([string]$Message) { Write-Error $Message; exit 1 }

# --- 1. binário -----------------------------------------------------------
$Oc = $null
if ($env:OPENCODE_BIN) {
  $c = Get-Command $env:OPENCODE_BIN -ErrorAction SilentlyContinue
  if ($c) { $Oc = $c.Source }
}
if (-not $Oc) {
  $c = Get-Command opencode -ErrorAction SilentlyContinue
  if ($c) { $Oc = $c.Source }
}
function Invoke-Oc {
  param([string[]]$Argv)
  if (-not $Oc) { return $null }
  try { return (& $Oc @Argv 2>$null) } catch { return $null }
}

# --- 2. banco (descoberta) ------------------------------------------------
$Db = $env:OPENCODE_DB
if (-not $Db -and $Oc) {
  $paths = Invoke-Oc @('debug', 'paths')
  if ($paths) {
    $line = $paths | Where-Object { $_ -match '^\s*db\s' } | Select-Object -First 1
    if ($line) { $Db = (($line -split '\s+') | Where-Object { $_ })[1] }
  }
}

# --- 3. sessão ------------------------------------------------------------
if (-not $SessionId) { $SessionId = $env:OPENCODE_SESSION_ID }

if (-not $SessionId -and $Oc) {
  $activeRaw = Invoke-Oc @('api', 'get', '/api/session/active')
  if ($activeRaw) {
    $active = $null
    try { $active = $activeRaw | ConvertFrom-Json } catch { $active = $null }
    $ids = @()
    if ($active -and $active.data) { $ids = @($active.data.PSObject.Properties.Name) }

    if ($ids.Count -eq 1) {
      $SessionId = $ids[0]
    }
    elseif ($ids.Count -gt 1) {
      $cwd = (Get-Location).Path
      $matches = @()
      foreach ($id in $ids) {
        $infoRaw = Invoke-Oc @('api', 'get', "/api/session/$id")
        if (-not $infoRaw) { continue }
        $info = $null
        try { $info = $infoRaw | ConvertFrom-Json } catch { continue }
        $dir = $null
        if ($info -and $info.data -and $info.data.location) { $dir = [string]$info.data.location.directory }
        if ($dir -and ($cwd -ieq $dir -or $cwd.StartsWith($dir, [System.StringComparison]::OrdinalIgnoreCase))) {
          $matches += $id
        }
      }
      if ($matches.Count -eq 1) { $SessionId = $matches[0] }
      else {
        # Mesmo diretório (ou nenhum): NÃO adivinha.
        $lines = @("AVISO: $($ids.Count) sessões ativas; não adivinho — passe -SessionId:")
        foreach ($id in $ids) {
          $infoRaw = Invoke-Oc @('api', 'get', "/api/session/$id")
          $label = '?'
          if ($infoRaw) { try { $label = [string]($infoRaw | ConvertFrom-Json).data.title } catch { } }
          $lines += "  - $id  $label"
        }
        Fail ($lines -join "`n")
      }
    }
  }
}

if (-not $SessionId -and $Oc) {
  $listRaw = Invoke-Oc @('session', 'list', '--format', 'json')
  if ($listRaw) {
    try {
      $list = $listRaw | ConvertFrom-Json
      if ($list -and $list.Count -ge 1) { $SessionId = [string]$list[0].id }
    } catch { }
  }
}

if (-not $SessionId) { Fail 'ERRO: não achei a sessão. Passe -SessionId ses_xxx' }
if ($SessionId -notmatch '^ses_[A-Za-z0-9_-]+$') { Fail "ERRO: SID inválido: $SessionId" }

$Title = '?'
if ($Oc) {
  $listRaw = Invoke-Oc @('session', 'list', '--format', 'json')
  if ($listRaw) {
    try {
      $match = ($listRaw | ConvertFrom-Json) | Where-Object { $_.id -eq $SessionId } | Select-Object -First 1
      if ($match -and $match.title) { $Title = [string]$match.title }
    } catch { }
  }
}

# --- 4. fonte de ground truth --------------------------------------------
$Tmp = $null
$Exp = $env:OPENCODE_SESSION_JSON
if (-not $Exp -and $Oc) {
  $Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("retro-$SessionId.json")
  try {
    Invoke-Oc @('session', 'export', $SessionId) | Set-Content -Path $Tmp -Encoding utf8
    if ((Test-Path $Tmp) -and (Get-Item $Tmp).Length -gt 0) { $Exp = $Tmp } else { $Exp = $null }
  } catch { $Exp = $null }
}

$Src = $null
$Messages = @()
if ($Exp -and (Test-Path $Exp)) {
  $export = Get-Content -Raw -Path $Exp | ConvertFrom-Json
  $Messages = @($export.messages)
  $Src = 'export'
}

if (-not $Src) {
  $sqlite = Get-Command sqlite3 -ErrorAction SilentlyContinue
  if (-not $sqlite) {
    Fail "ERRO: sem fonte da sessão. 'opencode session export' falhou e sqlite3 está ausente.`n      Alternativa: exporte manualmente e defina OPENCODE_SESSION_JSON."
  }
  if (-not $Db -or -not (Test-Path $Db)) { Fail "ERRO: banco não encontrado: $Db" }
  $query = "select seq,type,data from session_message where session_id='$SessionId' order by seq;"
  $rows = & $sqlite.Source -json $Db $query
  if (-not $rows) { Fail "ERRO: sessão vazia ou inacessível em $Db" }
  $Messages = @($rows | ConvertFrom-Json | ForEach-Object {
      $o = $_.data | ConvertFrom-Json
      if (-not $o.PSObject.Properties.Name.Contains('type')) {
        $o | Add-Member -NotePropertyName type -NotePropertyValue $_.type
      }
      $o
    })
  $Src = "sqlite3:$Db"
}

# --- 5. extração ----------------------------------------------------------
$Forte = 'TODO|FIXME|XXX|warning|aviso|não testei|nao testei|não validei|nao validei|não testado|nao testado|não consegui|nao consegui|pendente|pendência|pende[nç]cia|fica (pra|para) depois|ficou (pra|para)|deixei (pra|para)|por enquanto|workaround|gambiarra|não implementei|nao implementei|falta (testar|validar|fazer)'
$Fraco = '\bdepois\b|temporári|temporari|por ora|futuramente|idealmente|ideal seria|assum(indo|o|imos)|eventualmente|pretendo|planejo|se quiser|posso |quer que eu|sugiro|recomendo'

function Redact([string]$Text) {
  if ([string]::IsNullOrEmpty($Text)) { return '' }
  $t = $Text
  $t = $t -replace 'sk-[A-Za-z0-9]{20,}', 'sk-[REDACTED]'
  $t = $t -replace 'xvl-[A-Za-z0-9]{20,}', 'xvl-[REDACTED]'
  $t = $t -replace 'gh[pousr]_[A-Za-z0-9]{20,}', 'gh_[REDACTED]'
  $t = $t -replace 'AKIA[0-9A-Z]{16}', 'AKIA[REDACTED]'
  $t = $t -replace '-----BEGIN ([A-Z ]+)?PRIVATE KEY-----', '[PRIVATE KEY REDACTED]'
  return $t
}

function Excerpt([string]$Text, [string]$Pattern) {
  if ([string]::IsNullOrEmpty($Text)) { return '' }
  $m = [regex]::Match($Text, $Pattern, 'IgnoreCase')
  if (-not $m.Success) {
    $n = [Math]::Min(160, $Text.Length)
    return $Text.Substring(0, $n)
  }
  $start = [Math]::Max($m.Index - 40, 0)
  $end = [Math]::Min($m.Index + 140, $Text.Length)
  return $Text.Substring($start, $end - $start)
}

function MsgText($Msg) {
  if ($Msg.type -in @('user', 'system', 'synthetic')) { return [string]$Msg.text }
  $parts = @()
  foreach ($c in @($Msg.content)) { if ($c -and $c.type -eq 'text') { $parts += [string]$c.text } }
  return ($parts -join ' ')
}

function MsgTools($Msg) {
  $out = @()
  if ($Msg.type -ne 'assistant') { return $out }
  foreach ($c in @($Msg.content)) {
    if ($c -and $c.type -eq 'tool') {
      $status = '?'
      if ($c.state -and $c.state.status) { $status = [string]$c.state.status }
      $err = ''
      if ($c.state -and $c.state.error -and $c.state.error.message) { $err = [string]$c.state.error.message }
      elseif ($c.state -and $c.state.metadata -and $c.state.metadata.error) { $err = [string]$c.state.metadata.error }
      $out += [pscustomobject]@{ name = [string]$c.name; status = $status; err = (Redact $err) }
    }
  }
  return $out
}

$seq = 0
$normalized = @()
foreach ($m in $Messages) {
  $seq++
  $normalized += [pscustomobject]@{
    seq   = $seq
    type  = [string]$m.type
    text  = (Redact (MsgText $m))
    tools = @(MsgTools $m)
  }
}

$types = @($normalized | ForEach-Object { $_.type })
$nUser = @($types | Where-Object { $_ -eq 'user' }).Count
$nAssist = @($types | Where-Object { $_ -eq 'assistant' }).Count
$nCompact = @($types | Where-Object { $_ -eq 'compaction' }).Count

$errs = @()
$fortes = @()
$fracos = @()
foreach ($m in $normalized) {
  foreach ($t in $m.tools) {
    if ($t.status -eq 'error') {
      $flatErr = ($t.err -replace '\s+', ' ')
      if ($flatErr.Length -gt 120) { $flatErr = $flatErr.Substring(0, 120) }
      $errs += "[erro ] seq $($m.seq) · tool $($t.name): $flatErr"
    }
  }
  if ($m.type -in @('user', 'assistant') -and $m.text) {
    $flat = $m.text -replace '\s+', ' '
    if ($flat -match $Forte) {
      $fortes += "[forte] seq $($m.seq) ($($m.type)): $(Excerpt $flat $Forte)"
    }
    elseif ($flat -match $Fraco) {
      $fracos += "[fraco] seq $($m.seq) ($($m.type)): $(Excerpt $flat $Fraco)"
    }
  }
}

$out = @()
$out += "=== SESSÃO $SessionId — $Title ==="
$out += "fonte: $Src"
$out += "mensagens: $($normalized.Count)  |  user:$nUser  assistant:$nAssist  compaction:$nCompact  |  rastros: $($fortes.Count) fortes, $($fracos.Count) fracos, $($errs.Count) erros"
if ($nCompact -gt 0) {
  $out += "AVISO: houve COMPACTAÇÃO — parte do contexto foi descartada. Trechos antes dela são suspeitos."
}
else {
  $out += 'Sem compactação de contexto.'
}
$out += ''
$out += '=== RASTROS DE PENDÊNCIA (leads — confirme no transcript) ==='
if ($errs.Count -eq 0) { $out += '  (nenhum erro de tool)' } else { $out += $errs }
if ($fortes.Count -eq 0) { $out += '  (nenhum rastro forte)' } else { $out += $fortes | Select-Object -First 40 }
if ($fracos.Count -eq 0) { $out += '  (nenhum rastro fraco)' } else { $out += $fracos | Select-Object -First 15 }
$out += ''
$out += '=== TRANSCRIPT ==='
foreach ($m in $normalized) {
  if ($m.type -in @('user', 'system', 'synthetic')) {
    $t = $m.text
    if ($t.Length -gt $MaxChars) { $t = $t.Substring(0, $MaxChars) }
    $out += "[$($m.type.ToUpper())] $t"
  }
  elseif ($m.type -eq 'assistant') {
    $t = $m.text
    if ($t.Length -gt $MaxChars) { $t = $t.Substring(0, $MaxChars) }
    $names = @($m.tools | ForEach-Object { $_.name } | Sort-Object -Unique)
    $suffix = ''
    if ($names.Count -gt 0) { $suffix = "  <tools: $($names -join ',')>" }
    $out += "[ASSIST] $t$suffix"
  }
  elseif ($m.type -eq 'compaction') {
    $out += '--- [COMPACTAÇÃO] o contexto acima foi resumido/descartado aqui ---'
  }
}

$out | Write-Output
