[CmdletBinding()]
param(
    [string]$Phrase = 'Please review this contract carefully.',
    [int]$Rounds = 2,
    [switch]$AsJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms

$signature = @"
using System;
using System.Runtime.InteropServices;

public static class ClipboardWin32 {
  [DllImport("user32.dll", SetLastError = true)]
  public static extern uint GetClipboardSequenceNumber();

  [DllImport("user32.dll", SetLastError = true)]
  public static extern IntPtr GetForegroundWindow();

  [DllImport("user32.dll", SetLastError = true)]
  public static extern bool OpenClipboard(IntPtr hWndNewOwner);

  [DllImport("user32.dll", SetLastError = true)]
  public static extern bool EmptyClipboard();

  [DllImport("user32.dll", SetLastError = true)]
  public static extern bool CloseClipboard();
}
"@

Add-Type $signature

function Clear-ClipboardNative {
    $hwnd = [ClipboardWin32]::GetForegroundWindow()
    for ($attempt = 0; $attempt -lt 10; $attempt++) {
        if ([ClipboardWin32]::OpenClipboard($hwnd)) {
            try {
                [ClipboardWin32]::EmptyClipboard() | Out-Null
                return $true
            }
            finally {
                [ClipboardWin32]::CloseClipboard() | Out-Null
            }
        }
        Start-Sleep -Milliseconds 20
    }
    return $false
}

function Set-ClipboardText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    [System.Windows.Forms.Clipboard]::SetText($Text)
    $deadline = [DateTime]::UtcNow.AddSeconds(2)
    while ([DateTime]::UtcNow -lt $deadline) {
        if ((Get-ClipboardText) -eq $Text) {
            return
        }
        Start-Sleep -Milliseconds 20
    }
    throw "Failed to persist clipboard text."
}

function Get-ClipboardText {
    if ([System.Windows.Forms.Clipboard]::ContainsText()) {
        return [System.Windows.Forms.Clipboard]::GetText()
    }
    return ''
}

function Poll-ClipboardText {
    param(
        [uint32]$SequenceBefore
    )

    $deadline = [DateTime]::UtcNow.AddMilliseconds(900)
    while ([DateTime]::UtcNow -lt $deadline) {
        if ([ClipboardWin32]::GetClipboardSequenceNumber() -ne $SequenceBefore) {
            Start-Sleep -Milliseconds 40
            $text = Get-ClipboardText
            if ($text -ne '') {
                return $text
            }
        }
        Start-Sleep -Milliseconds 20
    }
    return ''
}

$results = New-Object System.Collections.Generic.List[object]

for ($round = 1; $round -le $Rounds; $round++) {
    Set-ClipboardText -Text $Phrase
    $before = Get-ClipboardText
    $clipboardCleared = Clear-ClipboardNative
    $sequenceBefore = [ClipboardWin32]::GetClipboardSequenceNumber()

    # 模擬使用者這次選到的文字，剛好和 clipboard 先前內容相同。
    Set-ClipboardText -Text $Phrase
    $selected = (Poll-ClipboardText -SequenceBefore $sequenceBefore).Trim()

    $results.Add([pscustomobject]@{
        Round             = $round
        ClipboardCleared  = $clipboardCleared
        Before            = $before
        Selected          = $selected
        OldLogicWouldFail = ($selected.Length -eq 0 -or $selected -eq $before.Trim())
        NewLogicWouldFail = ($selected.Length -eq 0)
    })
}

if ($AsJson) {
    $results | ConvertTo-Json -Depth 3
}
else {
    $results
}
