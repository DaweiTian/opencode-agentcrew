#Requires -Version 5.1
<#
.SYNOPSIS
    Agent consistency gate for the opencode-agentcrew repository.

.DESCRIPTION
    Keeps agents/*.md, the three primary agents' rosters, the handoff-contract
    copies and the markdown documentation (AGENTS.md / README.md / README.en.md)
    mutually consistent. Seven checks run in order; each prints one pass/fail
    mark followed by problem details when it fails:

      1/7 Roster coverage      - every subagent name is mentioned in all three
                                 primary agent bodies (smart-router.md, Zero.md,
                                 Erribaba.md); every agent-shaped name those
                                 bodies mention exists in agents/ (skill names
                                 such as agent-browser/report are excluded).
      2/7 Handoff contract     - the "Status semantics" block (from the
                                 **Status semantics:** line through the
                                 "do differently." line) is byte-identical in
                                 every subagent file and in
                                 references/workflow/handoff-contract.md (SSOT).
      3/7 Badge family map     - the first emoji of each frontmatter description
                                 matches the family map embedded below.
      4/7 Model whitelist      - the frontmatter model: value is one of the
                                 approved provider/model ids.
      5/7 Table reconciliation - the agent table rows in AGENTS.md, README.md and
                                 README.en.md equal the agents/ directory set in
                                 both directions (no missing row, no ghost row).
      6/7 Stale-claim scan     - no banned phrase in any *.md anywhere in the
                                 repo, and the expected agent-count heading is
                                 present in AGENTS.md.
      7/7 Frontmatter shape    - description/mode/model present and valid;
                                 subagents must declare permissions and deny
                                 `action: subagent`; the three primaries must
                                 not declare a permissions block.

    The checks are dynamic over the actual agents/ directory (a not-yet-created
    agent file never hard-fails by itself); the badge map and the contract check
    are full-coverage: an unmapped agent file is a failure that forces the map
    to be extended.

    ENCODING WARNING: Windows PowerShell 5.1 decodes UTF-8 files without BOM
    using the system ANSI codepage (GBK on zh-CN machines), which corrupts CJK
    text and emoji. Every file read therefore goes through
    [System.IO.File]::ReadAllText / ReadAllLines with an explicit UTF-8
    encoding. This script's own source is pure ASCII on purpose (all emoji and
    CJK characters are built from code points at runtime), so it is immune to
    the same trap when PowerShell parses it.

.PARAMETER Sync
    Propagation mode: extracts the synced block from
    references/workflow/handoff-contract.md (SSOT) and replaces the block in
    every subagent file (agents/*.md minus the three primaries) with it. Each
    file keeps its own line-ending style (CRLF stays CRLF, LF stays LF) and a
    possible BOM is preserved; files whose block already matches are left
    untouched on disk. Every file is reported as 'synced' or 'unchanged'
    (or 'skipped' when no block is found). The full 7-check audit always runs
    after the sync, so the result is verified in the same run.

.EXAMPLE
    pwsh -NoProfile -File scripts/check-agents.ps1

.EXAMPLE
    powershell -NoProfile -File scripts/check-agents.ps1 -Sync

.OUTPUTS
    Human-readable report on stdout.

.NOTES
    Exit codes: 0 = every check passed, 1 = at least one check failed.
    Line endings are normalized to LF before hashing; CRLF/LF differences
    alone are not treated as contract drift.
#>

[CmdletBinding()]
param(
    [switch]$Sync
)

Set-StrictMode -Version 1.0
$ErrorActionPreference = 'Stop'

# ----------------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------------

$script:Utf8 = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false
$script:OkMark = [string][char]0x2705     # U+2705 WHITE HEAVY CHECK MARK
$script:FailMark = [string][char]0x274C   # U+274C CROSS MARK
$script:FailCount = 0

$RepoRoot = Split-Path -Parent $PSScriptRoot
$AgentsDir = Join-Path $RepoRoot 'agents'
$WorkflowDir = Join-Path (Join-Path $RepoRoot 'references') 'workflow'
$SsotPath = Join-Path $WorkflowDir 'handoff-contract.md'

$PrimaryNames = @('smart-router', 'Zero', 'Erribaba')

# Badge family map: agent name -> Unicode code point of the emoji that must
# start its frontmatter description (variation selectors are ignored).
$BadgeMap = @{
    'smart-router'          = 0x1F3AF  # target
    'Zero'                  = 0x1F331  # seedling
    'Erribaba'              = 0x1F6E0  # hammer and wrench
    'workflow-orchestrator' = 0x1F9ED  # compass
    'code-generator'        = 0x2699   # gear
    'code-generator-lite'   = 0x2699
    'software-engineer'     = 0x2699
    'frontend-dev'          = 0x1F58C  # paintbrush
    'frontend-dev-lite'     = 0x1F58C
    'ui-designer'           = 0x1F3A8  # artist palette
    'vision-dev'            = 0x1F441  # eye
    'architect'             = 0x1F3D7  # building construction
    'api-designer'          = 0x1F3D7
    'api-designer-lite'     = 0x1F3D7
    'research'              = 0x1F50E  # left-pointing magnifying glass
    'research-lite'         = 0x1F50E
    'reviewer'              = 0x2696   # scales
    'reviewer-lite'         = 0x2696
    'frontend-reviewer'     = 0x2696
    'spec-reviewer'         = 0x1F50D  # right-pointing magnifying glass
    'security-auditor'      = 0x1F6E1  # shield
    'test-writer'           = 0x1F9EA  # test tube
    'test-writer-lite'      = 0x1F9EA
    'e2e-tester'            = 0x1F3AD  # performing arts
    'validator'             = 0x2705   # white heavy check mark
    'perf-optimizer'        = 0x26A1   # high voltage
    'debugger'              = 0x1F41B  # bug
    'debugger-lite'         = 0x1F41B
    'executor'              = 0x1F5A5  # desktop computer
    'refactorer'            = 0x1F9F9  # broom
    'refactorer-lite'       = 0x1F9F9
    'git-assistant'         = 0x1F33F  # herb
    'plan-writer'           = 0x1F5FA  # world map
    'project-manager'       = 0x1F5FA
    'devops'                = 0x1F680  # rocket
    'db-engineer'           = 0x1F5C4  # file cabinet
    'migration'             = 0x1F504  # anticlockwise downwards arrow
    'doc-writer'            = 0x1F4DA  # books
    'doc-writer-lite'       = 0x1F4DA
}

# Model whitelist: every frontmatter model: value must be one of these.
$ModelWhitelist = @(
    'console-xiaomi-token-plan/mimo-v2.6-flash',
    'opencode-go/mimo-v2.6-flash',
    'opencode-go/mimo-v2.6-pro',
    'opencode-go/deepseek-v4.1-flash',
    'opencode-go/glm-5.2',
    'opencode-go/glm-5.3-flash',
    'opencode-go/kimi-k2.7-code',
    'opencode-go/qwen3.7-plus',
    'opencode-go/qwen3.8-flash'
)

# Tokens in primary bodies that look like agent names but are skills/tools.
$NonAgentTokens = @('agent-browser', 'report', 'agent-name')

# Last-segment suffixes that make a lowercase kebab token agent-shaped.
$RoleSuffixes = @(
    'dev', 'designer', 'writer', 'reviewer', 'auditor', 'optimizer', 'tester',
    'generator', 'orchestrator', 'assistant', 'manager', 'engineer', 'router',
    'executor', 'validator', 'debugger', 'refactorer', 'migration', 'architect',
    'research', 'devops', 'lite'
)

# Single-word lowercase agent names.
$SingletonNames = @(
    'executor', 'validator', 'debugger', 'refactorer', 'migration',
    'architect', 'research', 'devops'
)

# Banned phrases: no *.md anywhere in the repo may contain them.
# The CJK phrase is built from code points to keep this file pure ASCII.
$StaleCjk = '38 ' + [char]0x4E2A + [char]0x667A + [char]0x80FD + [char]0x4F53  # 38 <ge-zhi-neng-ti>
$StaleCjkNoSpace = '38' + [char]0x4E2A + [char]0x667A + [char]0x80FD + [char]0x4F53
$BannedPhrases = @('MiniMax', 'Step-5 Preview', '38 agents', $StaleCjk, $StaleCjkNoSpace)

# ----------------------------------------------------------------------------
# Helpers (all reads go through explicit UTF-8; see ENCODING WARNING above)
# ----------------------------------------------------------------------------

function Read-TextUtf8 {
    param([string]$Path)
    return [System.IO.File]::ReadAllText($Path, $script:Utf8)
}

function Read-LinesUtf8 {
    param([string]$Path)
    $lines = [System.IO.File]::ReadAllLines($Path, $script:Utf8)
    if ($lines.Count -gt 0 -and $lines[0].Length -gt 0 -and [int][char]$lines[0][0] -eq 0xFEFF) {
        $lines[0] = $lines[0].Substring(1)
    }
    return ,$lines
}

function Get-FrontMatterText {
    # Returns the YAML frontmatter body (between the first two '---' lines) as
    # one LF-joined string, or '' when the file has no frontmatter.
    param([string[]]$Lines)
    if ($null -eq $Lines -or $Lines.Count -lt 2) { return '' }
    if ($Lines[0].Trim() -ne '---') { return '' }
    for ($i = 1; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i].Trim() -eq '---') {
            if ($i -eq 1) { return '' }
            return ($Lines[1..($i - 1)] -join "`n")
        }
    }
    return ''
}

function Get-LeadingCodePoint {
    # Unicode code point of the first visible character (surrogate pairs
    # combined; variation selectors are simply skipped by taking the lead).
    param([string]$Text)
    if ($null -eq $Text) { return -1 }
    $t = $Text.TrimStart()
    if ($t.Length -eq 0) { return -1 }
    $c = [int][char]$t[0]
    if ($c -ge 0xD800 -and $c -le 0xDBFF -and $t.Length -ge 2) {
        $c2 = [int][char]$t[1]
        if ($c2 -ge 0xDC00 -and $c2 -le 0xDFFF) {
            return (0x10000 + (($c - 0xD800) * 0x400) + ($c2 - 0xDC00))
        }
    }
    return $c
}

function Get-ContractSpan {
    # Char span [Start, End) of the synced handoff-contract block inside $Text:
    # from the beginning of the line holding '**Status semantics:**' through the
    # end of the line holding 'differently.' (line terminator excluded). Any
    # surrounding decoration (indent, '>' quote markers, a leading list bullet)
    # stays inside the span so callers can replace the whole region verbatim.
    # Returns $null when either marker is missing.
    param([string]$Text)
    if ($null -eq $Text -or $Text.Length -eq 0) { return $null }
    $startIdx = $Text.IndexOf('**Status semantics:**', [System.StringComparison]::Ordinal)
    if ($startIdx -lt 0) { return $null }
    $endIdx = $Text.IndexOf('differently.', $startIdx, [System.StringComparison]::Ordinal)
    if ($endIdx -lt 0) { return $null }
    $lineStart = $Text.LastIndexOf("`n", $startIdx)
    if ($lineStart -lt 0) { $lineStart = 0 } else { $lineStart = $lineStart + 1 }
    $eol = $Text.IndexOf("`n", $endIdx)
    if ($eol -lt 0) { $eol = $Text.Length }
    $contentEnd = $eol
    if ($contentEnd -gt $lineStart -and $Text[$contentEnd - 1] -eq "`r") { $contentEnd = $contentEnd - 1 }
    return @{ Start = $lineStart; End = $contentEnd }
}

function Remove-BlockDecorations {
    # Strips external markdown decorations some contexts wrap around the
    # contract block (shared indentation, '>' blockquote markers, a list bullet
    # in front of the marker line) so the canonical lines come out clean.
    # Identity for plain blocks like the ones currently in the repo.
    param([string[]]$Lines)
    $out = @()
    foreach ($ln in $Lines) { $out += $ln }

    # 1) shared leading whitespace indent
    $minIndent = -1
    foreach ($ln in $out) {
        if ($ln.Trim().Length -eq 0) { continue }
        $ws = [regex]::Match($ln, '^[ \t]*').Value.Length
        if ($minIndent -lt 0 -or $ws -lt $minIndent) { $minIndent = $ws }
    }
    if ($minIndent -gt 0) {
        for ($i = 0; $i -lt $out.Count; $i++) {
            if ($out[$i].Length -gt $minIndent) { $out[$i] = $out[$i].Substring($minIndent) }
            elseif ($out[$i].Length -gt 0) { $out[$i] = '' }
        }
    }

    # 2) blockquote markers shared by every non-empty line
    while ($true) {
        $allQuoted = $true
        foreach ($ln in $out) {
            if ($ln.Trim().Length -eq 0) { continue }
            if (-not [regex]::IsMatch($ln, '^[ \t]*>')) { $allQuoted = $false; break }
        }
        if (-not $allQuoted) { break }
        for ($i = 0; $i -lt $out.Count; $i++) {
            if ($out[$i].Trim().Length -eq 0) { continue }
            $out[$i] = [regex]::Replace($out[$i], '^[ \t]*>[ \t]?', '')
        }
    }

    # 3) list bullet directly in front of the marker line (continuation lines
    #    of such a list carry at most two extra spaces of indent)
    if ($out.Count -gt 0 -and [regex]::IsMatch($out[0], '^[-*+][ \t]+')) {
        $out[0] = [regex]::Replace($out[0], '^[-*+][ \t]+', '')
        for ($i = 1; $i -lt $out.Count; $i++) {
            if ($out[$i].Trim().Length -eq 0) { continue }
            $out[$i] = [regex]::Replace($out[$i], '^[ \t]{1,2}', '')
        }
    }
    return ,$out
}

function Get-ContractBlock {
    # Extracts the synced handoff-contract block: from the '**Status semantics:**'
    # line through the end of the line containing 'do differently.' (inclusive),
    # with external decorations removed. Line endings are normalized to LF so
    # CRLF/LF mixes are not treated as drift. Returns $null when the block
    # cannot be found.
    param([string]$Text)
    $span = Get-ContractSpan $Text
    if ($null -eq $span) { return $null }
    $block = $Text.Substring($span['Start'], $span['End'] - $span['Start'])
    $block = $block.Replace("`r`n", "`n").Replace("`r", "`n")
    $lines = Remove-BlockDecorations ($block -split "`n")
    return ($lines -join "`n")
}

function Get-Sha256Hex {
    param([string]$Text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = $script:Utf8.GetBytes($Text)
        $hash = $sha.ComputeHash($bytes)
    }
    finally {
        $sha.Dispose()
    }
    return ([System.BitConverter]::ToString($hash) -replace '-', '')
}

function Get-AgentLikeToken {
    # Returns the token when it looks like an agent name, otherwise ''.
    #   - 'Zero' / 'Erribaba' always count (capitalized primaries),
    #   - lowercase kebab with a role-like last segment counts
    #     (code-generator-lite -> 'lite', git-assistant -> 'assistant', ...),
    #   - a single lowercase word counts only when it is a known singleton.
    param([string]$Tok)
    if ($Tok -eq 'Zero' -or $Tok -eq 'Erribaba') { return $Tok }
    if ($Tok -cmatch '^[a-z][a-z0-9]*(?:-[a-z0-9]+)+$') {
        $parts = $Tok.Split('-')
        $last = $parts[$parts.Count - 1]
        if ($RoleSuffixes -contains $last) { return $Tok }
    }
    if ($Tok -cmatch '^[a-z][a-z0-9]*$') {
        if ($SingletonNames -contains $Tok) { return $Tok }
    }
    return ''
}

function Write-Check {
    param([int]$No, [string]$Title, $Problems)
    $list = @()
    if ($null -ne $Problems) { $list = @($Problems) }
    if ($list.Count -eq 0) {
        Write-Host ("{0} [{1}/7] {2}" -f $script:OkMark, $No, $Title)
    }
    else {
        Write-Host ("{0} [{1}/7] {2}" -f $script:FailMark, $No, $Title)
        foreach ($p in $list) { Write-Host ("        - " + $p) }
        $script:FailCount++
    }
}

if ($Sync) {
    # Propagation mode: copy the SSOT block into every subagent file, keeping
    # each file's own line-ending style, then fall through to the full audit.
    Write-Host ''
    Write-Host ('Sync: propagating the SSOT block to every subagent file')

    if (-not (Test-Path -LiteralPath $SsotPath)) {
        Write-Host ($script:FailMark + ' Sync aborted: SSOT missing: references/workflow/handoff-contract.md')
        exit 1
    }
    $ssotBlock = Get-ContractBlock (Read-TextUtf8 $SsotPath)
    if ($null -eq $ssotBlock) {
        Write-Host ($script:FailMark + ' Sync aborted: synced block not found in handoff-contract.md (expected **Status semantics:** .. do differently.)')
        exit 1
    }
    if (-not (Test-Path -LiteralPath $AgentsDir)) {
        Write-Host ($script:FailMark + ' Sync aborted: agents/ directory not found under ' + $RepoRoot)
        exit 1
    }

    $ssotHash = Get-Sha256Hex $ssotBlock
    $blockLineCount = @($ssotBlock -split "`n").Count
    Write-Host ('       source: references/workflow/handoff-contract.md (' + $blockLineCount + ' lines, sha256 ' + $ssotHash.Substring(0, 12) + ')')

    $syncFiles = @(Get-ChildItem -LiteralPath $AgentsDir -Filter '*.md' -File |
        Where-Object { $PrimaryNames -notcontains $_.BaseName } |
        Sort-Object Name)
    $syncedCount = 0
    $unchangedCount = 0
    $skippedCount = 0

    foreach ($f in $syncFiles) {
        $text = Read-TextUtf8 $f.FullName
        $span = Get-ContractSpan $text
        if ($null -eq $span) {
            Write-Host ('       - ' + $f.Name + ': skipped (synced block not found)')
            $skippedCount = $skippedCount + 1
            continue
        }

        $oldRaw = $text.Substring($span['Start'], $span['End'] - $span['Start'])
        $oldNorm = $oldRaw.Replace("`r`n", "`n").Replace("`r", "`n")
        $oldCanon = (Remove-BlockDecorations ($oldNorm -split "`n")) -join "`n"
        if ($oldCanon -ceq $ssotBlock) {
            Write-Host ('       - ' + $f.Name + ': unchanged')
            $unchangedCount = $unchangedCount + 1
            continue
        }

        # Keep the file's own line-ending style: CRLF files stay CRLF, LF stay LF.
        $eolSeq = "`n"
        $crlfCount = ([regex]::Matches($text, "`r`n")).Count
        $lfCount = ([regex]::Matches($text, "`n")).Count
        if ($crlfCount -gt 0 -and ($crlfCount * 2) -ge $lfCount) { $eolSeq = "`r`n" }
        $newRaw = $ssotBlock.Replace("`n", $eolSeq)
        $newText = $text.Substring(0, $span['Start']) + $newRaw + $text.Substring($span['End'])

        # ReadAllText strips a BOM; preserve one when the file originally had it.
        $enc = $script:Utf8
        $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            $enc = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $true
        }
        [System.IO.File]::WriteAllText($f.FullName, $newText, $enc)
        Write-Host ('       - ' + $f.Name + ': synced')
        $syncedCount = $syncedCount + 1
    }

    Write-Host ('Sync: ' + $syncFiles.Count + ' file(s) scanned - ' + $syncedCount + ' synced, ' + $unchangedCount + ' unchanged, ' + $skippedCount + ' skipped')
    Write-Host ''
}

# ----------------------------------------------------------------------------
# Inventory
# ----------------------------------------------------------------------------

if (-not (Test-Path -LiteralPath $AgentsDir)) {
    Write-Host ("{0} agents/ directory not found under {1}" -f $script:FailMark, $RepoRoot)
    exit 1
}

$AgentFiles = @(Get-ChildItem -LiteralPath $AgentsDir -Filter '*.md' -File | Sort-Object Name)
$AgentNameSet = @{}
foreach ($f in $AgentFiles) { $AgentNameSet[$f.BaseName] = $true }
$AgentNames = @($AgentNameSet.Keys | Sort-Object)
$SubFiles = @($AgentFiles | Where-Object { $PrimaryNames -notcontains $_.BaseName })

$PrimaryText = @{}
foreach ($p in $PrimaryNames) {
    $pp = Join-Path $AgentsDir ($p + '.md')
    if (Test-Path -LiteralPath $pp) {
        $PrimaryText[$p] = Read-TextUtf8 $pp
    }
    else {
        $PrimaryText[$p] = ''
    }
}

# All *.md files in the repo (stale-claim scan), plus non-agent basenames
# (used to avoid flagging documentation links as ghost agent rows).
$AllMdFiles = @(Get-ChildItem -LiteralPath $RepoRoot -Filter '*.md' -Recurse -File)
$NonAgentMdNames = @{}
foreach ($f in $AllMdFiles) {
    if ($f.Directory.FullName -ne (Get-Item -LiteralPath $AgentsDir).FullName) {
        $NonAgentMdNames[$f.BaseName] = $true
    }
}

# ----------------------------------------------------------------------------
# 1/7 Roster coverage
# ----------------------------------------------------------------------------

$problems = @()

foreach ($p in $PrimaryNames) {
    if ($PrimaryText[$p] -eq '') {
        $problems += ('primary agent file missing or unreadable: ' + $p + '.md')
    }
}

# Forward: every subagent must be listed in each of the three primary bodies.
# (The three primaries themselves are the roster owners, not roster entries.)
foreach ($n in ($AgentNames | Where-Object { $PrimaryNames -notcontains $_ })) {
    $pat = '(?<![A-Za-z0-9-])' + [regex]::Escape($n) + '(?![A-Za-z0-9-])'
    foreach ($p in $PrimaryNames) {
        if ($PrimaryText[$p] -eq '') { continue }
        if (-not [regex]::IsMatch($PrimaryText[$p], $pat)) {
            $problems += ('roster gap: ' + $n + ' is not mentioned in ' + $p + '.md')
        }
    }
}

# Reverse: every agent-shaped name mentioned in the primary bodies (in `code`
# spans or **bold**) must exist in agents/; skill names are whitelisted.
foreach ($p in $PrimaryNames) {
    if ($PrimaryText[$p] -eq '') { continue }
    $cited = @{}
    foreach ($m in [regex]::Matches($PrimaryText[$p], '`([^`\r\n]+)`')) {
        $tok = $m.Groups[1].Value.Trim()
        if ($tok.StartsWith('@')) { $tok = $tok.Substring(1) }
        if ($tok -cmatch '^[a-z][a-z0-9]*(?:-[a-z0-9]+)+$') { $cited[$tok] = $true }
    }
    foreach ($m in [regex]::Matches($PrimaryText[$p], '\*\*([^*\r\n]+)\*\*')) {
        $tok = $m.Groups[1].Value.Trim()
        if ($tok.StartsWith('@')) { $tok = $tok.Substring(1) }
        if ($tok -cmatch '^[a-z][a-z0-9]*(?:-[a-z0-9]+)+$') { $cited[$tok] = $true }
    }
    foreach ($tok in ($cited.Keys | Sort-Object)) {
        if ($NonAgentTokens -contains $tok) { continue }
        if (-not $AgentNameSet.ContainsKey($tok)) {
            $problems += ('ghost name: ' + $p + '.md cites unknown agent ''' + $tok + '''')
        }
    }
}

Write-Check 1 'Roster coverage (x3 primaries, forward + reverse)' $problems

# ----------------------------------------------------------------------------
# 2/7 Handoff contract block
# ----------------------------------------------------------------------------

$problems = @()
$blockHashes = @{}

foreach ($f in $SubFiles) {
    $block = Get-ContractBlock (Read-TextUtf8 $f.FullName)
    if ($null -eq $block) {
        $problems += ($f.Name + ': synced block not found (expected **Status semantics:** .. do differently.)')
    }
    else {
        $blockHashes[$f.Name] = Get-Sha256Hex $block
    }
}

if (-not (Test-Path -LiteralPath $SsotPath)) {
    $problems += ('SSOT missing: references/workflow/handoff-contract.md')
}
else {
    $block = Get-ContractBlock (Read-TextUtf8 $SsotPath)
    if ($null -eq $block) {
        $problems += ('handoff-contract.md: synced block not found')
    }
    else {
        $blockHashes['handoff-contract.md (SSOT)'] = Get-Sha256Hex $block
    }
}

$variants = @{}
foreach ($k in $blockHashes.Keys) {
    $h = $blockHashes[$k]
    if (-not $variants.ContainsKey($h)) { $variants[$h] = @() }
    $variants[$h] += $k
}
if ($variants.Count -gt 1) {
    foreach ($h in ($variants.Keys | Sort-Object)) {
        $names = @($variants[$h] | Sort-Object) -join ', '
        $problems += ('block drift, variant ' + $h.Substring(0, 12) + ' in: ' + $names)
    }
}
elseif ($variants.Count -eq 1) {
    $only = @($variants.Keys)[0]
    $count = @($variants[$only]).Count
    Write-Host ('       (' + $count + ' identical copies, sha256 ' + $only.Substring(0, 12) + ')')
}

Write-Check 2 'Handoff contract block (byte-identical copies + SSOT)' $problems

# ----------------------------------------------------------------------------
# 3/7 Badge family map
# ----------------------------------------------------------------------------

$problems = @()

foreach ($f in $AgentFiles) {
    $name = $f.BaseName
    if (-not $BadgeMap.ContainsKey($name)) {
        $problems += ($f.Name + ': no badge mapping - add ''' + $name + ''' to $BadgeMap')
        continue
    }
    $fm = Get-FrontMatterText (Read-LinesUtf8 $f.FullName)
    $m = [regex]::Match($fm, '(?m)^description:[ \t]*(.*)$')
    if (-not $m.Success) {
        $problems += ($f.Name + ': no description: line in frontmatter')
        continue
    }
    $cp = Get-LeadingCodePoint $m.Groups[1].Value
    $expected = [int]$BadgeMap[$name]
    if ($cp -ne $expected) {
        $problems += ($f.Name + ': description badge U+' + $cp.ToString('X4') + ' != expected U+' + $expected.ToString('X4'))
    }
}

Write-Check 3 'Badge family map (frontmatter description emoji)' $problems

# ----------------------------------------------------------------------------
# 4/7 Model whitelist
# ----------------------------------------------------------------------------

$problems = @()

foreach ($f in $AgentFiles) {
    $fm = Get-FrontMatterText (Read-LinesUtf8 $f.FullName)
    $m = [regex]::Match($fm, '(?m)^model:[ \t]*(.*)$')
    if (-not $m.Success) { continue }   # missing model: is reported by check 7
    $model = $m.Groups[1].Value.Trim()
    if ($model.Length -eq 0) { continue }
    if ($ModelWhitelist -notcontains $model) {
        $problems += ($f.Name + ': model ''' + $model + ''' is not in the whitelist')
    }
}

Write-Check 4 'Model whitelist (frontmatter model)' $problems

# ----------------------------------------------------------------------------
# 5/7 Table reconciliation
# ----------------------------------------------------------------------------

$problems = @()
$DocRelPaths = @('AGENTS.md', 'README.md', 'README.en.md')

foreach ($doc in $DocRelPaths) {
    $docPath = Join-Path $RepoRoot $doc
    if (-not (Test-Path -LiteralPath $docPath)) {
        $problems += ($doc + ' is missing')
        continue
    }
    $lines = Read-LinesUtf8 $docPath
    $rowNames = @{}
    foreach ($line in $lines) {
        $t = $line.TrimStart()
        if (-not $t.StartsWith('|')) { continue }
        if ($t -cmatch '^\|[\s\-:|]*$') { continue }   # separator row
        foreach ($m in [regex]::Matches($t, '([A-Za-z][A-Za-z0-9_.-]*)\.md')) {
            $rowNames[$m.Groups[1].Value] = $true
        }
        foreach ($m in [regex]::Matches($t, '[A-Za-z][A-Za-z0-9_-]*')) {
            $tok = Get-AgentLikeToken $m.Value
            if ($tok -ne '') { $rowNames[$tok] = $true }
        }
    }

    foreach ($n in $AgentNames) {
        if (-not $rowNames.ContainsKey($n)) {
            $problems += ($doc + ': missing table row for ' + $n)
        }
    }
    foreach ($n in ($rowNames.Keys | Sort-Object)) {
        if ($AgentNameSet.ContainsKey($n)) { continue }
        if ($NonAgentMdNames.ContainsKey($n)) { continue }   # e.g. README.md links
        $problems += ($doc + ': ghost table row for unknown agent ''' + $n + '''')
    }
}

Write-Check 5 'Table reconciliation (docs vs agents/ both directions)' $problems

# ----------------------------------------------------------------------------
# 6/7 Stale-claim scan
# ----------------------------------------------------------------------------

$problems = @()

foreach ($f in $AllMdFiles) {
    $text = Read-TextUtf8 $f.FullName
    foreach ($phrase in $BannedPhrases) {
        $idx = $text.IndexOf($phrase, [System.StringComparison]::Ordinal)
        if ($idx -ge 0) {
            $lineNo = ([regex]::Matches($text.Substring(0, $idx), "`n")).Count + 1
            $rel = $f.FullName.Substring($RepoRoot.Length).TrimStart([char[]]@('\', '/'))
            $problems += ($rel + ':' + $lineNo + ' contains banned phrase ''' + $phrase + '''')
        }
    }
}

$agentsMdPath = Join-Path $RepoRoot 'AGENTS.md'
if (Test-Path -LiteralPath $agentsMdPath) {
    if (-not (Read-TextUtf8 $agentsMdPath).Contains('All 39 Agents')) {
        $problems += ('AGENTS.md: heading ''All 39 Agents'' not found (update the count)')
    }
}
else {
    $problems += ('AGENTS.md is missing')
}

Write-Check 6 'Stale-claim scan (banned phrases + agent-count heading)' $problems

# ----------------------------------------------------------------------------
# 7/7 Frontmatter integrity
# ----------------------------------------------------------------------------

$problems = @()

foreach ($f in $AgentFiles) {
    $name = $f.BaseName
    $isPrimary = $PrimaryNames -contains $name
    $fm = Get-FrontMatterText (Read-LinesUtf8 $f.FullName)
    if ($fm.Length -eq 0) {
        $problems += ($f.Name + ': no YAML frontmatter')
        continue
    }

    if (-not [regex]::IsMatch($fm, '(?m)^description:[ \t]*\S')) {
        $problems += ($f.Name + ': frontmatter missing description')
    }

    $m = [regex]::Match($fm, '(?m)^mode:[ \t]*(\S+)')
    if (-not $m.Success) {
        $problems += ($f.Name + ': frontmatter missing mode')
    }
    else {
        $mode = $m.Groups[1].Value.Trim()
        if ($isPrimary -and $mode -ne 'primary') {
            $problems += ($f.Name + ': primary must use mode: primary (found ''' + $mode + ''')')
        }
        if ((-not $isPrimary) -and $mode -ne 'subagent') {
            $problems += ($f.Name + ': subagent must use mode: subagent (found ''' + $mode + ''')')
        }
    }

    if (-not [regex]::IsMatch($fm, '(?m)^model:[ \t]*\S')) {
        $problems += ($f.Name + ': frontmatter missing model')
    }

    $hasPermissions = [regex]::IsMatch($fm, '(?m)^permissions:[ \t]*')
    if ($isPrimary) {
        if ($hasPermissions) {
            $problems += ($f.Name + ': primary must not declare a permissions block')
        }
    }
    else {
        if (-not $hasPermissions) {
            $problems += ($f.Name + ': subagent must declare a permissions block')
        }
        $denySubagent = 'action:[ \t]*subagent\b(?:(?!action:)[\s\S])*?effect:[ \t]*deny'
        if (-not [regex]::IsMatch($fm, $denySubagent)) {
            $problems += ($f.Name + ': subagent must deny ''action: subagent'' (effect: deny)')
        }
    }
}

Write-Check 7 'Frontmatter integrity (description/mode/model/permissions)' $problems

# ----------------------------------------------------------------------------
# Summary
# ----------------------------------------------------------------------------

Write-Host ''
if ($script:FailCount -eq 0) {
    Write-Host ($script:OkMark + ' SUMMARY: all 7 checks passed (' + $AgentNames.Count + ' agents, ' + $SubFiles.Count + ' subagent contract copies)')
    exit 0
}
else {
    Write-Host ($script:FailMark + ' SUMMARY: ' + $script:FailCount + ' of 7 checks failed')
    exit 1
}
