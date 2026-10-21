#Requires -Version 5.1
<#
.SYNOPSIS
    Mechanical checker for subagent handoff receipts.

.DESCRIPTION
    Every subagent final output must open with the four-field receipt header
    defined in references/workflow/handoff-contract.md:

        ---
        **Agent**: code-generator
        **Status**: done
        **Suggest Next**: reviewer
        **Context For Next**: implementation done, tests pending
        ---

    This script batch-checks the mechanical part of that contract so the
    primary agent does not have to eyeball every receipt. A receipt block
    starts at a line whose trimmed text begins with '**Agent**:' and runs until
    the next such line or the end of file (one file may hold several
    receipts). Checks per block:

      [1] FAIL  all four fields present: **Agent**: / **Status**: /
                **Suggest Next**: / **Context For Next**:
      [2] FAIL  **Status**: is exactly one literal value matching
                ^**Status**:\s*(done|partial|blocked|needs_input)\s*$
                Leftover menu text such as [done | partial | ...] is reported
                as 'left bracket menu unfilled'.
      [3] FAIL  Status partial/blocked but Context For Next is missing, empty,
                or still the unfilled [placeholder] text.
      [4] FAIL  'Overall Status' appears anywhere in the block: legacy
                vocabulary, use Overall Gate (spec-reviewer).
      [5] WARN  bare claim-level 'Status: pass' / 'Status: fail' on a line
                other than the metadata **Status**: header line: claim results
                must use Claim Status (spec-reviewer).
      [6] WARN  Status done but Suggest Next is neither 'none' nor a
                comma-separated list of agent-shaped names.

    Any FAIL item makes the run exit 1. WARN items are printed but never fail
    the run. Line 1..n numbers shown in messages are absolute file line
    numbers.

    ENCODING WARNING: Windows PowerShell 5.1 decodes UTF-8 files without BOM
    using the system ANSI codepage (GBK on zh-CN machines), which corrupts CJK
    text and emoji. Every file read therefore goes through
    [System.IO.File]::ReadAllText / ReadAllLines with an explicit UTF-8
    encoding, and this script's own source is pure ASCII.

.PARAMETER Path
    One or more files, directories or wildcard patterns (e.g. receipts\*.txt).
    Directories pick up every file inside them (top level only). A literal
    path and a pattern can be mixed in one call.

.EXAMPLE
    echo receipt > temp.txt; pwsh check-receipt.ps1 -Path temp.txt

.EXAMPLE
    pwsh -NoProfile -File scripts/check-receipt.ps1 -Path receipts\*.txt

.EXAMPLE
    powershell -NoProfile -File scripts/check-receipt.ps1 -Path a.txt,b.txt

.OUTPUTS
    Human-readable per-file / per-block PASS-FAIL-WARN report on stdout.

.NOTES
    Exit codes: 0 = no FAIL item found, 1 = at least one FAIL item (or no
    receipt block at all). WARN items do not affect the exit code.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string[]]$Path
)

Set-StrictMode -Version 1.0
$ErrorActionPreference = 'Stop'

# ----------------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------------

$script:Utf8 = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false
$script:FailItems = 0
$script:WarnItems = 0
$script:BlocksTotal = 0
$script:BlocksPass = 0
$script:BlocksWarnOnly = 0
$script:BlocksFail = 0

# The four literal Status values defined by the handoff contract.
$StatusValues = @('done', 'partial', 'blocked', 'needs_input')

# Exact shape of a valid metadata Status line (applied to the trimmed line).
$StatusLinePattern = '^\*\*Status\*\*:\s*(done|partial|blocked|needs_input)\s*$'

# Bare claim-level status results, e.g. 'Status: pass' on a claim line. The
# lookbehinds skip the preferred 'Claim Status: pass' form and words like
# 'OverallStatus'.
$BareClaimStatusPattern = "(?<!Claim )(?<![A-Za-z])Status[ \t]*:[ \t]*(pass|fail)\b"

# ----------------------------------------------------------------------------
# Helpers (all reads go through explicit UTF-8; see ENCODING WARNING above)
# ----------------------------------------------------------------------------

function Read-LinesUtf8 {
    param([string]$FilePath)
    $lines = [System.IO.File]::ReadAllLines($FilePath, $script:Utf8)
    if ($lines.Count -gt 0 -and $lines[0].Length -gt 0 -and [int][char]$lines[0][0] -eq 0xFEFF) {
        $lines[0] = $lines[0].Substring(1)
    }
    return ,$lines
}

function Get-FieldValue {
    # Text after the first ':' of the field line, trimmed. Returns '' when the
    # line has no colon at all.
    param([string]$Line)
    $idx = $Line.IndexOf(':')
    if ($idx -lt 0) { return '' }
    return $Line.Substring($idx + 1).Trim()
}

function Test-EmptyValue {
    # True for missing/blank values and for still-unfilled [placeholder] text.
    param([string]$Value)
    if ($null -eq $Value) { return $true }
    $v = $Value.Trim()
    if ($v.Length -eq 0) { return $true }
    if ($v -match '^\[[^]]*\]$') { return $true }
    return $false
}

function Get-ReceiptBlocks {
    # Splits file lines into receipt blocks. A block starts at a line whose
    # trimmed text begins with '**Agent**:' and runs to the next such line or
    # EOF. Returns an array of hashtables: @{ StartLine; Lines }.
    param([string[]]$Lines)
    $blocks = @()
    $cur = $null
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $t = $Lines[$i].TrimStart()
        if ($t.StartsWith('**Agent**:')) {
            if ($null -ne $cur) { $blocks += ,$cur }
            $cur = @{ StartLine = $i + 1; Lines = @() }
        }
        if ($null -ne $cur) {
            $cur['Lines'] = @($cur['Lines']) + @($Lines[$i])
        }
    }
    if ($null -ne $cur) { $blocks += ,$cur }
    return ,$blocks
}

function Test-ReceiptBlock {
    # Runs checks [1]-[6] over one receipt block. Returns findings as an array
    # of hashtables: @{ Level = 'FAIL'|'WARN'; Text = ... }.
    param([string[]]$Lines, [int]$StartLine)
    $findings = @()

    $agentLine = $null
    $statusLine = $null
    $suggestLine = $null
    $contextLine = $null
    $statusLineIdx = -1

    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $t = $Lines[$i].TrimStart()
        if ($null -eq $agentLine -and $t.StartsWith('**Agent**:')) {
            $agentLine = $Lines[$i]
        }
        elseif ($null -eq $statusLine -and $t.StartsWith('**Status**:')) {
            $statusLine = $Lines[$i]
            $statusLineIdx = $i
        }
        elseif ($null -eq $suggestLine -and $t.StartsWith('**Suggest Next**:')) {
            $suggestLine = $Lines[$i]
        }
        elseif ($null -eq $contextLine -and $t.StartsWith('**Context For Next**:')) {
            $contextLine = $Lines[$i]
        }
    }

    # [1] four fields present
    $missing = @()
    if ($null -eq $agentLine) { $missing += '**Agent**:' }
    if ($null -eq $statusLine) { $missing += '**Status**:' }
    if ($null -eq $suggestLine) { $missing += '**Suggest Next**:' }
    if ($null -eq $contextLine) { $missing += '**Context For Next**:' }
    if ($missing.Count -gt 0) {
        $findings += @{ Level = 'FAIL'; Text = '[1] missing field(s): ' + ($missing -join ', ') }
    }

    $statusVal = ''
    if ($null -ne $statusLine) {
        $statusVal = Get-FieldValue $statusLine

        # [2] Status must be one literal value, never the unfilled bracket menu
        if (($statusVal.IndexOf('[') -ge 0) -or ($statusVal.IndexOf('|') -ge 0)) {
            $findings += @{ Level = 'FAIL'; Text = '[2] left bracket menu unfilled: ' + $statusVal + ' (fill in exactly one literal value)' }
        }
        elseif ($statusLine.Trim() -cnotmatch $StatusLinePattern) {
            $findings += @{ Level = 'FAIL'; Text = '[2] Status must be exactly one of ' + ($StatusValues -join '|') + " (found '" + $statusVal + "')" }
        }
    }

    # [3] partial/blocked require a real gap note in Context For Next
    $statusLower = $statusVal.ToLowerInvariant()
    if ($statusLower -eq 'partial' -or $statusLower -eq 'blocked') {
        if ($null -eq $contextLine) {
            $findings += @{ Level = 'FAIL'; Text = '[3] Status ' + $statusLower + ' requires **Context For Next**: (missing) - name the exact gap + what the next agent must change' }
        }
        elseif (Test-EmptyValue (Get-FieldValue $contextLine)) {
            $findings += @{ Level = 'FAIL'; Text = '[3] Status ' + $statusLower + ' requires a non-empty Context For Next - name the exact gap + what the next agent must change' }
        }
    }

    # [4] legacy vocabulary + [5] bare claim-level Status values
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $absLine = $StartLine + $i
        $line = $Lines[$i]
        if ($line.Contains('Overall Status')) {
            $findings += @{ Level = 'FAIL'; Text = "[4] line " + $absLine + ": 'Overall Status' is legacy vocabulary, use Overall Gate (spec-reviewer)" }
            continue
        }
        if ($i -eq $statusLineIdx) { continue }   # the metadata header line
        foreach ($m in [regex]::Matches($line, $BareClaimStatusPattern)) {
            $findings += @{ Level = 'WARN'; Text = "[5] line " + $absLine + ": bare claim status '" + $m.Value + "' - use Claim Status (spec-reviewer)" }
        }
    }

    # [6] Status done needs a usable Suggest Next
    if ($statusLower -eq 'done') {
        $ok = $false
        $sg = ''
        if ($null -ne $suggestLine) {
            $sg = Get-FieldValue $suggestLine
            if ($sg.ToLowerInvariant() -eq 'none') {
                $ok = $true
            }
            elseif ($sg.Length -gt 0) {
                $ok = $true
                foreach ($tok in ($sg -split ',')) {
                    $t2 = $tok.Trim()
                    if ($t2.StartsWith('@')) { $t2 = $t2.Substring(1) }
                    if ($t2.StartsWith('`')) { $t2 = $t2.Substring(1) }
                    if ($t2.EndsWith('`')) { $t2 = $t2.Substring(0, $t2.Length - 1) }
                    $t2 = $t2.Trim()
                    if ($t2 -cnotmatch '^[A-Za-z][A-Za-z0-9_-]*$') { $ok = $false; break }
                }
            }
        }
        if (-not $ok) {
            $shown = $sg
            if ($null -eq $suggestLine) { $shown = '(field missing)' }
            $findings += @{ Level = 'WARN'; Text = "[6] Status done but Suggest Next is neither 'none' nor an agent-name list (found '" + $shown + "')" }
        }
    }

    return ,$findings
}

# ----------------------------------------------------------------------------
# Resolve input files (literal paths, directories and globs, multiple entries)
# ----------------------------------------------------------------------------

$resolved = @{}
$badInput = 0

foreach ($entry in $Path) {
    if ($entry -match '[\*\?]') {
        $hits = @(Get-ChildItem -Path $entry -File -ErrorAction SilentlyContinue)
        if ($hits.Count -eq 0) {
            Write-Host ("[FAIL] no file matches pattern '" + $entry + "'")
            $badInput = $badInput + 1
        }
        foreach ($h in $hits) { $resolved[$h.FullName] = $h }
    }
    elseif (Test-Path -LiteralPath $entry -PathType Container) {
        $hits = @(Get-ChildItem -LiteralPath $entry -File)
        if ($hits.Count -eq 0) {
            Write-Host ("[FAIL] directory holds no file: '" + $entry + "'")
            $badInput = $badInput + 1
        }
        foreach ($h in $hits) { $resolved[$h.FullName] = $h }
    }
    elseif (Test-Path -LiteralPath $entry -PathType Leaf) {
        $h = Get-Item -LiteralPath $entry
        $resolved[$h.FullName] = $h
    }
    else {
        Write-Host ("[FAIL] path not found: '" + $entry + "'")
        $badInput = $badInput + 1
    }
}

$files = @($resolved.Keys | Sort-Object | ForEach-Object { $resolved[$_] })

if ($files.Count -eq 0) {
    Write-Host ''
    Write-Host ('FAIL: no input file to check')
    exit 1
}

# ----------------------------------------------------------------------------
# Check every file / every receipt block
# ----------------------------------------------------------------------------

foreach ($f in $files) {
    Write-Host ('file: ' + $f.FullName)
    $lines = Read-LinesUtf8 $f.FullName
    # Note: Get-ReceiptBlocks returns a comma-wrapped array (so 0/1-block
    # results stay arrays); assign it directly instead of @(...) - the array
    # subexpression around a command would wrap that array in another array.
    $blocks = Get-ReceiptBlocks $lines
    if ($null -eq $blocks) { $blocks = @() }

    if ($blocks.Count -eq 0) {
        Write-Host ('  [FAIL] no receipt block found (expected a line starting with **Agent**:)')
        $script:FailItems = $script:FailItems + 1
        $script:BlocksFail = $script:BlocksFail + 1
        Write-Host ''
        continue
    }

    $bn = 0
    foreach ($blk in $blocks) {
        $bn = $bn + 1
        $script:BlocksTotal = $script:BlocksTotal + 1
        $blkLines = @($blk['Lines'])
        $startLine = [int]$blk['StartLine']

        $agent = ''
        foreach ($ln in $blkLines) {
            if ($ln.TrimStart().StartsWith('**Agent**:')) { $agent = Get-FieldValue $ln; break }
        }
        if ($agent.Length -eq 0) { $agent = '(unfilled)' }

        Write-Host ('  block ' + $bn + ' (line ' + $startLine + '): ' + $agent)

        $findings = Test-ReceiptBlock $blkLines $startLine
        if ($null -eq $findings) { $findings = @() }
        $blockFails = 0
        $blockWarns = 0
        foreach ($fd in $findings) {
            Write-Host ('    [' + $fd['Level'] + '] ' + $fd['Text'])
            if ($fd['Level'] -eq 'FAIL') {
                $blockFails = $blockFails + 1
                $script:FailItems = $script:FailItems + 1
            }
            else {
                $blockWarns = $blockWarns + 1
                $script:WarnItems = $script:WarnItems + 1
            }
        }

        if ($blockFails -gt 0) {
            $script:BlocksFail = $script:BlocksFail + 1
            Write-Host ('    result: FAIL (' + $blockFails + ' fail item(s), ' + $blockWarns + ' warn item(s))')
        }
        elseif ($blockWarns -gt 0) {
            $script:BlocksWarnOnly = $script:BlocksWarnOnly + 1
            Write-Host ('    result: PASS with warnings (' + $blockWarns + ' warn item(s))')
        }
        else {
            $script:BlocksPass = $script:BlocksPass + 1
            Write-Host ('    result: PASS')
        }
    }
    Write-Host ''
}

# ----------------------------------------------------------------------------
# Summary
# ----------------------------------------------------------------------------

Write-Host ('----')
Write-Host ('SUMMARY: files ' + $files.Count + ', blocks ' + $script:BlocksTotal + ' | PASS ' + $script:BlocksPass + ', WARN-only ' + $script:BlocksWarnOnly + ', FAIL ' + $script:BlocksFail + ' | fail items ' + $script:FailItems + ', warn items ' + $script:WarnItems)

if ($script:FailItems -gt 0 -or $badInput -gt 0) {
    Write-Host ('FAIL: receipt checks failed')
    exit 1
}
Write-Host ('PASS: every receipt block passed the mechanical checks (WARN items above are advisory)')
exit 0
