[CmdletBinding()]
param(
    [ValidateSet("pdf", "clean")]
    [string]$Action = "pdf"
)

$ErrorActionPreference = "Stop"
$Main = "tgmManual"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

function Assert-Tool {
    param([string]$Name)

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required tool '$Name' was not found on PATH."
    }
}

function Invoke-Tool {
    param(
        [string]$Name,
        [string[]]$Arguments
    )

    & $Name @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Name failed with exit code $LASTEXITCODE."
    }
}

Push-Location $Root
try {
    switch ($Action) {
        "pdf" {
            foreach ($Tool in @("pdflatex", "bibtex", "makeglossaries", "makeindex")) {
                Assert-Tool -Name $Tool
            }

            Invoke-Tool -Name "pdflatex" -Arguments @(
                "-interaction=nonstopmode",
                "-halt-on-error",
                "$Main.tex"
            )
            Invoke-Tool -Name "bibtex" -Arguments @($Main)
            Invoke-Tool -Name "makeglossaries" -Arguments @($Main)
            Invoke-Tool -Name "makeindex" -Arguments @("$Main.idx")
            Invoke-Tool -Name "pdflatex" -Arguments @(
                "-interaction=nonstopmode",
                "-halt-on-error",
                "$Main.tex"
            )
            Invoke-Tool -Name "pdflatex" -Arguments @(
                "-interaction=nonstopmode",
                "-halt-on-error",
                "$Main.tex"
            )
        }
        "clean" {
            Assert-Tool -Name "latexmk"
            Invoke-Tool -Name "latexmk" -Arguments @("-c", "$Main.tex")

            foreach ($Extension in @(
                "acn", "acr", "alg", "bbl", "blg", "glg", "glo", "gls",
                "ist", "xdy"
            )) {
                $GeneratedFile = Join-Path $Root "$Main.$Extension"
                Remove-Item -Path $GeneratedFile -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
finally {
    Pop-Location
}
