$Host.UI.RawUI.WindowTitle='dev'; Clear-Host
Add-Type -Namespace Win32 -Name Power -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint f);'
# ES_CONTINUOUS|ES_SYSTEM_REQUIRED|ES_DISPLAY_REQUIRED (0x80000003): keep PC and screen awake while running
[void][Win32.Power]::SetThreadExecutionState(2147483651)

$blocks = @(
  @{ file='invoices.py'
     code=@(
       'import os, json, logging',
       'from dataclasses import dataclass',
       '',
       'logger = logging.getLogger(__name__)',
       '',
       '@dataclass',
       'class Invoice:',
       '    id: int',
       '    customer: str',
       '    amount: float',
       '    paid: bool = False',
       '',
       'def load_invoices(path):',
       '    if not os.path.exists(path):',
       '        logger.warning("file not found: %s", path)',
       '        return []',
       '    with open(path, encoding="utf-8") as f:',
       '        raw = json.load(f)',
       '    return [Invoice(**item) for item in raw]',
       '',
       'def total_unpaid(invoices):',
       '    return round(sum(i.amount for i in invoices if not i.paid), 2)')
     log=@('INFO  loaded 42 invoices from data/invoices.json','INFO  3 customers, 11 unpaid','INFO  total unpaid: 18,450.00','OK    done in 0.31s') },
  @{ file='report.py'
     code=@(
       'from invoices import load_invoices, total_unpaid',
       '',
       'def group_by_customer(invoices):',
       '    result = {}',
       '    for inv in invoices:',
       '        result.setdefault(inv.customer, []).append(inv)',
       '    return result',
       '',
       'def main():',
       '    invoices = load_invoices("data/invoices.json")',
       '    for name, items in group_by_customer(invoices).items():',
       '        print(f"{name}: {total_unpaid(items):,.2f}")',
       '',
       'if __name__ == "__main__":',
       '    main()')
     log=@('Alpha Co: 6,200.00','Beta Ltd: 9,050.50','Gamma JSC: 3,199.50','OK    done in 0.18s') }
)

function Pause-Ms($min, $max) { Start-Sleep -Milliseconds (Get-Random -Minimum $min -Maximum $max) }

function Blink($seconds) {
  $end = (Get-Date).AddSeconds($seconds)
  while ((Get-Date) -lt $end) {
    [Console]::Write('_'); Start-Sleep -Milliseconds 500
    [Console]::Write("`b `b"); Start-Sleep -Milliseconds 500
  }
}

function Back($n) { for ($i = 0; $i -lt $n; $i++) { [Console]::Write("`b `b"); Pause-Ms 40 90 } }

function Type-Char($ch) {
  [Console]::Write($ch)
  $d = Get-Random -Minimum 30 -Maximum 120
  if ($ch -in ' ','(',',','.',':','=') { $d += Get-Random -Minimum 0 -Maximum 90 }
  if ((Get-Random -Maximum 40) -eq 0) { $d += Get-Random -Minimum 250 -Maximum 700 }  # hesitation
  Start-Sleep -Milliseconds $d
}

function Type-Line($line) {
  $color = if ($line -match '^\s*(def|class|import|from|if|for|with|return)\b') {'Cyan'} elseif ($line -match '^\s*#|^@') {'DarkGray'} else {'Green'}
  [Console]::ForegroundColor = $color
  $chars = $line.ToCharArray()
  $i = 0
  while ($i -lt $chars.Length) {
    $ch = $chars[$i]
    # typo: wrong letter, notice, backspace, retype
    if ($ch -match '[a-z]' -and (Get-Random -Maximum 28) -eq 0) {
      $wrong = [char](Get-Random -Minimum 97 -Maximum 123)
      Type-Char $wrong
      $extra = Get-Random -Minimum 0 -Maximum 3
      for ($k = 1; $k -le $extra -and ($i + $k) -lt $chars.Length; $k++) { Type-Char $chars[$i + $k] }
      Pause-Ms 200 600
      Back (1 + $extra)
    }
    Type-Char $ch
    $i++
  }
  # sometimes delete the whole line's last word and retype it
  if ($line.Length -gt 12 -and (Get-Random -Maximum 12) -eq 0) {
    $m = [regex]::Match($line, '\w+\W*$')
    if ($m.Success -and $m.Length -le 12) {
      Pause-Ms 400 1000
      Back $m.Length
      Pause-Ms 300 800
      foreach ($c in $m.Value.ToCharArray()) { Type-Char $c }
    }
  }
  [Console]::WriteLine()
  Pause-Ms 150 900
  if ((Get-Random -Maximum 6) -eq 0) { Blink (Get-Random -Minimum 2 -Maximum 6) }  # thinking
}

function Run-Command($cmd, $log) {
  [Console]::ForegroundColor = 'White'
  [Console]::Write('PS> ')
  foreach ($c in $cmd.ToCharArray()) { Type-Char $c }
  Pause-Ms 300 900
  [Console]::WriteLine()
  Pause-Ms 400 1200
  foreach ($l in $log) {
    [Console]::ForegroundColor = if ($l -like 'OK*') { 'Green' } elseif ($l -like 'WARN*') { 'Yellow' } else { 'Gray' }
    $stamp = (Get-Date).ToString('HH:mm:ss')
    [Console]::WriteLine("[$stamp] $l")
    Pause-Ms 200 900
  }
  [Console]::WriteLine()
  Blink (Get-Random -Minimum 4 -Maximum 10)
}

try {
  while ($true) {
    foreach ($b in $blocks) {
      [Console]::ForegroundColor = 'DarkGray'
      [Console]::WriteLine("# --- $($b.file) ---")
      Pause-Ms 500 1500
      foreach ($line in $b.code) { Type-Line $line }
      Blink (Get-Random -Minimum 2 -Maximum 5)
      Run-Command ('python ' + $b.file) $b.log
    }
    Clear-Host
  }
} finally { [void][Win32.Power]::SetThreadExecutionState(2147483648); [Console]::ResetColor() }
