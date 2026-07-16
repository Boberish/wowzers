param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).ProviderPath,
    [ValidateSet("Good", "Parry")]
    [string]$Set = "Good"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$sourceDir = Join-Path $Root $(if ($Set -eq "Parry") { "parry_round_01" } else { "dodge_round_01" })
$gatePath = Join-Path $sourceDir $(if ($Set -eq "Parry") { "parry_four_pose_gate_v1.png" } else { "good_duck_four_pose_gate_v2_sword_foreground.png" })
$readyPath = Join-Path $Root "dodge_round_01/user_refs/newSwordGaurd.png"
$cardDir = Join-Path $sourceDir "production_cards"
$runtimeBase = (Resolve-Path (Join-Path $Root "../../../godot/prototypes/misprint_dodge")).ProviderPath
$runtimeDir = Join-Path $runtimeBase $(if ($Set -eq "Parry") { "frames_parry_v1" } else { "frames_good_v2" })
[System.IO.Directory]::CreateDirectory($cardDir) | Out-Null
[System.IO.Directory]::CreateDirectory($runtimeDir) | Out-Null

# The approved boards use a warm, low-saturation paper field rather than a
# chroma key. This helper flood-fills only paper-like pixels connected to an
# image edge, then keeps the largest remaining connected component. It never
# repaints the figure: surviving RGB values are copied exactly. The one resize
# is the separately-authored READY anchor, normalized to the pose-gate scale.
$source = @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public sealed class CutoutResult : IDisposable {
    public Bitmap Image;
    public Rectangle Bounds;
    public int RootX;
    public void Dispose() { if (Image != null) Image.Dispose(); }
}

public static class MisprintCutout {
    private static bool IsPaper(byte r, byte g, byte b) {
        int max = Math.Max(r, Math.Max(g, b));
        int min = Math.Min(r, Math.Min(g, b));
        return r >= 155 && g >= 142 && b >= 105 &&
            r >= g - 8 && g >= b - 12 &&
            r - g <= 78 && g - b <= 82 && max - min <= 128;
    }

    public static CutoutResult Extract(Bitmap source, Rectangle crop) {
        Bitmap image = new Bitmap(crop.Width, crop.Height, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(image)) {
            g.CompositingMode = CompositingMode.SourceCopy;
            g.DrawImage(source, new Rectangle(0, 0, crop.Width, crop.Height), crop, GraphicsUnit.Pixel);
        }

        int width = image.Width;
        int height = image.Height;
        Rectangle rect = new Rectangle(0, 0, width, height);
        BitmapData data = image.LockBits(rect, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
        int stride = data.Stride;
        byte[] pixels = new byte[stride * height];
        Marshal.Copy(data.Scan0, pixels, 0, pixels.Length);

        bool[] background = new bool[width * height];
        Queue<int> queue = new Queue<int>();
        Action<int, int> seed = (x, y) => {
            int i = y * width + x;
            int p = y * stride + x * 4;
            if (!background[i] && IsPaper(pixels[p + 2], pixels[p + 1], pixels[p])) {
                background[i] = true;
                queue.Enqueue(i);
            }
        };
        for (int x = 0; x < width; x++) { seed(x, 0); seed(x, height - 1); }
        for (int y = 0; y < height; y++) { seed(0, y); seed(width - 1, y); }
        int[] dx = { -1, 1, 0, 0 };
        int[] dy = { 0, 0, -1, 1 };
        while (queue.Count > 0) {
            int i = queue.Dequeue();
            int x = i % width;
            int y = i / width;
            for (int d = 0; d < 4; d++) {
                int nx = x + dx[d], ny = y + dy[d];
                if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
                int ni = ny * width + nx;
                if (background[ni]) continue;
                int p = ny * stride + nx * 4;
                if (!IsPaper(pixels[p + 2], pixels[p + 1], pixels[p])) continue;
                background[ni] = true;
                queue.Enqueue(ni);
            }
        }

        // Remove isolated paper flecks by retaining the largest foreground
        // component. The sword, cup guard, hands, body, coat and boots are one
        // continuous inked component in every approved source pose.
        bool[] visited = new bool[width * height];
        List<int> largest = new List<int>();
        for (int start = 0; start < visited.Length; start++) {
            if (background[start] || visited[start]) continue;
            List<int> component = new List<int>();
            visited[start] = true;
            queue.Enqueue(start);
            while (queue.Count > 0) {
                int i = queue.Dequeue();
                component.Add(i);
                int x = i % width, y = i / width;
                for (int d = 0; d < 4; d++) {
                    int nx = x + dx[d], ny = y + dy[d];
                    if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
                    int ni = ny * width + nx;
                    if (background[ni] || visited[ni]) continue;
                    visited[ni] = true;
                    queue.Enqueue(ni);
                }
            }
            if (component.Count > largest.Count) largest = component;
        }
        bool[] keep = new bool[width * height];
        foreach (int i in largest) keep[i] = true;

        int minX = width, minY = height, maxX = -1, maxY = -1;
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                int i = y * width + x;
                int p = y * stride + x * 4;
                if (!keep[i]) {
                    pixels[p + 3] = 0;
                } else {
                    pixels[p + 3] = 255;
                    minX = Math.Min(minX, x); minY = Math.Min(minY, y);
                    maxX = Math.Max(maxX, x); maxY = Math.Max(maxY, y);
                }
            }
        }
        Marshal.Copy(pixels, 0, data.Scan0, pixels.Length);
        image.UnlockBits(data);
        if (maxX < minX || maxY < minY) throw new InvalidOperationException("No figure found");

        // Root registration comes from the boot-contact band, not the full
        // silhouette (whose rapier/coat direction changes from pose to pose).
        int contactMinX = maxX;
        int contactMaxX = minX;
        int contactTop = Math.Max(minY, maxY - Math.Max(12, (maxY - minY + 1) / 8));
        for (int y = contactTop; y <= maxY; y++) {
            for (int x = minX; x <= maxX; x++) {
                if (keep[y * width + x]) {
                    contactMinX = Math.Min(contactMinX, x);
                    contactMaxX = Math.Max(contactMaxX, x);
                }
            }
        }
        int rootX = contactMaxX >= contactMinX ? (contactMinX + contactMaxX) / 2 : (minX + maxX) / 2;
        return new CutoutResult {
            Image = image,
            Bounds = Rectangle.FromLTRB(minX, minY, maxX + 1, maxY + 1),
            RootX = rootX
        };
    }

    public static Bitmap Card(CutoutResult cutout, double scale, int canvas, int anchorX, int baselineY) {
        Bitmap card = new Bitmap(canvas, canvas, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(card)) {
            g.Clear(Color.Transparent);
            g.CompositingMode = CompositingMode.SourceCopy;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            int width = (int)Math.Round(cutout.Image.Width * scale);
            int height = (int)Math.Round(cutout.Image.Height * scale);
            int x = anchorX - (int)Math.Round(cutout.RootX * scale);
            int y = baselineY - (int)Math.Round((cutout.Bounds.Bottom - 1) * scale);
            if (Math.Abs(scale - 1.0) < 0.0001) g.DrawImageUnscaled(cutout.Image, x, y);
            else g.DrawImage(cutout.Image, new Rectangle(x, y, width, height));
        }
        return card;
    }
}
'@
Add-Type -TypeDefinition $source -ReferencedAssemblies System.Drawing

$gate = [System.Drawing.Bitmap]::new($gatePath)
$ready = [System.Drawing.Bitmap]::new($readyPath)
try {
    $half = [int]($gate.Width / 2)
    if (($gate.Width % 2) -ne 0 -or ($gate.Height % 2) -ne 0 -or $half -ne [int]($gate.Height / 2)) {
        throw "Expected an even square 2x2 pose gate; got $($gate.Width)x$($gate.Height)"
    }
    if ($Set -eq "Parry") {
        $specs = @(
            @{ Name = "parry_ready"; Source = $ready; Crop = [Drawing.Rectangle]::new(0, 0, $ready.Width, $ready.Height); Scale = 0.57 },
            @{ Name = "parry_load"; Source = $gate; Crop = [Drawing.Rectangle]::new(0, 0, $half, $half); Scale = 1.0 },
            @{ Name = "parry_contact"; Source = $gate; Crop = [Drawing.Rectangle]::new($half, 0, $half, $half); Scale = 1.0 },
            @{ Name = "parry_riposte"; Source = $gate; Crop = [Drawing.Rectangle]::new(0, $half, $half, $half); Scale = 1.0 },
            @{ Name = "parry_recover"; Source = $gate; Crop = [Drawing.Rectangle]::new($half, $half, $half, $half); Scale = 1.0 }
        )
    } else {
        $specs = @(
            @{ Name = "good_ready"; Source = $ready; Crop = [Drawing.Rectangle]::new(0, 0, $ready.Width, $ready.Height); Scale = 0.57 },
            @{ Name = "good_compress"; Source = $gate; Crop = [Drawing.Rectangle]::new(0, 0, $half, $half); Scale = 1.0 },
            @{ Name = "good_clearance"; Source = $gate; Crop = [Drawing.Rectangle]::new($half, 0, $half, $half); Scale = 1.0 },
            @{ Name = "good_settle"; Source = $gate; Crop = [Drawing.Rectangle]::new(0, $half, $half, $half); Scale = 1.0 },
            @{ Name = "good_recover"; Source = $gate; Crop = [Drawing.Rectangle]::new($half, $half, $half, $half); Scale = 1.0 }
        )
    }
    foreach ($spec in $specs) {
        $cutout = [MisprintCutout]::Extract($spec.Source, $spec.Crop)
        try {
            $card = [MisprintCutout]::Card($cutout, [double]$spec.Scale, 768, 384, 768)
            try {
                $file = "$($spec.Name).png"
                $cardPath = Join-Path $cardDir $file
                $runtimePath = Join-Path $runtimeDir $file
                $card.Save($cardPath, [Drawing.Imaging.ImageFormat]::Png)
                [IO.File]::Copy($cardPath, $runtimePath, $true)
                $transparent = $card.GetPixel(0, 0).A -eq 0 -and $card.GetPixel(767, 767).A -eq 0
                if (-not $transparent) { throw "$file does not have transparent corners" }
                "{0}: source bounds={1}, rootX={2}, scale={3}, canvas=768x768" -f $file, $cutout.Bounds, $cutout.RootX, $spec.Scale
            }
            finally { $card.Dispose() }
        }
        finally { $cutout.Dispose() }
    }
}
finally {
    $ready.Dispose()
    $gate.Dispose()
}
