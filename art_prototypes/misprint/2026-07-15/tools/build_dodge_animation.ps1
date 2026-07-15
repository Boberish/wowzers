param(
    [string]$Source = "outputs/misprint_dodge_test/dodge_pose_sheet_source.png",
    [string]$OutputDirectory = "outputs/misprint_dodge_test"
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$sourcePath = (Resolve-Path -LiteralPath $Source).Path
$outputPath = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputDirectory))
[System.IO.Directory]::CreateDirectory($outputPath) | Out-Null

$sourceImage = [System.Drawing.Bitmap]::new($sourcePath)

try {
    # The generated contact sheet is an exact 3x2 grid. Trim two pixels from
    # each cell edge so the divider rules do not enter the animation frames.
    $columnEdges = @(0, [int][math]::Round($sourceImage.Width / 3.0), [int][math]::Round(2.0 * $sourceImage.Width / 3.0), $sourceImage.Width)
    $rowEdges = @(0, [int][math]::Round($sourceImage.Height / 2.0), $sourceImage.Height)
    $framePaths = [System.Collections.Generic.List[string]]::new()
    $previewFramePaths = [System.Collections.Generic.List[string]]::new()

    for ($row = 0; $row -lt 2; $row++) {
        for ($column = 0; $column -lt 3; $column++) {
            $left = $columnEdges[$column] + 2
            $top = $rowEdges[$row] + 2
            $right = $columnEdges[$column + 1] - 2
            $bottom = $rowEdges[$row + 1] - 2
            $width = $right - $left
            $height = $bottom - $top

            $frame = [System.Drawing.Bitmap]::new($width, $height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $graphics = [System.Drawing.Graphics]::FromImage($frame)
            try {
                $graphics.Clear([System.Drawing.Color]::Transparent)
                $graphics.DrawImage(
                    $sourceImage,
                    [System.Drawing.Rectangle]::new(0, 0, $width, $height),
                    [System.Drawing.Rectangle]::new($left, $top, $width, $height),
                    [System.Drawing.GraphicsUnit]::Pixel
                )
            }
            finally {
                $graphics.Dispose()
            }

            # Convert the flat #ff00ff background to alpha. Because the sprite
            # has a charcoal contour, most antialiased edge pixels are a simple
            # mixture of black and magenta. Unmixing the magenta component keeps
            # the contour dark instead of leaving a neon fringe.
            for ($y = 0; $y -lt $height; $y++) {
                for ($x = 0; $x -lt $width; $x++) {
                    $pixel = $frame.GetPixel($x, $y)
                    $dr = 255 - $pixel.R
                    $dg = $pixel.G
                    $db = 255 - $pixel.B
                    $distance = [math]::Sqrt(($dr * $dr) + ($dg * $dg) + ($db * $db))

                    if ($distance -le 20) {
                        $frame.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
                    }
                    else {
                        $minimumKeyChannel = [double][math]::Min($pixel.R, $pixel.B)
                        $magentaExcess = $minimumKeyChannel - [double]$pixel.G
                        if (($pixel.G -lt 105) -and ($magentaExcess -gt 20)) {
                            $backgroundFraction = [math]::Min(0.985, $magentaExcess / [math]::Max(1.0, 255.0 - $pixel.G))
                            $foregroundFraction = 1.0 - $backgroundFraction
                            $alpha = [int][math]::Round(255.0 * $foregroundFraction)
                            $red = [int][math]::Max(0, [math]::Min(255, [math]::Round(($pixel.R - (255.0 * $backgroundFraction)) / $foregroundFraction)))
                            $green = [int][math]::Max(0, [math]::Min(255, [math]::Round($pixel.G / $foregroundFraction)))
                            $blue = [int][math]::Max(0, [math]::Min(255, [math]::Round(($pixel.B - (255.0 * $backgroundFraction)) / $foregroundFraction)))
                            $frame.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($alpha, $red, $green, $blue))
                        }
                    }
                }
            }

            $frameNumber = ($row * 3) + $column + 1
            $framePath = Join-Path $outputPath ("dodge_frame_{0:D2}.png" -f $frameNumber)
            $frame.Save($framePath, [System.Drawing.Imaging.ImageFormat]::Png)

            # GIF transparency is only one-bit and displays poorly in some
            # clients. Composite a warm paper-colored preview while retaining
            # the transparent PNGs as the actual Godot-ready test frames.
            $previewFrame = [System.Drawing.Bitmap]::new($width, $height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
            $previewGraphics = [System.Drawing.Graphics]::FromImage($previewFrame)
            try {
                $previewGraphics.Clear([System.Drawing.Color]::FromArgb(244, 232, 202))
                $previewGraphics.DrawImageUnscaled($frame, 0, 0)
            }
            finally {
                $previewGraphics.Dispose()
            }
            $previewFramePath = Join-Path $outputPath ("preview_frame_{0:D2}.png" -f $frameNumber)
            $previewFrame.Save($previewFramePath, [System.Drawing.Imaging.ImageFormat]::Png)
            $previewFrame.Dispose()

            $frame.Dispose()
            $framePaths.Add($framePath)
            $previewFramePaths.Add($previewFramePath)
        }
    }
}
finally {
    $sourceImage.Dispose()
}

function New-GifFrame {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [UInt16]$DelayCentiseconds,
        [switch]$FirstFrame
    )

    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $decoder = [System.Windows.Media.Imaging.PngBitmapDecoder]::new(
            $stream,
            [System.Windows.Media.Imaging.BitmapCreateOptions]::PreservePixelFormat,
            [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        )
        $bitmap = $decoder.Frames[0]
        $metadata = [System.Windows.Media.Imaging.BitmapMetadata]::new("gif")
        $metadata.SetQuery("/grctlext/Disposal", [byte]2)
        $metadata.SetQuery("/grctlext/Delay", $DelayCentiseconds)
        if ($FirstFrame) {
            $metadata.SetQuery("/appext/application", [System.Text.Encoding]::ASCII.GetBytes("NETSCAPE2.0"))
            $metadata.SetQuery("/appext/data", [byte[]](3, 1, 0, 0))
        }
        return [System.Windows.Media.Imaging.BitmapFrame]::Create($bitmap, $bitmap.Thumbnail, $metadata, $bitmap.ColorContexts)
    }
    finally {
        $stream.Dispose()
    }
}

# Durations deliberately follow the 30 Hz game cadence: the action snaps through
# the middle poses and holds the readable clearance silhouette for two ticks.
$delays = [UInt16[]](30, 3, 3, 7, 7, 13)
$gifPath = Join-Path $outputPath "dodge_animation_preview.gif"
$encoder = [System.Windows.Media.Imaging.GifBitmapEncoder]::new()

for ($index = 0; $index -lt $previewFramePaths.Count; $index++) {
    $encoder.Frames.Add((New-GifFrame -Path $previewFramePaths[$index] -DelayCentiseconds $delays[$index] -FirstFrame:($index -eq 0)))
}

$outputStream = [System.IO.File]::Create($gifPath)
try {
    $encoder.Save($outputStream)
}
finally {
    $outputStream.Dispose()
}

function Set-GifAnimationTiming {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [UInt16[]]$FrameDelays
    )

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 14 -or [System.Text.Encoding]::ASCII.GetString($bytes, 0, 3) -ne "GIF") {
        throw "Not a valid GIF: $Path"
    }

    $output = [System.IO.MemoryStream]::new()
    try {
        # Header + logical screen descriptor.
        $output.Write($bytes, 0, 13)
        $position = 13

        # Preserve a global color table when present.
        $globalPacked = $bytes[10]
        if (($globalPacked -band 0x80) -ne 0) {
            $globalTableLength = 3 * [math]::Pow(2, (($globalPacked -band 0x07) + 1))
            $output.Write($bytes, $position, [int]$globalTableLength)
            $position += [int]$globalTableLength
        }

        # Infinite-loop application extension.
        $loopExtension = [byte[]](
            0x21, 0xFF, 0x0B,
            0x4E, 0x45, 0x54, 0x53, 0x43, 0x41, 0x50, 0x45, 0x32, 0x2E, 0x30,
            0x03, 0x01, 0x00, 0x00, 0x00
        )
        $output.Write($loopExtension, 0, $loopExtension.Length)

        $frameIndex = 0
        while ($position -lt $bytes.Length) {
            $marker = $bytes[$position]

            if ($marker -eq 0x2C) {
                if ($frameIndex -ge $FrameDelays.Length) {
                    throw "GIF contains more frames than delays."
                }

                $delay = $FrameDelays[$frameIndex]
                $graphicControl = [byte[]](
                    0x21, 0xF9, 0x04, 0x04,
                    [byte]($delay -band 0xFF), [byte](($delay -shr 8) -band 0xFF),
                    0x00, 0x00
                )
                $output.Write($graphicControl, 0, $graphicControl.Length)

                $blockStart = $position
                if (($position + 10) -gt $bytes.Length) { throw "Truncated GIF image descriptor." }
                $localPacked = $bytes[$position + 9]
                $position += 10

                if (($localPacked -band 0x80) -ne 0) {
                    $localTableLength = 3 * [math]::Pow(2, (($localPacked -band 0x07) + 1))
                    $position += [int]$localTableLength
                }

                # LZW minimum code size, followed by data sub-blocks.
                $position += 1
                while ($true) {
                    if ($position -ge $bytes.Length) { throw "Truncated GIF image data." }
                    $blockLength = $bytes[$position]
                    $position += 1
                    if ($blockLength -eq 0) { break }
                    $position += $blockLength
                }

                $output.Write($bytes, $blockStart, $position - $blockStart)
                $frameIndex += 1
            }
            elseif ($marker -eq 0x21) {
                # Preserve any non-frame extension emitted by the encoder.
                $blockStart = $position
                $position += 2
                while ($true) {
                    if ($position -ge $bytes.Length) { throw "Truncated GIF extension." }
                    $blockLength = $bytes[$position]
                    $position += 1
                    if ($blockLength -eq 0) { break }
                    $position += $blockLength
                }
                $output.Write($bytes, $blockStart, $position - $blockStart)
            }
            elseif ($marker -eq 0x3B) {
                $output.WriteByte(0x3B)
                $position += 1
                break
            }
            else {
                throw ("Unexpected GIF marker 0x{0:X2} at byte {1}." -f $marker, $position)
            }
        }

        if ($frameIndex -ne $FrameDelays.Length) {
            throw "GIF frame count ($frameIndex) does not match delay count ($($FrameDelays.Length))."
        }

        [System.IO.File]::WriteAllBytes($Path, $output.ToArray())
    }
    finally {
        $output.Dispose()
    }
}

Set-GifAnimationTiming -Path $gifPath -FrameDelays $delays

$resultPaths = [string[]](@($gifPath) + $framePaths.ToArray())
Get-Item -LiteralPath $resultPaths | Select-Object FullName, Length
