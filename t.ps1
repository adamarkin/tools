$Host.UI.RawUI.WindowTitle='dev'; Clear-Host
Add-Type -Namespace Win32 -Name Power -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint f);'
# ES_CONTINUOUS|ES_SYSTEM_REQUIRED|ES_DISPLAY_REQUIRED (0x80000003): keep PC and screen awake while running
[void][Win32.Power]::SetThreadExecutionState(2147483651)
$code = @(
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
'    total = 0.0',
'    for inv in invoices:',
'        if not inv.paid:',
'            total += inv.amount',
'    return round(total, 2)',
'',
'def group_by_customer(invoices):',
'    result = {}',
'    for inv in invoices:',
'        result.setdefault(inv.customer, []).append(inv)',
'    return result',
'',
'def main():',
'    invoices = load_invoices("data/invoices.json")',
'    groups = group_by_customer(invoices)',
'    for name, items in groups.items():',
'        print(f"{name}: {total_unpaid(items):,.2f}")',
'',
'if __name__ == "__main__":',
'    main()',
'',
''
)
try {
  while ($true) {
    foreach ($line in $code) {
      $color = if ($line -match '^\s*(def|class|import|from|if|for|with|return)\b') {'Cyan'} elseif ($line -match '^\s*#|^@') {'DarkGray'} else {'Green'}
      [Console]::ForegroundColor = $color
      foreach ($ch in $line.ToCharArray()) {
        [Console]::Write($ch)
        $d = Get-Random -Minimum 25 -Maximum 110
        if ($ch -in ' ','(',',','.') { $d += Get-Random -Minimum 0 -Maximum 80 }
        Start-Sleep -Milliseconds $d
      }
      [Console]::WriteLine()
      Start-Sleep -Milliseconds (Get-Random -Minimum 150 -Maximum 700)
    }
    Start-Sleep -Milliseconds 800
  }
} finally { [void][Win32.Power]::SetThreadExecutionState(2147483648); [Console]::ResetColor() }
