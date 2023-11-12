# PVA - Dluznicek
## To make execution of the script possible:
## Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

$Command = $true

# People Hashtable
$People = @{
    Kristyna = 0
    Adam = 0
    Jan = 0
    Misa = 0
    David = 0
}

# Empty hashtable for Payments and Debt 
# Hashtable structure -> HT = @{$People[$Person] = @{$People[$Person2] = $Amount}}
$InDebt = @{}
$Payments = @{}
$Settled = @{}


function Add-Person {
    param([string]$Person)
    if (!$People.ContainsKey($Person)) {
        $People.Add($Person, 0)
        Write-Host $("Osoba {0} pridan" -f $Person) -ForegroundColor Green
    } else {
        Write-Error "Zadavana osoba jiz existuje..."
    }
}

function Add-Payment {
    param([string]$ToWhom)
    if ($People.ContainsKey($ToWhom)) {
        $TMP_HT = @{} 
        $TMP_HT2 = @{} 
            [string]$Who = Read-Host $("Kdo dluzi {0}?" -f $ToWhom)
            if ($People.ContainsKey($Who) -and ($ToWhom -ne $Who)) {
                [int]$Amount = Read-Host $("Kolik {0} dluzi {1}?" -f $Who, $ToWhom)
                if (!($Payments.ContainsKey($ToWhom))) {
                    $TMP_HT.Add($Who, $Amount)
                } else {
                    $TMP_HT[$Who] = ($TMP_HT[$Who] += $Amount)
                }

                $TMP_HT2.Add($ToWhom, $Amount)
                if (!($InDebt.ContainsKey($Who))) {
                    $InDebt.Add($Who, $TMP_HT2)
                } else {
                    foreach ($name2 in $TMP_HT2.Keys) {
                        $InDebt[$Who][$name2] += $TMP_HT2[$name2]
                    }
                }
            $People[$Who] += $Amount * -1
        }
        $People[$ToWhom] += ($TMP_HT.Values | Measure-Object -Sum | Select-Object -expand Sum)
        
        # If person already paid, only append indebted
        if (!($Payments.ContainsKey($ToWhom))) {
            $Payments.Add($ToWhom, $TMP_HT)
        } else {
            foreach ($name in $TMP_HT.Keys) {
                $Payments[$ToWhom][$name] += $TMP_HT[$name]
            }
        }
    } else {
        Write-Error "Zadana osoba neexistuje... / Osoba nemuze dluzit sama sobe..." 
    }
}

function Concat {
    Write-Host $("Kdo`t`tKomu`t`tKolik")
    foreach ($name in $Payments.Keys) {
        #Write-Host $("1: {0} ->" -f $name)
        if ($Payments.ContainsKey($name) -and $InDebt.Values.ContainsKey($name)) {
            foreach ($name2 in $InDebt.Keys) {
            #Write-Host $("2: {0} -> {1}" -f $name, $name2)
                if ($Payments.Values.ContainsKey($name2) -and $InDebt.ContainsKey($name2) -and ($name -ne $name2) -and ($InDebt[$name2][$name]) -gt 0) {
                    Write-Host $("{0} `t -> `t {1} `t = `t {2}" -f $name2, $name, $InDebt[$name2][$name])
                }
            }
        }
    }
}

function List-All {
    Write-Output "`n"
    Write-Output "Osoba`tZaplaceno"
    Write-Output "--------------"
    foreach ($key in $People.Keys) {
        Write-Output $("{0} - {1}" -f $key, $People[$key])
    }

    Write-Output "`n"
    Write-Output "Osoba`tJe dluznikem"
    Write-Output "--------------"
    foreach ($name in $InDebt.Keys) {
        Write-Output $("{0}" -f $name)
        foreach ($name2 in $InDebt[$name].Keys) {
        Write-Output $("`t{0} - {1}" -f $name2, $InDebt[$name][$name2])
        }
    }

    Write-Output "`n"
    Write-Output "Osoba`tDluznik"
    Write-Output "--------------"

    foreach ($name in $Payments.Keys) {
        Write-Output $("{0}" -f $name)
        foreach ($name2 in $Payments[$name].Keys) {
        Write-Output $("`t{0} - {1}" -f $name2, $Payments[$name][$name2])
        }
    }

}

# If $Command true (default = true)
while ($Command) {
    # User enters commands
    $UserCommand = Read-Host "Pro pokracovani zadejte prikaz, nebo si vypiste pomoc (`"HELP`")"
    Write-Output "`n"
    switch ($UserCommand.ToString()) {
        "ADD" {
            $TMP_PERSON = Read-Host "Zadejte jmeno osoby, kterou chcete přidat"
            Add-Person($TMP_PERSON)
            Remove-Variable TMP_PERSON
            Break
        }
        "PAYMENT" {
            $Next = $true
            while ($Next) {
                $TMP_NAME = Read-Host "Zadejte jmeno osoby, ktera platila"
                Add-Payment($TMP_NAME)
                Remove-Variable TMP_NAME
                switch (Read-Host "Pridat dalsiho dluznika? [Y/N]") {
                    "Y" { Write-Host "`n" }
                    Default {$Next = $false}
                }
            }
            Break
        }
        "LIST" {
            List-All
            Break
        }
        "SETTLE" {
            Write-Host -ForegroundColor Yellow "------------------------"
            Concat
            Write-Host -ForegroundColor Yellow "------------------------"
            Break
        }
        "HELP" {
            Write-Host "Mozne prikazy jsou: {ADD|PAYMENT|LIST|SETTLE|END|HELP}" -ForegroundColor Yellow
            Break
        }
        # User wants to exit, $Command set to false, while loop ends
        "END" {
            $Command = $false
            Break
        }
        Default {
            Write-Host "Neplatny prikaz... Vypiste si pomoc..."
            exit 1
            Break
        }
    }
    Write-Output "`n"
}
